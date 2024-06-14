mtelvers week 2: 2024/01/08 -- 2024/01/14

# Last Week

- System administration and ops (Plat174)
  - @mtelvers (5 days)
  - Planning Meeting + 1:1 Thibaut
  - Investigated CO2e emissions form the cluster compared to long haul travel
  - Setup Jenny with Windows desktop access
  - Jenny - user admin - delete GitHub and Google accounts
  - Reviewed and approved Fedora 39 PR https://github.com/ocurrent/ocaml-dockerfile/pull/200#pullrequestreview-1811120594
  - Installed Ubuntu updates on check.ci.ocaml.org
  - Changed Slack webhook for check.ci.ocaml.org to point to ocaml-org-deployer (rather than to Kate's personal channel)
  - https://github.com/tarides/infrastructure/issues/285
  - watch.ocaml.org was down [Issue#89](https://github.com/ocaml/infrastructure/issues/89) deleted log, installed updates and rebooted
  - Added support to opam-repo-ci for Windows builds.  [Draft](https://github.com/mtelvers/opam-repo-ci/pull/new/windows)
  - Cleaned up epochs on docs.ci.ocaml.org
  - OCaml.ci was running low on disk space.  The database was ~150GB containing jobs since the inception of the project.  Cleared the database and let the jobs result
  - Rebuilt all macOS workers to address [Issue#90](https://github.com/ocaml/infrastructure/issues/90)
  - Investigated Windows OCaml Dockerfile component of the base image builder and the KB numbers are a mix of server and workstation images.  [Draft](https://github.com/mtelvers/opam-repo-ci/pull/new/windows)
  - Scheduled power shutdown in Caelum.  Restarted various servers and VMs after power was restored.  Posted a notification on OCaml.org.  PR: (changelog) Electrical work post (ocaml/ocaml.org#1938), PR: Electrical Work (ocaml/infrastructure#91)
