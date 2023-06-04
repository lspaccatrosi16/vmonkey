module lexer

import token

pub struct Lexer {
	input string
mut:
	position      i64
	read_position i64
pub mut:
	ch rune
}

type MatchFn = fn (rune) bool

fn (mut l Lexer) read_char() {
	if l.read_position >= l.input.len {
		l.ch = 0
	} else {
		l.ch = l.input[l.read_position]
	}

	l.position = l.read_position
	l.read_position++
}

fn (l Lexer) peak() rune {
	return l.input[l.read_position]
}
pub fn (mut l Lexer) next_token() token.Token {
	l.skip_whitespace()
	ch := l.ch
	tok := match ch {
		`=` {
			l.double_char_look(`=`, token.TokenType.assign, token.TokenType.eq)
		}
		`>` {
			l.double_char_look(`=`, token.TokenType.gt, token.TokenType.gte)
		}
		`<` {
			l.double_char_look(`!`, token.TokenType.lt, token.TokenType.lte)
		}
		`;` {
			new_token(token.TokenType.semicolon, ch)
		}
		`(` {
			new_token(token.TokenType.l_paren, ch)
		}
		`)` {
			new_token(token.TokenType.r_paren, ch)
		}
		`,` {
			new_token(token.TokenType.comma, ch)
		}
		`+` {
			new_token(token.TokenType.plus, ch)
		}
		`-` {
			new_token(token.TokenType.minus, ch)
		}
		`!` {
			l.double_char_look(`=`, token.TokenType.bang, token.TokenType.neq)
		}
		`*` {
			new_token(token.TokenType.asterisk, ch)
		}
		`/` {
			new_token(token.TokenType.slash, ch)
		}
		`{` {
			new_token(token.TokenType.l_squirly, ch)
		}
		`}` {
			new_token(token.TokenType.r_squirly, ch)
		}
		0 {
			new_token(token.TokenType.eof, rune(0))
		}
		else {
			new_token(token.TokenType.illegal, ch)
		}
	}

	if is_letter(l.ch) {
		idt := l.read_ident()
		return new_token(token.lookup_ident(idt), idt)
	} else if is_digit(l.ch) {
		return new_token(token.TokenType.literal, l.read_literal())
	}

	l.read_char()

	return tok
}

fn (mut l Lexer) double_char_look(c2 rune, t1 token.TokenType, t2 token.TokenType) token.Token {
	println("Double char look ${l.ch} ${l.peak()}")

	if l.peak() == c2 {
		lit_val := [l.ch, l.peak()].string()
		l.read_char()

		return new_token(t2, lit_val)
	} else {
		return new_token(t1, l.ch)
	}
}

fn (mut l Lexer) skip_whitespace() {
	for l.ch == ` ` || l.ch == `\t` || l.ch == `\r` || l.ch == `\n` {
		l.read_char()
	}
}

fn (mut l Lexer) read_ident() string {
	mut idt := []rune{}

	for is_letter(l.ch) {
		idt << l.ch
		l.read_char()
	}

	return idt.string()
}

fn is_letter(ch rune) bool {
	return match ch {
		`a`...`z`, `A`...`Z`, `_` { true }
		else { false }
	}
}

fn (mut l Lexer) read_literal() string {
	mut lit := []rune{}

	if l.peak() == `b` {
		lit << l.ch
		l.read_char()
		lit << l.ch
		l.read_char()
		lit << l.read_base_n_literal(is_binary)
	} else if l.peak() == `x` {
		lit << l.ch
		l.read_char()
		lit << l.ch
		l.read_char()
		lit << l.read_base_n_literal(is_hex)
	} else if l.peak() == `o` {
		lit << l.ch
		l.read_char()
		lit << l.ch
		l.read_char()
		lit << l.read_base_n_literal(is_octal)
	} else {
		lit << l.read_base_n_literal(is_digit_or_point)
	}

	return lit.string()
}

fn (mut l Lexer) read_base_n_literal(f MatchFn) []rune {
	mut lit := []rune{}
	for f(l.ch) {
		lit << l.ch
		l.read_char()
	}

	return lit
}

fn is_hex(ch rune) bool {
	return match ch {
		`0`...`9`, `a`...`f` { true }
		else { false }
	}
}

fn is_octal(ch rune) bool {
	return match ch {
		`0`...`7` { true }
		else { false }
	}
}

fn is_binary(ch rune) bool {
	return match ch {
		`0`...`1` { true }
		else { false }
	}
}

fn is_digit(ch rune) bool {
	return match ch {
		`0`...`9` { true }
		else { false }
	}
}

fn is_digit_or_point(ch rune) bool {
	if is_digit(ch) || ch == `.` {
		return true
	}

	return false
}

pub fn new_lexer(input string) &Lexer {
	mut l := &Lexer{
		input: input
	}
	l.read_char()
	return l
}

type Literal = rune | string

fn new_token(tokenType token.TokenType, ch Literal) token.Token {
	if ch is string {
		return token.Token{
			token_type: tokenType
			literal: ch
		}
	}

	if ch is rune {
		return token.Token{
			token_type: tokenType
			literal: ch.str()
		}
	}

	return token.Token{
		token_type: token.TokenType.illegal
		literal: ''
	}
}
