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

# 1. Remove leading spaces (4+) that trigger automatic code blocks in Pandoc
sed -i 's/^    //g' manuscript_fixed.md

# 2. Remove any triple backticks that are wrapping your axioms
sed -i 's/```//g' manuscript_fixed.md

# 1. Fix list formatting: Force a newline before any hyphen that is preceded by a character
sed -i 's/\([[:alnum:]\)]\)- /\1\n- /g' manuscript_fixed.md

# 2. General Math-to-LaTeX: Convert simple symbols ($ followed by a backslash and letters) 
# into \( \) format. This removes the visible dollar signs for Greek letters globally.
sed -i 's/\$\(\\[a-zA-Z]\{1,\}\)\$/\\(\1\\)/g' manuscript_fixed.md

# Convert literal \( and \) sequences back to standard math $ markers
sed -i 's/\\(\\/$/g' manuscript_fixed.md
sed -i 's/\\)/$/g' manuscript_fixed.md

# Normalize blackboard bold sets and Unicode subscripts to LaTeX math
sed -i -e 's/ℝ/$\\mathbb{R}$/g' \
       -e 's/ℚ/$\\mathbb{Q}$/g' \
       -e 's/ℤ/$\\mathbb{Z}$/g' \
       -e 's/ₙ/$_n$/g' manuscript_fixed.md

pandoc manuscript_fixed.md -o !manuscript.pdf \
  --pdf-engine=xelatex \
  --from markdown+tex_math_dollars \
  --citeproc \
  --bibliography=references.bib \
  --metadata link-citations=true \
  --metadata title="CKS-GR-1-2026" \
  -V mainfont="FreeSerif" \
  -V monofont="FreeMono" \
  -V "title:" \
  -V header-includes="\usepackage{float}" \
  -V header-includes="\makeatletter\def\fps@figure{H}\makeatother" \
  --lua-filter=../../../_template/columns.lua \
  --metadata nocite='@*' \
  --csl=../../../pass-through.csl \
  -V colorlinks=true \
  -V linkcolor=blue

# Clean up the temporary file (optional)
rm manuscript_fixed.md

