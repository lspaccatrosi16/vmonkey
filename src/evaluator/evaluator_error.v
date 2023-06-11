module evaluator

import error
import token

fn eval_error(tkn token.Token, message string, source string) error.BaseError {
	return error.make_error(tkn.line, tkn.col, message, error.ErrorType.evaluator_error,
		source)
}
