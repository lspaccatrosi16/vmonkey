module parser

import ast

fn prefix_test(expr ast.Expression, spec PrefixSpec) bool {
	if expr is ast.Node {
		assert expr.operator == spec.op, 'Not expected operator ${expr.operator}, wanted ${spec.op}'
		if l := expr.left {
			assert false, 'Left side of prefix should be none, not ${l.type_name()}'
		}

		if r := expr.right {
			int_test := test_expression(r, spec.right)

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