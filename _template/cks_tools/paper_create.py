import json
import time
import os
from pathlib import Path
from zenosync import ZenodoSync  # Using the lib we built

# --- CONFIGURATION ---
PAPERS_JSON = "cks/papers.json"
MANIFEST_JSON = "zenodo_master_manifest.json"
PAPERS_ROOT = Path("cks")
SLEEP_INTERVAL = 5 # Seconds between API calls

def map_cks_to_zenodo(paper):
    """Converts papers.json entry to Zenodo Metadata Schema."""
    # Construct description from abstract and frontmatter
    description = f"<h3>Abstract</h3><p>{paper['abstract']}</p>"
    description += "<h3>Framework Metadata</h3><ul>"
    for k, v in paper['frontmatter'].items():
        description += f"<li><b>{k}:</b> {v}</li>"
    description += "</ul>"

    return {
        "title": paper["title"],
        "upload_type": "publication",
        "publication_type": "article",
        "description": description,
        "creators": [{"name": "Cymatic K-Space Framework", "affiliation": "CKS Research"}],
        "notes": f"Paper ID: {paper['paper_id']}",
        "access_right": "open"
    }

def main():
    # 1. Initialize Sync Library
    zn = ZenodoSync(manifest_path=MANIFEST_JSON)
    
    # 2. Load Work List
    with open(PAPERS_JSON, "r") as f:
        papers_worklist = json.load(f)

    print(f"Loaded {len(papers_worklist)} papers from registry.")

    # 3. Key Realignment (Fix 'remote_ID' to 'CKS-ID')
    # If a remote record contains a file named 'CKS-XXX.zip', rename the key
    records = zn.manifest.get("records", {})
    mapping_updates = {}
    for manifest_id, data in records.items():
        if manifest_id.startswith("remote_"):
            for filename in data.get("files", {}).keys():
                if filename.endswith(".zip") and "CKS-" in filename:
                    actual_id = filename.replace(".zip", "")
                    mapping_updates[manifest_id] = actual_id
    
    for old_id, new_id in mapping_updates.items():
        print(f"Mapping legacy {old_id} -> {new_id}")
        records[new_id] = records.pop(old_id)
    zn._save_manifest()

    # 4. Processing Loop
    for paper in papers_worklist:
        paper_id = paper["paper_id"]
        print(f"\n[Processing] {paper_id}")

        # Determine Local Paths
        # Based on: cks/papers/ADHM/CKS-ADHM-1-2026/manuscript.md
        # We look for manuscript.pdf and the .zip in that same folder
        base_dir = PAPERS_ROOT / Path(paper["file_path"]).parent
        
        # Collect files that exist
        files_to_upload = []
        possible_files = [
            base_dir / "!manuscript.pdf",
            base_dir / f"{paper_id}.zip"
        ]

        for f_path in possible_files:
            if f_path.exists():
                files_to_upload.append(str(f_path))
            else:
                print(f"  ! Warning: File not found: {f_path}")

        if not files_to_upload:
            print(f"  ! Skipping {paper_id}: No files found to upload.")
            continue

        # Prepare Metadata
        zenodo_metadata = map_cks_to_zenodo(paper)

        # Sync to Zenodo
        try:
            # zn.sync_record handles checking the manifest:
            # - If paper_id exists, it checks for metadata/file drift
            # - If not, it creates a new deposition
            result = zn.sync_record(
                local_id=paper_id,
                metadata=zenodo_metadata,
                file_paths=files_to_upload,
                publish=False # Safety: keep as draft so you can verify
            )
            
            print(f"  + Synced: {paper_id} (Zenodo ID: {result['zenodo_id']})")
            print(f"  + DOI: {result.get('doi')}")

        except Exception as e:
            print(f"  ! Error syncing {paper_id}: {e}")

        # Throttling
        print(f"Waiting {SLEEP_INTERVAL}s...")
        time.sleep(SLEEP_INTERVAL)

    print("\nBatch Sync Complete.")

if __name__ == "__main__":
    main()

