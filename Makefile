.PHONY: all build push

IMAGE=tarides/caretaker
PLATFORM=linux/amd64

all:
	dune build

build:
	docker build --platform=${PLATFORM} -t ${IMAGE} .

push: build
	docker push ${IMAGE}
