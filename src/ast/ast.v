module ast

import token

pub interface Node {
	literal() string
}

pub interface Statement {
	Node
	stat()
}

pub interface Expression {
	Node
	expr()
}

pub struct Program {
	statements []Statement
}

fn (p Program) literal() string {
	if p.statements.len > 0 {
		return p.statements[0].literal()
	} else {
		return ''
	}
}

pub struct Identifier {
	token token.Token
	value string
}

fn (i Identifier) literal() string {
	return i.token.literal
}

fn (i Identifier) expr() {}

pub struct LetStatement {
	token token.Token
	name  Identifier
	value Expression
}

fn (ls LetStatement) literal() string {
	return ls.token.literal
}

fn (ls LetStatement) stat() {}
