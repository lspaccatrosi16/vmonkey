module error

import term

pub enum ErrorType {
	lexer_error
	parser_error
	evaluator_error
}

fn (e ErrorType) str() string {
	return match e {
		.lexer_error { 'LexerError' }
		.parser_error { 'ParserError' }
		.evaluator_error { 'EvaluatorError' }
	}
}

pub struct BaseError {
	line        i32       [required]
	col         i32       [required]
	message     string    [required]
	error_type  ErrorType [required]
	source_code string    [required]
}

const line_delim = '| '

pub fn (e BaseError) str() string {
	mut error_strings := []string{}
	lines := e.source_code.split('\n')
	this_line := lines[e.line]
	mut prev_line := ''
	mut next_line := ''

	if e.line - 1 >= 0 {
		prev_line = lines[e.line - 1]
	}

	if e.line + 1 < lines.len {
		next_line = lines[e.line + 1]
	}

	line_prefix := make_line_prefix((e.line + 1).str())

	width, _ := term.get_terminal_size()
	blank_line_start := make_line_prefix(' ')
	blank_line := blank_line_start + ' '.repeat(width - blank_line_start.len)

	error_strings << '='.repeat(width)

	error_strings << term.bold('${e.error_type.str()} at [${e.line + 1}:${e.col + 1}]: ${e.message}')

	error_strings << '='.repeat(width)

	if prev_line != '' {
		error_strings << make_line_prefix((e.line).str()) + prev_line
	} else {
		error_strings << blank_line
	}

	error_strings << line_prefix + this_line
	mut start_underline_idx := 0

	if e.col >= 2 {
		start_underline_idx = -2
	}

	mut underline_this_line := make_line_prefix(' ') + ' '.repeat(start_underline_idx + e.col)

	for i := start_underline_idx; i <= 2; i++ {
		underline_this_line += term.red('^')
	}

	error_strings << underline_this_line

	if next_line != '' {
		error_strings << make_line_prefix((e.line + 2).str()) + next_line
	} else {
		error_strings << blank_line
	}

	return error_strings.join('\n')
}

pub fn make_error(line i32, col i32, message string, e_type ErrorType, source_code string) BaseError {
	return BaseError{
		line: line
		col: col
		message: message
		error_type: e_type
		source_code: source_code
	}
}

fn make_line_prefix(num string) string {
	return '${num:4}' + error.line_delim
}
