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

struct PrefixTest {
	input string
	op    string
	val   string
}

struct InfixTest {
	input string
	op    string
	left  string
	right string
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

	assert literal_test(expr, "foobar", "Identifier")
}

fn test_integer() {
	input := '5;
	0x3f;
	0o44;
	0b1100;'

	exp_lit := ['5', '0x3f', '0o44', '0b1100']

	statements := common(input, 4)

	for i, tt in exp_lit {
		stmt := statements[i]
		assert stmt is ast.ExpressionStatement, 'Not Expression Statement ${stmt.type_name()}'
		expr := (stmt as ast.ExpressionStatement).value
		assert literal_test(expr, tt, "IntegerLiteral")
	}
}

fn test_float() {
	input := '5.0;
	0.000000005;
	10000000.2;'
	exp_lit := ['5.0', '0.000000005', '10000000.2']

	statements := common(input, 3)

	for i, tt in exp_lit {
		stmt := statements[i]
		assert stmt is ast.ExpressionStatement, 'Not Expression Statement ${stmt.type_name()}'
		expr := (stmt as ast.ExpressionStatement).value
		assert literal_test(expr, tt, "FloatLiteral")
	}
}

fn test_bool() {
	input := 'true;
	false;'

	exp_lit:= ["true", "false"]

	statements := common(input, 2)

	for i,tt in exp_lit {
		stmt := statements[i]
		assert stmt is ast.ExpressionStatement, 'Not Expression Statement ${stmt.type_name()}'
		expr := (stmt as ast.ExpressionStatement).value
		assert literal_test(expr, tt, "BooleanLiteral")
	}
}

fn test_prefix() {
	tests := [
		PrefixTest{'!5;', '!', '5'},
		PrefixTest{'-15;', '-', '15'},
		PrefixTest{'++a;', '++', 'a'},
		PrefixTest{'--0xff;', '--', '0xff'},
	]

	for tt in tests {
		statements := common(tt.input, 1)
		stmt := statements[0]
		assert stmt is ast.ExpressionStatement, 'Not Expression Statement ${stmt.type_name()}'
		expr := (stmt as ast.ExpressionStatement).value
		assert prefix_operator_test(expr, tt.val, tt.op)
	}
}

fn prefix_operator_test(expr ast.Expression, val string, op string) bool {
	if expr is ast.Node {
		assert expr.operator == op, 'Not expected operator ${expr.operator}, wanted ${op}'
		if l := expr.left {
			assert false, 'Left side of prefix should be none, not ${l.type_name()}'
		}

		if r := expr.right {
			int_test := literal_test(r, val, "*")

			assert int_test
			return true
		} else {
			assert false
			assert false, 'Right side of prefix should not be none'
			return false
		}
	} else {
		assert false, 'Not Binary Node ${expr.type_name()}'
		return false
	}
}

fn test_infix() {
	tests := [
		InfixTest{'5+5;', '+', '5', '5'},
		InfixTest{'5-5;', '-', '5', '5'},
		InfixTest{'5*5;', '*', '5', '5'},
		InfixTest{'5/5;', '/', '5', '5'},
		InfixTest{'5>5;', '>', '5', '5'},
		InfixTest{'5<5;', '<', '5', '5'},
		InfixTest{'5==5;', '==', '5', '5'},
		InfixTest{'5!=5;', '!=', '5', '5'},
		InfixTest{'5>=5;', '>=', '5', '5'},
		InfixTest{'5<=5;', '<=', '5', '5'},
		InfixTest{'5+=5;', '+=', '5', '5'},
		InfixTest{'5-=5;', '-=', '5', '5'},
		InfixTest{'5*=5;', '*=', '5', '5'},
		InfixTest{'5/=5;', '/=', '5', '5'},
		InfixTest{'true==true;', '==', 'true', 'true'},
		InfixTest{'true!=false;', '!=' 'true', 'false'},
		InfixTest{'false==false;', '==', 'false', 'false'},
	]

	for tt in tests {
		statements := common(tt.input, 1)
		stmt := statements[0]
		assert stmt is ast.ExpressionStatement, 'Not Expression Statement ${stmt.type_name()}'
		expr := (stmt as ast.ExpressionStatement).value
		assert infix_operator_test(expr, tt.op, tt.left, tt.right)
	}
}

fn infix_operator_test(expr ast.Expression, op string, left string, right string) bool {
	if expr is ast.Node {
		assert expr.operator == op, 'Not expected operator ${expr.operator}, wanted ${op}'
		l := expr.left or {
			assert false, 'Left side should not be none'
			return false
		}

		r := expr.right or {
			assert false, 'Right side should not be none'
			return false
		}

		assert literal_test(l, left, "*")
		assert literal_test(r, right, "*")

		return true
	} else {
		assert false, 'Not Binary Node ${expr.type_name()}'
		return false
	}
}
