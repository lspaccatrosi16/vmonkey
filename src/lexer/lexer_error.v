module lexer

import error

fn lexer_error(line i32, col i32, message string, source string) error.BaseError {
	return error.make_error(line, col, message, error.ErrorType.lexer_error, source)
}
