.PHONY: all build push

IMAGE=tarides/caretaker
PLATFORMS=linux/amd64,linux/arm64

all:
	dune build --display=quiet

build:
	docker build -t ${IMAGE} .

push:
	docker buildx build --platform=${PLATFORMS} -t ${IMAGE} . --push

run:
	docker run -it -v ${HOME}/.github:/root/.github tarides/caretaker fetch


OPAM_REPO=$(HOME)/git/tarides/opam-repository
TARBALL=$(dune-release delegate-info tarball)
VERSION=$(dune-release delegate-info tarball | cut -d'-' -f2 | cut -d'.' -f '-3')

release:
	dune-release check
	dune-release distrib
	dune-release opam pkg
	cp _build/caretaker.$(VERSION) $(OPAM_REPO)/caretaker
	cp $(TARBALL) $(OPAM_REPO)/caretaker/caretaker.$(VERSION/
