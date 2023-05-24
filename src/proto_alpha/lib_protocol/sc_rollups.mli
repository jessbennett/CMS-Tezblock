(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

(** Here is the list of PVMs available in this protocol. *)

module PVM : sig
  type boot_sector = string

  module type S = sig
    val parse_boot_sector : string -> boot_sector option

    val pp_boot_sector : Format.formatter -> boot_sector -> unit

    include Sc_rollup_PVM_sig.S
  end

  type ('state, 'proof, 'output) implementation =
    (module S
       with type state = 'state
        and type proof = 'proof
        and type output_proof = 'output)

  type t = Packed : ('state, 'proof, 'output) implementation -> t [@@unboxed]
end

(** A smart contract rollup has a kind, which assigns meaning to
   rollup operations. *)
module Kind : sig
  (**

     The list of available rollup kinds.

     This list must only be appended for backward compatibility.
  *)
  type t = Example_arith | Wasm_2_0_0

  val encoding : t Data_encoding.t

  val equal : t -> t -> bool

  (** [pvm_of kind] returns the [PVM] of the given [kind]. *)
  val pvm_of : t -> PVM.t

  (** [no_proof_machine_of kind] returns a machine of a given [kind] capable of
      computing a rollup semantics, but incapable of doing any proof-related
      computations. *)
  val no_proof_machine_of : t -> (module Sc_rollup_machine_no_proofs.S)

  (** [all] returns all implemented PVM. *)
  val all : t list

  val of_string : string -> t option

  val to_string : t -> string

  val pp : Format.formatter -> t -> unit
end
