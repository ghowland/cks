import os
import json
import hashlib
import requests
import time
from typing import List, Dict, Any, Optional
from pathlib import Path

class ZenodoSync:
    def __init__(self, manifest_path: str, config_path: str = "~/.secure/zenodo.json"):
        self.config_path = Path(config_path).expanduser()
        self.manifest_path = Path(manifest_path)
        self.config = self._load_config()
        
        self.token = self.config["api_token"]
        self.sandbox = self.config.get("sandbox", True)
        self.base_url = (
            "https://sandbox.zenodo.org/api" 
            if self.sandbox 
            else "https://zenodo.org/api"
        )
        
        self.manifest = self._load_manifest()

    def _load_config(self) -> Dict[str, Any]:
        if not self.config_path.exists():
            raise FileNotFoundError(f"Config not found at {self.config_path}")
        with open(self.config_path, "r") as f:
            return json.load(f)

    def _load_manifest(self) -> Dict[str, Any]:
        if self.manifest_path.exists():
            with open(self.manifest_path, "r") as f:
                return json.load(f)
        return {"records": {}, "last_full_sync": None}

    def _save_manifest(self):
        temp_path = self.manifest_path.with_suffix(".tmp")
        with open(temp_path, "w") as f:
            json.dump(self.manifest, f, indent=2)
        temp_path.replace(self.manifest_path)

    def _get_file_hash(self, filepath: str) -> str:
        """MD5 hash to match Zenodo's internal checksums."""
        hash_md5 = hashlib.md5()
        with open(filepath, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()

    def _get_metadata_hash(self, metadata: Dict[str, Any]) -> str:
        """Deterministic hash of metadata dictionary."""
        encoded = json.dumps(metadata, sort_keys=True).encode("utf-8")
        return hashlib.sha256(encoded).hexdigest()

    def _request(self, method: str, endpoint: str, **kwargs) -> requests.Response:
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        params = kwargs.get("params", {})
        params["access_token"] = self.token
        kwargs["params"] = params
        
        response = requests.request(method, url, **kwargs)
        if response.status_code == 429:
            time.sleep(5)  # Basic rate limit backoff
            return self._request(method, endpoint, **kwargs)
        response.raise_for_status()
        return response

    def bootstrap_from_remote(self):
        """Initial sync: Pull all existing depositions into manifest."""
        print("Bootstrapping manifest from Zenodo...")
        url = "deposit/depositions"
        
        while url:
            # Handle absolute URLs returned by Zenodo pagination
            if url.startswith("http"):
                res = requests.get(url, params={"access_token": self.token})
            else:
                res = self._request("GET", url)
            
            res.raise_for_status()
            data = res.json()
            
            for item in data:
                # Individual fetch to get full file details
                depo_id = item["id"]
                full_item = self._request("GET", f"deposit/depositions/{depo_id}").json()
                
                # We use the title or a slug as a placeholder local_id if unknown
                # In production, mapping logic usually relies on specific metadata fields
                local_key = f"remote_{depo_id}"
                
                self.manifest["records"][local_key] = {
                    "zenodo_id": depo_id,
                    "doi": full_item.get("metadata", {}).get("prereserve_doi", {}).get("doi"),
                    "status": full_item.get("state"),
                    "metadata_hash": self._get_metadata_hash(full_item.get("metadata", {})),
                    "files": {
                        f["filename"]: {"checksum": f["checksum"], "filesize": f["filesize"]}
                        for f in full_item.get("files", [])
                    }
                }
            
            # Check links for next page
            links = res.links
            url = links.get("next", {}).get("url") if links else None
        
        self.manifest["last_full_sync"] = time.strftime("%Y-%m-%dT%H:%M:%SZ")
        self._save_manifest()

    def sync_record(self, local_id: str, metadata: Dict[str, Any], file_paths: List[str], publish: bool = False):
        """Sync specific document metadata and files."""
        record = self.manifest["records"].get(local_id, {})
        depo_id = record.get("zenodo_id")
        meta_hash = self._get_metadata_hash(metadata)
        
        # 1. Ensure Deposition exists
        if not depo_id:
            res = self._request("POST", "deposit/depositions", json={"metadata": metadata})
            depo_data = res.json()
            depo_id = depo_data["id"]
            record = {
                "zenodo_id": depo_id,
                "doi": depo_data["metadata"].get("prereserve_doi", {}).get("doi"),
                "status": "draft",
                "files": {}
            }
        else:
            # 2. Update Metadata if drifted
            if record.get("metadata_hash") != meta_hash:
                self._request("PUT", f"deposit/depositions/{depo_id}", json={"metadata": metadata})
        
        record["metadata_hash"] = meta_hash
        
        # 3. Verify Attachments
        # Refresh file list from server to be sure
        remote_info = self._request("GET", f"deposit/depositions/{depo_id}").json()
        bucket_url = remote_info["links"]["bucket"]
        remote_files = {f["filename"]: f for f in remote_info.get("files", [])}
        
        current_files_manifest = {}
        
        for p in file_paths:
            path = Path(p)
            fname = path.name
            local_hash = self._get_file_hash(p)
            
            needs_upload = False
            if fname not in remote_files:
                needs_upload = True
            elif remote_files[fname]["checksum"] != local_hash:
                # Delete old version before re-upload in draft
                file_id = remote_files[fname]["id"]
                self._request("DELETE", f"deposit/depositions/{depo_id}/files/{file_id}")
                needs_upload = True
            
            if needs_upload:
                with open(path, "rb") as f:
                    self._request("PUT", f"{bucket_url.split('/api/')[1]}/{fname}", data=f)
                # Re-fetch hash after upload
                current_files_manifest[fname] = {"checksum": local_hash, "size": path.stat().st_size}
            else:
                current_files_manifest[fname] = {
                    "checksum": remote_files[fname]["checksum"],
                    "size": remote_files[fname]["filesize"]
                }

        record["files"] = current_files_manifest

        # 4. Optional Publish
        if publish and record["status"] != "published":
            self._request("POST", f"deposit/depositions/{depo_id}/actions/publish")
            record["status"] = "published"
            # Refresh DOI after publish
            final = self._request("GET", f"deposit/depositions/{depo_id}").json()
            record["doi"] = final.get("doi")

        self.manifest["records"][local_id] = record
        self._save_manifest()
        return record

