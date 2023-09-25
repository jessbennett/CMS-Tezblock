(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
(*                                                                           *)
(*****************************************************************************)

(* Extract profiling result for provided block hash
   ------------------------
   Invocation:
     ./_build/default/devtools/testnet_experiment_tools/extract_data.exe extract \
     --profiling-dir <profiling-dir> --blocks <blocks>
   Requirements:
     <profiling-dir>  - directory where the profiling reports are stored
     <blocks>         - a list of block hashes to be searched, separated by a space
   Description:
     This file contains the script to extract all the results
     of profiling reports related to the given block hash.
     It produces one file per profiling report, for example,
     for the blocks BKtvd3iZm1P4JDcr25XpQLE7nHbyTBYD3dfU9c62hwUueHVSZMw and BLGTW18zuGn7yc1SMp9DHTAVfSUYnmmWgyybEFHksGVJ6eMYNgY
     the following reports will be generated:
        - chain_validator_profiling_BKtvd3iZm1P4JDcr25XpQLE7nHbyTBYD3dfU9c62hwUueHVSZMw.txt
        - chain_validator_profiling_BLGTW18zuGn7yc1SMp9DHTAVfSUYnmmWgyybEFHksGVJ6eMYNgY.txt
        - p2p_reader_profiling_BKtvd3iZm1P4JDcr25XpQLE7nHbyTBYD3dfU9c62hwUueHVSZMw.txt
        - p2p_reader_profiling_BLGTW18zuGn7yc1SMp9DHTAVfSUYnmmWgyybEFHksGVJ6eMYNgY.txt
        - requester_profiling_BKtvd3iZm1P4JDcr25XpQLE7nHbyTBYD3dfU9c62hwUueHVSZMw.txt
        - requester_profiling_BLGTW18zuGn7yc1SMp9DHTAVfSUYnmmWgyybEFHksGVJ6eMYNgY.txt
        - rpc_server_profiling_BKtvd3iZm1P4JDcr25XpQLE7nHbyTBYD3dfU9c62hwUueHVSZMw.txt
        - rpc_server_profiling_BLGTW18zuGn7yc1SMp9DHTAVfSUYnmmWgyybEFHksGVJ6eMYNgY.txt
     all these files are generated inside the folder where
     the profiler reports are stored.
*)

open Tezos_clic

let profiling_reports_directory_arg =
  arg
    ~doc:"Profiling reports directory"
    ~short:'D'
    ~long:"profiling-dir"
    ~placeholder:"profiling-dir-path"
    ( parameter @@ fun _ data_dir ->
      if Sys.file_exists data_dir && Sys.is_directory data_dir then
        Lwt_result_syntax.return data_dir
      else failwith "%s does not exists or is not a directory" data_dir )

let searched_blocks_arg =
  arg
    ~doc:
      "Blocks list from which ones we want the profiling results. Argument \
       must be block hashes list separetaed by white space and surrounded by \
       \", example:  \"BKtvd3iZm1P4JDcr25XpQLE7nHbyTBYD3dfU9c62hwUueHVSZMw and \
       BLGTW18zuGn7yc1SMp9DHTAVfSUYnmmWgyybEFHksGVJ6eMYNgY\""
    ~short:'B'
    ~long:"blocks"
    ~placeholder:"blocks"
    ( parameter @@ fun _ searched_blocks ->
      let searched_blocks = String.split_on_char ' ' searched_blocks in
      Lwt_result_syntax.return searched_blocks )

let split_lines_starting_with_b input_str =
  let regexp = Str.regexp "\nB" in
  let lines = Str.split regexp input_str in
  (* Split gets rid of the searched characters, let's re-add the 'B'. *)
  let lines = List.map (fun line -> "B" ^ line) lines in
  lines

let create_files_from_lines input_file searched_block =
  (* Get only file name. *)
  let output_file_prefix = String.split_on_char '/' input_file in
  (* Remove .txt. *)
  let output_file_prefix =
    String.split_on_char '.' (List.last "" output_file_prefix)
  in
  (* Get only the part before file extension. *)
  let output_file_prefix = List.hd output_file_prefix in
  match output_file_prefix with
  | None ->
      Stdlib.failwith @@ "Cannot get profiling file name of: " ^ input_file
  | Some output_file_prefix ->
      let in_channel = open_in input_file in
      let input_string =
        really_input_string in_channel (in_channel_length in_channel)
      in
      close_in in_channel ;
      let lines = split_lines_starting_with_b input_string in
      let extract_block_name = function [] -> "" | hd :: _ -> hd in
      List.iter
        (fun line ->
          (* The searched block name is always the first line. *)
          let first_line =
            extract_block_name (String.split_on_char '\n' line)
          in
          (* Luckily, its length is fixed! *)
          let block_name = String.sub first_line 0 51 in
          if
            String.starts_with ~prefix:"B" first_line
            && String.equal block_name searched_block
          then (
            let file_name =
              Printf.sprintf "%s_%s.txt" output_file_prefix block_name
            in
            let out_channel = open_out file_name in
            output_string out_channel line ;
            close_out out_channel))
        lines

(* Map the whole directory to find corresponding filenames. *)
let rec find_files_with_suffix dir suffix =
  let dir_contents = Sys.readdir dir in
  let matching_files = ref [] in
  Array.iter
    (fun entry ->
      let entry_path = Filename.concat dir entry in
      if Sys.is_directory entry_path then
        matching_files :=
          !matching_files @ find_files_with_suffix entry_path suffix
      else if Filename.check_suffix entry suffix then
        matching_files := entry_path :: !matching_files)
    dir_contents ;
  !matching_files

(* Find all files with [_profiling.txt] suffix in provided directory. *)
let find_and_process_profiling_file dir search_block =
  let profiling_files = find_files_with_suffix dir "_profiling.txt" in
  List.iter
    (fun profiling_file ->
      Printf.printf "Found profiling file: %s\n" profiling_file ;
      create_files_from_lines profiling_file search_block)
    profiling_files

let commands () =
  [
    command
      ~group:
        {
          name = "devtools";
          title =
            "Command for extracting profiling reports of specified block hash";
        }
      ~desc:"Extract block profiling info."
      (args2 profiling_reports_directory_arg searched_blocks_arg)
      (fixed ["extract"])
      (fun (profiling_reports_directory, search_blocks) _cctxt ->
        match (profiling_reports_directory, search_blocks) with
        | Some profiling_reports_directory, Some search_blocks ->
            Lwt_result_syntax.return
            @@ List.iter
                 (fun search_block ->
                   find_and_process_profiling_file
                     profiling_reports_directory
                     search_block)
                 search_blocks
        | Some _, _ ->
            failwith
              "No profiling reports directory specified, it is mandatory."
        | _, Some _ -> failwith "No block hash specified, it is mandatory."
        | _ ->
            failwith
              "No profiling reports directory specified and no block hash \
               specified, both are mandatory.");
  ]

let select_commands _ _ = Lwt_result_syntax.return (commands ())

let () = Client_main_run.run (module Client_config) ~select_commands
