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
TARBALL=$(shell dune-release delegate-info tarball)
VERSION=$(shell dune-release delegate-info tarball | cut -d'-' -f2 | cut -d'.' -f '-3')

tag:
	dune-release tag
	git push --tags

info:
	@echo "OPAM_REPO: $(OPAM_REPO)"
	@echo "TARBALL: $(TARBALL)"
	@echo "VERSION: $(VERSION)"

release:
	dune-release distrib
	dune-release opam pkg
	cp -R _build/caretaker.$(VERSION) $(OPAM_REPO)/caretaker/
	cp $(TARBALL) $(OPAM_REPO)/caretaker/caretaker.$(VERSION)/
