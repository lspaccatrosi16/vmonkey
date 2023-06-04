module repl

import os
import token
import lexer

const prompt = '>>'

pub fn start() {
	for {
		print(repl.prompt)

		line := os.get_line()

		if line == '' || line == 'exit' {
			return
		}

		mut l := lexer.new_lexer(line)

		for tok := l.next_token(); tok.token_type != token.TokenType.eof; tok = l.next_token() {
			print('${tok.token_type.str().to_upper()} : ${tok.literal}\n')
		}
	}
}
