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

type Expression = BlockLiteral
	| BooleanLiteral
	| CallLiteral
	| EmptyNode
	| FloatLiteral
	| FunctionLiteral
	| Identifier
	| IfExpression
	| IntegerLiteral
	| Node

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
	} else if e is IfExpression {
		return e.literal()
	} else if e is FunctionLiteral {
		return e.literal()
	} else if e is BlockLiteral {
		return e.literal()
	} else if e is CallLiteral {
		return e.literal()
	}

	assert false, 'UKNOWN EXPRESSION'
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

pub struct IfExpression {
pub:
	token       token.Token
	condition   Expression
	consequence BlockStatement
	alternative ?BlockStatement
}

pub fn (i IfExpression) literal() string {
	mut str := 'IF '
	str += i.condition.literal()
	str += ' THEN '
	str += i.consequence.block_string()
	if c := i.alternative {
		str += '\nELSE '
		str += c.block_string()
	}

	str += '\nEND IF'

	return str
}

pub struct FunctionLiteral {
pub:
	token      token.Token
	parameters []Identifier
	body       BlockStatement
}

pub fn (f FunctionLiteral) literal() string {
	mut str := 'FN ('

	for p in f.parameters {
		str += '${p.literal()}, '
	}

	str += ') => '

	str += f.body.block_string()

	return str
}

pub struct BlockLiteral {
pub:
	token token.Token
	body  BlockStatement
}

pub fn (b BlockLiteral) literal() string {
	return b.body.block_string()
}

pub struct CallLiteral {
pub:
	token     token.Token
	function  Expression
	arguments []Expression
}

pub fn (cl CallLiteral) literal() string {
	mut str := '${cl.function.literal()}('

	for a in cl.arguments {
		str += '${a.literal()}, '
	}

	str += ')'

	return str
}

pub fn make_empty_expr() Expression {
	return EmptyNode{}
}
