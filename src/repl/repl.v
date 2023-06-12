module repl

import lexer
import parser
import readline
import object
import term
import evaluator

fn clear_screen() {
	term.clear()
	println('Enter vmonkey program')
	println('${'.clear':-10}: clears screen')
	println('${'.exit':-10}: exit')
	println('${'.reset':-10}: resets environment')
	println('${'.rs':-10}: restart input')
}

pub fn start() {
	clear_screen()
	width, _ := term.get_terminal_size()
	divider := '='.repeat(width)

	mut env := object.new_environment()

	top: for {
		println(divider)
		mut ipt_lines := []string{}

		for {
			line := (readline.read_line('') or { '' }).replace('\r', '')

			ipt_lines << line

			if line == '.rs\n' {
				continue top
			} else if line == '.exit\n' {
				break top
			} else if line == '.clear\n' {
				clear_screen()
				continue top
			} else if line == '.reset\n' {
				clear_screen()
				env = object.new_environment()
				continue top
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

		mut eval := evaluator.new_evaluator(prog_ipt)

		obj := eval.eval(program, mut env)

		if eval.eval_errors.len >= 1 {
			for e in eval.eval_errors {
				println(e.str())
			}
			eval.free()

			continue
		}

		if r := obj {
			println((*r).string())
		} else if statements.len > 0 {
			println(program.prog_string())
		} else {
			for tok in tokens {
				print('${tok.token_type.str().to_upper()} : ${tok.literal}\n')
			}
		}

		eval.free()
	}
}
