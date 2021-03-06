#!/bin/bash

# Defaults
# Generate html version (0=no, <>0=yes)
HTML=1
# Generate epub version 
EPUB=0
# Generate pdf version 
PDF=0
# Build path (where /build is mounted in docker-compose.yml)
BUILDDIR=./_build

if [[ $# -gt 0 && ("$1" == '--help' ) ]]; then
  echo "
Usage: $0 -[ehp]

Builds this ebook, by default only in HTML format.

  -e: create ePub
  -h: *skip* HTML creation
  -p: create Pdf

"
  exit 1
fi

while getopts "hep" opt; do
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
    *)
      echo "Unknown option ${opt}"
      exit 1
      ;;
  esac
done

# Open stuff
# Mac default
OPEN=open
hash ${OPEN} >/dev/null 2>&1
if (( $? )); then
  OPEN=xdg-open
  hash ${OPEN} >/dev/null 2>&1
  if (( $? )); then
    OPEN=''
  fi
fi
# End Open stuff

set -euo pipefail

# build HTML book
docker-compose run adoc ./build.sh $@ -o /build 

if [ "${OPEN}" != '' ]; then
  if [ $HTML -ne 0 ]; then
    HTMLFILE=$(grep "HTML:" "${BUILDDIR}"/.built | cut -c 6-)
    ${OPEN} "${BUILDDIR}"/$HTMLFILE
  fi
  if [ $EPUB -ne 0 ]; then
    EPUBFILE=$(grep "EPUB:" "${BUILDDIR}"/.built | cut -c 6-)
    ${OPEN} "${BUILDDIR}"/${EPUBFILE}
  fi
  if [ $PDF -ne 0 ]; then
    PDFFILE=$(grep "PDF:" "${BUILDDIR}"/.built | cut -c 5-)
    ${OPEN} "${BUILDDIR}"/"${PDFFILE}"
  fi
fi

echo "All done! 🍻"