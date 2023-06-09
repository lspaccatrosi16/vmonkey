module parser

import ast
import lexer

fn float_literal_test(expr ast.Expression, val string) bool {
	if expr is ast.FloatLiteral {
		assert expr.value == val
		return true
	} else {
		assert false, 'Not integer expression ${expr.type_name()}'
		return false
	}
}

fn integer_literal_test(expr ast.Expression, val string) bool {
	if expr is ast.IntegerLiteral {
		assert expr.value == val
		return true
	} else {
		assert false, 'Not integer expression ${expr.type_name()}'
		return false
	}
}

fn ident_test(expr ast.Expression, val string) bool {
	if expr is ast.Identifier {
		assert expr.value == val
		return true
	} else {
		assert false, 'Not an identifier'
		return false
	}
}

fn bool_literal_test(expr ast.Expression, val string) bool {
	if expr is ast.BooleanLiteral {
		assert expr.value == val
		return true
	} else {
		assert false, 'Not an identifier'
		return false
	}
}

fn fn_literal_test(expr ast.Expression, val string) bool {
	if expr is ast.FunctionLiteral {
		parsed := val.split(',')

		for i, ident in parsed {
			if ident == '' {
				continue
			}
			assert expr.parameters.len > i, 'Not enough parameters parsed'
			assert literal_test(expr.parameters[i], ident.trim(' '), 'Identifier')
		}

		assert expr.body.statements.len >= 1
		return true
	} else {
		assert false, 'Not a function literal'
		return false
	}
}

fn block_literal_test(expr ast.Expression, val string) bool {
	if expr is ast.BlockLiteral {
		assert expr.body.statements.len >= 1
		return true
	} else {
		assert false, 'Not block literal ${expr.type_name()}'
		return false
	}
}

fn literal_test(expr ast.Expression, val string, t string) bool {
	if t != '*' {
		assert expr.type_name() == 'src.ast.' + t
	}

	if expr is ast.Node {
		assert false, 'Node is not a literal'
		return false
	} else if expr is ast.EmptyNode {
		assert false, 'Empty node is not a literal'
		return false
	} else if expr is ast.Identifier {
		assert ident_test(expr, val)
		return true
	} else if expr is ast.IntegerLiteral {
		assert integer_literal_test(expr, val)
		return true
	} else if expr is ast.FloatLiteral {
		assert float_literal_test(expr, val)
		return true
	} else if expr is ast.BooleanLiteral {
		assert bool_literal_test(expr, val)
		return true
	} else if expr is ast.FunctionLiteral {
		assert fn_literal_test(expr, val)
		return true
	} else if expr is ast.BlockLiteral {
		assert block_literal_test(expr, val)
	}

	assert false, 'Is not known literal'
	return false
}

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
