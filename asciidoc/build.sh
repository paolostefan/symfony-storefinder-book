#!/bin/bash

if [[ $# -gt 0 && ("$1" == '--help' ) ]]; then
  echo "Usage: $0 -[ehp]"
  echo "-h: skip HTML creation"
  echo "-e: create ePub"
  echo "-p: create Pdf"
  exit 1
fi


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

set -euxo pipefail

# Genera la versione html (0=no, <>0=sì)?
HTML=1
# Genera la versione epub?
EPUB=0
# Genera la versione pdf?
PDF=0

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

SRCDIR=$(realpath $(dirname $0))
BUILDDIR=$(realpath "${SRCDIR}"/../build)
MAIN="${SRCDIR}"/book.adoc
HTMLFILE=store_locator_symfony_book.html


echo "Building into ${BUILDDIR}"

# Aggiorna il numero di build
LAST_BUILDNO=$(cat ${MAIN} | grep :build: | cut -d ' ' -f 2)
BUILDNO=$((${LAST_BUILDNO} + 1))
REGEX="/:build:\\s${LAST_BUILDNO}/:build: ${BUILDNO}/"
sed -i s"${REGEX}" ${MAIN}

echo "Build n. ${BUILDNO}"

if [ $HTML -ne 0 ]; then
  asciidoctor -v -D "$BUILDDIR" ${MAIN} -o ${HTMLFILE}

  # Sync images dirs
  echo "Syncing image dirs"
  cd "${SRCDIR}"
  for i in $(find . -name "images" -type d); do
    i=$(echo $i | cut -c 3-)
    echo " Copying ${SRCDIR}/$i to $BUILDDIR/$i"
    mkdir -p "$BUILDDIR"/"$i"
    cp -r "$i"/* "$BUILDDIR"/$i/
  done
  echo "Sync done"

  if [ "${OPEN}" != "" ]; then
    ${OPEN} "$BUILDDIR"/$HTMLFILE
  fi
else
  echo "* Skipping html creation"
fi

if [ $EPUB -ne 0 ]; then
  asciidoctor-epub3 --trace -D "$BUILDDIR" -a ebook-validate 

  if [ "${OPEN}" != "" ]; then
    ${OPEN} "$BUILDDIR"/book.epub
  fi
else
  echo "* Skipping epub creation"
fi

if [ $PDF -ne 0 ]; then

PDFFILE=Store-finder-Symfony_${BUILDNO}.pdf

asciidoctor-pdf -v -a pdf-style="${SRCDIR}"/book-theme.yml \
  --trace -a pdf-fontsdir="${SRCDIR}"/font/ \
  -D "${BUILDDIR}" -o ${PDFFILE} ${MAIN}

  if [ "${OPEN}" != "" ]; then
    ${OPEN} "${BUILDDIR}"/"${PDFFILE}"
  fi
else
  echo "* Skipping pdf creation"
fi

echo "All done! 🍻"