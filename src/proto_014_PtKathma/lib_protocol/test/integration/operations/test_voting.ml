(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2022 Trili Tech  <contact@trili.tech>                       *)
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

(** Testing
    -------
    Component:  Protocol (voting)
    Invocation: dune exec \
                src/proto_alpha/lib_protocol/test/integration/operations/main.exe \
                -- test "^voting$"
    Subject:    On the voting process.

*)

open Protocol
open Alpha_context

(* missing stuff in Vote *)
let ballots_zero = Vote.{yay = 0L; nay = 0L; pass = 0L}

let ballots_equal b1 b2 =
  Vote.(b1.yay = b2.yay && b1.nay = b2.nay && b1.pass = b2.pass)

let ballots_pp ppf v =
  Vote.(
    Format.fprintf ppf "{ yay = %Ld ; nay = %Ld ; pass = %Ld" v.yay v.nay v.pass)

(* constants and ratios used in voting:
   percent_mul denotes the percent multiplier
   initial_participation is 7000 that is, 7/10 * percent_mul
   the participation EMA ratio pr_ema_weight / den = 7 / 10
   the participation ratio pr_num / den = 2 / 10
   note: we use the same denominator for both participation EMA and participation rate.
   supermajority rate is s_num / s_den = 8 / 10 *)
let percent_mul = 100_00

let den = 10

let initial_participation_num = 7

let initial_participation = initial_participation_num * percent_mul / den

let pr_ema_weight = 8

let pr_num = den - pr_ema_weight

let s_num = 8

let s_den = 10

let qr_min_num = 2

let qr_max_num = 7

let expected_qr_num participation_ema =
  let participation_ema = Int32.to_int participation_ema in
  let participation_ema = participation_ema * den / percent_mul in
  Float.(
    of_int qr_min_num
    +. of_int participation_ema
       *. (of_int qr_max_num -. of_int qr_min_num)
       /. of_int den)

(* Tezos_crypto.Protocol_hash.zero is "PrihK96nBAFSxVL1GLJTVhu9YnzkMFiBeuJRPA8NwuZVZCE1L6i" *)
let protos =
  Array.map
    (fun s -> Tezos_crypto.Protocol_hash.of_b58check_exn s)
    [|
      "ProtoALphaALphaALphaALphaALphaALphaALpha61322gcLUGH";
      "ProtoALphaALphaALphaALphaALphaALphaALphabc2a7ebx6WB";
      "ProtoALphaALphaALphaALphaALphaALphaALpha84efbeiF6cm";
      "ProtoALphaALphaALphaALphaALphaALphaALpha91249Z65tWS";
      "ProtoALphaALphaALphaALphaALphaALphaALpha537f5h25LnN";
      "ProtoALphaALphaALphaALphaALphaALphaALpha5c8fefgDYkr";
      "ProtoALphaALphaALphaALphaALphaALphaALpha3f31feSSarC";
      "ProtoALphaALphaALphaALphaALphaALphaALphabe31ahnkxSC";
      "ProtoALphaALphaALphaALphaALphaALphaALphabab3bgRb7zQ";
      "ProtoALphaALphaALphaALphaALphaALphaALphaf8d39cctbpk";
      "ProtoALphaALphaALphaALphaALphaALphaALpha3b981byuYxD";
      "ProtoALphaALphaALphaALphaALphaALphaALphaa116bccYowi";
      "ProtoALphaALphaALphaALphaALphaALphaALphacce68eHqboj";
      "ProtoALphaALphaALphaALphaALphaALphaALpha225c7YrWwR7";
      "ProtoALphaALphaALphaALphaALphaALphaALpha58743cJL6FG";
      "ProtoALphaALphaALphaALphaALphaALphaALphac91bcdvmJFR";
      "ProtoALphaALphaALphaALphaALphaALphaALpha1faaadhV7oW";
      "ProtoALphaALphaALphaALphaALphaALphaALpha98232gD94QJ";
      "ProtoALphaALphaALphaALphaALphaALphaALpha9d1d8cijvAh";
      "ProtoALphaALphaALphaALphaALphaALphaALphaeec52dKF6Gx";
      "ProtoALphaALphaALphaALphaALphaALphaALpha841f2cQqajX";
    |]

(** helper functions *)

let assert_period_kind expected_kind kind loc =
  if Stdlib.(expected_kind = kind) then return_unit
  else
    Alcotest.failf
      "%s - Unexpected voting period kind - expected %a, got %a"
      loc
      Voting_period.pp_kind
      expected_kind
      Voting_period.pp_kind
      kind

let assert_period_index expected_index index loc =
  if expected_index = index then return_unit
  else
    Alcotest.failf
      "%s - Unexpected voting period index - expected %ld, got %ld"
      loc
      expected_index
      index

let assert_period_position expected_position position loc =
  if position = expected_position then return_unit
  else
    Alcotest.failf
      "%s - Unexpected voting period position blocks - expected %ld, got %ld"
      loc
      expected_position
      position

let assert_period_remaining expected_remaining remaining loc =
  if remaining = expected_remaining then return_unit
  else
    Alcotest.failf
      "%s - Unexpected voting period remaining blocks - expected %ld, got %ld"
      loc
      expected_remaining
      remaining

let assert_period ?expected_kind ?expected_index ?expected_position
    ?expected_remaining b loc =
  Context.Vote.get_current_period (B b)
  >>=? fun {voting_period; position; remaining} ->
  (if Option.is_some expected_kind then
   assert_period_kind
     (WithExceptions.Option.get ~loc:__LOC__ expected_kind)
     voting_period.kind
     loc
  else return_unit)
  >>=? fun () ->
  (if Option.is_some expected_index then
   assert_period_index
     (WithExceptions.Option.get ~loc:__LOC__ expected_index)
     voting_period.index
     loc
  else return_unit)
  >>=? fun () ->
  (if Option.is_some expected_position then
   assert_period_position
     (WithExceptions.Option.get ~loc:__LOC__ expected_position)
     position
     loc
  else return_unit)
  >>=? fun () ->
  if Option.is_some expected_remaining then
    assert_period_remaining
      (WithExceptions.Option.get ~loc:__LOC__ expected_remaining)
      remaining
      loc
  else return_unit

let assert_ballots expected_ballots b loc =
  Context.Vote.get_ballots (B b) >>=? fun ballots ->
  Assert.equal
    ~loc
    ballots_equal
    "Unexpected ballots"
    ballots_pp
    ballots
    expected_ballots

let assert_empty_ballots b loc =
  assert_ballots ballots_zero b loc >>=? fun () ->
  Context.Vote.get_ballot_list (B b) >>=? function
  | [] -> return_unit
  | _ -> failwith "%s - Unexpected ballot list" loc

let mk_contracts_from_pkh pkh_list =
  List.map (fun c -> Contract.Implicit c) pkh_list

(* get the list of delegates and the list of their voting power from listings *)
let get_delegates_and_power_from_listings b =
  Context.Vote.get_listings (B b) >|=? fun l ->
  (mk_contracts_from_pkh (List.map fst l), List.map snd l)

(* compute the voting power of each delegate *)
let get_power b delegates loc =
  List.map_es
    (fun delegate ->
      let pkh = Context.Contract.pkh delegate in
      Context.Delegate.voting_info (B b) pkh >>=? fun info ->
      match info.voting_power with
      | None -> failwith "%s - Missing delegate" loc
      | Some power -> return power)
    delegates

(* Checks that the listings are populated *)
let assert_listings_not_empty b ~loc =
  Context.Vote.get_listings (B b) >>=? function
  | [] -> failwith "Unexpected empty listings (%s)" loc
  | _ -> return_unit

let equal_delegate_info a b =
  Option.equal Int64.equal a.Vote.voting_power b.Vote.voting_power
  && Option.equal Vote.equal_ballot a.current_ballot b.current_ballot
  && List.equal
       Tezos_crypto.Protocol_hash.equal
       (List.sort Tezos_crypto.Protocol_hash.compare a.current_proposals)
       (List.sort Tezos_crypto.Protocol_hash.compare b.current_proposals)
  && Int.equal a.remaining_proposals b.remaining_proposals

let assert_equal_info ~loc a b =
  Assert.equal
    ~loc
    equal_delegate_info
    "delegate_info"
    Vote.pp_delegate_info
    a
    b

let bake_until_first_block_of_next_period ?policy b =
  Context.Vote.get_current_period (B b) >>=? fun {remaining; _} ->
  Block.bake_n ?policy Int32.(add remaining one |> to_int) b

let context_init =
  (* Note that some of these tests assume (more or less) that the
     accounts remain active during a voting period, which roughly
     translates to the following condition being assumed to hold:
     `blocks_per_voting_period <= preserved_cycles * blocks_per_cycle.`
     We also set baking and endorsing rewards to zero in order to
     ease accounting of exact baker stake. *)
  Context.init_n
    ~blocks_per_cycle:4l
    ~cycles_per_voting_period:1l
    ~consensus_threshold:0
    ~endorsing_reward_per_slot:Tez.zero
    ~baking_reward_bonus_per_slot:Tez.zero
    ~baking_reward_fixed_portion:Tez.zero
    ~nonce_revelation_threshold:2l

(** A normal and successful vote sequence. *)
let test_successful_vote num_delegates () =
  let open Alpha_context in
  let min_proposal_quorum = Int32.(of_int @@ (100_00 / num_delegates)) in
  context_init ~min_proposal_quorum num_delegates () >>=? fun (b, _) ->
  (* no ballots in proposal period *)
  assert_empty_ballots b __LOC__ >>=? fun () ->
  (* Last baked block is first block of period Proposal *)
  assert_period
    ~expected_kind:Proposal
    ~expected_index:0l
    ~expected_position:0l
    b
    __LOC__
  >>=? fun () ->
  assert_listings_not_empty b ~loc:__LOC__ >>=? fun () ->
  (* participation EMA starts at initial_participation *)
  Context.Vote.get_participation_ema b >>=? fun v ->
  Assert.equal_int ~loc:__LOC__ initial_participation (Int32.to_int v)
  >>=? fun () ->
  (* listings must be populated in proposal period *)
  assert_listings_not_empty b ~loc:__LOC__ >>=? fun () ->
  (* beginning of proposal, denoted by _p1;
     take a snapshot of the active delegates and their voting power from listings *)
  get_delegates_and_power_from_listings b >>=? fun (delegates_p1, power_p1) ->
  (* no proposals at the beginning of proposal period *)
  Context.Vote.get_proposals (B b) >>=? fun ps ->
  (if Environment.Protocol_hash.Map.is_empty ps then return_unit
  else failwith "%s - Unexpected proposals" __LOC__)
  >>=? fun () ->
  (* no current proposal during proposal period *)
  (Context.Vote.get_current_proposal (B b) >>=? function
   | None -> return_unit
   | Some _ -> failwith "%s - Unexpected proposal" __LOC__)
  >>=? fun () ->
  let del1 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates_p1 0
  in
  let del2 =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates_p1 1
  in
  let pkh1 = Context.Contract.pkh del1 in
  let pkh2 = Context.Contract.pkh del2 in
  let pow1 = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth power_p1 0 in
  let pow2 = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth power_p1 1 in
  let props =
    List.map (fun i -> protos.(i)) (2 -- Constants.max_proposals_per_delegate)
  in
  Op.proposals (B b) del1 (Tezos_crypto.Protocol_hash.zero :: props)
  >>=? fun ops1 ->
  Op.proposals (B b) del2 [Tezos_crypto.Protocol_hash.zero] >>=? fun ops2 ->
  Block.bake ~operations:[ops1; ops2] b >>=? fun b ->
  Context.Delegate.voting_info (B b) pkh1 >>=? fun info1 ->
  Context.Delegate.voting_info (B b) pkh2 >>=? fun info2 ->
  assert_equal_info
    ~loc:__LOC__
    info1
    {
      voting_power = Some pow1;
      current_ballot = None;
      current_proposals = Tezos_crypto.Protocol_hash.zero :: props;
      remaining_proposals = 0;
    }
  >>=? fun () ->
  assert_equal_info
    ~loc:__LOC__
    info2
    {
      voting_power = Some pow2;
      current_ballot = None;
      current_proposals = [Tezos_crypto.Protocol_hash.zero];
      remaining_proposals = Constants.max_proposals_per_delegate - 1;
    }
  >>=? fun () ->
  (* proposals are now populated *)
  Context.Vote.get_proposals (B b) >>=? fun ps ->
  (* correctly count the double proposal for zero *)
  (let weight =
     Int64.add
       (WithExceptions.Option.get ~loc:__LOC__ @@ List.nth power_p1 0)
       (WithExceptions.Option.get ~loc:__LOC__ @@ List.nth power_p1 1)
   in
   match Environment.Protocol_hash.(Map.find zero ps) with
   | Some v ->
       if v = weight then return_unit
       else failwith "%s - Wrong count %Ld is not %Ld" __LOC__ v weight
   | None -> failwith "%s - Missing proposal" __LOC__)
  >>=? fun () ->
  (* proposing more than maximum_proposals fails *)
  Op.proposals (B b) del1 (Tezos_crypto.Protocol_hash.zero :: props)
  >>=? fun ops ->
  Block.bake ~operations:[ops] b >>= fun res ->
  Assert.proto_error_with_info ~loc:__LOC__ res "Too many proposals"
  >>=? fun () ->
  (* proposing less than one proposal fails *)
  Op.proposals (B b) del1 [] >>=? fun ops ->
  Block.bake ~operations:[ops] b >>= fun res ->
  Assert.proto_error_with_info ~loc:__LOC__ res "Empty proposal" >>=? fun () ->
  (* first block of exploration period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* next block is first block of exploration *)
  assert_period ~expected_kind:Exploration ~expected_index:1l b __LOC__
  >>=? fun () ->
  assert_listings_not_empty b ~loc:__LOC__ >>=? fun () ->
  (* listings must be populated in proposal period before moving to exploration period *)
  assert_listings_not_empty b ~loc:__LOC__ >>=? fun () ->
  (* beginning of exploration period, denoted by _p2;
     take a snapshot of the active delegates and their voting power from listings *)
  get_delegates_and_power_from_listings b >>=? fun (delegates_p2, power_p2) ->
  (* no proposals during exploration period *)
  Context.Vote.get_proposals (B b) >>=? fun ps ->
  (if Environment.Protocol_hash.Map.is_empty ps then return_unit
  else failwith "%s - Unexpected proposals" __LOC__)
  >>=? fun () ->
  (* current proposal must be set during exploration period *)
  (Context.Vote.get_current_proposal (B b) >>=? function
   | Some v ->
       if Tezos_crypto.Protocol_hash.(equal zero v) then return_unit
       else failwith "%s - Wrong proposal" __LOC__
   | None -> failwith "%s - Missing proposal" __LOC__)
  >>=? fun () ->
  (* unanimous vote: all delegates --active when p2 started-- vote *)
  List.map_es
    (fun del -> Op.ballot (B b) del Tezos_crypto.Protocol_hash.zero Vote.Yay)
    delegates_p2
  >>=? fun operations ->
  Block.bake ~operations b >>=? fun b ->
  Op.ballot (B b) del1 Tezos_crypto.Protocol_hash.zero Vote.Nay >>=? fun op ->
  Block.bake ~operations:[op] b >>= fun res ->
  Context.Delegate.voting_info (B b) pkh1 >>=? fun info1 ->
  assert_equal_info
    ~loc:__LOC__
    info1
    {
      voting_power = Some pow1;
      current_ballot = Some Yay;
      current_proposals = [];
      remaining_proposals = 0;
    }
  >>=? fun () ->
  Assert.proto_error_with_info ~loc:__LOC__ res "Duplicate ballot"
  >>=? fun () ->
  (* Allocate votes from weight of active delegates *)
  List.fold_left (fun acc v -> Int64.(add v acc)) 0L power_p2
  |> fun power_sum ->
  (* # of Yay in ballots matches votes of the delegates *)
  assert_ballots Vote.{yay = power_sum; nay = 0L; pass = 0L} b __LOC__
  >>=? fun () ->
  (* One Yay ballot per delegate *)
  (Context.Vote.get_ballot_list (B b) >>=? function
   | [] -> failwith "%s - Unexpected empty ballot list" __LOC__
   | l ->
       List.iter_es
         (fun delegate ->
           let pkh = Context.Contract.pkh delegate in
           match List.find_opt (fun (del, _) -> del = pkh) l with
           | None -> failwith "%s - Missing delegate" __LOC__
           | Some (_, Vote.Yay) -> return_unit
           | Some _ -> failwith "%s - Wrong ballot" __LOC__)
         delegates_p2)
  >>=? fun () ->
  (* skip to cooldown period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  assert_period ~expected_index:2l ~expected_kind:Cooldown b __LOC__
  >>=? fun () ->
  (* no ballots in cooldown period *)
  assert_empty_ballots b __LOC__ >>=? fun () ->
  (* listings must be populated in cooldown period before moving to promotion_vote period *)
  assert_listings_not_empty b ~loc:__LOC__ >>=? fun () ->
  (* skip to promotion period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  assert_period ~expected_kind:Promotion ~expected_index:3l b __LOC__
  >>=? fun () ->
  assert_listings_not_empty b ~loc:__LOC__ >>=? fun () ->
  (* period 3 *)
  (* listings must be populated in promotion period *)
  assert_listings_not_empty b ~loc:__LOC__ >>=? fun () ->
  (* beginning of promotion period, denoted by _p4;
     take a snapshot of the active delegates and their voting power from listings *)
  get_delegates_and_power_from_listings b >>=? fun (delegates_p4, power_p4) ->
  (* no proposals during promotion period *)
  Context.Vote.get_proposals (B b) >>=? fun ps ->
  (if Environment.Protocol_hash.Map.is_empty ps then return_unit
  else failwith "%s - Unexpected proposals" __LOC__)
  >>=? fun () ->
  (* current proposal must be set during promotion period *)
  (Context.Vote.get_current_proposal (B b) >>=? function
   | Some v ->
       if Tezos_crypto.Protocol_hash.(equal zero v) then return_unit
       else failwith "%s - Wrong proposal" __LOC__
   | None -> failwith "%s - Missing proposal" __LOC__)
  >>=? fun () ->
  (* unanimous vote: all delegates --active when p4 started-- vote *)
  List.map_es
    (fun del -> Op.ballot (B b) del Tezos_crypto.Protocol_hash.zero Vote.Yay)
    delegates_p4
  >>=? fun operations ->
  Block.bake ~operations b >>=? fun b ->
  List.fold_left (fun acc v -> Int64.(add v acc)) 0L power_p4
  |> fun power_sum ->
  (* # of Yays in ballots matches voting power of the delegate *)
  assert_ballots Vote.{yay = power_sum; nay = 0L; pass = 0L} b __LOC__
  >>=? fun () ->
  (* One Yay ballot per delegate *)
  (Context.Vote.get_ballot_list (B b) >>=? function
   | [] -> failwith "%s - Unexpected empty ballot list" __LOC__
   | l ->
       List.iter_es
         (fun delegate ->
           let pkh = Context.Contract.pkh delegate in
           match List.find_opt (fun (del, _) -> del = pkh) l with
           | None -> failwith "%s - Missing delegate" __LOC__
           | Some (_, Vote.Yay) -> return_unit
           | Some _ -> failwith "%s - Wrong ballot" __LOC__)
         delegates_p4)
  >>=? fun () ->
  (* skip to end of promotion period and activation*)
  bake_until_first_block_of_next_period b >>=? fun b ->
  assert_period ~expected_kind:Adoption ~expected_index:4l b __LOC__
  >>=? fun () ->
  (* skip to end of Adoption period and bake 1 more to activate *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  assert_period ~expected_kind:Proposal ~expected_index:5l b __LOC__
  >>=? fun () ->
  assert_listings_not_empty b ~loc:__LOC__ >>=? fun () ->
  (* zero is the new protocol (before the vote this value is unset) *)
  Context.Vote.get_protocol b >>= fun p ->
  Assert.equal
    ~loc:__LOC__
    Tezos_crypto.Protocol_hash.equal
    "Unexpected proposal"
    Tezos_crypto.Protocol_hash.pp
    p
    Tezos_crypto.Protocol_hash.zero
  >>=? fun () -> return_unit

(* given a list of active delegates,
   return the first k active delegates with which one can have quorum, that is:
   their voting power divided by the total voting power is bigger than pr_ema_weight/den *)
let get_smallest_prefix_voters_for_quorum active_delegates active_power
    participation_ema =
  let expected_quorum = expected_qr_num participation_ema in
  List.fold_left (fun acc v -> Int64.(add v acc)) 0L active_power
  |> fun active_power_sum ->
  let rec loop delegates power sum selected =
    match (delegates, power) with
    | [], [] -> selected
    | del :: delegates, del_power :: power ->
        if
          den * sum
          < Float.to_int (expected_quorum *. Int64.to_float active_power_sum)
        then
          loop delegates power (sum + Int64.to_int del_power) (del :: selected)
        else selected
    | _, _ -> []
  in
  loop active_delegates active_power 0 []

let get_expected_participation_ema power voter_power old_participation_ema =
  (* formula to compute the updated participation_ema *)
  let get_updated_participation_ema old_participation_ema participation =
    ((pr_ema_weight * Int32.to_int old_participation_ema)
    + (pr_num * participation))
    / den
  in
  List.fold_left (fun acc v -> Int64.(add v acc)) 0L power |> fun power_sum ->
  List.fold_left (fun acc v -> Int64.(add v acc)) 0L voter_power
  |> fun voter_power_sum ->
  let participation =
    Int64.(to_int (div (mul voter_power_sum (of_int percent_mul)) power_sum))
  in
  get_updated_participation_ema old_participation_ema participation

(** If not enough quorum
    -- get_updated_participation_ema < pr_ema_weight/den --
    in exploration, go back to proposal period. *)
let test_not_enough_quorum_in_exploration num_delegates () =
  let min_proposal_quorum = Int32.(of_int @@ (100_00 / num_delegates)) in
  context_init ~min_proposal_quorum num_delegates () >>=? fun (b, delegates) ->
  (* proposal period *)
  let open Alpha_context in
  assert_period ~expected_kind:Proposal b __LOC__ >>=? fun () ->
  let proposer =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 0
  in
  Op.proposals (B b) proposer [Tezos_crypto.Protocol_hash.zero] >>=? fun ops ->
  Block.bake ~operations:[ops] b >>=? fun b ->
  (* skip to exploration period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* we moved to an exploration period with one proposal *)
  assert_period ~expected_kind:Exploration b __LOC__ >>=? fun () ->
  Context.Vote.get_participation_ema b >>=? fun initial_participation_ema ->
  (* beginning of exploration period, denoted by _p2;
     take a snapshot of the active delegates and their voting power from listings *)
  get_delegates_and_power_from_listings b >>=? fun (delegates_p2, power_p2) ->
  Context.Vote.get_participation_ema b >>=? fun participation_ema ->
  get_smallest_prefix_voters_for_quorum delegates_p2 power_p2 participation_ema
  |> fun voters ->
  (* take the first two voters out so there cannot be quorum *)
  let voters_without_quorum =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.tl voters
  in
  get_power b voters_without_quorum __LOC__
  >>=? fun voters_power_in_exploration ->
  (* all voters_without_quorum vote, for yays;
     no nays, so supermajority is satisfied *)
  List.map_es
    (fun del -> Op.ballot (B b) del Tezos_crypto.Protocol_hash.zero Vote.Yay)
    voters_without_quorum
  >>=? fun operations ->
  Block.bake ~operations b >>=? fun b ->
  (* bake to next period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* we move back to the proposal period because not enough quorum *)
  assert_period ~expected_kind:Proposal b __LOC__ >>=? fun () ->
  (* check participation_ema update *)
  get_expected_participation_ema
    power_p2
    voters_power_in_exploration
    initial_participation_ema
  |> fun expected_participation_ema ->
  Context.Vote.get_participation_ema b >>=? fun new_participation_ema ->
  (* assert the formula to calculate participation_ema is correct *)
  Assert.equal_int
    ~loc:__LOC__
    expected_participation_ema
    (Int32.to_int new_participation_ema)
  >>=? fun () -> return_unit

(** If not enough quorum
   -- get_updated_participation_ema < pr_ema_weight/den --
   In promotion period, go back to proposal period. *)
let test_not_enough_quorum_in_promotion num_delegates () =
  let min_proposal_quorum = Int32.(of_int @@ (100_00 / num_delegates)) in
  context_init ~min_proposal_quorum num_delegates () >>=? fun (b, delegates) ->
  assert_period ~expected_kind:Proposal b __LOC__ >>=? fun () ->
  let proposer =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 0
  in
  Op.proposals (B b) proposer [Tezos_crypto.Protocol_hash.zero] >>=? fun ops ->
  Block.bake ~operations:[ops] b >>=? fun b ->
  (* skip to exploration period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* we moved to an exploration period with one proposal *)
  assert_period ~expected_kind:Exploration b __LOC__ >>=? fun () ->
  (* beginning of exploration period, denoted by _p2;
     take a snapshot of the active delegates and their voting power from listings *)
  get_delegates_and_power_from_listings b >>=? fun (delegates_p2, power_p2) ->
  Context.Vote.get_participation_ema b >>=? fun participation_ema ->
  get_smallest_prefix_voters_for_quorum delegates_p2 power_p2 participation_ema
  |> fun voters ->
  let open Alpha_context in
  (* all voters vote, for yays;
       no nays, so supermajority is satisfied *)
  List.map_es
    (fun del -> Op.ballot (B b) del Tezos_crypto.Protocol_hash.zero Vote.Yay)
    voters
  >>=? fun operations ->
  Block.bake ~operations b >>=? fun b ->
  (* skip to first block cooldown period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* we move to cooldown because we have supermajority and enough quorum *)
  assert_period ~expected_kind:Cooldown b __LOC__ >>=? fun () ->
  (* skip to first block of promotion period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  assert_period ~expected_kind:Promotion b __LOC__
  (* bake_until_first_block_of_next_period ~offset:1l b
   * >>=? fun b ->
   * assert_period ~expected_kind:Promotion b __LOC__ *)
  >>=?
  fun () ->
  Context.Vote.get_participation_ema b >>=? fun initial_participation_ema ->
  (* beginning of promotion period, denoted by _p4;
     take a snapshot of the active delegates and their voting power from listings *)
  get_delegates_and_power_from_listings b >>=? fun (delegates_p4, power_p4) ->
  Context.Vote.get_participation_ema b >>=? fun participation_ema ->
  get_smallest_prefix_voters_for_quorum delegates_p4 power_p4 participation_ema
  |> fun voters ->
  (* take the first voter out so there cannot be quorum *)
  let voters_without_quorum =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.tl voters
  in
  get_power b voters_without_quorum __LOC__ >>=? fun voter_power ->
  (* all voters_without_quorum vote, for yays;
     no nays, so supermajority is satisfied *)
  List.map_es
    (fun del -> Op.ballot (B b) del Tezos_crypto.Protocol_hash.zero Vote.Yay)
    voters_without_quorum
  >>=? fun operations ->
  Block.bake ~operations b >>=? fun b ->
  (* skip to end of promotion period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  get_expected_participation_ema power_p4 voter_power initial_participation_ema
  |> fun expected_participation_ema ->
  Context.Vote.get_participation_ema b >>=? fun new_participation_ema ->
  (* assert the formula to calculate participation_ema is correct *)
  Assert.equal_int
    ~loc:__LOC__
    expected_participation_ema
    (Int32.to_int new_participation_ema)
  >>=? fun () ->
  (* we move back to the proposal period because not enough quorum *)
  assert_period ~expected_kind:Proposal b __LOC__ >>=? fun () ->
  assert_listings_not_empty b ~loc:__LOC__ >>=? fun () -> return_unit

(** Identical proposals (identified by their hash) must be counted as
    one. *)
let test_multiple_identical_proposals_count_as_one () =
  context_init 1 () >>=? fun (b, delegates) ->
  assert_period ~expected_kind:Proposal b __LOC__ >>=? fun () ->
  let proposer = WithExceptions.Option.get ~loc:__LOC__ @@ List.hd delegates in
  Op.proposals
    (B b)
    proposer
    [Tezos_crypto.Protocol_hash.zero; Tezos_crypto.Protocol_hash.zero]
  >>=? fun ops ->
  Block.bake ~operations:[ops] b >>=? fun b ->
  (* compute the weight of proposals *)
  Context.Vote.get_proposals (B b) >>=? fun ps ->
  (* compute the voting power of proposer *)
  let pkh = Context.Contract.pkh proposer in
  Context.Vote.get_listings (B b) >>=? fun l ->
  (match List.find_opt (fun (del, _) -> del = pkh) l with
  | None -> failwith "%s - Missing delegate" __LOC__
  | Some (_, proposer_power) -> return proposer_power)
  >>=? fun proposer_power ->
  (* correctly count the double proposal for zero as one proposal *)
  let expected_weight_proposer = proposer_power in
  match Environment.Protocol_hash.(Map.find zero ps) with
  | Some v ->
      if v = expected_weight_proposer then return_unit
      else
        failwith
          "%s - Wrong count %Ld is not %Ld; identical proposals count as one"
          __LOC__
          v
          expected_weight_proposer
  | None -> failwith "%s - Missing proposal" __LOC__

(** Assume the initial balance of accounts allocated by Context.init_n is at
    least 4 times the value of the tokens_per_roll constant. *)
let test_supermajority_in_proposal there_is_a_winner () =
  let min_proposal_quorum = 0l in
  let initial_balance = 1L in
  context_init
    ~min_proposal_quorum
    ~initial_balances:[initial_balance; initial_balance; initial_balance]
    10
    ()
  >>=? fun (b, delegates) ->
  Context.get_constants (B b) >>=? fun {parametric = {tokens_per_roll; _}; _} ->
  let del1 = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 0 in
  let del2 = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 1 in
  let del3 = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 2 in
  let pkhs =
    List.map (fun del -> Context.Contract.pkh del) [del1; del2; del3]
  in
  let policy = Block.Excluding pkhs in
  Op.transaction
    (B b)
    (WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 3)
    del1
    tokens_per_roll
  >>=? fun op1 ->
  Op.transaction
    (B b)
    (WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 4)
    del2
    tokens_per_roll
  >>=? fun op2 ->
  (if there_is_a_winner then Test_tez.( *? ) tokens_per_roll 3L
  else
    Test_tez.( *? ) tokens_per_roll 2L
    >>? Test_tez.( +? ) (Test_tez.of_mutez_exn initial_balance))
  >>?= fun bal3 ->
  Op.transaction
    (B b)
    (WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 5)
    del3
    bal3
  >>=? fun op3 ->
  Block.bake ~policy ~operations:[op1; op2; op3] b >>=? fun b ->
  bake_until_first_block_of_next_period ~policy b >>=? fun b ->
  (* make the proposals *)
  Op.proposals (B b) del1 [protos.(0)] >>=? fun ops1 ->
  Op.proposals (B b) del2 [protos.(0)] >>=? fun ops2 ->
  Op.proposals (B b) del3 [protos.(1)] >>=? fun ops3 ->
  Block.bake ~policy ~operations:[ops1; ops2; ops3] b >>=? fun b ->
  bake_until_first_block_of_next_period ~policy b >>=? fun b ->
  (* we remain in the proposal period when there is no winner,
     otherwise we move to the exploration period *)
  (if there_is_a_winner then assert_period ~expected_kind:Exploration b __LOC__
  else assert_period ~expected_kind:Proposal b __LOC__)
  >>=? fun () -> return_unit

(** After one voting period, if [has_quorum] then the period kind must
    have been the cooldown vote. Otherwise, it should have remained in
    place in the proposal period. *)
let test_quorum_in_proposal has_quorum () =
  let total_tokens = 32_000_000_000_000L in
  let half_tokens = Int64.div total_tokens 2L in
  context_init ~initial_balances:[1L; half_tokens; half_tokens] 3 ()
  >>=? fun (b, delegates) ->
  Context.get_constants (B b)
  >>=? fun {parametric = {min_proposal_quorum; _}; _} ->
  let del1 = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 0 in
  let del2 = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 1 in
  let pkhs = List.map (fun del -> Context.Contract.pkh del) [del1; del2] in
  let policy = Block.Excluding pkhs in
  let quorum =
    if has_quorum then Int64.of_int32 min_proposal_quorum
    else Int64.(sub (of_int32 min_proposal_quorum) 10L)
  in
  let bal =
    Int64.(div (mul total_tokens quorum) 100_00L) |> Test_tez.of_mutez_exn
  in
  Op.transaction (B b) del2 del1 bal >>=? fun op2 ->
  Block.bake ~policy ~operations:[op2] b >>=? fun b ->
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* make the proposal *)
  Op.proposals (B b) del1 [protos.(0)] >>=? fun ops ->
  Block.bake ~policy ~operations:[ops] b >>=? fun b ->
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* we remain in the proposal period when there is no quorum,
     otherwise we move to the cooldown vote period *)
  (if has_quorum then assert_period ~expected_kind:Exploration b __LOC__
  else assert_period ~expected_kind:Proposal b __LOC__)
  >>=? fun () -> return_unit

(** If a supermajority is reached, then the voting period must be
    reached. Otherwise, it remains in proposal period. *)
let test_supermajority_in_exploration supermajority () =
  let min_proposal_quorum = Int32.(of_int @@ (100_00 / 100)) in
  context_init ~min_proposal_quorum 100 () >>=? fun (b, delegates) ->
  let del1 = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 0 in
  let proposal = protos.(0) in
  Op.proposals (B b) del1 [proposal] >>=? fun ops1 ->
  Block.bake ~operations:[ops1] b >>=? fun b ->
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* move to exploration *)
  assert_period ~expected_kind:Exploration b __LOC__ >>=? fun () ->
  (* assert our proposal won *)
  (Context.Vote.get_current_proposal (B b) >>=? function
   | Some v ->
       if Tezos_crypto.Protocol_hash.(equal proposal v) then return_unit
       else failwith "%s - Wrong proposal" __LOC__
   | None -> failwith "%s - Missing proposal" __LOC__)
  >>=? fun () ->
  (* beginning of exploration period, denoted by _p2;
     take a snapshot of the active delegates and their voting power from listings *)
  get_delegates_and_power_from_listings b >>=? fun (delegates_p2, _power_p2) ->
  (* supermajority means [num_yays / (num_yays + num_nays) >= s_num / s_den],
     which is equivalent with [num_yays >= num_nays * s_num / (s_den - s_num)] *)
  let num_delegates = List.length delegates_p2 in
  let num_nays = num_delegates / 5 in
  (* any smaller number will do as well *)
  let num_yays = num_nays * s_num / (s_den - s_num) in
  (* majority/minority vote depending on the [supermajority] parameter *)
  let num_yays = if supermajority then num_yays else num_yays - 1 in
  let open Alpha_context in
  let nays_delegates, rest = List.split_n num_nays delegates_p2 in
  let yays_delegates, _ = List.split_n num_yays rest in
  List.map_es (fun del -> Op.ballot (B b) del proposal Vote.Yay) yays_delegates
  >>=? fun operations_yays ->
  List.map_es (fun del -> Op.ballot (B b) del proposal Vote.Nay) nays_delegates
  >>=? fun operations_nays ->
  let operations = operations_yays @ operations_nays in
  Block.bake ~operations b >>=? fun b ->
  bake_until_first_block_of_next_period b >>=? fun b ->
  (if supermajority then assert_period ~expected_kind:Cooldown b __LOC__
  else assert_period ~expected_kind:Proposal b __LOC__)
  >>=? fun () -> return_unit

(** Test also how the selection scales: all delegates propose max
    proposals. *)
let test_no_winning_proposal num_delegates () =
  let min_proposal_quorum = Int32.(of_int @@ (100_00 / num_delegates)) in
  context_init ~min_proposal_quorum num_delegates () >>=? fun (b, _) ->
  (* beginning of proposal, denoted by _p1;
     take a snapshot of the active delegates and their voting power from listings *)
  get_delegates_and_power_from_listings b >>=? fun (delegates_p1, _power_p1) ->
  let open Alpha_context in
  let props =
    List.map (fun i -> protos.(i)) (1 -- Constants.max_proposals_per_delegate)
  in
  (* all delegates active in p1 propose the same proposals *)
  List.map_es (fun del -> Op.proposals (B b) del props) delegates_p1
  >>=? fun ops_list ->
  Block.bake ~operations:ops_list b >>=? fun b ->
  (* skip to exploration period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* we stay in the same proposal period because no winning proposal *)
  assert_period ~expected_kind:Proposal b __LOC__ >>=? fun () -> return_unit

(** Vote to pass with maximum possible participation_ema (100%), it is
    sufficient for the vote quorum to be equal or greater than the
    maximum quorum cap. *)
let test_quorum_capped_maximum num_delegates () =
  let min_proposal_quorum = Int32.(of_int @@ (100_00 / num_delegates)) in
  context_init ~min_proposal_quorum num_delegates () >>=? fun (b, delegates) ->
  (* set the participation EMA to 100% *)
  Context.Vote.set_participation_ema b 100_00l >>= fun b ->
  Context.get_constants (B b) >>=? fun {parametric = {quorum_max; _}; _} ->
  (* proposal period *)
  let open Alpha_context in
  assert_period ~expected_kind:Proposal b __LOC__ >>=? fun () ->
  (* propose a new protocol *)
  let protocol = Tezos_crypto.Protocol_hash.zero in
  let proposer =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 0
  in
  Op.proposals (B b) proposer [protocol] >>=? fun ops ->
  Block.bake ~operations:[ops] b >>=? fun b ->
  (* skip to exploration period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* we moved to an exploration period with one proposal *)
  assert_period ~expected_kind:Exploration b __LOC__ >>=? fun () ->
  (* take percentage of the delegates equal or greater than quorum_max *)
  let minimum_to_pass =
    Float.of_int (List.length delegates)
    *. Int32.(to_float quorum_max)
    /. 100_00.
    |> Float.ceil |> Float.to_int
  in
  let voters = List.take_n minimum_to_pass delegates in
  (* all voters vote for yays; no nays, so supermajority is satisfied *)
  List.map_es (fun del -> Op.ballot (B b) del protocol Vote.Yay) voters
  >>=? fun operations ->
  Block.bake ~operations b >>=? fun b ->
  (* skip to next period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* expect to move to cooldown because we have supermajority and enough quorum *)
  assert_period ~expected_kind:Cooldown b __LOC__

(** Vote to pass with minimum possible participation_ema (0%), it is
    sufficient for the vote quorum to be equal or greater than the
    minimum quorum cap. *)
let test_quorum_capped_minimum num_delegates () =
  let min_proposal_quorum = Int32.(of_int @@ (100_00 / num_delegates)) in
  context_init ~min_proposal_quorum num_delegates () >>=? fun (b, delegates) ->
  (* set the participation EMA to 0% *)
  Context.Vote.set_participation_ema b 0l >>= fun b ->
  Context.get_constants (B b) >>=? fun {parametric = {quorum_min; _}; _} ->
  (* proposal period *)
  let open Alpha_context in
  assert_period ~expected_kind:Proposal b __LOC__ >>=? fun () ->
  (* propose a new protocol *)
  let protocol = Tezos_crypto.Protocol_hash.zero in
  let proposer =
    WithExceptions.Option.get ~loc:__LOC__ @@ List.nth delegates 0
  in
  Op.proposals (B b) proposer [protocol] >>=? fun ops ->
  Block.bake ~operations:[ops] b >>=? fun b ->
  (* skip to exploration period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* we moved to an exploration period with one proposal *)
  assert_period ~expected_kind:Exploration b __LOC__ >>=? fun () ->
  (* take percentage of the delegates equal or greater than quorum_min *)
  let minimum_to_pass =
    Float.of_int (List.length delegates)
    *. Int32.(to_float quorum_min)
    /. 100_00.
    |> Float.ceil |> Float.to_int
  in
  let voters = List.take_n minimum_to_pass delegates in
  (* all voters vote for yays; no nays, so supermajority is satisfied *)
  List.map_es (fun del -> Op.ballot (B b) del protocol Vote.Yay) voters
  >>=? fun operations ->
  Block.bake ~operations b >>=? fun b ->
  (* skip to next period *)
  bake_until_first_block_of_next_period b >>=? fun b ->
  (* expect to move to cooldown because we have supermajority and enough quorum *)
  assert_period ~expected_kind:Cooldown b __LOC__

(* gets the voting power *)
let get_voting_power block pkhash =
  let ctxt = Context.B block in
  Context.get_voting_power ctxt pkhash

(** Test that the voting power changes if the balance between bakers changes
    and the blockchain moves to the next voting period. It also checks that
    the total voting power coincides with the addition of the voting powers
    of bakers *)
let test_voting_power_updated_each_voting_period () =
  let init_bal1 = 80_000_000_000L in
  let init_bal2 = 48_000_000_000L in
  let init_bal3 = 40_000_000_000L in
  (* Create three accounts with different amounts *)
  context_init ~initial_balances:[init_bal1; init_bal2; init_bal3] 3 ()
  >>=? fun (genesis, contracts) ->
  let con1 = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 0 in
  let con2 = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 1 in
  let con3 = WithExceptions.Option.get ~loc:__LOC__ @@ List.nth contracts 2 in
  (* Get the key hashes of the bakers *)
  let baker1 = Context.Contract.pkh con1 in
  let baker2 = Context.Contract.pkh con2 in
  let baker3 = Context.Contract.pkh con3 in
  (* Retrieve balance of con1 *)
  let open Test_tez in
  Context.Contract.balance (B genesis) con1 >>=? fun balance1 ->
  Context.Delegate.current_frozen_deposits (B genesis) baker1
  >>=? fun frozen_deposits1 ->
  balance1 +? frozen_deposits1 >>?= fun full_balance1 ->
  Assert.equal_tez ~loc:__LOC__ full_balance1 (of_mutez_exn init_bal1)
  >>=? fun () ->
  (* Retrieve balance of con2 *)
  Context.Contract.balance (B genesis) con2 >>=? fun balance2 ->
  Context.Delegate.current_frozen_deposits (B genesis) baker2
  >>=? fun frozen_deposits2 ->
  balance2 +? frozen_deposits2 >>?= fun full_balance2 ->
  Assert.equal_tez ~loc:__LOC__ full_balance2 (of_mutez_exn init_bal2)
  >>=? fun () ->
  (* Retrieve balance of con3 *)
  Context.Contract.balance (B genesis) con3 >>=? fun balance3 ->
  Context.Delegate.current_frozen_deposits (B genesis) baker3
  >>=? fun frozen_deposits3 ->
  balance3 +? frozen_deposits3 >>?= fun full_balance3 ->
  Assert.equal_tez ~loc:__LOC__ full_balance3 (of_mutez_exn init_bal3)
  >>=? fun () ->
  (* Auxiliary assert_voting_power *)
  let assert_voting_power ~loc n block baker =
    get_voting_power block baker >>=? fun voting_power ->
    Assert.equal_int64 ~loc n voting_power
  in
  (* Auxiliary assert_total_voting_power *)
  let assert_total_voting_power ~loc n block =
    Context.get_total_voting_power (B block) >>=? fun total_voting_power ->
    Assert.equal_int64 ~loc n total_voting_power
  in
  let expected_power_of_baker_1 = Tez.to_mutez full_balance1 in
  assert_voting_power ~loc:__LOC__ expected_power_of_baker_1 genesis baker1
  >>=? fun () ->
  let expected_power_of_baker_2 = Tez.to_mutez full_balance2 in
  assert_voting_power ~loc:__LOC__ expected_power_of_baker_2 genesis baker2
  >>=? fun () ->
  (* Assert total voting power *)
  let expected_power_of_baker_3 = Tez.to_mutez full_balance3 in
  assert_total_voting_power
    ~loc:__LOC__
    Int64.(
      add
        (add expected_power_of_baker_1 expected_power_of_baker_2)
        expected_power_of_baker_3)
    genesis
  >>=? fun () ->
  (* Create policy that excludes baker1 and baker2 from baking *)
  let policy = Block.Excluding [baker1; baker2] in
  (* Transfer 30,000 tez from baker1 to baker2 *)
  let amount = Tez.of_mutez_exn 30_000_000_000L in
  Op.transaction (B genesis) con1 con2 amount >>=? fun op ->
  (* Bake the block containing the transaction *)
  Block.bake ~policy ~operations:[op] genesis >>=? fun block ->
  (* Retrieve balance of con1 *)
  Context.Contract.balance (B block) con1 >>=? fun balance1 ->
  (* Assert balance has changed by deducing the amount *)
  of_mutez_exn init_bal1 -? amount >>?= fun balance1_after_deducing_amount ->
  Context.Delegate.current_frozen_deposits (B block) baker1
  >>=? fun frozen_deposit1 ->
  balance1_after_deducing_amount -? frozen_deposit1
  >>?= Assert.equal_tez ~loc:__LOC__ balance1
  >>=? fun () ->
  (* Retrieve balance of con2 *)
  Context.Contract.balance (B block) con2 >>=? fun balance2 ->
  (* Assert balance has changed by adding amount *)
  of_mutez_exn init_bal2 +? amount >>?= fun balance2_after_adding_amount ->
  Context.Delegate.current_frozen_deposits (B block) baker2
  >>=? fun frozen_deposit2 ->
  balance2_after_adding_amount -? frozen_deposit2
  >>?= Assert.equal_tez ~loc:__LOC__ balance2
  >>=? fun () ->
  Block.bake ~policy block >>=? fun block ->
  (* Assert voting power (and total) remains the same before next voting period *)
  assert_voting_power ~loc:__LOC__ expected_power_of_baker_1 block baker1
  >>=? fun () ->
  assert_voting_power ~loc:__LOC__ expected_power_of_baker_2 block baker2
  >>=? fun () ->
  assert_voting_power ~loc:__LOC__ expected_power_of_baker_3 block baker3
  >>=? fun () ->
  assert_total_voting_power
    ~loc:__LOC__
    Int64.(
      add
        (add expected_power_of_baker_1 expected_power_of_baker_2)
        expected_power_of_baker_3)
    block
  >>=? fun () ->
  bake_until_first_block_of_next_period block >>=? fun block ->
  (* Assert voting power of baker1 has decreased by [amount] *)
  let expected_power_of_baker_1 =
    Int64.sub expected_power_of_baker_1 (Tez.to_mutez amount)
  in
  assert_voting_power ~loc:__LOC__ expected_power_of_baker_1 block baker1
  >>=? fun _ ->
  (* Assert voting power of baker2 has increased by [amount] *)
  let expected_power_of_baker_2 =
    Int64.add expected_power_of_baker_2 (Tez.to_mutez amount)
  in
  assert_voting_power ~loc:__LOC__ expected_power_of_baker_2 block baker2
  >>=? fun _ ->
  (* Retrieve voting power of baker3 *)
  get_voting_power block baker3 >>=? fun power ->
  let power_of_baker_3 = power in
  (* Assert total voting power *)
  assert_total_voting_power
    ~loc:__LOC__
    Int64.(
      add
        (add expected_power_of_baker_1 expected_power_of_baker_2)
        power_of_baker_3)
    block

let test_voting_period_pp () =
  let vp =
    Voting_period_repr.
      {
        index = Int32.of_int 123;
        kind = Proposal;
        start_position = Int32.of_int 321;
      }
  in
  Assert.equal
    ~loc:__LOC__
    ( = )
    "Unexpected pretty printing of voting period"
    Format.pp_print_string
    (Format.asprintf "%a" Voting_period_repr.pp vp)
    "index: 123, kind:proposal, start_position: 321"

let tests =
  [
    Tztest.tztest "voting successful_vote" `Quick (test_successful_vote 137);
    Tztest.tztest
      "voting cooldown, not enough quorum"
      `Quick
      (test_not_enough_quorum_in_exploration 245);
    Tztest.tztest
      "voting promotion, not enough quorum"
      `Quick
      (test_not_enough_quorum_in_promotion 432);
    Tztest.tztest
      "voting counting double proposal"
      `Quick
      test_multiple_identical_proposals_count_as_one;
    Tztest.tztest
      "voting proposal, with supermajority"
      `Quick
      (test_supermajority_in_proposal true);
    Tztest.tztest
      "voting proposal, without supermajority"
      `Quick
      (test_supermajority_in_proposal false);
    Tztest.tztest
      "voting proposal, with quorum"
      `Quick
      (test_quorum_in_proposal true);
    Tztest.tztest
      "voting proposal, without quorum"
      `Quick
      (test_quorum_in_proposal false);
    Tztest.tztest
      "voting cooldown, with supermajority"
      `Quick
      (test_supermajority_in_exploration true);
    Tztest.tztest
      "voting cooldown, without supermajority"
      `Quick
      (test_supermajority_in_exploration false);
    Tztest.tztest
      "voting proposal, no winning proposal"
      `Quick
      (test_no_winning_proposal 400);
    Tztest.tztest
      "voting quorum, quorum capped maximum"
      `Quick
      (test_quorum_capped_maximum 400);
    Tztest.tztest
      "voting quorum, quorum capped minimum"
      `Quick
      (test_quorum_capped_minimum 401);
    Tztest.tztest
      "voting power updated in each voting period"
      `Quick
      test_voting_power_updated_each_voting_period;
    Tztest.tztest "voting period pretty print" `Quick test_voting_period_pp;
  ]
