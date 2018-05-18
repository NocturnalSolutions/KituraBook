#!/usr/bin/env csh
# Script to generate ebooks
setenv MDLIST "README.md `ls README.md *.md appendices/*.md | sed -E -e 's/(README|SUMMARY).md//g' | paste -s -d ' ' -`"
setenv TOCSETS "--toc --toc-depth=2"
setenv PDFSETS "$TOCSETS --include-in-header=tex-addons.tex -V fontfamily:bookman --listings"
pandoc -o ebooks/Kitura-Until-Dawn.pdf -V papersize:letter $PDFSETS $MDLIST && echo "Letter size PDF exported"
pandoc -o ebooks/Kitura-Until-Dawn-A4.pdf -V papersize:A4 $PDFSETS $MDLIST && echo "A4 size PDF exported"
pandoc -o ebooks/Kitura-Until-Dawn.epub --epub-metadata=epub-metadata.xml --epub-cover-image=images/logo-vert.png $TOCSETS $MDLIST && echo "Epub exported"
pandoc -o ebooks/Kitura-Until-Dawn.docx $TOCSETS $MDLIST && echo "Word exported"
# KindleGen downloaded from https://www.amazon.com/gp/feature.html?docId=1000765211
kindlegen ebooks/Kitura-Until-Dawn.epub && echo "Mobipocket exported"
