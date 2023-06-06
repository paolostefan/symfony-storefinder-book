#!/bin/bash

if [[ $# -gt 0 && ("$1" == '--help' ) ]]; then
  echo "
Usage: $0 -[ehp]

Builds this ebook using asciidoctor docker container.

  -e: build ePub
  -h: build HTML
  -p: build Pdf

"
  exit 1
fi

# Defaults
# Build html (0=no, <>0=yes)
HTML=0
# Build epub 
EPUB=0
# Build pdf 
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
      HTML=1
      ;;
    *)
      echo "Unknown option ${opt}"
      exit 1
      ;;
  esac
done

set -euo pipefail

# build HTML book
docker compose run adoc /scripts/build.sh $@ -o /build 

echo "All done! 🍻"