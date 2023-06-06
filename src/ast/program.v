module ast

pub struct Program {
mut:
	statements []Statement
}

pub fn (mut p Program) add_statement(s Statement) {
	p.statements << s
}

pub fn (p Program) prog_string() string {
	mut stats := ['PROGRAM: \n']

	for s in p.statements {
		stats << s.literal() + '\n'
	}

	stats << 'PROGRAM END'
	return stats.join('')
}

pub fn (p Program) get_statements() []Statement {
	return p.statements
}
