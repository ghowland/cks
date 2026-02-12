import json
import os
import shutil

def generate_bib_entry(manuscript_data):
    """
    Creates a BibTeX entry using the 'publisher' field as a safe 
    pass-through variable for the Registry ID.
    """
    # Extract ID: "[CKS-GR-1-2026]" -> "CKS-GR-1-2026"
    full_id = manuscript_data["registry_id"].strip("[]")
    long_title = manuscript_data["title"]
    
    parts = full_id.split('-')
    
    # Determine Topic Folder and Year
    # Pattern CKS-0-2026 (3 parts) -> _CKS
    # Pattern CKS-MATH-0-2026 (4 parts) -> MATH
    if len(parts) == 3:
        topic_folder = "_CKS"
        year = parts[2]
    else:
        topic_folder = parts[1]
        year = parts[3]

    github_url = f"https://github.com/ghowland/cks/tree/main/papers/{topic_folder}/{full_id}"
    
    # Generate entry using double-braces to preserve exact casing and content.
    # We use 'publisher' because Citeproc reliably passes this string to the CSL.
    entry = f"""@article{{{full_id},
  author = {{Howland, Geoffrey}},
  title = {{{{{long_title}}}}},
  publisher = {{{{{full_id}}}}},
  year = {{{year}}},
  url = {{https://zenodo.org/record/YOUR_ID_HERE}},
  note = {{Github: {github_url} }}
}}
"""
    return entry

def main():
    # Execute from the root directory where the 'papers' folder lives
    root_papers_dir = "./papers"  
    master_entries = {}
    target_dirs = []

    if not os.path.exists(root_papers_dir):
        print(f"Error: {root_papers_dir} directory not found.")
        return

    print(f"Scanning for manuscript.json files in {root_papers_dir}...")

    # 1. Walk through all directories to find manuscripts and collect data
    for root, dirs, files in os.walk(root_papers_dir):
        if "manuscript.json" in files:
            file_path = os.path.join(root, "manuscript.json")
            
            try:
                with open(file_path, 'r') as f:
                    data = json.load(f)
                    reg_id = data.get("registry_id")
                    
                    if reg_id:
                        print(f"  Found: {reg_id}")
                        # Keep track of every directory that needs a bib file
                        target_dirs.append(root)
                        # Generate and store the bib entry
                        entry = generate_bib_entry(data)
                        master_entries[reg_id] = entry
                    else:
                        print(f"  Warning: No registry_id in {file_path}")
                        
            except Exception as e:
                print(f"  Error reading {file_path}: {e}")

    if not master_entries:
        print("No valid entries found in manifest.json files.")
        return

    # 2. Write the Master Bibliography to the current root directory
    master_bib_name = "references.bib"
    sorted_ids = sorted(master_entries.keys())
    
    with open(master_bib_name, "w") as f:
        for reg_id in sorted_ids:
            f.write(master_entries[reg_id])
            f.write("\n")

    print(f"\nSuccess: Generated master {master_bib_name} with {len(sorted_ids)} entries.")

    # 3. Copy the Master Bib to every directory that contains a manifest.json
    print(f"Distributing {master_bib_name} to {len(target_dirs)} directories...")
    for target in target_dirs:
        dest = os.path.join(target, master_bib_name)
        shutil.copy2(master_bib_name, dest)
        print(f"  Copied to: {target}")

    print("\nGlobal Bibliography Distribution Complete.")

if __name__ == "__main__":
    main()
    