(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2019 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

let () = Additional_registrations.force_linking ()

let commands = Commands.commands ()

let home = try Sys.getenv "HOME" with Not_found -> "/tmp"

let default_base_dir = Filename.concat home ".tezos-client"

let base_dir_arg =
  let open Clic in
  arg
    ~long:"base-dir"
    ~short:'d'
    ~placeholder:"path"
    ~doc:
      ("data directory\n\
        The directory where the Tezos codec will output logs.\n\
        By default: '" ^ default_base_dir ^ "'.")
    (parameter (fun _ctxt x -> Lwt.return_ok x))

let global_options = Clic.args1 base_dir_arg

let parse_config_args argv =
  let open Lwt_result_syntax in
  (* The context used during argument parsing. We switch to a real context
     that is created based on some of the parsed arguments. *)
  let ctxt = Client_context.null_printer in
  let* (base_dir, argv) = Clic.parse_global_options global_options ctxt argv in
  let* base_dir =
    match base_dir with
    | None ->
        let base_dir = default_base_dir in
        let*! () =
          if Sys.file_exists base_dir then Lwt.return_unit
          else Lwt_utils_unix.create_dir base_dir
        in
        return base_dir
    | Some dir ->
        if not (Sys.file_exists dir) then
          failwith
            "Specified -base-dir does not exist. Please create the directory \
             and try again."
        else if not (Sys.is_directory dir) then
          failwith "Specified -base-dir must be a directory"
        else return dir
  in
  return (base_dir, argv)

(* Main (lwt) entry *)
let main commands =
  let open Lwt_result_syntax in
  let executable_name = Filename.basename Sys.executable_name in
  let run () =
    let (argv, autocomplete) =
      (* for shell aliases *)
      let rec move_autocomplete_token_upfront acc = function
        | "bash_autocomplete" :: prev_arg :: cur_arg :: script :: args ->
            let args = List.rev acc @ args in
            (args, Some (prev_arg, cur_arg, script))
        | x :: rest -> move_autocomplete_token_upfront (x :: acc) rest
        | [] -> (List.rev acc, None)
      in
      match Array.to_list Sys.argv with
      | _ :: args -> move_autocomplete_token_upfront [] args
      | [] -> ([], None)
    in
    Random.self_init () ;
    ignore
      Clic.(
        setup_formatter
          Format.std_formatter
          (if Unix.isatty Unix.stdout then Ansi else Plain)
          Short) ;
    ignore
      Clic.(
        setup_formatter
          Format.err_formatter
          (if Unix.isatty Unix.stderr then Ansi else Plain)
          Short) ;
    let*! () = Tezos_base_unix.Internal_event_unix.init () in
    let* (base_dir, argv) = parse_config_args argv in
    let ctxt = new Client_context_unix.unix_logger ~base_dir in
    let commands =
      Clic.add_manual
        ~executable_name
        ~global_options
        (if Unix.isatty Unix.stdout then Clic.Ansi else Clic.Plain)
        Format.std_formatter
        commands
    in
    match autocomplete with
    | Some (prev_arg, cur_arg, script) ->
        let* completions =
          Clic.autocompletion
            ~script
            ~cur_arg
            ~prev_arg
            ~args:argv
            ~global_options
            commands
            ctxt
        in
        List.iter print_endline completions ;
        return_unit
    | None -> Clic.dispatch commands ctxt argv
  in
  Stdlib.exit
    (Lwt_main.run
       (let*! retcode =
          let*! r =
            Lwt.catch run (function
                | Failure msg -> failwith "%s" msg
                | exn -> failwith "%s" (Printexc.to_string exn))
          in
          match r with
          | Ok () -> Lwt.return 0
          | Error [Clic.Version] ->
              let version = Tezos_version.Bin_version.version_string in
              Format.printf "%s\n" version ;
              Lwt.return 0
          | Error [Clic.Help command] ->
              Clic.usage
                Format.std_formatter
                ~executable_name
                ~global_options
                (match command with None -> [] | Some c -> [c]) ;
              Lwt.return 0
          | Error errs ->
              Clic.pp_cli_errors
                Format.err_formatter
                ~executable_name
                ~global_options
                ~default:Error_monad.pp
                errs ;
              Lwt.return 1
        in
        Format.pp_print_flush Format.err_formatter () ;
        Format.pp_print_flush Format.std_formatter () ;
        Lwt.return retcode))

let () = main commands
