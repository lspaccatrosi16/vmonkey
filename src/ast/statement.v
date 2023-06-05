module ast

import token

pub enum StatementType {
	var
	empty
	@return
}

pub type Statement = EmptyStatement | VarStatement | ReturnStatement

pub fn (s Statement) literal() string {
	if s is EmptyStatement {
		return '<EMPTY STAT>'
	} else if s is VarStatement {
		return s.stat_string()
	} else if s is ReturnStatement {
		return s.stat_string()
	}

	return '<ERROR UNKOWN STATEMENT>'
}

pub fn make_empty_statement() EmptyStatement {
	return EmptyStatement{}
}

pub struct EmptyStatement {
	statement_type StatementType = .empty
}

pub struct VarStatement {
pub:
	name           Identifier    [required]
	value          Expression    [required]
	statement_type StatementType = .var
	token          token.Token   [required]
}

pub fn (l VarStatement) stat_string() string {
	mut type_text := "LET"

	if l.token.token_type == token.TokenType.@const {
		type_text = "CONST"
	}
	
	return '${type_text} ${l.name.literal()} = ${l.value.literal()}'
}

pub struct ReturnStatement {
	token          token.Token   [required]
	statement_type StatementType = .@return
	value          Expression    [required]
}

pub fn (r ReturnStatement) stat_string() string {
	return 'RET ${r.value.literal()}'
}