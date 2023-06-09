module parser

import ast

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

fn test_ident() {
	input := 'foobar;'

	statements := common(input, 1)
	stmt := statements[0]
	expr := expr_stat_test(stmt)

	assert literal_test(expr, 'foobar', 'Identifier')
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
		expr := expr_stat_test(stmt)
		assert literal_test(expr, tt, 'IntegerLiteral')
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
		expr := expr_stat_test(stmt)
		assert literal_test(expr, tt, 'FloatLiteral')
	}
}

fn test_bool() {
	input := 'true;
	false;'

	exp_lit := ['true', 'false']

	statements := common(input, 2)

	for i, tt in exp_lit {
		stmt := statements[i]
		expr := expr_stat_test(stmt)
		assert literal_test(expr, tt, 'BooleanLiteral')
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
		expr := expr_stat_test(stmt)
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
			int_test := literal_test(r, val, '*')

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
		InfixTest{'true!=false;', '!=', 'true', 'false'},
		InfixTest{'false==false;', '==', 'false', 'false'},
	]

	for tt in tests {
		statements := common(tt.input, 1)
		stmt := statements[0]
		expr := expr_stat_test(stmt)
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

		assert literal_test(l, left, '*')
		assert literal_test(r, right, '*')

		return true
	} else {
		assert false, 'Not Binary Node ${expr.type_name()}'
		return false
	}
}

fn test_if() {
	input := 'if (x < y) { x } else { y }'
	statements := common(input, 1)

	stmt := statements[0]
	expr := expr_stat_test(stmt)
	assert if_test(expr)
}

fn if_test(expr ast.Expression) bool {
	if expr is ast.IfExpression {
		cond := expr.condition
		cons := expr.consequence
		assert infix_operator_test(cond, '<', 'x', 'y')
		assert cons.statements.len == 1
		expr_con := expr_stat_test(cons.statements[0])
		assert literal_test(expr_con, 'x', 'Identifier')

		if alt := expr.alternative {
			assert alt.statements.len == 1
			expr_alt := expr_stat_test(alt.statements[0])
			assert literal_test(expr_alt, 'y', 'Identifier')
			return true
		} else {
			assert false, 'Expecting an alternate but found none'
			return false
		}
	} else {
		assert false, 'Not If Expression ${expr.type_name()}'
		return false
	}
}

fn test_function() {
	input := [['fn (x, y) { x + y; }', 'x,y'], ['fn () {x + y;}', ''],
		['fn (x) {x;}', 'x']]

	for t in input {
		statements := common(t[0], 1)

		expr := expr_stat_test(statements[0])

		assert literal_test(expr, t[1], 'FunctionLiteral')
	}
}

fn test_block_expression() {
	input := '{ x + y; }'

	statements := common(input, 1)

	expr := expr_stat_test(statements[0])

	assert literal_test(expr, 'x + y', 'BlockLiteral')
}
