module parser

import error
import token

fn parser_error(tkn token.Token, message string, source string) error.BaseError {
	return error.make_error(tkn.line, tkn.col, message, error.ErrorType.parser_error,
		source)
}

fn wrong_token_type_error(tkn token.Token, exp token.TokenType, source string) error.BaseError {
	return parser_error(tkn, 'Expected ${exp.str().to_upper()} but found ${tkn.token_type.str().to_upper()}',
		source)
}
