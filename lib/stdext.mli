open Bos_setup

(** Safe wrapping for some Bytes functions. *)
module Sbytes : sig
  type t = Bytes.t
  (** An alias for the type of byte sequences. *)

  val make : int -> char -> (t, [> R.msg ]) result
  (** [make n c] returns a new byte sequence of length [n], filled with the byte
      [c]. Returns an error message if [n < 0] or [n > Sys.max_string_length]. *)

  val blit_string :
    string -> int -> t -> int -> int -> (unit, [> R.msg ]) result
  (** [blit src srcoff dst dstoff len] copies [len] bytes from string [src],
      starting at index [srcoff], to byte sequence [dst], starting at index
      [dstoff]. Returns an error message if [srcoff] and [len] do not designate
      a valid range of [src], or if [dstoff] and [len] do not designate a valid
      range of [dst]. *)
end

module Path : sig
  val is_backup_file : string -> bool
  (** [is_backup_file s] returns [true] iff the filename [s]:

      - ends with ['~']
      - or begins with ['#'] and ends with ['#']. *)

  val find_files : name_wo_ext:string -> Fpath.t list -> Fpath.t list
  (** [find_files ~name_wo_ext files] returns the list of files among [files]
      whose name without the extension is equal to [name_wo_ext]. Backup files
      are ignored. *)
end
