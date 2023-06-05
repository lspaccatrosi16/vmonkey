module parser

import ast
import lexer

struct LetTest {
	name string
	val  string
}

pub fn test_parser() {
	input := '
	let x = 5;
	let y = 10.0;
	let foobar = 0xffff;
	'
	mut l := lexer.new_lexer(input)
	tkns := l.run_lexer()

	assert l.lex_errors.len == 0
	mut p := new_parser(tkns)

	program := p.parse_program()
	println('parsed')

	assert p.parse_errors.len == 0

	statements := program.get_statements()

	assert statements.len == 3, 'Did not return 3 statements'
	dump(statements)
	exp_idents := [LetTest{
		name: 'x'
		val: '5'
	}, LetTest{
		name: 'y'
		val: '10.0'
	}, LetTest{
		name: 'foobar'
		val: '0xffff'
	}]

	for i, tt in exp_idents {
		stmt := statements[i]
		assert let_statement_test(stmt, tt.name, tt.val), 'TEST ${i + 1} FAILED'
	}
}

fn let_statement_test(s ast.Statement, name string, val string) bool {
	if s is ast.LetStatement {
		assert s.name.literal() == name, 'Expected name ${name}, Got: ${s.name.literal()}'
		return true
	} else {
		assert false, 'Not let statement: ${s.type_name()}'
		return false
	}
}
