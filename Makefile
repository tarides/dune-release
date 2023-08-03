.PHONY: all build push

IMAGE=tarides/caretaker
PLATFORMS=linux/amd64,linux/arm64

all:
	dune build --display=quiet

build:
	docker build -t ${IMAGE} .

push:
	docker buildx build --platform=${PLATFORMS} -t ${IMAGE} . --push
