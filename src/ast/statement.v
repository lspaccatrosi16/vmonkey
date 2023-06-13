module ast

import token

pub enum StatementType {
	var
	empty
	@return
	expr_stat
	assign
}

pub type Statement = AssignStatement | ExpressionStatement | ReturnStatement | VarStatement

pub fn (s Statement) literal() string {
	if s is VarStatement {
		return s.stat_string()
	} else if s is ReturnStatement {
		return s.stat_string()
	} else if s is ExpressionStatement {
		return s.stat_string()
	} else if s is AssignStatement {
		return s.stat_string()
	}

	return '<UNKOWN STATEMENT>'
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
	mut type_text := 'LET'

	if l.token.token_type == token.TokenType.@const {
		type_text = 'CONST'
	}

	return '${type_text} ${l.name.literal()} = ${l.value.literal()}'
}

pub struct AssignStatement {
pub:
	name           Identifier    [required]
	value          Expression    [required]
	statement_type StatementType = .assign
	token          token.Token   [required]
}

pub fn (a AssignStatement) stat_string() string {
	return '${a.name.literal()} = ${a.value.literal()}'
}

pub struct ReturnStatement {
pub:
	token          token.Token   [required]
	statement_type StatementType = .@return
	value          Expression    [required]
}

pub fn (r ReturnStatement) stat_string() string {
	return 'RET ${r.value.literal()}'
}

pub struct ExpressionStatement {
pub:
	token          token.Token   [required]
	statement_type StatementType = .expr_stat
	value          Expression    [required]
}

pub fn (e ExpressionStatement) stat_string() string {
	return e.value.literal()
}
