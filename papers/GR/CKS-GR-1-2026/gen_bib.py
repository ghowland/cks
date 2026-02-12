import json
import re

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
    # Remove brackets: [CKS-MATH-0-2026] -> CKS-MATH-0-2026
    clean_id = registry_id.strip("[]")
    
    # Split parts: CKS, TOPIC, INDEX, YEAR
    parts = clean_id.split('-')
    
    # Handle the special case [CKS-0-2026] where there is no topic
    if len(parts) == 3:
        topic = "CORE"
        index = parts[1]
        year = parts[2]
        key = f"CORE-{index}-{year}"
    else:
        topic = parts[1]
        index = parts[2]
        year = parts[3]
        # Generate the Key as per your pattern: MATH-0-2026
        key = f"{topic}-{index}-{year}"

    # Build the specific Github path based on your topic
    # Note: Using the full clean_id for the final folder name
    github_url = f"https://github.com/ghowland/cks/tree/main/papers/{topic}/{clean_id}"
    
    # Create the BibTeX string
    entry = f"""@article{{{key},
  author = {{Howland, Geoffrey}},
  title = {{CKS Reference: {clean_id}}},
  year = {{{year}}},
  url = {{https://zenodo.org/record/YOUR_ID_HERE}},
  note = {{Github: {github_url}}}
}}
"""
    return entry

def main():
    # We generate entries for the dependencies
    bib_entries = []
    for dep in manuscript_json["dependencies"]:
        bib_entries.append(generate_bib_entry(dep))
    
    # Write to file
    with open("references.bib", "w") as f:
        f.write("\n".join(bib_entries))
    
    print("Successfully generated references.bib with the following keys:")
    for entry in bib_entries:
        # Just print the first line for verification
        print(f"  {entry.split('{')[1].split(',')[0]}")

if __name__ == "__main__":
    main()

