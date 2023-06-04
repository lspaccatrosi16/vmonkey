module repl

import os
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

		tokens := l.run_lexer()

		if l.lex_errors.len >= 1 {
			for e in l.lex_errors {
				println(e.str())
			}
		} else {
			for tok in tokens {
				print('${tok.token_type.str().to_upper()} : ${tok.literal}\n')
			}
		}
	}
}
