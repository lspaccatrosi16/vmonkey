module token

pub struct SourcePosition {
pub:
	line i32 [required]
	col  i32 [required]
}

pub struct Token {
	SourcePosition
pub:
	token_type TokenType [required]
	literal    string    [required]
}

pub enum TokenType {
	illegal
	eof
	ident
	literal
	assign
	comment
	// Operators
	plus
	minus
	asterisk
	slash
	bang
	// Comparisons
	gt
	gte
	lt
	lte
	eq
	neq
	// Syntax
	comma
	semicolon
	l_paren
	r_paren
	l_squirly
	r_squirly
	// Kwords
	function
	let
	@const
	@true
	@false
	@if
	@else
	@return
}

pub const kwords = {
	'fn':     TokenType.function
	'let':    TokenType.let
	'const':  TokenType.@const
	'true':   TokenType.@true
	'false':  TokenType.@false
	'if':     TokenType.@if
	'else':   TokenType.@else
	'return': TokenType.@return
}

pub fn lookup_ident(ident string) TokenType {
	if tok := token.kwords[ident] {
		return tok
	} else {
		return TokenType.ident
	}
}

type Literal = rune | string

pub fn new_token(tokenType TokenType, ch Literal, line i32, col i32) Token {
	if ch is string {
		return Token{
			col: col
			line: line
			token_type: tokenType
			literal: ch
		}
	}

	if ch is rune {
		return Token{
			col: col
			line: line
			token_type: tokenType
			literal: ch.str()
		}
	}

	return Token{
		col: col
		line: line
		token_type: TokenType.illegal
		literal: ''
	}
}
