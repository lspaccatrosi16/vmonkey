module token

pub struct Token {
pub:
	token_type TokenType
	literal    string
}

pub enum TokenType {
	illegal
	eof


	ident
	literal
	assign

	//Operators
	plus
	minus
	asterisk
	slash
	bang

	//Comparisons
	gt
	gte
	lt
	lte
	eq
	neq

	//Syntax 
	comma
	semicolon
	l_paren
	r_paren
	l_squirly
	r_squirly

	//Kwords
	function
	let
	@true
	@false
	@if
	@else
	@return

}

pub const kwords = {
	'fn':  TokenType.function
	'let': TokenType.let
	'true': TokenType.@true
	'false': TokenType.@false
	'if': TokenType.@if,
	'else': TokenType.@else,
	'return': TokenType.@return 
}

pub fn lookup_ident (ident string) TokenType {
	if  tok := kwords[ident] {
		return tok
	} else {
		return TokenType.ident
	}
}
