#!/bin/bash

# Defaults
# Generate html version (0=no, <>0=yes)
HTML=0
# Generate epub version 
EPUB=0
# Generate pdf version 
PDF=0
# Build path
BUILDDIR=../build

if [[ $# -gt 0 && ("$1" == '--help' ) ]]; then
  echo "
Usage: $0 -[ehp] [-o BUILDDIR]

Builds this ebook, by default only in HTML format.

  -h: *skip* HTML creation
  -e: create ePub
  -p: create Pdf
  -o BUILDDIR: output contents to BUILDDIR (the default is $(realpath ${BUILDDIR}))"
  exit 1
fi

set -euo pipefail

while getopts "heo:p" opt; do
  case "${opt}" in
    e)
      EPUB=1
      ;;
    p)
      PDF=1
      ;;
    h)
      HTML=0
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

SRCDIR=/asciidoc
BUILDDIR=$(realpath "${BUILDDIR}")
MAIN="${SRCDIR}"/book.adoc


echo "Building into ${BUILDDIR}"

# Increment build number
LAST_BUILDNO=$(cat ${MAIN} | grep :build: | cut -d ' ' -f 2)
BUILDNO=$((${LAST_BUILDNO} + 1))
REGEX="/:build:\\s${LAST_BUILDNO}/:build: ${BUILDNO}/"
sed -i s"${REGEX}" ${MAIN}

echo "Build n. ${BUILDNO}"

echo -n "" >${BUILDDIR}/.built

if [ $HTML -ne 0 ]; then
  typeset -x HTMLFILE=Store-finder-Symfony_${BUILDNO}.html
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

if [ $EPUB -ne 0 ]; then
  asciidoctor-epub3 --trace -D "${BUILDDIR}" -a ebook-validate 
  echo "EPUB:book.epub" >>${BUILDDIR}/.built
else
  echo "* Skipping epub creation"
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
