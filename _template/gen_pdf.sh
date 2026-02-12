#!/bin/bash

# Replace the Unicode ₖ with math-mode _k
sed 's/ₖ/_k/g' manuscript.md > manuscript_fixed.md

# Force every citation to be a manual internal link to its bibliography anchor
sed -i 's/\[@\(CKS-[^]]*\)\]/[[\1]](#ref-\1)/g' manuscript_fixed.md

# Run your successful Pandoc command on the fixed file
pandoc manuscript_fixed.md -o manuscript.pdf \
  --pdf-engine=xelatex \
  -V mainfont="FreeSerif" \
  -V monofont="FreeMono" \
  --filter pandoc-citeproc \
  --bibliography=references.bib \
  --metadata link-citations=true \
  -V colorlinks=true \
  -V linkcolor=blue 

# Clean up the temporary file (optional)
rm manuscript_fixed.md

