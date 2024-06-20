FROM ocaml/opam:alpine-ocaml-4.14 AS build
RUN sudo mv /usr/bin/opam-2.2 /usr/bin/opam
WORKDIR /src
RUN opam repo add tarides https://github.com/tarides/opam-repository.git
COPY caretaker.opam .
RUN opam install . --depext-only
RUN opam install . --deps-only --with-test
COPY . .
RUN opam exec -- dune build

FROM alpine
COPY --from=build /src/_build/install/default/bin/caretaker /caretaker
RUN apk add curl
WORKDIR /src
ENTRYPOINT ["/caretaker"]
