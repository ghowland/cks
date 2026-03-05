import sys
import json
from pathlib import Path
from zenosync import ZenodoSync

ZENODO_CRED_PATH = "/mnt/c/Users/Geoff/.secure/zenodo.json"
PAPERS_JSON_PATH = "papers.json"


def load_papers(papers_path):
    with open(papers_path, "r") as f:
        return json.load(f)


def find_paper(papers, paper_id):
    for paper in papers:
        if paper["paper_id"] == paper_id:
            return paper
    return None


def format_description(text):
    if not text:
        return ""
    import re
    text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
    paragraphs = text.split("\n\n")
    result = []
    for para in paragraphs:
        para = para.strip().replace("\n", "<br>")
        if para:
            result.append("<p>" + para + "</p>")
    return "\n".join(result)


def build_metadata(paper):
    title = paper["title"]
    if paper.get("subtitle"):
        title = title + ": " + paper["subtitle"]

    description = format_description(paper.get("abstract") or "")

    publication_date = "2026-02"
    raw_date = paper.get("frontmatter", {}).get("Date", "")
    if raw_date:
        # "February 2026" -> "2026-02", just use as-is if already formatted
        months = {
            "January": "01", "February": "02", "March": "03", "April": "04",
            "May": "05", "June": "06", "July": "07", "August": "08",
            "September": "09", "October": "10", "November": "11", "December": "12"
        }
        parts = raw_date.split()
        if len(parts) == 2 and parts[0] in months:
            publication_date = parts[1] + "-" + months[parts[0]]

    github_path = paper.get("file_path", "")

    metadata = {
        "title": title,
        "upload_type": "publication",
        "publication_type": "article",
        "description": description,
        "version": "1.0",
        "publication_date": publication_date,
        "access_right": "open",
        "license": "CC-BY-4.0",
        "keywords": [
            "cymatic k-space mechanics",
            "CKS framework",
            "hexagonal lattice",
            "discrete spacetime",
            "zero free parameters",
            "falsifiable physics",
            "substrate mechanics",
            "python"
        ],
        "related_identifiers": [
            {
                "scheme": "url",
                "identifier": "https://github.com/ghowland/cks/blob/main/" + github_path,
                "relation": "isSupplementedBy",
                "resource_type": "software"
            }
        ],
        "creators": [
            {
                "name": "Howland, Geoffrey",
                "affiliation": "Independent Researcher",
                "orcid": "0009-0009-7752-341X"
            }
        ],
        "contributors": [
            {
                "name": "Howland, Geoffrey",
                "type": "ContactPerson",
                "affiliation": "Independent Researcher"
            },
            {
                "name": "Claude Sonnet 4.5",
                "type": "Researcher",
                "affiliation": "Anthropic PBC"
            },
            {
                "name": "Gemini 3 Flash",
                "type": "Researcher",
                "affiliation": "Google LLC"
            },
            {
                "name": "DeepSeek-V3",
                "type": "Researcher",
                "affiliation": "DeepSeek AI"
            }
        ],
        "communities": [
            {"identifier": "zenodo"},
            {"identifier": "cks"}
        ],
        "subjects": [
            {
                "term": "Physics",
                "identifier": "https://id.loc.gov/authorities/subjects/sh85101653",
                "scheme": "url"
            }
        ],
        "language": "eng"
    }

    return metadata


def create_paper(paper_id, papers_path=PAPERS_JSON_PATH, config_path=ZENODO_CRED_PATH):
    papers = load_papers(papers_path)

    paper = find_paper(papers, paper_id)
    if paper is None:
        raise ValueError("paper_id not found in papers.json: " + paper_id)

    metadata = build_metadata(paper)

    manifest_path = "zenodo_master_manifest.json"
    zn = ZenodoSync(manifest_path=manifest_path, config_path=config_path)

    created = zn.create_draft([(paper_id, metadata)], limit=1)
    if not created:
        raise RuntimeError("create_draft returned empty result for: " + paper_id)

    doi = zn.reserve_doi(paper_id)
    zenodo_id = zn.manifest["records"][paper_id].get("zenodo_id")

    output_paper = {}
    for k, v in paper.items():
        output_paper[k] = v

    output_paper["doi"] = {
        "raw": doi or "10.5281/zenodo.zzz",
        "is_stub": doi is None,
        "zenodo_id": zenodo_id,
        "status": "draft"
    }

    output_path = Path("paper_" + paper_id + ".json")
    temp_path = output_path.with_suffix(".tmp")
    with open(temp_path, "w") as f:
        json.dump(output_paper, f, indent=2)
    temp_path.replace(output_path)

    print("Created draft for: " + paper_id)
    print("Zenodo ID: " + str(zenodo_id))
    print("DOI: " + str(doi))
    print("Written to: " + str(output_path))

    return output_paper


def main():
    if len(sys.argv) < 2:
        print("Usage: python create_paper.py <paper_id>")
        print("Example: python create_paper.py CKS-MATH-11-2026")
        sys.exit(1)

    paper_id = sys.argv[1]

    try:
        result = create_paper(paper_id)
    except Exception as e:
        print("Error: " + str(e))
        sys.exit(1)


if __name__ == "__main__":
    main()
    