module parser

import ast

struct LiteralSpec {
	val string
	t   string
}

struct PrefixSpec {
	op    string
	right TestSpec
}

struct InfixSpec {
	left  TestSpec
	op    string
	right TestSpec
}

type TestSpec = InfixSpec | LiteralSpec | PrefixSpec

fn test_expression(expr ast.Expression, spec TestSpec) bool {
	return match spec {
		LiteralSpec { literal_test(expr, spec) }
		PrefixSpec { prefix_test(expr, spec) }
		InfixSpec { infix_test(expr, spec) }
	}
}
