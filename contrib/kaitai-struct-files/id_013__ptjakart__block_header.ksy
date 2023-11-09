meta:
  id: id_013__ptjakart__block_header
  endian: be
  imports:
  - block_header__shell
doc: ! 'Encoding id: 013-PtJakart.block_header'
types:
  id_013__ptjakart__block_header__alpha__full_header:
    seq:
    - id: id_013__ptjakart__block_header__alpha__full_header
      type: block_header__shell
    - id: id_013__ptjakart__block_header__alpha__signed_contents
      type: id_013__ptjakart__block_header__alpha__signed_contents
  id_013__ptjakart__block_header__alpha__signed_contents:
    seq:
    - id: id_013__ptjakart__block_header__alpha__unsigned_contents
      type: id_013__ptjakart__block_header__alpha__unsigned_contents
    - id: signature
      size: 64
  id_013__ptjakart__block_header__alpha__unsigned_contents:
    seq:
    - id: payload_hash
      size: 32
    - id: payload_round
      type: s4
    - id: proof_of_work_nonce
      size: 8
    - id: seed_nonce_hash_tag
      type: u1
      enum: bool
    - id: seed_nonce_hash
      size: 32
      if: (seed_nonce_hash_tag == bool::true)
    - id: liquidity_baking_toggle_vote
      type: s1
enums:
  bool:
    0: false
    255: true
seq:
- id: id_013__ptjakart__block_header__alpha__full_header
  type: id_013__ptjakart__block_header__alpha__full_header
