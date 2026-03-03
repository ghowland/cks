import os
import json
import sys
from pathlib import Path
from zenosync import ZenodoSync

ZENODO_CRED_PATH = "/mnt/c/Users/Geoff/.secure/zenodo.json"
OUTPUT_JSON_PATH = "zenodo_master_manifest.json"

def main():
    # 1. Define Paths
    config_path = Path(ZENODO_CRED_PATH).expanduser()
    manifest_path = Path(OUTPUT_JSON_PATH)

    # 2. Check if credentials exist
    if not config_path.exists():
        print(f"Error: Credentials file not found at {config_path}")
        sys.exit(1)

    # 3. Initialize the library
    # The library handles the base URL (Sandbox vs Production) internally 
    # based on the 'sandbox' flag in your zenodo.json
    print(f"Initializing ZenodoSync with config: {config_path}")
    
    try:
        zn = ZenodoSync(
            manifest_path=str(manifest_path), 
            config_path=str(config_path)
        )
    except Exception as e:
        print(f"Failed to initialize library: {e}")
        sys.exit(1)

    # 4. Perform the Bootstrap (The Initial Inventory Download)
    print("Connecting to Zenodo to download current inventory...")
    print("Note: This may take a minute as we fetch file details for each deposition.")
    
    try:
        # This method iterates through all pages of your account
        # and populates the manifest_path with all 145+ existing documents.
        zn.bootstrap_from_remote()
        
        # Verify result
        if manifest_path.exists():
            with open(manifest_path, "r") as f:
                data = json.load(f)
                record_count = len(data.get("records", {}))
                
            print("-" * 30)
            print(f"SUCCESS: Inventory complete.")
            print(f"Master manifest saved to: {manifest_path.absolute()}")
            print(f"Total records recovered: {record_count}")
            print(f"Last Sync Timestamp: {data.get('last_full_sync')}")
            print("-" * 30)
        else:
            print("Error: Sync finished but manifest file was not created.")

    except Exception as e:
        print(f"An error occurred during inventory sync: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

