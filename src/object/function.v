module object

import ast

pub struct Function {
pub:
	parameters []ast.Identifier
	body       ast.BlockStatement
	env        &Environment
}

pub fn (f Function) str() string {
	mut str := 'fn('

	mut params := []string{}

	for p in f.parameters {
		params << p.literal()
	}

	str += params.join(', ')
	str += ')'

	return str
}
