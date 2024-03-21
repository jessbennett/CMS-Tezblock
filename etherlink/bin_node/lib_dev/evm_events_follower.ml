(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2024 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

type parameters = {rollup_node_endpoint : Uri.t}

module StringSet = Set.Make (String)

module Types = struct
  type state = parameters

  type nonrec parameters = parameters
end

module Name = struct
  (* We only have a single events follower in the evm node *)
  type t = unit

  let encoding = Data_encoding.unit

  let base = ["evm_node"; "dev"; "events_follower"; "worker"]

  let pp _ _ = ()

  let equal () () = true
end

module Request = struct
  type ('a, 'b) t = New_rollup_node_block : Int32.t -> (unit, error trace) t

  type view = View : _ t -> view

  let view (req : _ t) = View req

  let encoding =
    let open Data_encoding in
    union
      [
        case
          (Tag 0)
          ~title:"New_rollup_node_block"
          (obj2
             (req "request" (constant "new_rollup_node_block"))
             (req "rollup_head" int32))
          (function
            | View (New_rollup_node_block rollup_head) -> Some ((), rollup_head))
          (fun ((), rollup_head) -> View (New_rollup_node_block rollup_head));
      ]

  let pp ppf (View r) =
    match r with
    | New_rollup_node_block rollup_head ->
        Format.fprintf ppf "New_rollup_node_block (level %ld)" rollup_head
end

module Worker = Worker.MakeSingle (Name) (Request) (Types)

type worker = Worker.infinite Worker.queue Worker.t

let read_from_rollup_node path level rollup_node_endpoint =
  let open Rollup_services in
  call_service
    ~base:rollup_node_endpoint
    durable_state_value
    ((), Block_id.Level level)
    {key = path}
    ()

let fetch_event ({rollup_node_endpoint; _} : Types.state) rollup_block_lvl
    event_index =
  let open Lwt_result_syntax in
  let path = Durable_storage_path.Evm_events.nth_event event_index in
  let* bytes_opt =
    read_from_rollup_node path rollup_block_lvl rollup_node_endpoint
  in
  let event_opt = Option.bind bytes_opt Ethereum_types.Evm_events.of_bytes in
  let*! () =
    if Option.is_none event_opt then
      Evm_events_follower_events.unreadable_event (event_index, rollup_block_lvl)
    else Lwt.return_unit
  in
  return event_opt

let on_new_head ({rollup_node_endpoint} as state : Types.state) rollup_block_lvl
    =
  let open Lwt_result_syntax in
  let* nb_of_events_bytes =
    read_from_rollup_node
      Durable_storage_path.Evm_events.length
      rollup_block_lvl
      rollup_node_endpoint
  in
  match nb_of_events_bytes with
  | None -> return_unit
  | Some nb_of_events_bytes ->
      let (Qty nb_of_events) =
        Ethereum_types.decode_number nb_of_events_bytes
      in
      let nb_of_events = Z.to_int nb_of_events in
      let* events =
        List.init_ep
          ~when_negative_length:
            (error_of_fmt
               "Internal error: the rollup node advertised a negative length \
                for the events stream")
          nb_of_events
          (fetch_event state rollup_block_lvl)
      in
      let events = List.filter_map Fun.id events in
      Evm_context.apply_evm_events ~finalized_level:rollup_block_lvl events

module Handlers = struct
  type self = worker

  let on_request :
      type r request_error.
      worker -> (r, request_error) Request.t -> (r, request_error) result Lwt.t
      =
   fun worker request ->
    let open Lwt_result_syntax in
    match request with
    | Request.New_rollup_node_block rollup_block_lvl ->
        protect @@ fun () ->
        let* () = on_new_head (Worker.state worker) rollup_block_lvl in
        return_unit

  type launch_error = error trace

  let on_launch _w () (parameters : Types.parameters) =
    let state = parameters in
    Lwt_result_syntax.return state

  let on_error :
      type r request_error.
      worker ->
      Tezos_base.Worker_types.request_status ->
      (r, request_error) Request.t ->
      request_error ->
      unit tzresult Lwt.t =
   fun _w _ _req _errs ->
    let open Lwt_result_syntax in
    return_unit

  let on_completion _ _ _ _ = Lwt.return_unit

  let on_no_request _ = Lwt.return_unit

  let on_close _ = Lwt.return_unit
end

let table = Worker.create_table Queue

let worker_promise, worker_waker = Lwt.task ()

type error += No_worker

let worker =
  lazy
    (match Lwt.state worker_promise with
    | Lwt.Return worker -> Ok worker
    | Lwt.Fail e -> Error (TzTrace.make @@ error_of_exn e)
    | Lwt.Sleep -> Error (TzTrace.make No_worker))

let start parameters =
  let open Lwt_result_syntax in
  let*! () = Evm_events_follower_events.started () in
  let+ worker = Worker.launch table () parameters (module Handlers) in
  Lwt.wakeup worker_waker worker

let shutdown () =
  let open Lwt_syntax in
  let w = Lazy.force worker in
  match w with
  | Error _ ->
      (* There is no events follower, nothing to do *)
      Lwt.return_unit
  | Ok w ->
      let* () = Evm_events_follower_events.shutdown () in
      Worker.shutdown w

let worker_add_request ~request : unit tzresult Lwt.t =
  let open Lwt_result_syntax in
  match Lazy.force worker with
  | Ok w ->
      let*! (_pushed : bool) = Worker.Queue.push_request w request in
      return_unit
  | Error e -> Lwt.return (Error e)

let new_rollup_block rollup_level =
  worker_add_request ~request:(New_rollup_node_block rollup_level)
