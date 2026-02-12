#!/bin/bash

# Replace the Unicode ₖ with math-mode _k
# sed 's/ₖ/_k/g' manuscript.md > manuscript_fixed.md
sed -e 's/ₖ/$_k$/g' \
    -e 's/ᵢ/$_i$/g' \
    -e 's/ρ/$\\rho$/g' \
    -e 's/π/$\\pi$/g' \
    -e 's/μ/$\\mu$/g' \
    -e 's/ν/$\\nu$/g' \
    -e 's/Λ/$\\Lambda$/g' \
    -e 's/𝕋/$\\mathbb{T}$/g' \
    -e 's/✓/$\\checkmark$/g' \
    -e 's/✗/$\\times$/g' \
    -e 's/⚠/\\textbf{!}/g' \
    manuscript.md > manuscript_fixed.md


# Remove the invisible Variation Selector (U+FE0F)
sed -i 's/\xEF\xB8\x8F//g' manuscript_fixed.md

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
  -V "title:" \
  --metadata nocite='@*' \
  --csl=../../../pass-through.csl \
  -V colorlinks=true \
  -V linkcolor=blue

# Clean up the temporary file (optional)
rm manuscript_fixed.md

