module parser

import ast

fn infix_test(expr ast.Expression, spec InfixSpec) bool {
	if expr is ast.Node {
		assert expr.operator == spec.op, 'Not expected operator ${expr.operator}, wanted ${spec.op}'
		l := expr.left or {
			assert false, 'Left side should not be none'
			return false
		}

		r := expr.right or {
			assert false, 'Right side should not be none'
			return false
		}

		assert test_expression(l, spec.left)
		assert test_expression(r, spec.right)
		return true
	} else {
		assert false, 'Not Binary Node ${expr.type_name()}'
		return false
	}
}
