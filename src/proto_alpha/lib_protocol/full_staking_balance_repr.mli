(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

type t = private {
  own_frozen : Tez_repr.t;
  staked_frozen : Tez_repr.t;
  delegated : Tez_repr.t;
}

val make :
  own_frozen:Tez_repr.t -> staked_frozen:Tez_repr.t -> delegated:Tez_repr.t -> t

val zero : t

val encoding : t Data_encoding.t
