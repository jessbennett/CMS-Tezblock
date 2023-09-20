/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

mod ast;
mod gas;
mod parser;
mod stack;
mod syntax;
mod typechecker;

fn main() {}

#[cfg(test)]
mod tests {
    use std::collections::VecDeque;

    use crate::ast::*;
    use crate::gas::Gas;
    use crate::parser;
    use crate::typechecker;

    #[test]
    fn typecheck_test_expect_success() {
        let ast = parser::parse(&FIBONACCI_SRC).unwrap();
        let mut stack = VecDeque::from([Type::Nat]);
        assert!(typechecker::typecheck(&ast, &mut Gas::default(), &mut stack).is_ok());
        assert_eq!(stack, VecDeque::from([Type::Int]));
    }

    #[test]
    fn typecheck_gas() {
        let ast = parser::parse(&FIBONACCI_SRC).unwrap();
        let mut stack = VecDeque::from([Type::Nat]);
        let mut gas = Gas::new(11460);
        assert!(typechecker::typecheck(&ast, &mut gas, &mut stack).is_ok());
        assert_eq!(gas.milligas(), 0);
    }

    #[test]
    fn typecheck_out_of_gas() {
        let ast = parser::parse(&FIBONACCI_SRC).unwrap();
        let mut stack = VecDeque::from([Type::Nat]);
        let mut gas = Gas::new(1000);
        assert_eq!(
            typechecker::typecheck(&ast, &mut gas, &mut stack),
            Err(typechecker::TcError::OutOfGas)
        );
    }

    #[test]
    fn typecheck_test_expect_fail() {
        let ast = parser::parse(&FIBONACCI_ILLTYPED_SRC).unwrap();
        let mut stack = VecDeque::from([Type::Nat]);
        assert_eq!(
            typechecker::typecheck(&ast, &mut Gas::default(), &mut stack),
            Err(typechecker::TcError::StackTooShort)
        );
    }

    #[test]
    fn parser_test_expect_success() {
        let ast = parser::parse(&FIBONACCI_SRC).unwrap();
        // use built in pretty printer to validate the expected AST.
        assert_eq!(format!("{:#?}", ast), AST_PRETTY_EXPECTATION);
    }

    #[test]
    fn parser_test_expect_fail() {
        assert_eq!(
            &parser::parse(&FIBONACCI_MALFORMED_SRC)
                .unwrap_err()
                .to_string(),
            "Unrecognized token `GT` found at 133:135\nExpected one of \";\" or \"}\""
        );
    }

    const FIBONACCI_SRC: &str = "{ INT ; PUSH int 0 ; DUP 2 ; GT ;
           IF { DIP { PUSH int -1 ; ADD } ;
            PUSH int 1 ;
            DUP 3 ;
            GT ;
            LOOP { SWAP ; DUP 2 ; ADD ; DIP 2 { PUSH int -1 ; ADD } ; DUP 3 ; GT } ;
            DIP { DROP 2 } }
          { DIP { DROP } } }";

    const FIBONACCI_ILLTYPED_SRC: &str = "{ INT ; PUSH int 0 ; DUP 2 ; GT ;
           IF { DIP { PUSH int -1 ; ADD } ;
            PUSH int 1 ;
            DUP 4 ;
            GT ;
            LOOP { SWAP ; DUP 2 ; ADD ; DIP 2 { PUSH int -1 ; ADD } ; DUP 3 ; GT } ;
            DIP { DROP 2 } }
          { DIP { DROP } } }";

    const FIBONACCI_MALFORMED_SRC: &str = "{ INT ; PUSH int 0 ; DUP 2 ; GT ;
           IF { DIP { PUSH int -1 ; ADD } ;
            PUSH int 1 ;
            DUP 4
            GT ;
            LOOP { SWAP ; DUP 2 ; ADD ; DIP 2 { PUSH int -1 ; ADD } ; DUP 3 ; GT } ;
            DIP { DROP 2 } }
          { DIP { DROP } } }";

    const AST_PRETTY_EXPECTATION: &str = "[
    Int,
    Push(
        Int,
        NumberValue(
            0,
        ),
    ),
    Dup(
        Some(
            2,
        ),
    ),
    Gt,
    If(
        [
            Dip(
                None,
                [
                    Push(
                        Int,
                        NumberValue(
                            -1,
                        ),
                    ),
                    Add,
                ],
            ),
            Push(
                Int,
                NumberValue(
                    1,
                ),
            ),
            Dup(
                Some(
                    3,
                ),
            ),
            Gt,
            Loop(
                [
                    Swap,
                    Dup(
                        Some(
                            2,
                        ),
                    ),
                    Add,
                    Dip(
                        Some(
                            2,
                        ),
                        [
                            Push(
                                Int,
                                NumberValue(
                                    -1,
                                ),
                            ),
                            Add,
                        ],
                    ),
                    Dup(
                        Some(
                            3,
                        ),
                    ),
                    Gt,
                ],
            ),
            Dip(
                None,
                [
                    Drop(
                        Some(
                            2,
                        ),
                    ),
                ],
            ),
        ],
        [
            Dip(
                None,
                [
                    Drop(
                        None,
                    ),
                ],
            ),
        ],
    ),
]";
}
