#!/bin/bash

# Replace the Unicode ₖ with math-mode _k
sed 's/ₖ/_k/g' manuscript.md > manuscript_fixed.md

# 2. Build PDF using the MODERN engine
# --citeproc is now a built-in flag
# ::: {#refs} ::: will now work perfectly in your .md file
pandoc manuscript_fixed.md -o manuscript.pdf \
  --pdf-engine=xelatex \
  --citeproc \
  --bibliography=references.bib \
  --metadata link-citations=true \
  --metadata title="CKS-GR-1-2026" \
  -V mainfont="FreeSerif" \
  -V monofont="FreeMono" \
  --csl=pass-through.csl \
  -V colorlinks=true \
  -V linkcolor=blue

# Clean up the temporary file (optional)
rm manuscript_fixed.md

