module repl

import readline
import object
import term
import runner

fn clear_screen() {
	term.clear()
	println('Enter vmonkey program')
	println('${'.clear':-10}: clears screen')
	println('${'.exit':-10}: exit')
	println('${'.reset':-10}: resets environment')
	println('${'.rs':-10}: restart input')
}

pub fn start(track bool, strat string) {
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

		runner.run(prog_ipt, track, mut env, strat)
	}
}
