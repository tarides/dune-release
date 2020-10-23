let upgrade ~filename ~url ~id ~version opam_t =
  let commit_hash =
    { OpamParserTypes.FullPos.pelem = OpamParserTypes.FullPos.String id
    ; pos = OpamTypesBase.pos_file filename }
  in
  match version with
  | `V1 descr ->
      opam_t |> OpamFormatUpgrade.opam_file_from_1_2_to_2_0
      |> OpamFile.OPAM.with_url url
      |> OpamFile.OPAM.with_descr descr
      |> OpamFile.OPAM.with_version_opt None
      |> OpamFile.OPAM.with_name_opt None
      |> fun x -> OpamFile.OPAM.add_extension x "x-commit-hash" commit_hash
  | `V2 ->
      opam_t |> OpamFile.OPAM.with_url url
      |> OpamFile.OPAM.with_version_opt None
      |> OpamFile.OPAM.with_name_opt None
      |> fun x -> OpamFile.OPAM.add_extension x "x-commit-hash" commit_hash
