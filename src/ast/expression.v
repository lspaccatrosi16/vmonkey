module ast

import token

pub struct EmptyNode {}

pub struct Node {
pub:
	literal string
	token   token.Token
	left    ?Expression
	right   ?Expression
}

pub fn (n Node) literal() string {
	mut left := ''
	mut right := ''

	if l := n.left {
		left = l.literal()
	}

	if r := n.right {
		right = r.literal()
	}

	return ' ( ${left} ${n.literal} ${right} ) '
}

type Expression = EmptyNode | Identifier | Node | IntegerLiteral

pub fn (e Expression) literal() string {
	if e is EmptyNode {
		return '<EMPTY EXPR>'
	} else if e is Identifier {
		return e.literal()
	} else if e is Node {
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

pub fn make_empty_expr() Expression {
	return EmptyNode{}
}
