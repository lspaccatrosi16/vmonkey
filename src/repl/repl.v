module repl

import os
import lexer
import parser

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

			continue
		}

		mut p := parser.new_parser(tokens)
		program := p.parse_program()

		if p.parse_errors.len >= 1 {
			for e in p.parse_errors {
				println(e.str())
			}
			continue
		}

		statements := (*program).get_statements()

		for stmt in statements {
			println(stmt.literal())
		}
	}
}
