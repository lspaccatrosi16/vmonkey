module parser

import ast

import lexer 


fn common(input string, stmt_len i32) []ast.Statement {
	mut l := lexer.new_lexer(input)
	tkns := l.run_lexer()

	for err in l.lex_errors {
		println(err.str())
	}

	assert l.lex_errors.len == 0
	mut p := new_parser(tkns, input)

	program := p.parse_program()

	for err in p.parse_errors {
		println(err.str())
	}

	assert p.parse_errors.len == 0

	statements := program.get_statements()

	assert statements.len == stmt_len, 'Did not return ${stmt_len} statements'

	return statements
}

fn expr_stat_test(stmt ast.Statement) ast.Expression {
	assert stmt is ast.ExpressionStatement, 'Not Expression Statement ${stmt.type_name()}'

	expr := (stmt as ast.ExpressionStatement).value

	return expr
}