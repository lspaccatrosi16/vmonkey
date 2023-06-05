module ast

import token

pub enum StatementType {
	let
	empty
}

pub type Statement = EmptyStatement | LetStatement

pub struct EmptyStatement {
	statement_type StatementType = .empty
}

pub struct LetStatement {
pub:
	name           Identifier    [required]
	value          Expression    [required]
	statement_type StatementType = .let
	token          token.Token   [required]
}

pub fn (l LetStatement) stat_string() string {
	return 'LET ${l.name.literal()} = ${l.value.literal()}'
}

pub fn (s Statement) literal() string {
	if s is EmptyStatement {
		return '<EMPTY STAT>'
	} else if s is LetStatement {
		return s.stat_string()
	}

	return '<ERROR UNKOWN STATEMENT>'
}

pub fn make_empty_statement() EmptyStatement {
	return EmptyStatement{}
}
