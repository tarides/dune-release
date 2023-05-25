(lang dune 3.7)

(name caretaker)

(generate_opam_files true)

(source
 (github tarides/caretake))

(authors "Thomas Gazagnaire")

(maintainers "Tarides")

(license ISC)

(package
 (name caretaker)
 (synopsis "Taking care of our technical projects")
 (description
  "A tool to interface with the different sources we use for project management.")
 (depends
  cohttp-lwt-unix
  yojson
  cmdliner
  lwt_ssl
  csv
  conduit-lwt-unix
  omd
  calendar
  (alcotest :with-test)))
