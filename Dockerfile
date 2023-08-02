FROM ocaml/opam:alpine-ocaml-4.14 AS build
RUN sudo mv /usr/bin/opam-2.2 /usr/bin/opam
WORKDIR /src
COPY caretaker.opam .
RUN opam install . --depext-only
RUN opam install . --deps-only --with-test
COPY . .
RUN opam exec -- dune build

FROM alpine
COPY --from=build /src/_build/install/default/bin/caretaker /caretaker
WORKDIR /src
ENTRYPOINT ["/caretaker"]
