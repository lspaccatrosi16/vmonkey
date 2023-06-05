module lexer

import token

struct TokenSequenceTest {
	expected_type    token.TokenType
	expected_literal string
}

pub fn test_lexer() {
	input := 'let five = 5.0;
let ten = 0xa;
let add = fn(x, y) {
x + y + 0o777 + 0b1110;
};
# This is a comment with things
let result = add(five, ten);
!-/*5;
5 < 10 >= 5;

if (5 < 10 ) {
	return true;
} else {
	return false;
}

10 == 10;
10 != 9;
const a = ten;
'
	tests := [
		TokenSequenceTest{token.TokenType.let, 'let'},
		TokenSequenceTest{token.TokenType.ident, 'five'},
		TokenSequenceTest{token.TokenType.assign, '='},
		TokenSequenceTest{token.TokenType.literal, '5.0'},
		TokenSequenceTest{token.TokenType.semicolon, ';'},
		TokenSequenceTest{token.TokenType.let, 'let'},
		TokenSequenceTest{token.TokenType.ident, 'ten'},
		TokenSequenceTest{token.TokenType.assign, '='},
		TokenSequenceTest{token.TokenType.literal, '0xa'},
		TokenSequenceTest{token.TokenType.semicolon, ';'},
		TokenSequenceTest{token.TokenType.let, 'let'},
		TokenSequenceTest{token.TokenType.ident, 'add'},
		TokenSequenceTest{token.TokenType.assign, '='},
		TokenSequenceTest{token.TokenType.function, 'fn'},
		TokenSequenceTest{token.TokenType.l_paren, '('}, // 15
		TokenSequenceTest{token.TokenType.ident, 'x'},
		TokenSequenceTest{token.TokenType.comma, ','},
		TokenSequenceTest{token.TokenType.ident, 'y'},
		TokenSequenceTest{token.TokenType.r_paren, ')'},
		TokenSequenceTest{token.TokenType.l_squirly, '{'},
		TokenSequenceTest{token.TokenType.ident, 'x'},
		TokenSequenceTest{token.TokenType.plus, '+'},
		TokenSequenceTest{token.TokenType.ident, 'y'},
		TokenSequenceTest{token.TokenType.plus, '+'},
		TokenSequenceTest{token.TokenType.literal, '0o777'},
		TokenSequenceTest{token.TokenType.plus, '+'},
		TokenSequenceTest{token.TokenType.literal, '0b1110'},
		TokenSequenceTest{token.TokenType.semicolon, ';'},
		TokenSequenceTest{token.TokenType.r_squirly, '}'},
		TokenSequenceTest{token.TokenType.semicolon, ';'}, // 30
		TokenSequenceTest{token.TokenType.comment, '# This is a comment with things'},
		TokenSequenceTest{token.TokenType.let, 'let'},
		TokenSequenceTest{token.TokenType.ident, 'result'},
		TokenSequenceTest{token.TokenType.assign, '='},
		TokenSequenceTest{token.TokenType.ident, 'add'},
		TokenSequenceTest{token.TokenType.l_paren, '('},
		TokenSequenceTest{token.TokenType.ident, 'five'},
		TokenSequenceTest{token.TokenType.comma, ','},
		TokenSequenceTest{token.TokenType.ident, 'ten'},
		TokenSequenceTest{token.TokenType.r_paren, ')'},
		TokenSequenceTest{token.TokenType.semicolon, ';'},
		TokenSequenceTest{token.TokenType.bang, '!'},
		TokenSequenceTest{token.TokenType.minus, '-'},
		TokenSequenceTest{token.TokenType.slash, '/'},
		TokenSequenceTest{token.TokenType.asterisk, '*'},
		TokenSequenceTest{token.TokenType.literal, '5'}, // 45
		TokenSequenceTest{token.TokenType.semicolon, ';'},
		TokenSequenceTest{token.TokenType.literal, '5'},
		TokenSequenceTest{token.TokenType.lt, '<'},
		TokenSequenceTest{token.TokenType.literal, '10'},
		TokenSequenceTest{token.TokenType.gte, '>='},
		TokenSequenceTest{token.TokenType.literal, '5'},
		TokenSequenceTest{token.TokenType.semicolon, ';'},
		TokenSequenceTest{token.TokenType.@if, 'if'},
		TokenSequenceTest{token.TokenType.l_paren, '('},
		TokenSequenceTest{token.TokenType.literal, '5'},
		TokenSequenceTest{token.TokenType.lt, '<'},
		TokenSequenceTest{token.TokenType.literal, '10'},
		TokenSequenceTest{token.TokenType.r_paren, ')'},
		TokenSequenceTest{token.TokenType.l_squirly, '{'},
		TokenSequenceTest{token.TokenType.@return, 'return'}, // 60,
		TokenSequenceTest{token.TokenType.@true, 'true'},
		TokenSequenceTest{token.TokenType.semicolon, ';'},
		TokenSequenceTest{token.TokenType.r_squirly, '}'},
		TokenSequenceTest{token.TokenType.@else, 'else'},
		TokenSequenceTest{token.TokenType.l_squirly, '{'},
		TokenSequenceTest{token.TokenType.@return, 'return'},
		TokenSequenceTest{token.TokenType.@false, 'false'},
		TokenSequenceTest{token.TokenType.semicolon, ';'},
		TokenSequenceTest{token.TokenType.r_squirly, '}'},
		TokenSequenceTest{token.TokenType.literal, '10'},
		TokenSequenceTest{token.TokenType.eq, '=='},
		TokenSequenceTest{token.TokenType.literal, '10'},
		TokenSequenceTest{token.TokenType.semicolon, ';'},
		TokenSequenceTest{token.TokenType.literal, '10'},
		TokenSequenceTest{token.TokenType.neq, '!='}, // 75
		TokenSequenceTest{token.TokenType.literal, '9'},
		TokenSequenceTest{token.TokenType.semicolon, ';'},
		TokenSequenceTest{token.TokenType.@const, 'const'},
		TokenSequenceTest{token.TokenType.ident, 'a'},
		TokenSequenceTest{token.TokenType.assign, '='},
		TokenSequenceTest{token.TokenType.ident, 'ten'},
		TokenSequenceTest{token.TokenType.semicolon, ';'},
	]

	mut l := new_lexer(input)

	for i, tt in tests {
		tok := l.next_token()
		assert tok.literal == tt.expected_literal, 'Expected: ${tt.expected_literal} Got: ${tok.literal} at TEST:${
			i + 1}'

		assert tok.token_type == tt.expected_type, 'Expected: ${tt.expected_type} Got: ${tok.token_type} at TEST:${
			i + 1}'
	}

	assert l.lex_errors.len == 0, 'Lexer ecounted lex-errors'
}
