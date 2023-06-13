module evaluator

import ast
import error
import object
import strconv
import token

const null = object.new_null_value()

const o_size = sizeof(object.Object)

fn get_null_ptr() voidptr {
	return &evaluator.null
}

[heap]
pub struct Evaluator {
	source_code string
	obj_track   bool
mut:
	literal_map map[string]&object.Object
	true_ptr    &object.Object
	false_ptr   &object.Object
	null_ptr    &object.Object
pub mut:
	eval_errors     []error.BaseError
	scope_errors    []error.BaseError
	lit_alloc_count i64
	eval_count      i64
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
		if _unlikely_(e.obj_track) {
			e.lit_alloc_count++
		}
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

pub fn (mut e Evaluator) eval(node ast.AstNode, mut env object.Environment) ?&object.Object {
	if _unlikely_(e.obj_track) {
		e.eval_count++
		// dump(node)
	}

	mut ret := e.null_ptr

	if e.scope_errors.len >= 1 {
		return none
	}

	if node is ast.Expression {
		ret = e.eval_expression(node, mut env) or { return none }
	} else if node is ast.Statement {
		ret = e.eval_statement(node, mut env) or { return none }
	} else if node is ast.BlockStatement {
		ret = e.eval_block(node, mut env) or { return none }
	} else if node is ast.Program {
		ret = e.eval_program(node, mut env) or { return none }
	} else {
		return none
	}

	return ret
}

pub fn (mut e Evaluator) eval_expression(expr ast.Expression, mut env object.Environment) ?&object.Object {
	mut ret := e.null_ptr
	if expr is ast.IntegerLiteral {
		ret = e.eval_integer(expr) or { return none }
	} else if expr is ast.FloatLiteral {
		ret = e.eval_float(expr) or { return none }
	} else if expr is ast.BooleanLiteral {
		ret = e.eval_bool(expr) or { return none }
	} else if expr is ast.Node {
		ret = e.eval_node(expr, mut env) or { return none }
	} else if expr is ast.IfExpression {
		ret = e.eval_if_expression(expr, mut env) or { return none }
	} else if expr is ast.Identifier {
		ret = e.eval_identifier(expr, mut env) or { return none }
	} else if expr is ast.BlockLiteral {
		ret = e.eval_block(expr.body, mut env) or { return none }
	} else if expr is ast.FunctionLiteral {
		ret = e.eval_function_literal(expr, mut env) or { return none }
	} else if expr is ast.CallLiteral {
		ret = e.eval_call_expression(expr, mut env) or { return none }
	} else {
		e.make_eval_error(expr)
		return none
	}
	return ret
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
	mut ret := e.null_ptr
	if expr.value == 'true' {
		ret = e.true_ptr
	} else if expr.value == 'false' {
		ret = e.false_ptr
	} else {
		e.make_convert_error(expr)
		return none
	}

	return ret
}

pub fn (mut e Evaluator) eval_node(expr ast.Node, mut env object.Environment) ?&object.Object {
	mut left := if l := expr.left {
		if lval := e.eval(l, mut env) {
			lval
		} else {
			e.null_ptr
		}
	} else {
		e.null_ptr
	}

	right := if r := expr.right {
		if rval := e.eval(r, mut env) {
			rval
		} else {
			e.null_ptr
		}
	} else {
		e.null_ptr
	}

	if right.is_null() {
		return none
		// dump(expr)
		// panic('Right side of a node must always contain a value')
	}

	if left.is_null() {
		return e.eval_prefix_expression(expr.operator, right, expr.token) or { return none }
	} else {
		return e.eval_infix_expression(expr.operator, left, right, expr.token) or { return none }
	}
}

pub fn (mut e Evaluator) eval_node_side(s ?ast.Expression, mut env object.Environment) ?&object.Object {
	if side := s {
		return e.eval(side, mut env) or { none }
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

pub fn (mut e Evaluator) eval_if_expression(expr ast.IfExpression, mut env object.Environment) ?&object.Object {
	mut condition := e.null_ptr
	condition = e.eval(expr.condition, mut env) or { return none }
	if condition is object.Boolean {
		t := unsafe {
			&condition == e.true_ptr
		}

		if t {
			conseq := e.eval(expr.consequence, mut env) or { return none }

			return conseq
		} else {
			if con := expr.alternative {
				return e.eval(con, mut env)
			} else {
				return none
			}
		}
	} else {
		e.make_expr_err(expr.token, 'Condition must precisely be of type boolean, not ${condition.type_name()}')
		return none
	}
}

pub fn (mut e Evaluator) eval_identifier(expr ast.Identifier, mut env object.Environment) ?&object.Object {
	val := env.get(expr.value) or {
		e.make_expr_err(expr.token, err.msg())
		return none
	}

	return val
}

pub fn (mut e Evaluator) eval_function_literal(expr ast.FunctionLiteral, mut env object.Environment) ?&object.Object {
	params := expr.parameters
	body := expr.body
	fn_lit := object.Function{
		parameters: params
		body: body
		env: env
	}
	return &fn_lit
}

pub fn (mut e Evaluator) eval_call_expression(expr ast.CallLiteral, mut env object.Environment) ?&object.Object {
	function_obj := e.eval(expr.function, mut env) or { return none }

	if function_obj !is object.Function {
		e.make_expr_err(expr.token, 'Object is not a Function ${function_obj.type_name()}')
		return none
	}

	function := function_obj as object.Function

	mut args := []&object.Object{}

	for arg in expr.arguments {
		v := e.eval(arg, mut env) or { return none }
		args << v
	}

	if function.parameters.len != args.len {
		e.make_expr_err(expr.token, 'Expecting ${function.parameters.len} arguments but got ${args.len}')
		return none
	}

	mut ext_env := object.new_enclosed_environment(function.env)

	for i, param in function.parameters {
		ext_env.declare(param.value, args[i], false) or {
			e.make_expr_err(param.token, err.msg())
			return none
		}
	}

	f_res := e.eval(function.body, mut ext_env) or { return none }

	if f_res is object.ReturnValue {
		return f_res.value
	}

	return f_res
}

pub fn (mut e Evaluator) eval_statement(stat ast.Statement, mut env object.Environment) ?&object.Object {
	if stat is ast.ExpressionStatement {
		return e.eval(stat.value, mut env)
	} else if stat is ast.ReturnStatement {
		return e.eval_return_statement(stat, mut env)
	} else if stat is ast.VarStatement {
		return e.eval_var_statement(stat, mut env)
	} else if stat is ast.AssignStatement {
		return e.eval_assign_statement(stat, mut env)
	}

	e.make_eval_error(stat)
	return none
}

pub fn (mut e Evaluator) eval_return_statement(stat ast.ReturnStatement, mut env object.Environment) ?&object.Object {
	val := e.eval(stat.value, mut env) or { return none }
	return &object.ReturnValue{
		value: val
	}
}

pub fn (mut e Evaluator) eval_var_statement(stat ast.VarStatement, mut env object.Environment) ?&object.Object {
	mutable := stat.token.literal == 'let'
	name := stat.name.value
	val := e.eval(stat.value, mut env) or { return none }

	env.declare(name, val, mutable) or {
		e.make_expr_err(stat.token, err.msg())
		return none
	}

	return e.null_ptr
}

pub fn (mut e Evaluator) eval_assign_statement(stat ast.AssignStatement, mut env object.Environment) ?&object.Object {
	name := stat.name.value
	val := e.eval(stat.value, mut env) or { return none }

	env.set(name, val) or {
		e.make_expr_err(stat.token, err.msg())
		return none
	}

	return e.null_ptr
}

pub fn (mut e Evaluator) eval_block(block ast.BlockStatement, mut env object.Environment) ?&object.Object {
	mut result := e.null_ptr

	for stat in block.statements {
		result = e.eval(stat, mut env) or { e.null_ptr }

		if result is object.ReturnValue {
			return result
		}
	}

	return result
}

pub fn (mut e Evaluator) eval_program(prog ast.Program, mut env object.Environment) ?&object.Object {
	mut result := e.null_ptr
	e.scope_errors.clear()

	for stat in prog.statements {
		if e.eval_errors.len >= 1 {
			return none
		}
		result = e.eval(stat, mut env) or { e.null_ptr }
		if mut result is object.ReturnValue {
			return result.value
		}
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
			e.add_to_err(err)
		}
		ast.BlockStatement {
			err := eval_error(tkn, 'No Evaluator Function found for BlockStatement', e.source_code)
			e.add_to_err(err)
		}
		ast.Statement {
			err := eval_error(tkn, 'No Evaluator Function found for ${node.type_name()}',
				e.source_code)
			e.add_to_err(err)
		}
		ast.Expression {
			err := eval_error(tkn, 'No Evaluator Function found for ${node.type_name()}',
				e.source_code)
			e.add_to_err(err)
		}
	}
}

pub fn (mut e Evaluator) make_convert_error(expr ast.Literal) {
	err := eval_error(expr.token, 'Could not convert ${expr.value} to ${expr.type_name()}',
		e.source_code)
	e.add_to_err(err)
}

pub fn (mut e Evaluator) make_expr_err(tkn token.Token, str string) {
	err := eval_error(tkn, str, e.source_code)
	e.add_to_err(err)
}

pub fn (mut e Evaluator) add_to_err(err error.BaseError) {
	e.eval_errors << err
	e.scope_errors << err
}

pub fn new_evaluator(src string, track bool) Evaluator {
	println('new EVAL')
	mut e := Evaluator{
		source_code: src
		true_ptr: get_null_ptr()
		false_ptr: get_null_ptr()
		null_ptr: get_null_ptr()
		obj_track: track
	}
	e.true_ptr = e.make_val_literal(true)
	e.false_ptr = e.make_val_literal(false)

	return e
}
