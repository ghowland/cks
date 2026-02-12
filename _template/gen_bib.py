import json

# Your JSON data
manuscript_json = {
    "file_name": "manuscript.md",
    "title": "[CKS-GR-1-2026] General Relativity as Mathematical Consequence of CKS",
    "registry_id": "[CKS-GR-1-2026]",
    "dependencies": [
        "[CKS-0-2026]",
        "[CKS-MATH-0-2026]",
        "[CKS-MATH-1-2026]",
        "[CKS-MATH-10-2026]",
        "[CKS-QM-1-2026]",
        "[CKS-SM-1-2026]"
    ]
}

def generate_bib_entry(registry_id):
    # Strip brackets: [CKS-GR-1-2026] -> CKS-GR-1-2026
    # This full string IS the key and the directory name
    full_id = registry_id.strip("[]")
    
    parts = full_id.split('-')
    
    # Determine folder and Year based on ID structure
    if len(parts) == 3: # Pattern: CKS-0-2026
        topic_folder = "CORE"
        year = parts[2]
    else: # Pattern: CKS-MATH-0-2026
        topic_folder = parts[1]
        year = parts[3]

    github_url = f"https://github.com/ghowland/cks/tree/main/papers/{topic_folder}/{full_id}"
    
    # Generate entry using the full CKS-ID as the key
    entry = f"""@article{{{full_id},
  author = {{Howland, Geoffrey}},
  title = {{CKS Reference: {full_id}}},
  year = {{{year}}},
  url = {{https://zenodo.org/record/YOUR_ID_HERE}},
  note = {{Github: {github_url} }}
}}
"""

    return entry

def main():
    bib_entries = []
    for dep in manuscript_json["dependencies"]:
        bib_entries.append(generate_bib_entry(dep))
    
    with open("references.bib", "w") as f:
        f.write("\n".join(bib_entries))
    
    print("Generated references.bib with full CKS keys.")

if __name__ == "__main__":
    main()
    