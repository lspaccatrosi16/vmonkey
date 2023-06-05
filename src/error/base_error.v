module error

pub enum ErrorType {
	lexer_error
	parser_error
	interpreter_error
}

fn (e ErrorType) str() string {
	return match e {
		.lexer_error { 'LexerError' }
		.parser_error { 'ParserError' }
		.interpreter_error { 'InterpreterError' }
	}
}

pub struct BaseError {
	line       i32       [required]
	col        i32       [required]
	message    string    [required]
	error_type ErrorType [required]
}

pub fn (e BaseError) str() string {
	return '${e.error_type.str()} at [${e.line}:${e.col + 1}]: ${e.message}'
}

pub fn make_error(line i32, col i32, message string, e_type ErrorType) BaseError {
	return BaseError{
		line: line
		col: col
		message: message
		error_type: e_type
	}
}
