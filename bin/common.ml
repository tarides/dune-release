open Caretaker
open Cmdliner

let org_term =
  Arg.(
    value @@ pos 0 string "tarides"
    @@ info ~doc:"The organisation to get projects from" ~docv:"ORG" [])

type source = Github | Okr_updates | Admin | Local

let source_term default =
  let sources =
    Arg.enum
      [
        ("github", Github);
        ("okr-updates", Okr_updates);
        ("admin", Admin);
        ("local", Local);
      ]
  in
  Arg.(
    value @@ opt sources default
    @@ info ~doc:"The data-source to read data from." ~docv:"SOURCE"
         [ "source"; "s" ])

let dry_run_term =
  Arg.(value @@ flag @@ info ~doc:"Do not do any network calls." [ "dry-run" ])

let project_number_term =
  Arg.(
    value @@ opt int 25
    @@ info ~doc:"The project IDS" ~docv:"ID" [ "number"; "n" ])

let project_goals_term =
  Arg.(
    value @@ opt string "goals"
    @@ info ~doc:"The project goals" ~docv:"REPOSITORY" [ "goals" ])

let items_per_page =
  Arg.(
    value
    @@ opt (some int) None
    @@ info
         ~doc:
           "Number of items per page for the GraphQL pagination calls (default \
            is 80)"
         [ "items-per-page" ])

let years =
  let all_years = [ 2021; 2022; 2023 ] in
  Arg.(
    value
    @@ opt (list ~sep:',' int) all_years
    @@ info ~doc:"The years to consider" ~docv:"YEARS" [ "years" ])

let weeks =
  let weeks = Arg.conv (Weeks.of_string, Weeks.pp) in
  Arg.(
    value @@ opt weeks Weeks.all
    @@ info
         ~doc:
           "The weeks to consider. By default, use all weeks. The format is a \
            $(b,`,')-separated list of values, where a value is either \
            specific week number, an (inclusive) range between week numbers \
            like $(b,`12-16'), or a quarter name (like $(b,`q1'). For \
            instance, $(b,--weeks='12,q1,34-45') is a valid parameter."
         ~docv:"WEEKS" [ "weeks" ])

let users =
  Arg.(
    value
    @@ opt (some (list ~sep:',' string)) None
    @@ info ~doc:"The users to consider" ~docv:"NAMES" [ "users" ])

let ids =
  let arg =
    Arg.(
      value
      @@ opt (some (list ~sep:',' string)) None
      @@ info
           ~doc:
             "The IDs to consider. Use $(b, -id) to not consider a specific ID \
              $(b,id). "
           ~docv:"IDs" [ "ids" ])
  in
  let f ids =
    match ids with None -> None | Some ids -> Some (List.map Filter.query ids)
  in
  Term.(const f $ arg)

let data_dir_term =
  let env = Cmd.Env.info ~doc:"PATH" "DATA_DIR" in
  Arg.(
    value @@ opt string "data"
    @@ info ~env
         ~doc:"Use data from a local directory instead of querying the web"
         ~docv:"FILE" [ "d"; "data-dir" ])

let common_options = "COMMON OPTIONS"

let okr_updates_dir_term =
  let env = Cmd.Env.info ~doc:"PATH" "OKR_UPDATES_DIR" in
  Arg.(
    value
    @@ opt (some string) None
    @@ info ~docs:common_options ~env ~doc:"Path to the okr-updates repository"
         [ "okr-updates-dir" ])

let admin_dir_term =
  let env = Cmd.Env.info ~doc:"PATH" "ADMIN_DIR" in
  Arg.(
    value
    @@ opt (some string) None
    @@ info ~docs:common_options ~env ~doc:"Path to the admin repository"
         [ "admin-dir" ])

let token =
  Arg.(
    value
    @@ opt (some string) None
    @@ info ~docs:common_options
         ~doc:
           "The Github token to use. By default it will try to read the okra \
            one, stored under `/.github/github-activity-token`."
         [ "token" ])

let setup () =
  let open Let_syntax_cmdliner in
  let+ style_renderer = Fmt_cli.style_renderer ~docs:common_options ()
  and+ token = token
  and+ level = Logs_cli.level () in
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  Fmt_tty.setup_std_outputs ?style_renderer ();
  match token with None -> () | Some t -> Github.Token.set t

type t = {
  org : string;
  source : source;
  dry_run : bool;
  project_number : int;
  project_goals : string;
  items_per_page : int option;
  years : int list;
  weeks : Weeks.t;
  users : string list option;
  ids : Filter.query list option;
  data_dir : string;
  okr_updates_dir : string option;
  admin_dir : string option;
}

let term ~default_source =
  let open Let_syntax_cmdliner in
  let+ () = setup ()
  and+ org = org_term
  and+ source = source_term default_source
  and+ dry_run = dry_run_term
  and+ project_number = project_number_term
  and+ project_goals = project_goals_term
  and+ items_per_page = items_per_page
  and+ years = years
  and+ weeks = weeks
  and+ users = users
  and+ ids = ids
  and+ data_dir = data_dir_term
  and+ okr_updates_dir = okr_updates_dir_term
  and+ admin_dir = admin_dir_term in
  {
    org;
    source;
    dry_run;
    project_number;
    project_goals;
    items_per_page;
    years;
    weeks;
    users;
    ids;
    data_dir;
    okr_updates_dir;
    admin_dir;
  }
