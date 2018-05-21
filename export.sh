#!/usr/bin/env csh
# Script to generate ebooks
# Call from .git/hooks/pre-push
setenv MDLIST "README.md `ls README.md *.md appendices/*.md | sed -E -e 's/(README|SUMMARY).md//g' | paste -s -d ' ' -`"
setenv TOCSETS "--toc --toc-depth=2"
setenv GEOM "-V geometry:top=1.5cm -V geometry:bottom=1.5cm -V geometry:left=2cm -V geometry:right=2cm -V geometry:includefoot"
setenv PDFSETS "$TOCSETS $GEOM --include-in-header=tex-addons.tex -V fontfamily:bookman --listings"
pandoc -o ebooks/Kitura-Until-Dawn.pdf -V papersize:letter $PDFSETS $MDLIST && echo "Letter size PDF exported"
pandoc -o ebooks/Kitura-Until-Dawn-A4.pdf -V papersize:A4 $PDFSETS $MDLIST && echo "A4 size PDF exported"
pandoc -o ebooks/Kitura-Until-Dawn.epub --epub-metadata=epub-metadata.xml --epub-cover-image=images/logo-vert.png $TOCSETS $MDLIST && echo "Epub exported"
pandoc -o ebooks/Kitura-Until-Dawn.docx $TOCSETS $MDLIST && echo "Word exported"
pandoc -o ebooks/Kitura-Until-Dawn.rtf -s $TOCSETS $MDLIST && echo "RTF exported"
# KindleGen downloaded from https://www.amazon.com/gp/feature.html?docId=1000765211
kindlegen ebooks/Kitura-Until-Dawn.epub && echo "Mobipocket exported"
# Exit with code 0 so push continues even if building failed
exit 0
