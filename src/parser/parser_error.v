module parser

import error

fn parser_error(line i32, col i32, message string) error.BaseError {
	return error.make_error(line, col, message, error.ErrorType.parser_error)
}
