#!/bin/bash

# Defaults
# Generate html version (0=no, <>0=yes)
HTML=1
# Generate epub version 
EPUB=0
# Generate pdf version 
PDF=0
# Build path
BUILDDIR=../_build

if [[ $# -gt 0 && ("$1" == '--help' ) ]]; then
  echo "
Usage: $0 -[ehp] [-o BUILDDIR]

Builds this ebook.

  -h: build HTML
  -e: build ePub
  -p: build Pdf
  -o BUILDDIR: output contents to BUILDDIR (defaults to $(realpath ${BUILDDIR}))

"
  exit 1
fi

set -euo pipefail

while getopts "ehpo:" opt; do
  case "${opt}" in
    e)
      EPUB=1
      ;;
    h)
      HTML=1
      ;;
    p)
      PDF=1
      ;;
    o)
      BUILDDIR=$OPTARG
      ;;
    *)
      echo "Unknown option ${opt}"
      exit 1
      ;;
  esac
done

SRCDIR=$(realpath $(dirname $0))
BUILDDIR=$(realpath "${BUILDDIR}")
MAIN="${SRCDIR}"/book.adoc

echo "Building into ${BUILDDIR}"

# Increment build number (variable in ${MAIN} asciidoc file)
LAST_BUILDNO=$(cat ${MAIN} | grep :build: | cut -d ' ' -f 2)
BUILDNO=$((${LAST_BUILDNO} + 1))
REGEX="/:build:\\s${LAST_BUILDNO}/:build: ${BUILDNO}/"
sed -i s"${REGEX}" ${MAIN}

echo "Build n. ${BUILDNO}"

echo -n "" >${BUILDDIR}/.built

if [ $EPUB -ne 0 ]; then
  asciidoctor-epub3 --trace -D "${BUILDDIR}" -a ebook-validate 
  echo "EPUB:book.epub" >>${BUILDDIR}/.built
else
  echo "* Skipping epub creation"
fi

if [ $HTML -ne 0 ]; then
  HTMLFILE=Store-finder-Symfony_${BUILDNO}.html
  asciidoctor -v -D "${BUILDDIR}" ${MAIN} -o ${HTMLFILE}

  # Sync images dirs
  echo "Syncing image dirs"
  cd "${SRCDIR}"
  for i in $(find . -name "images" -type d | cut -c 3-); do
    echo " Copying ${SRCDIR}/$i to ${BUILDDIR}/$i"
    mkdir -p "${BUILDDIR}"/"$i"
    cp -r "$i"/* "${BUILDDIR}"/$i/
  done
  echo "Sync done"
  
  echo "HTML:${HTMLFILE}" >>${BUILDDIR}/.built
else
  echo "* Skipping html creation"
fi

if [ $PDF -ne 0 ]; then
  PDFFILE=Store-finder-Symfony_${BUILDNO}.pdf

  asciidoctor-pdf -v -a pdf-style="${SRCDIR}"/book-theme.yml \
    --trace -a pdf-fontsdir="${SRCDIR}"/font/ \
    -D "${BUILDDIR}" -o ${PDFFILE} ${MAIN}
  echo "PDF:${PDFFILE}" >>${BUILDDIR}/.built
else
  echo "* Skipping pdf creation"
fi
