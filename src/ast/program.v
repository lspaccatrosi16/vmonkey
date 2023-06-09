module ast

import token

pub struct BlockStatement {
pub mut:
	statements []Statement
	token      ?token.Token
}

pub fn (mut p BlockStatement) add_statement(s Statement) {
	p.statements << s
}

pub fn (p BlockStatement) prog_string() string {
	mut stats := ['PROGRAM: \n']

	for s in p.statements {
		stats << s.literal() + '\n'
	}

	stats << 'PROGRAM END'
	return stats.join('')
}

pub fn (p BlockStatement) block_string() string {
	mut stats := ['BLOCK \n']

	for s in p.statements {
		stats << '  ' + s.literal() + '\n'
	}

	stats << 'BLOCK END'

	return stats.join('')
}

pub fn (p BlockStatement) get_statements() []Statement {
	return p.statements
}

pub type Program = BlockStatement
