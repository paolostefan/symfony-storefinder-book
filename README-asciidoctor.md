# Asciidoc

## Prerequisites

- `sudo apt install build-essential pkg-config zlib1g-dev libxslt1-dev libxml2-dev`
- `sudo gem install bundler:2.1.4`
- `bundle install`

## With Docker

```sh
docker pull asciidoctor/docker-asciidoctor:latest
docker-compose run adoc # opens an interactive shell in the asciidoctor container
docker-compose run adoc ./build.sh     # build HTML book
docker-compose run adoc ./build.sh -hp # build PDF
docker-compose run adoc ./build.sh -he # build EPUB
docker-compose run adoc ./build.sh -ep # build HTML+EPUB+PDF
```

<https://asciidoctor.org/docs/user-manual/>