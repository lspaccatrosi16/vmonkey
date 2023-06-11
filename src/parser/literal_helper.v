module parser

import ast

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

fn literal_test(expr ast.Expression, spec LiteralSpec) bool {
	val := spec.val
	t := spec.t

	if t != '*' {
		assert expr.type_name() == 'ast.' + t
	}

	if expr is ast.Identifier {
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
	}

	assert false, 'Is not known literal'
	return false
}
