module lexer

import token
import error

pub struct Lexer {
	input string
mut:
	position      i32
	read_position i32
	current_line  i32
	line_col      i32
pub mut:
	lex_errors []error.BaseError
	ch         rune
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
	l.line_col++
}

fn (l Lexer) peak() rune {
	return l.input[l.read_position]
}

fn (mut l Lexer) next_token() token.Token {
	tkn := l.int_next_token()

	if tkn.token_type == token.TokenType.illegal {
		err := lexer_error(tkn.line, tkn.col - 1, 'Illegal character "${tkn.literal}" found in source',
			l.input)
		l.lex_errors << err
	}

	return tkn
}

fn (mut l Lexer) int_next_token() token.Token {
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
			l.double_char_look(`=`, token.TokenType.lt, token.TokenType.lte)
		}
		`;` {
			l.new_token(token.TokenType.semicolon, ch)
		}
		`(` {
			l.new_token(token.TokenType.l_paren, ch)
		}
		`)` {
			l.new_token(token.TokenType.r_paren, ch)
		}
		`,` {
			l.new_token(token.TokenType.comma, ch)
		}
		`+` {
			l.double_char_multi_option([`=`, `+`], [.plus, .plus_equals, .pf_plus])
		}
		`-` {
			l.double_char_multi_option([`=`, `-`], [.minus, .minus_equals, .pf_minus])
		}
		`!` {
			l.double_char_look(`=`, token.TokenType.bang, token.TokenType.neq)
		}
		`*` {
			l.double_char_look(`=`, token.TokenType.asterisk, token.TokenType.asterisk_equals)
		}
		`/` {
			l.double_char_look(`=`, token.TokenType.slash, token.TokenType.slash_equals)
		}
		`{` {
			l.new_token(token.TokenType.l_squirly, ch)
		}
		`}` {
			l.new_token(token.TokenType.r_squirly, ch)
		}
		0 {
			l.new_token(token.TokenType.eof, rune(0))
		}
		else {
			l.new_token(token.TokenType.illegal, ch)
		}
	}

	if l.ch == `#` {
		return l.new_token(token.TokenType.comment, l.all_to_end_of_line())
	} else if is_letter(l.ch) {
		idt := l.read_ident()
		return l.new_token(token.lookup_ident(idt), idt)
	} else if is_digit(l.ch) {
		tt, val := l.read_num_literal()

		return l.new_token(tt, val)
	}

	l.read_char()

	return tok
}

fn (mut l Lexer) new_token(tokenType token.TokenType, ch token.Literal) token.Token {
	line := l.current_line
	col := l.line_col
	return token.new_token(tokenType, ch, line, col)
}

fn (mut l Lexer) all_to_end_of_line() string {
	mut com := []rune{}

	for {
		if l.ch == `\n` {
			break
		}
		com << l.ch
		l.read_char()
	}

	return com.string()
}

fn (mut l Lexer) double_char_look(c2 rune, t1 token.TokenType, t2 token.TokenType) token.Token {
	if l.peak() == c2 {
		lit_val := [l.ch, l.peak()].string()
		l.read_char()

		return l.new_token(t2, lit_val)
	} else {
		return l.new_token(t1, l.ch)
	}
}

fn (mut l Lexer) double_char_multi_option(chars []rune, t []token.TokenType) token.Token {
	for idx, c in chars {
		if l.peak() == c {
			lit_val := [l.ch, l.peak()].string()
			l.read_char()

			return l.new_token(t[idx + 1], lit_val)
		}
	}

	return l.new_token(t[0], l.ch)
}

fn (mut l Lexer) skip_whitespace() {
	for is_whitespace(l.ch) {
		if l.ch == `\n` {
			l.current_line++
			l.line_col = 0
		}
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

fn (mut l Lexer) read_num_literal() (token.TokenType, string) {
	mut lit := []rune{}
	mut tt := token.TokenType.integer_literal

	if l.peak() == `b` {
		lit << l.ch
		l.read_char()
		lit << l.ch
		l.read_char()
		lit << l.read_base_n_literal(is_binary, is_illegal_binary)
	} else if l.peak() == `x` {
		lit << l.ch
		l.read_char()
		lit << l.ch
		l.read_char()
		lit << l.read_base_n_literal(is_hex, is_illegal_hex)
	} else if l.peak() == `o` {
		lit << l.ch
		l.read_char()
		lit << l.ch
		l.read_char()
		lit << l.read_base_n_literal(is_octal, is_illegal_octal)
	} else {
		lit << l.read_base_n_literal(is_digit, none)
		if l.ch == `.` {
			tt = token.TokenType.float_literal
			lit << l.ch
			l.read_char()
			lit << l.read_base_n_literal(is_digit, is_illegal_digit)
		}
	}

	return tt, lit.string()
}

fn (mut l Lexer) read_base_n_literal(f MatchFn, i ?MatchFn) []rune {
	mut lit := []rune{}
	for f(l.ch) {
		lit << l.ch
		l.read_char()
	}

	if f_i := i {
		if f_i(l.ch) {
			err := lexer_error(l.current_line, l.line_col - 1, 'Illegal character "${l.ch}" found in numeric literal',
				l.input)

			l.lex_errors << err
		}
	}

	return lit
}

pub fn (mut l Lexer) run_lexer() []token.Token {
	mut tokens := []token.Token{}

	for tok := l.next_token(); tok.token_type != token.TokenType.eof; tok = l.next_token() {
		tokens << tok
	}

	return tokens
}

fn is_hex(ch rune) bool {
	return match ch {
		`0`...`9`, `a`...`f` { true }
		else { false }
	}
}

fn is_illegal_hex(ch rune) bool {
	return match ch {
		`g`...`z` { true }
		else { false }
	}
}

fn is_octal(ch rune) bool {
	return match ch {
		`0`...`7` { true }
		else { false }
	}
}

fn is_illegal_octal(ch rune) bool {
	return match ch {
		`8`...`9`, `a`...`z` { true }
		else { false }
	}
}

fn is_binary(ch rune) bool {
	return match ch {
		`0`...`1` { true }
		else { false }
	}
}

fn is_illegal_binary(ch rune) bool {
	return match ch {
		`2`...`9`, `a`...`z` { true }
		else { false }
	}
}

fn is_digit(ch rune) bool {
	return match ch {
		`0`...`9` { true }
		else { false }
	}
}

fn is_illegal_digit(ch rune) bool {
	return match ch {
		`a`...`z` { true }
		else { false }
	}
}

fn is_whitespace(ch rune) bool {
	return match ch {
		` `, `\t`, `\r`, `\n` { true }
		else { false }
	}
}

pub fn new_lexer(input string) &Lexer {
	mut l := &Lexer{
		input: input + '\n'
		current_line: 0
	}
	l.read_char()
	return l
}
