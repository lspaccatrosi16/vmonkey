module evaluator

import ast
import error
import object
import strconv
import token

const null = object.new_null_value()

const o_size = sizeof(object.Object)

fn get_null_ptr() &object.Object {
	return &evaluator.null
}

pub struct Evaluator {
	source_code string
mut:
	literal_map map[string]&object.Object
pub mut:
	eval_errors []error.BaseError
}

pub fn (mut e Evaluator) make_val_literal(val object.Literal) &object.Object {
	key := match val {
		bool { 'BOOL_${val}' }
		f64 { 'F64_${val}' }
		i64 { 'I64_${val}' }
	}

	if v := e.literal_map[key] {
		return v
	} else {
		obj := match val {
			bool { object.Object(object.Boolean{val}) }
			f64 { object.Object(object.Float{val}) }
			i64 { object.Object(object.Integer{val}) }
		}

		obj_ptr := unsafe { memdup_uncollectable(&obj, int(evaluator.o_size)) }
		e.literal_map[key] = obj_ptr
		return obj_ptr
	}
}

pub fn (mut e Evaluator) free() {
	values := e.literal_map.keys()

	for v in values {
		unsafe {
			free(v)
		}
	}
	unsafe {
		e.literal_map.free()
	}
}

pub fn (mut e Evaluator) eval(node ast.AstNode) ?&object.Object {
	if node is ast.Expression {
		return e.eval_expression(node)
	} else if node is ast.Statement {
		return e.eval_statement(node)
	} else if node is ast.BlockStatement {
		return e.eval_block(node)
	} else if node is ast.Program {
		return e.eval_program(node)
	}
	return none
}

pub fn (mut e Evaluator) eval_expression(expr ast.Expression) ?&object.Object {
	if expr is ast.IntegerLiteral {
		return e.eval_integer(expr)
	} else if expr is ast.FloatLiteral {
		return e.eval_float(expr)
	} else if expr is ast.BooleanLiteral {
		return e.eval_bool(expr)
	} else if expr is ast.Node {
		return e.eval_node(expr)
	}

	e.make_eval_error(expr)
	return none
}

pub fn (mut e Evaluator) eval_integer(expr ast.IntegerLiteral) ?&object.Object {
	val_as_int := strconv.parse_int(expr.value, 0, 64) or {
		e.make_convert_error(expr)
		return none
	}
	return e.make_val_literal(val_as_int)
}

pub fn (mut e Evaluator) eval_float(expr ast.FloatLiteral) ?&object.Object {
	val_as_float := strconv.atof64(expr.value) or {
		e.make_convert_error(expr)
		return none
	}
	return e.make_val_literal(val_as_float)
}

pub fn (mut e Evaluator) eval_bool(expr ast.BooleanLiteral) ?&object.Object {
	mut val_as_bool := false

	if expr.value == 'true' {
		val_as_bool = true
	} else if expr.value == 'false' {
		val_as_bool = false
	} else {
		e.make_convert_error(expr)
		return none
	}

	return e.make_val_literal(val_as_bool)
}

pub fn (mut e Evaluator) eval_node(expr ast.Node) ?&object.Object {
	mut left := if l := expr.left {
		if lval := e.eval(l) {
			lval
		} else {
			get_null_ptr()
		}
	} else {
		get_null_ptr()
	}

	right := if r := expr.right {
		if rval := e.eval(r) {
			rval
		} else {
			get_null_ptr()
		}
	} else {
		get_null_ptr()
	}

	if right.is_null() {
		dump(expr)
		panic('Right side of a node must always contain a value')
	}

	if left.is_null() {
		return e.eval_prefix_expression(expr.operator, right, expr.token) or { return none }
	} else {
		return e.eval_infix_expression(expr.operator, left, right, expr.token) or { return none }
	}
}

pub fn (mut e Evaluator) eval_node_side(s ?ast.Expression) ?&object.Object {
	if side := s {
		return e.eval(side) or { none }
	} else {
		return none
	}
}

pub fn (mut e Evaluator) eval_prefix_expression(operator string, right object.Object, tkn token.Token) ?&object.Object {
	return match operator {
		'!' {
			e.handle_prefix_node_result(object.bang, right, tkn)
		}
		'-' {
			e.handle_prefix_node_result(object.negate, right, tkn)
		}
		else {
			e.make_expr_err(tkn, 'No handler for prefix operator ${operator} for ${right.type_name()}')
			none
		}
	}
}

pub fn (mut e Evaluator) handle_prefix_node_result(f object.PrefixOperation, right object.Object, tkn token.Token) ?&object.Object {
	val := f(right) or {
		e.make_expr_err(tkn, err.msg())
		return none
	}

	return e.make_val_literal(val)
}

pub fn (mut e Evaluator) eval_infix_expression(operator string, left object.Object, right object.Object, tkn token.Token) ?&object.Object {
	return match operator {
		'+', '-', '*', '/' {
			e.handle_infix_node_result(object.arithmetic, operator, left, right, tkn)
		}
		'==' {
			v := unsafe {
				&left == &right
			}
			e.make_val_literal(v)
		}
		'!=' {
			v := unsafe {
				&left != &right
			}
			e.make_val_literal(v)
		}
		'>', '>=', '<', '<=' {
			e.handle_infix_node_result(object.gt_lt, operator, left, right, tkn)
		}
		else {
			e.make_expr_err(tkn, 'No handler for infix operator ${operator} for ${left.type_name()}')
			none
		}
	}
}

pub fn (mut e Evaluator) handle_infix_node_result(f object.InfixOperation, op string, left object.Object, right object.Object, tkn token.Token) ?&object.Object {
	val := f(op, left, right) or {
		e.make_expr_err(tkn, err.msg())
		return none
	}

	return e.make_val_literal(val)
}

pub fn (mut e Evaluator) eval_statement(stat ast.Statement) ?&object.Object {
	if stat is ast.ExpressionStatement {
		return e.eval(stat.value)
	}

	e.make_eval_error(stat)
	return none
}

pub fn (mut e Evaluator) eval_block(block ast.BlockStatement) ?&object.Object {
	e.make_eval_error(block)
	return none
}

pub fn (mut e Evaluator) eval_program(prog ast.Program) ?&object.Object {
	mut result := get_null_ptr()

	for stat in prog.statements {
		result = e.eval(stat) or { &evaluator.null }
	}

	return result
}

pub fn (mut e Evaluator) make_eval_error(node ast.AstNode) {
	tkn := node.get_token() or {
		dump(node)
		panic('Encountered error and could not retrieve token for it')
	}

	match node {
		ast.Program {
			err := eval_error(tkn, 'No Evaluator Function found for Program', e.source_code)
			e.eval_errors << err
		}
		ast.BlockStatement {
			err := eval_error(tkn, 'No Evaluator Function found for BlockStatement', e.source_code)
			e.eval_errors << err
		}
		ast.Statement {
			err := eval_error(tkn, 'No Evaluator Function found for ${node.type_name()}',
				e.source_code)
			e.eval_errors << err
		}
		ast.Expression {
			err := eval_error(tkn, 'No Evaluator Function found for ${node.type_name()}',
				e.source_code)
			e.eval_errors << err
		}
	}
}

pub fn (mut e Evaluator) make_convert_error(expr ast.Literal) {
	err := eval_error(expr.token, 'Could not convert ${expr.value} to ${expr.type_name()}',
		e.source_code)
	e.eval_errors << err
}

pub fn (mut e Evaluator) make_expr_err(tkn token.Token, str string) {
	err := eval_error(tkn, str, e.source_code)
	e.eval_errors << err
}

pub fn new_evaluator(src string) Evaluator {
	return Evaluator{
		source_code: src
	}
}