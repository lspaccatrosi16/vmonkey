module ast

import token

pub struct EmptyNode {}

pub struct Node {
pub:
	literal string
	token   token.Token
	left    Expression
	right   Expression
}

pub fn (n Node) literal() string {
	return ' ( ${n.left.literal()} ${n.literal} ${n.right.literal()} ) '
}

type Expression = EmptyNode | Node | Identifier

pub fn (e Expression) literal() string {
	if e is EmptyNode {
		return '<EMPTY EXPR>'
	} else {
		return e.literal()
	}
}

pub struct Identifier {
pub:
	value string
	token token.Token
}

pub fn (i Identifier) literal() string {
	return i.value
}

pub fn make_empty_expr() Expression {
	return EmptyNode{}
}
