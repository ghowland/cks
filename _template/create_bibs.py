import json
import os
import shutil

def generate_bib_entry(manuscript_data):
    """
    Creates a BibTeX entry from a manuscript.json object.
    """
    # Extract ID: "[CKS-GR-1-2026]" -> "CKS-GR-1-2026"
    full_id = manuscript_data["registry_id"].strip("[]")
    title = manuscript_data["title"]
    
    parts = full_id.split('-')
    
    # Determine Topic Folder and Year
    if len(parts) == 3:  # Pattern: CKS-0-2026
        topic_folder = "_CKS"
        year = parts[2]
    else:               # Pattern: CKS-MATH-0-2026
        topic_folder = parts[1]
        year = parts[3]

    github_url = f"https://github.com/ghowland/cks/tree/main/papers/{topic_folder}/{full_id}"
    
    # Generate the entry
    entry = f"""@article{{{full_id},
  author = {{Howland, Geoffrey}},
  title = {{{title}}},
  year = {{{year}}},
  url = {{https://zenodo.org/record/YOUR_ID_HERE}},
  note = {{Github: {github_url} }}
}}
"""
    return entry

def main():
    root_papers_dir = "./papers"  # Set this to your papers root
    master_entries = {}
    target_dirs = []

    print(f"Scanning for manuscript.json files in {root_papers_dir}...")

    # 1. Walk through all directories to find manuscripts and collect data
    for root, dirs, files in os.walk(root_papers_dir):
        if "manuscript.json" in files:
            file_path = os.path.join(root, "manuscript.json")
            target_dirs.append(root)  # Store this dir to copy the bib file later
            
            try:
                with open(file_path, 'r') as f:
                    data = json.load(f)
                    reg_id = data.get("registry_id")
                    
                    if reg_id:
                        print(f"  Found: {reg_id}")
                        entry = generate_bib_entry(data)
                        master_entries[reg_id] = entry
            except Exception as e:
                print(f"  Error reading {file_path}: {e}")

    if not master_entries:
        print("No entries found. Check your root_papers_dir path.")
        return

    # 2. Write the Master Bibliography to the current directory
    master_bib_path = "references.bib"
    sorted_ids = sorted(master_entries.keys())
    
    with open(master_bib_path, "w") as f:
        for reg_id in sorted_ids:
            f.write(master_entries[reg_id])
            f.write("\n")

    print(f"\nSuccess: Generated master {master_bib_path} with {len(sorted_ids)} entries.")

    # 3. Copy the Master Bib to every directory that contains a manuscript.json
    print(f"Distributing {master_bib_path} to {len(target_dirs)} directories...")
    for target in target_dirs:
        dest = os.path.join(target, master_bib_path)
        shutil.copy2(master_bib_path, dest)
        print(f"  Copied to: {target}")

    print("\nGlobal Bibliography Distribution Complete.")

if __name__ == "__main__":
    main()
    