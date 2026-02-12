#!/bin/bash

# 1. Replace the Unicode ₖ with math-mode _k
sed 's/ₖ/_k/g' manuscript.md > manuscript_fixed.md

# 2. Run your successful Pandoc command on the fixed file
pandoc manuscript_fixed.md -o manuscript.pdf \
  --pdf-engine=xelatex \
  -V mainfont="FreeSerif" \
  -V monofont="FreeMono" \
  --filter pandoc-citeproc \
  --bibliography=references.bib \
  --metadata link-citations=true \
  --csl=pass-through.csl \
  -V colorlinks=true \
  -V linkcolor=blue 

# 3. Clean up the temporary file (optional)
rm manuscript_fixed.md

