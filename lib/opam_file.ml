let upgrade ~url ~version opam_t =
  match version with
  | `V1 descr ->
      opam_t |> OpamFormatUpgrade.opam_file_from_1_2_to_2_0
      |> OpamFile.OPAM.with_url url
      |> OpamFile.OPAM.with_descr descr
      |> OpamFile.OPAM.with_version_opt None
      |> OpamFile.OPAM.with_name_opt None
  | `V2 ->
      opam_t |> OpamFile.OPAM.with_url url
      |> OpamFile.OPAM.with_version_opt None
      |> OpamFile.OPAM.with_name_opt None
