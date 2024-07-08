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

#### GH Project Boards

```
$ dune exec -- ./bin/main.exe
org: tarides

== Platform Roadmap (PVT_kwDOAeo-K84AA2jF) ==

 - Odoc Generates Rich and Easily Navigable Documentation -
  [   OD29] Output usage statistics of identifiers to enable ranked search
    Objective   : Odoc Generates Rich and Easily Navigable Documentation
    Status      :
    Schedule    : Q2 2023 - Apr-Jun
    Priority    : 🌋 Top Priority
    Team        : Tooling
    Stakeholder : Leo White
  [Plat244] Odoc has a search bar to search through the documentation
    Objective   : Odoc Generates Rich and Easily Navigable Documentation
    Status      : Active 🏗
    Schedule    : Q2 2023 - Apr-Jun
    Priority    : 🌋 Top Priority
    Team        : Tooling
  [Plat267] Markdown rendering engine for odoc
    Objective   : Odoc Generates Rich and Easily Navigable Documentation
    Status      : Unscheduled 🔮
    Schedule    :
    Stakeholder : Leo White
    Funder      : Jane Street - Commercial
    Team        : Tooling
  [Plat266] Odoc supports documentation of function parameters
    Objective   : Odoc Generates Rich and Easily Navigable Documentation
    Status      : Unscheduled 🔮
    Schedule    :
    Stakeholder : Leo White
    Funder      : Jane Street - Commercial

[...]
```

Use `--format=csv` to get an extract to CSV.

#### Timesheets


```
$ export OKR_UPDATES=~/git/okr-updates
$ dune exec -- bin/main.exe --timesheets
"MC103","2023"," 3","3.5"
"Plat216","2023"," 3","1.0"
"Plat216","2023"," 4","1.5"
"Plat216","2023"," 8","1.5"
"Plat216","2023"," 9","0.5"
"Plat163","2023"," 1","0.5"
"Plat163","2023"," 2","4.0"
"Plat163","2023"," 3","4.0"
"Plat163","2023"," 4","4.0"
"Plat163","2023"," 6","1.5"
"Plat163","2023"," 7","3.0"
"Plat163","2023"," 8","1.5"
"Plat163","2023"," 9","0.5"
"Plat163","2023","10","2.5"
"Plat163","2023","11","2.0"
"Plat184","2023"," 1","1.5"
"MOS99","2023"," 5","1.0"
"MOS99","2023"," 6","0.0"
"MOS99","2023"," 9","0.0"
"Com21","2023"," 1","0.5"
"Com21","2023"," 6","1.0"
"Com21","2023"," 7","1.0"
"Com21","2023"," 7","1.0"
"Com21","2023"," 8","3.0"
"Com21","2023"," 8","1.0"
"Com21","2023"," 9","1.5"
"Com21","2023"," 9","1.0"
"Com21","2023","11","0.5"
"Com21","2023","12","0.5"
"Comp79","2023"," 1","0.5"
"Comp79","2023"," 3","0.5"
"Comp79","2023"," 4","0.0"
"Comp121","2023"," 4","2.0"
"Comp121","2023"," 5","5.5"
"Comp121","2023"," 6","4.0"
"Comp121","2023"," 7","4.5"
"Comp121","2023"," 8","4.5"
"Comp121","2023"," 9","3.5"
[...]
```

#### Upload CSV

```
$ dune exec -- ./bin/upload.exe input.csv
```
