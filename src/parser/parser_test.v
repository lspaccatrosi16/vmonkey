module parser

import ast
import lexer

struct VarTest {
	name string
	val  string
}

struct RetTest {
	val string
}

fn common(input string, stmt_len i32) []ast.Statement {
	mut l := lexer.new_lexer(input)
	tkns := l.run_lexer()

	assert l.lex_errors.len == 0
	mut p := new_parser(tkns, input)

	program := p.parse_program()
	assert p.parse_errors.len == 0

	statements := program.get_statements()

	assert statements.len == stmt_len, 'Did not return ${stmt_len} statements'

	return statements
}

fn test_var() {
	input := '
	let x = 5;
	const y = 10.0;
	let foobar = 0xffff;
	'

	statements := common(input, 3)

	exp_idents := [VarTest{
		name: 'x'
		val: '5'
	}, VarTest{
		name: 'y'
		val: '10.0'
	}, VarTest{
		name: 'foobar'
		val: '0xffff'
	}]

	for i, tt in exp_idents {
		stmt := statements[i]
		assert var_statement_test(stmt, tt.name, tt.val), 'TEST ${i + 1} FAILED'
	}
}

fn var_statement_test(s ast.Statement, name string, val string) bool {
	if s is ast.VarStatement {
		assert s.name.literal() == name, 'Expected name ${name}, Got: ${s.name.literal()}'
		return true
	} else {
		assert false, 'Not let statement: ${s.type_name()}'
		return false
	}
}

fn test_return() {
	input := '
	return 5;
	return 10;
	return 69.420;
	'
	statements := common(input, 3)

	exp_vals := [RetTest{
		val: '5'
	}, RetTest{
		val: '10'
	}, RetTest{
		val: '69.420'
	}]

	for i, tt in exp_vals {
		stmt := statements[i]
		assert ret_statement_test(stmt, tt.val)
	}
}

fn ret_statement_test(s ast.Statement, val string) bool {
	if s is ast.ReturnStatement {
		return true
	} else {
		assert false, 'Not return statement: ${s.type_name()}'
		return false
	}
}

fn test_ident() {
	input := 'foobar;'

	statements := common(input, 1)
	stmt := statements[0]

	assert stmt is ast.ExpressionStatement, 'Not Expression Statement ${stmt.type_name()}'

	expr := (stmt as ast.ExpressionStatement).value

	if expr is ast.Identifier {
		assert expr.value == 'foobar'
	} else {
		assert false, 'Not ident expression ${expr.type_name()}'
	}
}
