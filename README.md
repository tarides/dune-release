<h1 align="center">
  caretaker
</h1>

<p align="center">
  <strong>Taking care of our technical projects.</strong>
</p>

<p align="center">
  <!--
  <a href="https://ocaml.ci.dev/github/tarides/caretaker">
    <img src="https://img.shields.io/endpoint?url=https://ocaml.ci.dev/badge/tarides/caretaker/main&logo=ocaml" alt="OCaml-CI Build Status" />
  </a>
  -->

  <a href="https://github.com/tarides/caretaker/actions/workflows/build.yml">
    <img src="https://github.com/tarides/caretaker/actions/workflows/build.yml/badge.svg?branch=main" alt="Build Status" />
  </a>
</p>

## Getting Started

### Installation

Install opam if you don't already have it, and add [`tarides/opam-repository`](https://github.com/tarides/opam-repository) to your list of opam repositories:

Either only to the current opam switch with the command:
```sh
opam repository add tarides https://github.com/tarides/opam-repository.git
```

Or to the list of opam repositories for all opam switches with the command:
```sh
opam repository add --all tarides https://github.com/tarides/opam-repository.git
```

Update your list of packages:
```sh
opam update
```

Then install caretaker:
```sh
opam install caretaker
```

### Build

```
dune build
```

### Usage

Use `--format=csv` to get an extract to CSV.

#### GH Project Boards

#### Timesheets

#### Upload CSV
