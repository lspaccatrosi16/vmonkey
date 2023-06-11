module parser

import ast
import token
import error

type PrefixParser = fn () ?ast.Expression

type InfixParser = fn (ast.Expression) ?ast.Expression

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

const precedence_table = {
	token.TokenType.eq:              Precedence.equals
	token.TokenType.neq:             Precedence.equals
	token.TokenType.lt:              Precedence.less_greater
	token.TokenType.lte:             Precedence.less_greater
	token.TokenType.gt:              Precedence.less_greater
	token.TokenType.gte:             Precedence.less_greater
	token.TokenType.plus:            Precedence.sum
	token.TokenType.plus_equals:     Precedence.sum
	token.TokenType.minus:           Precedence.sum
	token.TokenType.minus_equals:    Precedence.sum
	token.TokenType.slash:           Precedence.product
	token.TokenType.slash_equals:    Precedence.product
	token.TokenType.asterisk:        Precedence.product
	token.TokenType.asterisk_equals: Precedence.product
	token.TokenType.l_paren:         Precedence.call
}

[heap]
pub struct Parser {
	tokens      []token.Token [required]
	source_code string        [required]
mut:
	infix_fns     map[token.TokenType]InfixParser
	prefix_fns    map[token.TokenType]PrefixParser
	current_token token.Token
	peak_token    token.Token

	read_position i32
	position      i32
pub mut:
	parse_errors []error.BaseError
}

fn (mut p Parser) next_token() {
	p.current_token = p.peak_token
	p.peak_token = p.read_token() or { token.eof_token() }
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

fn (p Parser) cur_token_is(t token.TokenType) bool {
	return p.current_token.token_type == t
}

fn (p Parser) peak_token_is(t token.TokenType) bool {
	return p.peak_token.token_type == t
}

fn (mut p Parser) expect_peak(t token.TokenType) bool {
	if p.peak_token_is(t) {
		p.next_token()
		return true
	} else {
		p.parse_errors << wrong_token_type_error(p.current_token, t, p.source_code)
		return false
	}
}

fn (p Parser) peak_precedence() Precedence {
	if p.peak_token.token_type in parser.precedence_table {
		return parser.precedence_table[p.peak_token.token_type]
	} else {
		return Precedence.lowest
	}
}

fn (p Parser) cur_precedence() Precedence {
	if p.current_token.token_type in parser.precedence_table {
		return parser.precedence_table[p.current_token.token_type]
	} else {
		return Precedence.lowest
	}
}

fn (mut p Parser) register_prefix_fn(tt token.TokenType, f PrefixParser) {
	p.prefix_fns[tt] = f
}

fn (mut p Parser) register_infix_fn(tt token.TokenType, f InfixParser) {
	p.infix_fns[tt] = f
}

fn (p Parser) get_prefix_parser_fn(t token.TokenType) ?PrefixParser {
	if t in p.prefix_fns {
		return p.prefix_fns[t]
	} else {
		return none
	}
}

fn (p Parser) get_infix_parser_fn(t token.TokenType) ?InfixParser {
	if t in p.infix_fns {
		return p.infix_fns[t]
	} else {
		return none
	}
}

//
//  EXPRESSIONS
//

fn (mut p Parser) parse_expression(precedence Precedence) ?ast.Expression {
	prefix := p.get_prefix_parser_fn(p.current_token.token_type) or {
		p.parse_errors << parser_error(p.current_token, 'No prefix parser function for ${p.current_token.token_type.str()}',
			p.source_code)

		return none
	}

	mut left_exp := prefix() or { return none }
	for !p.peak_token_is(.semicolon) && u8(precedence) < u8(p.peak_precedence()) {
		infix := p.get_infix_parser_fn(p.peak_token.token_type) or {
			p.parse_errors << parser_error(p.current_token, 'No infix parser function for ${p.peak_token.token_type.str()}',
				p.source_code)
			return none
		}
		p.next_token()

		left_exp = infix(left_exp) or { return none }
	}

	return left_exp
}

fn (p Parser) parse_identifiter() ?ast.Expression {
	return ast.Identifier{
		value: p.current_token.literal
		token: p.current_token
	}
}

fn (p Parser) parse_integer_literal() ?ast.Expression {
	return ast.IntegerLiteral{
		value: p.current_token.literal
		token: p.current_token
	}
}

fn (p Parser) parse_float_literal() ?ast.Expression {
	return ast.FloatLiteral{
		value: p.current_token.literal
		token: p.current_token
	}
}

fn (p Parser) parse_boolean_literal() ?ast.Expression {
	return ast.BooleanLiteral{
		value: p.current_token.literal
		token: p.current_token
	}
}

fn (mut p Parser) parse_prefix_expression() ?ast.Expression {
	tkn := p.current_token
	operator := p.current_token.literal

	p.next_token()

	right := p.parse_expression(.prefix) or { return none }

	expr := ast.Node{
		operator: operator
		left: none
		right: right
		token: tkn
	}

	return ast.Expression(expr)
}

fn (mut p Parser) parse_infix_expression(left ast.Expression) ?ast.Expression {
	tkn := p.current_token
	op := p.current_token.literal

	precedence := p.cur_precedence()

	p.next_token()

	right := p.parse_expression(precedence) or { return none }

	expr := ast.Node{
		operator: op
		left: left
		right: right
		token: tkn
	}

	return ast.Expression(expr)
}

fn (mut p Parser) parse_grouped_expression() ?ast.Expression {
	p.next_token()

	expr := p.parse_expression(.lowest)

	if !p.expect_peak(.r_paren) {
		return none
	}

	return expr
}

fn (mut p Parser) parse_if_expression() ?ast.Expression {
	tkn := p.current_token

	if !p.expect_peak(.l_paren) {
		return none
	}

	p.next_token()

	cond := p.parse_expression(.lowest) or { return none }

	if !p.expect_peak(.r_paren) {
		return none
	}
	if !p.expect_peak(.l_squirly) {
		return none
	}

	cons := p.parse_block_statement()

	expr := ast.IfExpression{
		token: tkn
		condition: cond
		consequence: cons
		alternative: p.get_else_statement()
	}

	return ast.Expression(expr)
}

fn (mut p Parser) get_else_statement() ?ast.BlockStatement {
	if p.peak_token_is(.@else) {
		p.next_token()

		if !p.expect_peak(.l_squirly) {
			return none
		}

		return p.parse_block_statement()
	} else {
		return none
	}
}

fn (mut p Parser) parse_block_expression() ?ast.Expression {
	tkn := p.current_token
	body := p.parse_block_statement()

	expr := ast.BlockLiteral{
		token: tkn
		body: body
	}

	return ast.Expression(expr)
}

fn (mut p Parser) parse_function_expression() ?ast.Expression {
	tkn := p.current_token

	if !p.expect_peak(.l_paren) {
		return none
	}

	params := p.parse_function_parameters() or { return none }

	if !p.expect_peak(.l_squirly) {
		return none
	}

	body := p.parse_block_statement()

	lit := ast.FunctionLiteral{
		token: tkn
		parameters: params
		body: body
	}

	return ast.Expression(lit)
}

fn (mut p Parser) parse_function_parameters() ?[]ast.Identifier {
	mut identifiers := []ast.Identifier{}

	if p.peak_token_is(.r_paren) {
		p.next_token()
		return []
	}

	p.next_token()

	mut ident := ast.Identifier{
		token: p.current_token
		value: p.current_token.literal
	}
	identifiers << ident

	for p.peak_token_is(.comma) {
		p.next_token()
		p.next_token()
		ident = ast.Identifier{
			token: p.current_token
			value: p.current_token.literal
		}
		identifiers << ident
	}

	if !p.expect_peak(.r_paren) {
		return none
	}

	return identifiers
}

fn (mut p Parser) parse_call_expression(function ast.Expression) ?ast.Expression {
	tkn := p.current_token
	args := p.parse_call_arguments() or { return none }

	expr := ast.CallLiteral{
		token: tkn
		arguments: args
		function: function
	}

	return ast.Expression(expr)
}

fn (mut p Parser) parse_call_arguments() ?[]ast.Expression {
	mut args := []ast.Expression{}

	if p.peak_token_is(.r_paren) {
		p.next_token()
		return args
	}

	p.next_token()

	mut arg := p.parse_expression(.lowest) or { return none }

	args << arg

	for p.peak_token_is(.comma) {
		p.next_token()
		p.next_token()
		arg = p.parse_expression(.lowest) or { return none }

		args << arg
	}

	if !p.expect_peak(.r_paren) {
		return none
	}

	return args
}

//
//	STATEMENTS
//

fn (mut p Parser) parse_block_statement() ast.BlockStatement {
	tkn := p.current_token
	mut statements := []ast.Statement{}
	p.next_token()

	for !p.cur_token_is(.r_squirly) && !p.cur_token_is(.eof) {
		if stmt := p.parse_statement() {
			statements << stmt
		}

		p.next_token()
	}

	block := ast.BlockStatement{
		token: tkn
		statements: statements
	}

	return block
}

fn (mut p Parser) parse_var_statement() ?ast.Statement {
	tok := p.current_token

	if !p.expect_peak(.ident) {
		return none
	}
	name := ast.Identifier{
		value: p.current_token.literal
		token: p.current_token
	}
	if !p.expect_peak(.assign) {
		return none
	}

	p.next_token()

	val := p.parse_expression(.lowest) or { return none }

	if p.peak_token_is(.semicolon) {
		p.next_token()
	}

	stmt := ast.VarStatement{
		token: tok
		name: name
		value: val
	}
	return ast.Statement(stmt)
}

fn (mut p Parser) parse_return_statement() ?ast.Statement {
	tok := p.current_token

	p.next_token()

	ret := p.parse_expression(.lowest) or { return none }

	if p.peak_token_is(.semicolon) {
		p.next_token()
	}

	stmt := ast.ReturnStatement{
		token: tok
		value: ret
	}
	return ast.Statement(stmt)
}

fn (mut p Parser) parse_expression_statement() ?ast.Statement {
	tkn := p.current_token

	expr := p.parse_expression(Precedence.lowest) or { return none }

	if p.peak_token_is(.semicolon) {
		p.next_token()
	}

	stmt := ast.ExpressionStatement{
		token: tkn
		value: expr
	}

	return ast.Statement(stmt)
}

fn (mut p Parser) parse_statement() ?ast.Statement {
	return match p.current_token.token_type {
		.let, .@const { p.parse_var_statement() }
		.@return { p.parse_return_statement() }
		else { p.parse_expression_statement() }
	}
}

pub fn (mut p Parser) parse_program() &ast.Program {
	mut program := &ast.Program{}

	for !p.cur_token_is(.eof) {
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
		peak_token: token.eof_token()
		source_code: source_code
	}
	p.next_token()
	p.next_token()

	// REGISTERED PARSRE FUNCTIONS

	// LITERALS
	p.register_prefix_fn(.ident, p.parse_identifiter)
	p.register_prefix_fn(.integer_literal, p.parse_integer_literal)
	p.register_prefix_fn(.float_literal, p.parse_float_literal)
	p.register_prefix_fn(.@true, p.parse_boolean_literal)
	p.register_prefix_fn(.@false, p.parse_boolean_literal)
	p.register_prefix_fn(.l_squirly, p.parse_block_expression)

	// PREFIX EXPRESSIONS

	p.register_prefix_fn(.bang, p.parse_prefix_expression)
	p.register_prefix_fn(.minus, p.parse_prefix_expression)
	p.register_prefix_fn(.pf_plus, p.parse_prefix_expression)
	p.register_prefix_fn(.pf_minus, p.parse_prefix_expression)
	p.register_prefix_fn(.l_paren, p.parse_grouped_expression)
	p.register_prefix_fn(.@if, p.parse_if_expression)
	p.register_prefix_fn(.function, p.parse_function_expression)

	// INFIX EXPRESSIONS

	p.register_infix_fn(.eq, p.parse_infix_expression)
	p.register_infix_fn(.neq, p.parse_infix_expression)
	p.register_infix_fn(.lt, p.parse_infix_expression)
	p.register_infix_fn(.lte, p.parse_infix_expression)
	p.register_infix_fn(.gt, p.parse_infix_expression)
	p.register_infix_fn(.gte, p.parse_infix_expression)
	p.register_infix_fn(.plus, p.parse_infix_expression)
	p.register_infix_fn(.plus_equals, p.parse_infix_expression)
	p.register_infix_fn(.minus, p.parse_infix_expression)
	p.register_infix_fn(.minus_equals, p.parse_infix_expression)
	p.register_infix_fn(.slash, p.parse_infix_expression)
	p.register_infix_fn(.slash_equals, p.parse_infix_expression)
	p.register_infix_fn(.asterisk, p.parse_infix_expression)
	p.register_infix_fn(.asterisk_equals, p.parse_infix_expression)
	p.register_infix_fn(.l_paren, p.parse_call_expression)

	return p
}
