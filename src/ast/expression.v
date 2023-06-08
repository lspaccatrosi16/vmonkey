module ast

import token

pub struct EmptyNode {}

pub struct Node {
pub:
	token    token.Token
	left     ?Expression
	right    ?Expression
	operator string
}

pub fn (n Node) literal() string {
	mut left := ' '
	mut right := ' '

	if l := n.left {
		left = ' ${l.literal()} '
	}

	if r := n.right {
		right = ' ${r.literal()} '
	}

	return ' (${left}${n.operator}${right}) '
}

type Expression = BooleanLiteral | EmptyNode | FloatLiteral | Identifier | IntegerLiteral | Node

pub fn (e Expression) literal() string {
	if e is EmptyNode {
		return '<EMPTY EXPR>'
	} else if e is Identifier {
		return e.literal()
	} else if e is Node {
		return e.literal()
	} else if e is IntegerLiteral {
		return e.literal()
	} else if e is FloatLiteral {
		return e.literal()
	} else if e is BooleanLiteral {
		return e.literal()
	}

	return '<UNKNOWN EXPR>'
}

pub struct Identifier {
pub:
	value string
	token token.Token
}

pub fn (i Identifier) literal() string {
	return i.value
}

pub struct IntegerLiteral {
pub:
	value string
	token token.Token
}

pub fn (i IntegerLiteral) literal() string {
	return i.value
}

pub struct FloatLiteral {
pub:
	value string
	token token.Token
}

pub fn (f FloatLiteral) literal() string {
	return f.value
}

pub struct BooleanLiteral {
pub:
	value string
	token token.Token
}

pub fn (b BooleanLiteral) literal() string {
	return b.value
}

pub fn make_empty_expr() Expression {
	return EmptyNode{}
}
