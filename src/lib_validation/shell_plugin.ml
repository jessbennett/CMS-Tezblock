(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Nomadic Development. <contact@tezcore.com>             *)
(* Copyright (c) 2018-2022 Nomadic Labs, <contact@nomadic-labs.com>          *)
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

module type FILTER = sig
  module Proto : Registered_protocol.T

  module Mempool : sig
    type config

    val config_encoding : config Data_encoding.t

    val default_config : config

    type filter_info

    val init :
      Tezos_protocol_environment.Context.t ->
      head:Tezos_base.Block_header.shell_header ->
      filter_info tzresult Lwt.t

    val flush :
      filter_info ->
      head:Tezos_base.Block_header.shell_header ->
      filter_info tzresult Lwt.t

    val syntactic_check : Proto.operation -> [`Well_formed | `Ill_formed]

    val pre_filter :
      filter_info ->
      config ->
      Proto.operation ->
      [ `Passed_prefilter of [`High | `Medium | `Low of Q.t list]
      | `Branch_delayed of tztrace
      | `Branch_refused of tztrace
      | `Refused of tztrace
      | `Outdated of tztrace ]
      Lwt.t

    val conflict_handler : config -> Proto.Mempool.conflict_handler

    module Conflict_map : sig
      type t

      val empty : t

      val update :
        t ->
        new_operation:Proto.operation ->
        replacements:Proto.operation list ->
        t

      val fee_needed_to_replace_by_fee :
        config -> candidate_op:Proto.operation -> conflict_map:t -> int64 option
    end

    val fee_needed_to_overtake :
      op_to_overtake:Proto.operation ->
      candidate_op:Proto.operation ->
      int64 option
  end
end

module type RPC = sig
  module Proto : Registered_protocol.T

  val rpc_services :
    Tezos_protocol_environment.rpc_context Tezos_rpc.Directory.directory
end

module No_filter (Proto : Registered_protocol.T) :
  FILTER with module Proto = Proto and type Mempool.filter_info = unit = struct
  module Proto = Proto

  module Mempool = struct
    type config = unit

    let config_encoding = Data_encoding.empty

    let default_config = ()

    type filter_info = unit

    let init _ ~head:_ = Lwt_result_syntax.return_unit

    let flush _ ~head:_ = Lwt_result_syntax.return_unit

    let syntactic_check _ = `Well_formed

    let pre_filter _ _ _ = Lwt.return @@ `Passed_prefilter (`Low [])

    let conflict_handler _ ~existing_operation ~new_operation =
      if Proto.compare_operations existing_operation new_operation < 0 then
        `Replace
      else `Keep

    module Conflict_map = struct
      type t = unit

      let empty = ()

      let update _t ~new_operation:_ ~replacements:_ = ()

      let fee_needed_to_replace_by_fee _config ~candidate_op:_ ~conflict_map:_ =
        None
    end

    let fee_needed_to_overtake ~op_to_overtake:_ ~candidate_op:_ = None
  end
end

module type METRICS = sig
  val hash : Protocol_hash.t

  val update_metrics :
    protocol_metadata:bytes ->
    Fitness.t ->
    (cycle:float -> consumed_gas:float -> round:float -> unit) ->
    unit Lwt.t
end

module Undefined_metrics_plugin (Proto : sig
  val hash : Protocol_hash.t
end) =
struct
  let hash = Proto.hash

  let update_metrics ~protocol_metadata:_ _ _ = Lwt.return_unit
end

let rpc_table : (module RPC) Protocol_hash.Table.t =
  Protocol_hash.Table.create 5

let metrics_table : (module METRICS) Protocol_hash.Table.t =
  Protocol_hash.Table.create 5

let register_rpc (module Rpc : RPC) =
  assert (not (Protocol_hash.Table.mem rpc_table Rpc.Proto.hash)) ;
  Protocol_hash.Table.add rpc_table Rpc.Proto.hash (module Rpc)

let register_metrics (module Metrics : METRICS) =
  Protocol_hash.Table.replace metrics_table Metrics.hash (module Metrics)

let find_rpc = Protocol_hash.Table.find rpc_table

let find_metrics = Protocol_hash.Table.find metrics_table

let safe_find_metrics hash =
  match find_metrics hash with
  | Some proto_metrics -> Lwt.return proto_metrics
  | None ->
      let module Metrics = Undefined_metrics_plugin (struct
        let hash = hash
      end) in
      Lwt.return (module Metrics : METRICS)

let filter_table : (module FILTER) Protocol_hash.Table.t =
  Protocol_hash.Table.create 5

let add_to_filter_table proto_hash filter =
  assert (not (Protocol_hash.Table.mem filter_table proto_hash)) ;
  Protocol_hash.Table.add filter_table proto_hash filter

let register_filter (module Filter : FILTER) =
  add_to_filter_table Filter.Proto.hash (module Filter)

let validator_filter_not_found =
  Internal_event.Simple.declare_1
    ~section:["block"; "validation"]
    ~name:"protocol_filter_not_found"
    ~msg:"no protocol filter found for protocol {protocol_hash}"
    ~level:Warning
    ~pp1:Protocol_hash.pp
    ("protocol_hash", Protocol_hash.encoding)

let find_filter ~block_hash protocol_hash =
  let open Lwt_result_syntax in
  match Protocol_hash.Table.find filter_table protocol_hash with
  | Some filter -> return filter
  | None -> (
      match Registered_protocol.get protocol_hash with
      | None ->
          tzfail
            (Block_validator_errors.Unavailable_protocol
               {block = block_hash; protocol = protocol_hash})
      | Some (module Proto : Registered_protocol.T) ->
          let*! () =
            match Proto.environment_version with
            | V0 ->
                (* This is normal for protocols Genesis and 000
                   because they don't have a plugin. *)
                Lwt.return_unit
            | _ ->
                Internal_event.Simple.(emit validator_filter_not_found)
                  protocol_hash
          in
          return (module No_filter (Proto) : FILTER))