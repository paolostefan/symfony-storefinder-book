#!/bin/bash

set -euo pipefail

SRCDIR=/documents
BUILDDIR=/tmp
MAIN="${SRCDIR}"/book.adoc

echo "Building into ${BUILDDIR}"

# Increment build number (variable in ${MAIN} asciidoc file)
BUILDNO=$(cat ${MAIN} | grep :build: | cut -d ' ' -f 2)

echo "Build n. ${BUILDNO}"

PDFFILE=Store-finder-Symfony_${BUILDNO}.pdf

asciidoctor-pdf -v -a pdf-style="${SRCDIR}"/book-theme.yml \
    --trace -a pdf-fontsdir="${SRCDIR}"/font/ \
    -D "${BUILDDIR}" -o ${PDFFILE} ${MAIN}

echo ":floppy_disk: Built PDF: ${PDFFILE}" >>$GITHUB_STEP_SUMMARY

echo "All done! :beers:" >>$GITHUB_STEP_SUMMARY