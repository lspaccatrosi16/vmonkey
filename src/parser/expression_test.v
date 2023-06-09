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

	assert test_expression(expr, LiteralSpec{'foobar', 'Identifier'})
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
		assert test_expression(expr, LiteralSpec{tt, 'IntegerLiteral'})
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
		assert test_expression(expr, LiteralSpec{tt, 'FloatLiteral'})
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
		assert test_expression(expr, LiteralSpec{tt, 'BooleanLiteral'})
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
		assert test_expression(expr, PrefixSpec{tt.op, LiteralSpec{tt.val, '*'}})
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
		assert test_expression(expr, InfixSpec{LiteralSpec{tt.left, '*'}, tt.op, LiteralSpec{tt.right, '*'}})
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
		assert test_expression(cond, InfixSpec{LiteralSpec{'x', 'Identifier'}, '<', LiteralSpec{'y', 'Identifier'}})
		assert cons.statements.len == 1
		expr_con := expr_stat_test(cons.statements[0])
		assert test_expression(expr_con, LiteralSpec{'x', 'Identifier'})

		if alt := expr.alternative {
			assert alt.statements.len == 1
			expr_alt := expr_stat_test(alt.statements[0])
			assert test_expression(expr_alt, LiteralSpec{'y', 'Identifier'})
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

		assert fn_test(expr, t[1])
	}
}

fn fn_test(expr ast.Expression, val string) bool {
	if expr is ast.FunctionLiteral {
		parsed := val.split(',')

		for i, ident in parsed {
			if ident == '' {
				continue
			}
			assert expr.parameters.len > i, 'Not enough parameters parsed'
			assert test_expression(expr.parameters[i], LiteralSpec{ident.trim(' '), 'Identifier'})
		}

		assert expr.body.statements.len >= 1
		return true
	} else {
		assert false, 'Not a function literal'
		return false
	}
}

fn test_block_expression() {
	input := '{ x + y; }'

	statements := common(input, 1)

	expr := expr_stat_test(statements[0])

	assert block_test(expr, InfixSpec{LiteralSpec{'x', 'Identifier'}, '+', LiteralSpec{'y', 'Identifier'}})
}

fn block_test(expr ast.Expression, spec InfixSpec) bool {
	if expr is ast.BlockLiteral {
		assert expr.body.statements.len >= 1

		stmt := expr.body.statements[0]

		sub_expr := expr_stat_test(stmt)

		assert test_expression(sub_expr, spec)

		return true
	} else {
		assert false, 'Not block literal ${expr.type_name()}'
		return false
	}
}

fn test_call_expression() {
	input := 'add(1+2, 3*4, 5);'

	statements := common(input, 1)
	expr := expr_stat_test(statements[0])
	assert call_test(expr, [
		InfixSpec{LiteralSpec{'1', 'IntegerLiteral'}, '+', LiteralSpec{'2', 'IntegerLiteral'}},
		InfixSpec{LiteralSpec{'3', 'IntegerLiteral'}, '*', LiteralSpec{'4', 'IntegerLiteral'}},
		LiteralSpec{'5', 'IntegerLiteral'},
	])
}

fn call_test(expr ast.Expression, specs []TestSpec) bool {
	if expr is ast.CallLiteral {
		for i, spec in specs {
			test_expression(expr.arguments[i], spec)
		}
		return true
	} else {
		assert false, 'Not call literal ${expr.type_name()}'
		return false
	}
}
