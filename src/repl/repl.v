module repl

import lexer
import parser
import readline
import term

pub fn start() {
	term.clear()
	width, _ := term.get_terminal_size()
	divider := '='.repeat(width)
	println('Enter vmonkey program')
	println('${'.rs':-10}: restart input')
	println('${'.exit':-10}: exit')
	top: for {
		println(divider)
		mut ipt_lines := []string{}

		for {
			line := readline.read_line('') or { '' }
			ipt_lines << line

			if line == '.rs\n' {
				continue top
			} else if line == '.exit\n' {
				break top
			}

			if line == '' || line == '\n' {
				break
			}
		}

		prog_ipt := ipt_lines.join('').trim(' \n')

		if prog_ipt == '' {
			break
		}

		mut l := lexer.new_lexer(prog_ipt)

		tokens := l.run_lexer()

		if l.lex_errors.len >= 1 {
			for e in l.lex_errors {
				println(e.str())
			}

			continue
		}

		mut p := parser.new_parser(tokens, prog_ipt)
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

		if statements.len == 0 {
			for tok in tokens {
				print('${tok.token_type.str().to_upper()} : ${tok.literal}\n')
			}
		}
	}
}
