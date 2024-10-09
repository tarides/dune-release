(lang dune 3.7)

(name caretaker)

(generate_opam_files true)

(source
 (github tarides/caretaker))

(authors "Thomas Gazagnaire")

(maintainers "Tarides")

(license ISC)

(package
 (name caretaker)
 (synopsis "Taking care of our technical projects")
 (description
  "A tool to interface with the different sources we use for project management.")
 (depends
  (alcotest :with-test)
  cmdliner
  (caretaker-lib
   (= :version))
  dune-build-info))

(package
 (name caretaker-lib)
 (synopsis "Taking care of our technical projects")
 (description
  "A library to interface with the different sources we use for project management.")
 (depends
  (alcotest :with-test)
  calendar
  cohttp-lwt-unix
  conduit-lwt-unix
  csv
  lwt_ssl
  (okra-lib
   (and
    (>= 3.0.0)
    (< 4.0.0)))
  (omd
   (>= 2.0.0~alpha4))
  yojson))
