#!/usr/bin/env csh
# Script to generate ebooks
# Call from .git/hooks/pre-push

# List of chapters, in order
setenv MDLIST "../README.md `ls content/*.md content/appendices/*.md | sed -E -e 's/(README|SUMMARY|afterword).md//g' | sed -E -e 's/(.+)/..\/\1/g' | paste -s -d ' ' -`"
# Filter to correct paths for Pandoc
setenv FILTER "--lua-filter=../meta/internal-link-rewrite.lua"
# Option to add TOC to certain document types that use it
setenv TOCSETS "--toc --toc-depth=2"
# Geometry settings for PDF
setenv GEOM "-V geometry:top=1.5cm -V geometry:bottom=1.5cm -V geometry:left=2cm -V geometry:right=2cm -V geometry:includefoot"
# Combined settings for PDF
setenv PDFSETS "$TOCSETS $GEOM --include-in-header=../meta/tex-addons.tex -V fontfamily:bookman -V subparagraph --listings"

cd content && pwd

pandoc -o ../ebooks/Kitura-Until-Dawn.pdf -V papersize:letter $FILTER $PDFSETS $MDLIST && echo "Letter size PDF exported"
pandoc -o ../ebooks/Kitura-Until-Dawn-A4.pdf -V papersize:A4 $FILTER $PDFSETS $MDLIST && echo "A4 size PDF exported"
# The warning about a nonemtpy <title> element can be ignored. Don't add
# "--metadata title=blah" to the CLI command or else KindleGen will see two
# titles and fail, and both Apple Books and Calibre will handle the epub just
# fine anyway.
pandoc -o ../ebooks/Kitura-Until-Dawn.epub --epub-metadata=../meta/epub-metadata.xml --epub-cover-image=images/logo-vert.png $FILTER $TOCSETS $MDLIST && echo "Epub exported"
pandoc -o ../ebooks/Kitura-Until-Dawn.docx $FILTER $TOCSETS $MDLIST && echo "Word exported"
pandoc -o ../ebooks/Kitura-Until-Dawn.rtf -s $FILTER $TOCSETS $MDLIST && echo "RTF exported"
# KindleGen downloaded from https://www.amazon.com/gp/feature.html?docId=1000765211
kindlegen ../ebooks/Kitura-Until-Dawn.epub && echo "Mobipocket exported"

# Synch web site
# Commented out while Edition 2 is still in progress
# rsync -vaz ../ebooks/ nocturn1@nocturnal.solutions:learnkitura.com/files/

# Exit with code 0 so push continues even if building failed
exit 0
