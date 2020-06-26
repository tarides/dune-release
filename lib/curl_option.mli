type auth = { user : string; token : string }

type t =
  | Location
      (** If the server reports that the requested page has moved to a different
          location, this option will make curl redo the request on the new
          place. *)
  | User of auth
      (** Specify the user name and password for server authentication. *)
  | Silent
      (** Silent or quiet mode. Don't show progress meter or error messages.
          Makes Curl mute. It will still output the data you ask for,
          potentially even to the terminal/stdout unless you redirect it. *)
  | Show_error
      (** When used with -s, --silent, it makes curl show an error message if it
          fails. *)
  | Config of [ `Stdin | `File of string ]
      (** Specify a text file to read curl arguments from. The command line
          arguments found in the text file will be used as if they were provided
          on the command line. *)
  | Dump_header of [ `Ignore | `File of string ]
      (** Write the received protocol headers to the specified file. *)
  | Data of [ `Data of string | `File of string ]
      (** Sends the specified data in a POST request to the HTTP server. *)
  | Data_binary of [ `Data of string | `File of string ]
      (** This posts data exactly as specified with no extra processing
          whatsoever. *)
  | Header of string
      (** Extra header to include in the request when sending HTTP. *)

val to_string_list : t list -> string list
