(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

open Protocol
open Alpha_context
open Batcher_worker_types
module Message_queue = Hash_queue.Make (L2_message.Hash) (L2_message)

module type S = sig
  val init :
    ?simulate:bool ->
    ?min_batch_elements:int ->
    ?min_batch_size:int ->
    ?max_batch_elements:int ->
    ?max_batch_size:int ->
    signer:public_key_hash ->
    _ Node_context.t ->
    unit tzresult Lwt.t

  val active : unit -> bool

  val find_message : L2_message.hash -> L2_message.t option tzresult

  val get_queue : unit -> (L2_message.hash * L2_message.t) list tzresult

  val register_messages : string list -> L2_message.hash list tzresult Lwt.t

  val batch : unit -> unit tzresult Lwt.t

  val new_head : Layer1.head -> unit tzresult Lwt.t

  val shutdown : unit -> unit Lwt.t
end

module Make (Simulation : Simulation.S) : S = struct
  module PVM = Simulation.PVM

  type state = {
    node_ctxt : Node_context.ro;
    signer : Tezos_crypto.Signature.public_key_hash;
    simulate : bool;
    min_batch_elements : int;
    min_batch_size : int;
    max_batch_elements : int;
    max_batch_size : int;
    messages : Message_queue.t;
    mutable simulation_ctxt : Simulation.t option;
  }

  let inject_batch state (messages : L2_message.t list) =
    let messages = List.map L2_message.content messages in
    let operation = Sc_rollup_add_messages {messages} in
    Injector.add_pending_operation ~source:state.signer operation

  let inject_batches state = List.iter_es (inject_batch state)

  let get_batches state ~only_full =
    let ( current_rev_batch,
          current_batch_size,
          current_batch_elements,
          full_batches ) =
      Message_queue.fold
        (fun msg_hash
             message
             ( current_rev_batch,
               current_batch_size,
               current_batch_elements,
               full_batches ) ->
          let size = String.length (L2_message.content message) in
          let new_batch_size = current_batch_size + size in
          let new_batch_elements = current_batch_elements + 1 in
          if
            new_batch_size <= state.max_batch_size
            && new_batch_elements <= state.max_batch_elements
          then
            (* We can add the message to the current batch because we are still
               within the bounds. *)
            ( (msg_hash, message) :: current_rev_batch,
              new_batch_size,
              new_batch_elements,
              full_batches )
          else
            (* The batch augmented with the message would be too big but it is
               below the limit without it. We finalize the current batch and
               create a new one for the message. NOTE: Messages in the queue are
               always < [state.conf.max_batch_size] because {!on_register} only
               accepts those. *)
            let batch = List.rev current_rev_batch in
            ([(msg_hash, message)], size, 1, batch :: full_batches))
        state.messages
        ([], 0, 0, [])
    in
    let batches =
      if
        (not only_full)
        || current_batch_size >= state.min_batch_size
           && current_batch_elements >= state.min_batch_elements
      then
        (* We have enough to make a batch with the last non-full batch. *)
        List.rev current_rev_batch :: full_batches
      else full_batches
    in
    List.fold_left
      (fun (batches, to_remove) -> function
        | [] -> (batches, to_remove)
        | batch ->
            let msg_hashes, batch = List.split batch in
            let to_remove = List.rev_append msg_hashes to_remove in
            (batch :: batches, to_remove))
      ([], [])
      batches

  let produce_batches state ~only_full =
    let open Lwt_result_syntax in
    let batches, to_remove = get_batches state ~only_full in
    match batches with
    | [] -> return_unit
    | _ ->
        let* () = inject_batches state batches in
        List.iter
          (fun tr_hash -> Message_queue.remove state.messages tr_hash)
          to_remove ;
        return_unit

  let on_batch state = produce_batches state ~only_full:false

  let simulate node_ctxt simulation_ctxt (messages : L2_message.t list) =
    let open Lwt_result_syntax in
    let ext_messages =
      List.map
        (fun m -> Sc_rollup.Inbox_message.External (L2_message.content m))
        messages
    in
    let+ simulation_ctxt, _ticks =
      Simulation.simulate_messages node_ctxt simulation_ctxt ext_messages
    in
    simulation_ctxt

  let on_register state (messages : string list) =
    let open Lwt_result_syntax in
    let*? messages =
      List.mapi_e
        (fun i message ->
          if String.length message > state.max_batch_size then
            error_with
              "Message %d is too large (max size is %d)"
              i
              state.max_batch_size
          else Ok (L2_message.make message))
        messages
    in
    let* () =
      if not state.simulate then return_unit
      else
        match state.simulation_ctxt with
        | None -> failwith "Simulation context of batcher not initialized"
        | Some simulation_ctxt ->
            let+ simulation_ctxt =
              simulate state.node_ctxt simulation_ctxt messages
            in
            state.simulation_ctxt <- Some simulation_ctxt
    in
    let hashes =
      List.map
        (fun message ->
          let msg_hash = L2_message.hash message in
          Message_queue.replace state.messages msg_hash message ;
          msg_hash)
        messages
    in
    let+ () = produce_batches state ~only_full:true in
    hashes

  let on_new_head state head =
    let open Lwt_result_syntax in
    let* simulation_ctxt =
      Simulation.start_simulation ~reveal_map:None state.node_ctxt head
    in
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/4224
       Replay with simulation may be too expensive *)
    let+ simulation_ctxt, failing =
      if not state.simulate then return (simulation_ctxt, [])
      else
        (* Re-simulate one by one *)
        Message_queue.fold_es
          (fun msg_hash msg (simulation_ctxt, failing) ->
            let*! result = simulate state.node_ctxt simulation_ctxt [msg] in
            match result with
            | Ok simulation_ctxt -> return (simulation_ctxt, failing)
            | Error _ -> return (simulation_ctxt, msg_hash :: failing))
          state.messages
          (simulation_ctxt, [])
    in
    state.simulation_ctxt <- Some simulation_ctxt ;
    (* Forget failing messages *)
    List.iter (Message_queue.remove state.messages) failing

  let init_batcher_state node_ctxt ~signer ~simulate ~min_batch_elements
      ~min_batch_size ~max_batch_elements ~max_batch_size =
    let open Lwt_syntax in
    return
      {
        node_ctxt;
        signer;
        simulate;
        min_batch_elements;
        min_batch_size;
        max_batch_elements;
        max_batch_size;
        messages = Message_queue.create 100_000 (* ~ 400MB *);
        simulation_ctxt = None;
      }

  module Types = struct
    type nonrec state = state

    type parameters = {
      node_ctxt : Node_context.ro;
      signer : Tezos_crypto.Signature.public_key_hash;
      simulate : bool;
      min_batch_elements : int;
      min_batch_size : int;
      max_batch_elements : int;
      max_batch_size : int;
    }
  end

  module Worker = Worker.MakeSingle (Name) (Request) (Types)

  type worker = Worker.infinite Worker.queue Worker.t

  module Handlers = struct
    type self = worker

    let on_request :
        type r request_error.
        worker ->
        (r, request_error) Request.t ->
        (r, request_error) result Lwt.t =
     fun w request ->
      let state = Worker.state w in
      match request with
      | Request.Register messages ->
          protect @@ fun () -> on_register state messages
      | Request.Batch -> protect @@ fun () -> on_batch state
      | Request.New_head head -> protect @@ fun () -> on_new_head state head

    type launch_error = error trace

    let on_launch _w ()
        Types.
          {
            node_ctxt;
            signer;
            simulate;
            min_batch_elements;
            min_batch_size;
            max_batch_elements;
            max_batch_size;
          } =
      let open Lwt_result_syntax in
      let*! state =
        init_batcher_state
          node_ctxt
          ~signer
          ~simulate
          ~min_batch_elements
          ~min_batch_size
          ~max_batch_elements
          ~max_batch_size
      in
      return state

    let on_error (type a b) _w _st (_r : (a, b) Request.t) (_errs : b) :
        unit tzresult Lwt.t =
      return_unit

    let on_completion _w _r _ _st = Lwt.return_unit

    let on_no_request _ = Lwt.return_unit

    let on_close _w = Lwt.return_unit
  end

  let table = Worker.create_table Queue

  let worker_promise, worker_waker = Lwt.task ()

  let init ?(simulate = true) ?(min_batch_elements = 10) ?(min_batch_size = 10)
      ?(max_batch_elements = max_int) ?(max_batch_size = 4096) ~signer node_ctxt
      =
    let open Lwt_result_syntax in
    let node_ctxt = Node_context.readonly node_ctxt in
    let+ worker =
      Worker.launch
        table
        ()
        {
          node_ctxt;
          signer;
          simulate;
          min_batch_elements;
          min_batch_size;
          max_batch_elements;
          max_batch_size;
        }
        (module Handlers)
    in
    Lwt.wakeup worker_waker worker

  (* This is a batcher worker for a single scoru *)
  let worker =
    lazy
      (match Lwt.state worker_promise with
      | Lwt.Return worker -> ok worker
      | Lwt.Fail _ | Lwt.Sleep -> error Sc_rollup_node_errors.No_batcher)

  let active () =
    match Lwt.state worker_promise with
    | Lwt.Return _ -> true
    | Lwt.Fail _ | Lwt.Sleep -> false

  let find_message hash =
    let open Result_syntax in
    let+ w = Lazy.force worker in
    let state = Worker.state w in
    Message_queue.find_opt state.messages hash

  let get_queue () =
    let open Result_syntax in
    let+ w = Lazy.force worker in
    let state = Worker.state w in
    Message_queue.bindings state.messages

  let handle_request_error rq =
    let open Lwt_syntax in
    let* rq = rq in
    match rq with
    | Ok res -> return_ok res
    | Error (Worker.Request_error errs) -> Lwt.return_error errs
    | Error (Closed None) -> Lwt.return_error [Worker_types.Terminated]
    | Error (Closed (Some errs)) -> Lwt.return_error errs
    | Error (Any exn) -> Lwt.return_error [Exn exn]

  let register_messages messages =
    let open Lwt_result_syntax in
    let*? w = Lazy.force worker in
    Worker.Queue.push_request_and_wait w (Request.Register messages)
    |> handle_request_error

  let batch () =
    let w = Lazy.force worker in
    match w with
    | Error _ ->
        (* There is no batcher, nothing to do *)
        return_unit
    | Ok w ->
        Worker.Queue.push_request_and_wait w Request.Batch
        |> handle_request_error

  let new_head b =
    let open Lwt_result_syntax in
    let w = Lazy.force worker in
    match w with
    | Error _ ->
        (* There is no batcher, nothing to do *)
        return_unit
    | Ok w ->
        let*! (_pushed : bool) =
          Worker.Queue.push_request w (Request.New_head b)
        in
        return_unit

  let shutdown () =
    let w = Lazy.force worker in
    match w with
    | Error _ ->
        (* There is no batcher, nothing to do *)
        Lwt.return_unit
    | Ok w -> Worker.shutdown w
end
