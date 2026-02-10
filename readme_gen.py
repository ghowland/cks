#!/usr/bin/env python3
"""
CKS README.md Generator
Populates template with paper metadata and generates README.md for each paper
"""

import json
import re
from pathlib import Path

# Domain mapping for cleaner output
DOMAIN_NAMES = {
    'MATH': 'Mathematical Foundation',
    'QM': 'Quantum Mechanics',
    'SM': 'Standard Model',
    'GR': 'General Relativity',
    'COS': 'Cosmology',
    'BIO': 'Biology & Life Sciences',
    'BODY': 'Movement & Body Mechanics',
    'COG': 'Cognition & Consciousness',
    'NEURO': 'Neuroscience',
    'SENS': 'Sensory Systems',
    'MED': 'Medical Applications',
    'AI': 'Computing & AI',
    'DWDM': 'Telecommunications & Photonics',
    'MAT': 'Materials Science',
    'SEMI': 'Semiconductors',
    'ENG': 'Engineering & Mechanics',
    'FLOW': 'Fluid Dynamics',
    'ENV': 'Environment & Infrastructure',
    'SOC': 'Social Systems',
    'LANG': 'Language & Communication',
    'DATA': 'Data & Information Theory',
    'META': 'Meta-Analysis',
    'DISC': 'Discovery Process',
    'EDU': 'Education',
    'ART': 'Art & Aesthetics',
    'TEST': 'Experimental Falsification'
}


def clean_title(title):
    """Remove embedded registry IDs from titles"""
    return re.sub(r'\[CKS-[A-Z]+-\d+-\d+\]\s*', '', title)


def make_bib_key(registry_id):
    """Create bibtex key from registry ID"""
    # CKS-MATH-1-2026 -> cks_math_1_2026
    return registry_id.replace('-', '_').lower()


def format_prerequisites(deps):
    """Format dependency list for README"""
    # Remove CKS-0-2026 from prerequisites (always implicit)
    filtered = [d for d in deps if d != 'CKS-0-2026']
    if not filtered:
        return 'None (foundation paper)'
    return ', '.join(filtered)


def generate_readme(paper, template):
    """Generate README.md for a single paper"""
    
    rid = paper['registry_id']
    topic = rid.split('-')[1]
    title = clean_title(paper['title'])
    
    # Basic replacements
    readme = template
    readme = readme.replace('<<TITLE>>', title)
    readme = readme.replace('<<REGISTRY_ID>>', rid)
    readme = readme.replace('<<SERIES_PATH>>', paper.get('series_path', ''))
    readme = readme.replace('<<DOI_LINK>>', f'[Pending - {rid}]')
    readme = readme.replace('<<DOMAIN>>', DOMAIN_NAMES.get(topic, topic))
    readme = readme.replace('<<DOMAIN_FOCUS>>', DOMAIN_NAMES.get(topic, topic))
    readme = readme.replace('<<PREREQUISITES>>', format_prerequisites(paper['dependencies']))
    readme = readme.replace('<<BIB_KEY>>', make_bib_key(rid))
    
    # LLM placeholders - leave for manual population
    readme = readme.replace('<<LLM_ABSTRACT>>', '[To be extracted from manuscript.md]')
    readme = readme.replace('<<LLM_DOMAIN_RESULTS>>', '[To be extracted from manuscript.md]')
    readme = readme.replace('<<LLM_INDUSTRIAL_APP>>', '[To be extracted from manuscript.md]')
    readme = readme.replace('<<FAQS>>', '')
    
    return readme


def main():
    # Load data
    papers = json.load(open('papers.json'))
    template = open('_template/README.md').read()
    
    # Process each paper
    count = 0
    for paper in papers:
        rid = paper['registry_id']
        topic = rid.split('-')[1]
        
        # Create output path
        output_dir = Path('papers') / topic / rid
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Generate and write README
        readme = generate_readme(paper, template)
        output_file = output_dir / 'README.md'
        output_file.write_text(readme)
        
        print(f'Generated: {output_file}')
        count += 1
    
    print(f'\nTotal: {count} README files generated')


if __name__ == '__main__':
    main()


