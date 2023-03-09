val dune_checks :
  dry_run:bool ->
  skip_build:bool ->
  skip_tests:bool ->
  pkg_names:string list ->
  Fpath.t ->
  (int, [ `Msg of string ]) result
(** Checks if the packages in [dir] build and pass their tests. It returns an
    error if any of the checks couldn't be performed. Otherwise, it returns
    [Ok 0] if checking positive and [Ok 1] if checking negative. If [pkg_names]
    is not empty, it limits which packages get checked. If [skip_build] or
    [skip_tests] are [true], the correspondent checks are skipped. *)

val check_project :
  pkg_names:string list ->
  skip_lint:bool ->
  skip_build:bool ->
  skip_tests:bool ->
  check_change_log:bool ->
  ?tag:Vcs.Tag.t ->
  ?version:Version.t ->
  keep_v:bool ->
  ?build_dir:Fpath.t ->
  dir:Fpath.t ->
  unit ->
  (int, [ `Msg of string ]) result
(** Checks

    - if the project in [dir] is compatible with dune-release \
    - if the user is connected to internet \
    - if the packages in [dir] can be built and pass their tests; tweakable by
      [skip_build] and [skip_tests]\
    - if the packages in [dir] pass the linting; tweakable by [skip_linting]\

    the arguments [pkg_names], [tag], [version], [keep_v], [build_dir] and [dir]
    are used to create a [Pkg.t] the same way it would be created running other
    dune-release commands. *)
