module runner

import lexer
import parser
import evaluator
import object

pub fn run(file string, track bool, mut env object.Environment) {
	mut l := lexer.new_lexer(file)

	tokens := l.run_lexer()

	if l.lex_errors.len >= 1 {
		for e in l.lex_errors {
			println(e.str())
		}

		return
	}

	mut p := parser.new_parser(tokens, file)
	program := p.parse_program()

	if p.parse_errors.len >= 1 {
		for e in p.parse_errors {
			println(e.str())
		}
		return
	}
	statements := (*program).get_statements()

	mut eval := evaluator.new_evaluator(file, track)

	obj := eval.eval(program, mut env)

	if eval.eval_errors.len >= 1 {
		for e in eval.eval_errors {
			println(e.str())
		}
		eval.free()

		return
	}

	if r := obj {
		println((*r).string())
		if track {
			println('LIT ALLOC: ${eval.lit_alloc_count} EVAL COUNT: ${eval.eval_count}')
		}
	} else if statements.len > 0 {
		println(program.prog_string())
	} else {
		for tok in tokens {
			print('${tok.token_type.str().to_upper()} : ${tok.literal}\n')
		}
	}

	eval.free()
	return
}
