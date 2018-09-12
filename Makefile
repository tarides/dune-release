.PHONY: all clean test

all:
	dune build

clean:
	dune clean

test:
	dune runtest
