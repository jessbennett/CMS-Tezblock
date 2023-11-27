meta:
  id: id_012__psithaca__contract__big_map_diff
  endian: be
types:
  annots:
    seq:
    - id: len_annots
      type: s4
    - id: annots
      size: len_annots
  args:
    seq:
    - id: len_args
      type: s4
    - id: args
      type: args_entries
      size: len_args
      repeat: eos
  args_entries:
    seq:
    - id: args_elt
      type: micheline__012__psithaca__michelson_v1__expression
  bytes:
    seq:
    - id: len_bytes
      type: s4
    - id: bytes
      size: len_bytes
  id_012__psithaca__contract__big_map_diff_elt_alloc:
    seq:
    - id: big_map
      type: z
    - id: key_type
      type: micheline__012__psithaca__michelson_v1__expression
    - id: value_type
      type: micheline__012__psithaca__michelson_v1__expression
  id_012__psithaca__contract__big_map_diff_elt_copy:
    seq:
    - id: source_big_map
      type: z
    - id: destination_big_map
      type: z
  id_012__psithaca__contract__big_map_diff_elt_update:
    seq:
    - id: big_map
      type: z
    - id: key_hash
      size: 32
    - id: key
      type: micheline__012__psithaca__michelson_v1__expression
    - id: value_tag
      type: u1
      enum: bool
    - id: value
      type: micheline__012__psithaca__michelson_v1__expression
      if: (value_tag == bool::true)
  id_012__psithaca__contract__big_map_diff_entries:
    seq:
    - id: id_012__psithaca__contract__big_map_diff_elt_tag
      type: u1
      enum: id_012__psithaca__contract__big_map_diff_elt_tag
    - id: id_012__psithaca__contract__big_map_diff_elt_update
      type: id_012__psithaca__contract__big_map_diff_elt_update
      if: (id_012__psithaca__contract__big_map_diff_elt_tag == id_012__psithaca__contract__big_map_diff_elt_tag::update)
    - id: id_012__psithaca__contract__big_map_diff_elt_remove
      type: z
      if: (id_012__psithaca__contract__big_map_diff_elt_tag == id_012__psithaca__contract__big_map_diff_elt_tag::remove)
    - id: id_012__psithaca__contract__big_map_diff_elt_copy
      type: id_012__psithaca__contract__big_map_diff_elt_copy
      if: (id_012__psithaca__contract__big_map_diff_elt_tag == id_012__psithaca__contract__big_map_diff_elt_tag::copy)
    - id: id_012__psithaca__contract__big_map_diff_elt_alloc
      type: id_012__psithaca__contract__big_map_diff_elt_alloc
      if: (id_012__psithaca__contract__big_map_diff_elt_tag == id_012__psithaca__contract__big_map_diff_elt_tag::alloc)
  micheline__012__psithaca__michelson_v1__expression:
    seq:
    - id: micheline__012__psithaca__michelson_v1__expression_tag
      type: u1
      enum: micheline__012__psithaca__michelson_v1__expression_tag
    - id: micheline__012__psithaca__michelson_v1__expression_int
      type: z
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::int)
    - id: micheline__012__psithaca__michelson_v1__expression_string
      type: string
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::string)
    - id: micheline__012__psithaca__michelson_v1__expression_sequence
      type: micheline__012__psithaca__michelson_v1__expression_sequence
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::sequence)
    - id: micheline__012__psithaca__michelson_v1__expression_prim__no_args__no_annots
      type: u1
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: id_012__psithaca__michelson__v1__primitives
    - id: micheline__012__psithaca__michelson_v1__expression_prim__no_args__some_annots
      type: micheline__012__psithaca__michelson_v1__expression_prim__no_args__some_annots
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: micheline__012__psithaca__michelson_v1__expression_prim__1_arg__no_annots
      type: micheline__012__psithaca__michelson_v1__expression_prim__1_arg__no_annots
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: micheline__012__psithaca__michelson_v1__expression_prim__1_arg__some_annots
      type: micheline__012__psithaca__michelson_v1__expression_prim__1_arg__some_annots
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: micheline__012__psithaca__michelson_v1__expression_prim__2_args__no_annots
      type: micheline__012__psithaca__michelson_v1__expression_prim__2_args__no_annots
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: micheline__012__psithaca__michelson_v1__expression_prim__2_args__some_annots
      type: micheline__012__psithaca__michelson_v1__expression_prim__2_args__some_annots
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: micheline__012__psithaca__michelson_v1__expression_prim__generic
      type: micheline__012__psithaca__michelson_v1__expression_prim__generic
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__generic)
    - id: micheline__012__psithaca__michelson_v1__expression_bytes
      type: bytes
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::bytes)
  micheline__012__psithaca__michelson_v1__expression_prim__1_arg__no_annots:
    seq:
    - id: prim
      type: u1
      enum: id_012__psithaca__michelson__v1__primitives
    - id: arg
      type: micheline__012__psithaca__michelson_v1__expression
  micheline__012__psithaca__michelson_v1__expression_prim__1_arg__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_012__psithaca__michelson__v1__primitives
    - id: arg
      type: micheline__012__psithaca__michelson_v1__expression
    - id: annots
      type: annots
  micheline__012__psithaca__michelson_v1__expression_prim__2_args__no_annots:
    seq:
    - id: prim
      type: u1
      enum: id_012__psithaca__michelson__v1__primitives
    - id: arg1
      type: micheline__012__psithaca__michelson_v1__expression
    - id: arg2
      type: micheline__012__psithaca__michelson_v1__expression
  micheline__012__psithaca__michelson_v1__expression_prim__2_args__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_012__psithaca__michelson__v1__primitives
    - id: arg1
      type: micheline__012__psithaca__michelson_v1__expression
    - id: arg2
      type: micheline__012__psithaca__michelson_v1__expression
    - id: annots
      type: annots
  micheline__012__psithaca__michelson_v1__expression_prim__generic:
    seq:
    - id: prim
      type: u1
      enum: id_012__psithaca__michelson__v1__primitives
    - id: args
      type: args
    - id: annots
      type: annots
  micheline__012__psithaca__michelson_v1__expression_prim__no_args__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_012__psithaca__michelson__v1__primitives
    - id: annots
      type: annots
  micheline__012__psithaca__michelson_v1__expression_sequence:
    seq:
    - id: len_sequence
      type: s4
    - id: sequence
      type: sequence_entries
      size: len_sequence
      repeat: eos
  n_chunk:
    seq:
    - id: has_more
      type: b1be
    - id: payload
      type: b7be
  sequence_entries:
    seq:
    - id: sequence_elt
      type: micheline__012__psithaca__michelson_v1__expression
  string:
    seq:
    - id: len_string
      type: s4
    - id: string
      size: len_string
  z:
    seq:
    - id: has_tail
      type: b1be
    - id: sign
      type: b1be
    - id: payload
      type: b6be
    - id: tail
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
      if: has_tail.as<bool>
enums:
  bool:
    0: false
    255: true
  id_012__psithaca__contract__big_map_diff_elt_tag:
    0: update
    1: remove
    2: copy
    3: alloc
  id_012__psithaca__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3:
      id: false
      doc: False
    4:
      id: elt
      doc: Elt
    5:
      id: left
      doc: Left
    6:
      id: none_0
      doc: None
    7:
      id: pair_1
      doc: Pair
    8:
      id: right
      doc: Right
    9:
      id: some_0
      doc: Some
    10:
      id: true
      doc: True
    11:
      id: unit_1
      doc: Unit
    12:
      id: pack
      doc: PACK
    13:
      id: unpack
      doc: UNPACK
    14:
      id: blake2b
      doc: BLAKE2B
    15:
      id: sha256
      doc: SHA256
    16:
      id: sha512
      doc: SHA512
    17:
      id: abs
      doc: ABS
    18:
      id: add
      doc: ADD
    19:
      id: amount
      doc: AMOUNT
    20:
      id: and
      doc: AND
    21:
      id: balance
      doc: BALANCE
    22:
      id: car
      doc: CAR
    23:
      id: cdr
      doc: CDR
    24:
      id: check_signature
      doc: CHECK_SIGNATURE
    25:
      id: compare
      doc: COMPARE
    26:
      id: concat
      doc: CONCAT
    27:
      id: cons
      doc: CONS
    28:
      id: create_account
      doc: CREATE_ACCOUNT
    29:
      id: create_contract
      doc: CREATE_CONTRACT
    30:
      id: implicit_account
      doc: IMPLICIT_ACCOUNT
    31:
      id: dip
      doc: DIP
    32:
      id: drop
      doc: DROP
    33:
      id: dup
      doc: DUP
    34:
      id: ediv
      doc: EDIV
    35:
      id: empty_map
      doc: EMPTY_MAP
    36:
      id: empty_set
      doc: EMPTY_SET
    37:
      id: eq
      doc: EQ
    38:
      id: exec
      doc: EXEC
    39:
      id: failwith
      doc: FAILWITH
    40:
      id: ge
      doc: GE
    41:
      id: get
      doc: GET
    42:
      id: gt
      doc: GT
    43:
      id: hash_key
      doc: HASH_KEY
    44:
      id: if
      doc: IF
    45:
      id: if_cons
      doc: IF_CONS
    46:
      id: if_left
      doc: IF_LEFT
    47:
      id: if_none
      doc: IF_NONE
    48:
      id: int_0
      doc: INT
    49:
      id: lambda_0
      doc: LAMBDA
    50:
      id: le
      doc: LE
    51:
      id: left_0
      doc: LEFT
    52:
      id: loop
      doc: LOOP
    53:
      id: lsl
      doc: LSL
    54:
      id: lsr
      doc: LSR
    55:
      id: lt
      doc: LT
    56:
      id: map_0
      doc: MAP
    57:
      id: mem
      doc: MEM
    58:
      id: mul
      doc: MUL
    59:
      id: neg
      doc: NEG
    60:
      id: neq
      doc: NEQ
    61:
      id: nil
      doc: NIL
    62:
      id: none
      doc: NONE
    63:
      id: not
      doc: NOT
    64:
      id: now
      doc: NOW
    65:
      id: or_0
      doc: OR
    66:
      id: pair_0
      doc: PAIR
    67:
      id: push
      doc: PUSH
    68:
      id: right_0
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some
      doc: SOME
    71:
      id: source
      doc: SOURCE
    72:
      id: sender
      doc: SENDER
    73:
      id: self
      doc: SELF
    74:
      id: steps_to_quota
      doc: STEPS_TO_QUOTA
    75:
      id: sub
      doc: SUB
    76:
      id: swap
      doc: SWAP
    77:
      id: transfer_tokens
      doc: TRANSFER_TOKENS
    78:
      id: set_delegate
      doc: SET_DELEGATE
    79:
      id: unit_0
      doc: UNIT
    80:
      id: update
      doc: UPDATE
    81:
      id: xor
      doc: XOR
    82:
      id: iter
      doc: ITER
    83:
      id: loop_left
      doc: LOOP_LEFT
    84:
      id: address_0
      doc: ADDRESS
    85:
      id: contract_0
      doc: CONTRACT
    86:
      id: isnat
      doc: ISNAT
    87:
      id: cast
      doc: CAST
    88:
      id: rename
      doc: RENAME
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111:
      id: slice
      doc: SLICE
    112:
      id: dig
      doc: DIG
    113:
      id: dug
      doc: DUG
    114:
      id: empty_big_map
      doc: EMPTY_BIG_MAP
    115:
      id: apply
      doc: APPLY
    116: chain_id
    117:
      id: chain_id_0
      doc: CHAIN_ID
    118:
      id: level
      doc: LEVEL
    119:
      id: self_address
      doc: SELF_ADDRESS
    120: never
    121:
      id: never_0
      doc: NEVER
    122:
      id: unpair
      doc: UNPAIR
    123:
      id: voting_power
      doc: VOTING_POWER
    124:
      id: total_voting_power
      doc: TOTAL_VOTING_POWER
    125:
      id: keccak
      doc: KECCAK
    126:
      id: sha3
      doc: SHA3
    127:
      id: pairing_check
      doc: PAIRING_CHECK
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_0
      doc: TICKET
    137:
      id: read_ticket
      doc: READ_TICKET
    138:
      id: split_ticket
      doc: SPLIT_TICKET
    139:
      id: join_tickets
      doc: JOIN_TICKETS
    140:
      id: get_and_update
      doc: GET_AND_UPDATE
    141: chest
    142: chest_key
    143:
      id: open_chest
      doc: OPEN_CHEST
    144:
      id: view_0
      doc: VIEW
    145: view
    146: constant
    147:
      id: sub_mutez
      doc: SUB_MUTEZ
  micheline__012__psithaca__michelson_v1__expression_tag:
    0: int
    1: string
    2: sequence
    3:
      id: prim__no_args__no_annots
      doc: Primitive with no arguments and no annotations
    4:
      id: prim__no_args__some_annots
      doc: Primitive with no arguments and some annotations
    5:
      id: prim__1_arg__no_annots
      doc: Primitive with one argument and no annotations
    6:
      id: prim__1_arg__some_annots
      doc: Primitive with one argument and some annotations
    7:
      id: prim__2_args__no_annots
      doc: Primitive with two arguments and no annotations
    8:
      id: prim__2_args__some_annots
      doc: Primitive with two arguments and some annotations
    9:
      id: prim__generic
      doc: Generic primitive (any number of args with or without annotations)
    10: bytes
seq:
- id: len_id_012__psithaca__contract__big_map_diff
  type: s4
- id: id_012__psithaca__contract__big_map_diff
  type: id_012__psithaca__contract__big_map_diff_entries
  size: len_id_012__psithaca__contract__big_map_diff
  repeat: eos