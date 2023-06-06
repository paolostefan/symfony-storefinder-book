#!/bin/bash

set -euo pipefail

SRCDIR=$GITHUB_WORKSPACE/asciidoc
BUILDDIR=/tmp
MAIN="${SRCDIR}"/book.adoc

echo "Building into ${BUILDDIR}"

# Get current build number (variable in ${MAIN} asciidoc file)
BUILDNO=$(cat ${MAIN} | grep :build: | cut -d ' ' -f 2)

echo "Build n. ${BUILDNO}"

PDFFILE=Store-finder-Symfony_${BUILDNO}.pdf

asciidoctor-pdf -v -a pdf-style="${SRCDIR}"/book-theme.yml \
    --trace -a pdf-fontsdir="${SRCDIR}"/font/ \
    -D "${BUILDDIR}" -o ${PDFFILE} ${MAIN}

ls -la ${BUILDDIR}/${PDFFILE}

# Set the artifact path for subsequent steps
echo "PDF_PATH=${BUILDDIR}/${PDFFILE}" >> "$GITHUB_OUTPUT"

echo ":floppy_disk: Built PDF at path ${BUILDDIR}/${PDFFILE}" >>$GITHUB_STEP_SUMMARY
