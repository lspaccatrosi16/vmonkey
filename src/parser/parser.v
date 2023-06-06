module parser

import ast
import token
import error

type PrefixParser = fn () ast.Expression
type InfixParser = fn (ast.Expression) ast.Expression

enum Precedence as u8 {
	_
	lowest
	equals
	less_greater
	sum
	product
	prefix
	call
}

pub struct Parser {
	tokens      []token.Token [required]
	source_code string        [required]
mut:
	infix_fns     map[token.TokenType]PrefixParser
	prefix_fns    map[token.TokenType]PrefixParser
	current_token token.Token
	peek_token    token.Token

	read_position i32
	position      i32
pub mut:
	parse_errors []error.BaseError
}

fn (mut p Parser) next_token() {
	p.current_token = p.peek_token
	p.peek_token = p.read_token() or { token.eof_token() }
}

fn (mut p Parser) read_token() ?token.Token {
	if p.read_position >= p.tokens.len {
		return none
	}

	tok := p.tokens[p.read_position]
	p.position = p.read_position
	p.read_position++
	return tok
}

fn (mut p Parser) register_prefix_fn(tt token.TokenType, f PrefixParser) {
	p.prefix_fns[tt] = f
}

fn (mut p Parser) register_infix_fn(tt token.TokenType, f PrefixParser) {
	p.infix_fns[tt] = f
}

fn (p Parser) cur_token_is(t token.TokenType) bool {
	return p.current_token.token_type == t
}

fn (p Parser) peek_token_is(t token.TokenType) bool {
	return p.peek_token.token_type == t
}

fn (mut p Parser) expect_peak(t token.TokenType) bool {
	if p.peek_token_is(t) {
		p.next_token()
		return true
	} else {
		p.parse_errors << wrong_token_type_error(p.current_token, t, p.source_code)
		return false
	}
}

//
//  EXPRESSIONS
//


fn (mut p Parser) parse_expression(p Precedence) {

}

//
//	STATEMENTS
//

fn (mut p Parser) parse_var_statement() ?ast.Statement {
	tok := p.current_token

	if !p.expect_peak(token.TokenType.ident) {
		return none
	}
	name := ast.Identifier{
		value: p.current_token.literal
		token: p.current_token
	}
	if !p.expect_peak(token.TokenType.assign) {
		return none
	}
	for !p.cur_token_is(token.TokenType.semicolon) {
		p.next_token()
	}
	stmt := ast.VarStatement{
		token: tok
		name: name
		value: ast.make_empty_expr()
	}
	return ast.Statement(stmt)
}

fn (mut p Parser) parse_return_statement() ?ast.Statement {
	tok := p.current_token

	p.next_token()
	for !p.cur_token_is(token.TokenType.semicolon) {
		p.next_token()
	}
	stmt := ast.ReturnStatement{
		token: tok
		value: ast.make_empty_expr()
	}
	return ast.Statement(stmt)
}

fn (mut p Parser) parse_expression_statement() ?ast.Statement {
	tkn := p.current_token

	expr := p.parse_expression(Precedence.lowest) or {
		return none
	}

	if p.peek_token_is(token.TokenType.semicolon) {
		p.next_token()
	}

	stmt := ast.ExpressionStatement {
		token: tkn
		value: expr
	}

	return ast.Statement(stmt)
}

fn (mut p Parser) parse_statement() ?ast.Statement {
	return match p.current_token.token_type {
		.let, .@const { p.parse_var_statement() }
		.@return { p.parse_return_statement() }
		else { parse_expression_statement() }
	}
}

pub fn (mut p Parser) parse_program() &ast.Program {
	mut program := &ast.Program{}

	for !p.cur_token_is(token.TokenType.eof) {
		if stmt := p.parse_statement() {
			program.add_statement(stmt)
		}
		p.next_token()
	}

	return program
}

pub fn new_parser(tkns []token.Token, source_code string) &Parser {
	mut p := &Parser{
		tokens: tkns
		current_token: token.eof_token()
		peek_token: token.eof_token()
		source_code: source_code
	}
	p.next_token()
	p.next_token()

	return p
}
