module evaluator

import ast
import error
import object
import strconv
import token

const null = object.new_null_value()

const o_size = sizeof(object.Object)

const allow_ostrat = ['cache_c', 'cache_v', 'direct']

fn get_null_ptr() voidptr {
	return &evaluator.null
}

[heap]
pub struct ObjectWrapper {
	ptr &object.Object = unsafe { 0 }
	obj object.Object
}

pub fn (o ObjectWrapper) get_obj() object.Object {
	// if unsafe { o.ptr == 0 } {
	// 	return o.obj
	// } else {
	// 	obj := unsafe { *o.ptr }
	// 	return obj
	// }

	return o.obj
}

[heap]
pub struct Evaluator {
	source_code string
	obj_track   bool
	strat       string
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

fn (e Evaluator) wrap_value(val object.Object) ObjectWrapper {
	return match e.strat {
		'cache_c' {
			ObjectWrapper{
				ptr: &val
			}
		}
		'cache_v' {
			ObjectWrapper{
				ptr: &val
			}
		}
		'direct' {
			ObjectWrapper{
				obj: val
			}
		}
		else {
			panic('unknown object stratergy ${e.strat}')
		}
	}
}

fn (e Evaluator) get_null_wrapped() ObjectWrapper {
	return e.wrap_value(e.null_ptr)
}

fn (mut e Evaluator) cache_object_strat_c(val object.Literal) ObjectWrapper {
	key := match val {
		bool { 'BOOL_${val}' }
		f64 { 'F64_${val}' }
		i64 { 'I64_${val}' }
	}

	if v := e.literal_map[key] {
		return ObjectWrapper{
			ptr: v
		}
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
		unsafe { free(obj) }
		e.literal_map[key] = obj_ptr

		return ObjectWrapper{
			ptr: obj_ptr
		}
	}
}

fn (mut e Evaluator) cache_object_strat_v(val object.Literal) ObjectWrapper {
	key := match val {
		bool { 'BOOL_${val}' }
		f64 { 'F64_${val}' }
		i64 { 'I64_${val}' }
	}

	if v := e.literal_map[key] {
		return ObjectWrapper{
			ptr: v
		}
	} else {
		if _unlikely_(e.obj_track) {
			e.lit_alloc_count++
		}
		obj := match val {
			bool { object.Object(object.Boolean{val}) }
			f64 { object.Object(object.Float{val}) }
			i64 { object.Object(object.Integer{val}) }
		}

		mut obj_ptr := get_null_ptr()

		obj_ptr := vcalloc(int(evaluator.o_size))
		unsafe {
			vmemcpy(obj_ptr, &obj, int(evaluator.o_size))
			e.literal_map[key] = obj_ptr // incompat warm
		}
		unsafe { free(obj) }
		return e.wrap_value(*obj_ptr)
	}
}

fn (e Evaluator) direct_object_strat(val object.Literal) ObjectWrapper {
	obj := match val {
		bool { object.Object(object.Boolean{val}) }
		f64 { object.Object(object.Float{val}) }
		i64 { object.Object(object.Integer{val}) }
	}

	// println('make ${val} ${&obj:p} ${dest_ptr:p}')

	return ObjectWrapper{
		obj: obj
	}
}

pub fn (mut e Evaluator) make_val_literal(val object.Literal) ObjectWrapper {
	return match e.strat {
		'cache_c' {
			e.cache_object_strat_c(val)
		}
		'cache_v' {
			e.cache_object_strat_v(val)
		}
		'direct' {
			e.direct_object_strat(val)
		}
		else {
			panic('unknown object stratergy ${e.strat}')
		}
	}
}

pub fn (mut e Evaluator) compare_vals(left ObjectWrapper, right ObjectWrapper) bool {
	// println('l ${&left:p} r ${&right:p}')

	match e.strat {
		'cache_c', 'cache_v' {
			return unsafe { &left.ptr == &right.ptr && &left.ptr != 0 }
		}
		'direct' {
			return left.get_obj().compare(right.get_obj()) or { false }
		}
		else {
			panic('unknown object stratergy ${e.strat}')
		}
	}
	return false
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

pub fn (mut e Evaluator) eval(node ast.AstNode, mut env object.Environment) ?ObjectWrapper {
	if _unlikely_(e.obj_track) {
		e.eval_count++
		// dump(node)
	}

	if e.scope_errors.len >= 1 {
		return none
	}

	if node is ast.Expression {
		return e.eval_expression(node, mut env) or { return none }
	} else if node is ast.Statement {
		return e.eval_statement(node, mut env) or { return none }
	} else if node is ast.BlockStatement {
		return e.eval_block(node, mut env) or { return none }
	} else if node is ast.Program {
		return e.eval_program(node, mut env) or { return none }
	} else {
		return none
	}
}

pub fn (mut e Evaluator) eval_expression(expr ast.Expression, mut env object.Environment) ?ObjectWrapper {
	if expr is ast.IntegerLiteral {
		return e.eval_integer(expr) or { return none }
	} else if expr is ast.FloatLiteral {
		return e.eval_float(expr) or { return none }
	} else if expr is ast.BooleanLiteral {
		return e.eval_bool(expr) or { return none }
	} else if expr is ast.Node {
		return e.eval_node(expr, mut env) or { return none }
	} else if expr is ast.IfExpression {
		return e.eval_if_expression(expr, mut env) or { return none }
	} else if expr is ast.Identifier {
		return e.eval_identifier(expr, mut env) or { return none }
	} else if expr is ast.BlockLiteral {
		return e.eval_block(expr.body, mut env) or { return none }
	} else if expr is ast.FunctionLiteral {
		return e.eval_function_literal(expr, mut env) or { return none }
	} else if expr is ast.CallLiteral {
		return e.eval_call_expression(expr, mut env) or { return none }
	} else {
		e.make_eval_error(expr)
		return none
	}
}

pub fn (mut e Evaluator) eval_integer(expr ast.IntegerLiteral) ?ObjectWrapper {
	val_as_int := strconv.parse_int(expr.value, 0, 64) or {
		e.make_convert_error(expr)
		return none
	}
	return e.make_val_literal(val_as_int)
}

pub fn (mut e Evaluator) eval_float(expr ast.FloatLiteral) ?ObjectWrapper {
	val_as_float := strconv.atof64(expr.value) or {
		e.make_convert_error(expr)
		return none
	}
	return e.make_val_literal(val_as_float)
}

pub fn (mut e Evaluator) eval_bool(expr ast.BooleanLiteral) ?ObjectWrapper {
	if expr.value == 'true' {
		return e.make_val_literal(true)
	} else if expr.value == 'false' {
		return e.make_val_literal(false)
	} else {
		e.make_convert_error(expr)
		return none
	}
}

pub fn (mut e Evaluator) eval_node(expr ast.Node, mut env object.Environment) ?ObjectWrapper {
	mut left := if l := expr.left {
		if lval := e.eval(l, mut env) {
			lval
		} else {
			e.get_null_wrapped()
		}
	} else {
		e.get_null_wrapped()
	}

	right := if r := expr.right {
		if rval := e.eval(r, mut env) {
			rval
		} else {
			e.get_null_wrapped()
		}
	} else {
		e.get_null_wrapped()
	}

	if right.get_obj().is_null() {
		return none
		// dump(expr)
		// panic('Right side of a node must always contain a value')
	}

	if left.get_obj().is_null() {
		return e.eval_prefix_expression(expr.operator, right, expr.token) or { return none }
	} else {
		return e.eval_infix_expression(expr.operator, left, right, expr.token) or { return none }
	}
}

pub fn (mut e Evaluator) eval_node_side(s ?ast.Expression, mut env object.Environment) ?ObjectWrapper {
	if side := s {
		return e.eval(side, mut env) or { none }
	} else {
		return none
	}
}

pub fn (mut e Evaluator) eval_prefix_expression(operator string, right ObjectWrapper, tkn token.Token) ?ObjectWrapper {
	return match operator {
		'!' {
			e.handle_prefix_node_result(object.bang, right, tkn)
		}
		'-' {
			e.handle_prefix_node_result(object.negate, right, tkn)
		}
		else {
			e.make_expr_err(tkn, 'No handler for prefix operator ${operator} for ${right.get_obj().type_name()}')
			none
		}
	}
}

pub fn (mut e Evaluator) handle_prefix_node_result(fp object.PrefixOperation, right ObjectWrapper, tkn token.Token) ?ObjectWrapper {
	val := fp(right.get_obj()) or {
		e.make_expr_err(tkn, err.msg())
		return none
	}

	return e.make_val_literal(val)
}

pub fn (mut e Evaluator) eval_infix_expression(operator string, left ObjectWrapper, right ObjectWrapper, tkn token.Token) ?ObjectWrapper {
	return match operator {
		'+', '-', '*', '/' {
			e.handle_infix_node_result(object.arithmetic, operator, left, right, tkn)
		}
		'==' {
			// println('l ${&left:p} r ${&right:p}')
			v := e.compare_vals(&left, &right)
			e.make_val_literal(v)
		}
		'!=' {
			// println('l ${&left:p} r ${&right:p}')
			v := !e.compare_vals(&left, &right)
			e.make_val_literal(v)
		}
		'>', '>=', '<', '<=' {
			e.handle_infix_node_result(object.gt_lt, operator, left, right, tkn)
		}
		else {
			e.make_expr_err(tkn, 'No handler for infix operator ${operator} for ${left.get_obj().type_name()}')
			none
		}
	}
}

pub fn (mut e Evaluator) handle_infix_node_result(f object.InfixOperation, op string, left ObjectWrapper, right ObjectWrapper, tkn token.Token) ?ObjectWrapper {
	val := f(op, left.get_obj(), right.get_obj()) or {
		e.make_expr_err(tkn, err.msg())
		return none
	}

	return e.make_val_literal(val)
}

pub fn (mut e Evaluator) eval_if_expression(expr ast.IfExpression, mut env object.Environment) ?ObjectWrapper {
	condition := (e.eval(expr.condition, mut env) or { return none })
	if condition.get_obj() is object.Boolean {
		t := e.compare_vals(condition, e.make_val_literal(true))

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
		e.make_expr_err(expr.token, 'Condition must precisely be of type boolean, not ${condition.get_obj().type_name()}')
		return none
	}
}

pub fn (mut e Evaluator) eval_identifier(expr ast.Identifier, mut env object.Environment) ?ObjectWrapper {
	val := env.get(expr.value) or {
		e.make_expr_err(expr.token, err.msg())
		return none
	}

	return e.wrap_value(val)
}

pub fn (mut e Evaluator) eval_function_literal(expr ast.FunctionLiteral, mut env object.Environment) ?ObjectWrapper {
	params := expr.parameters
	body := expr.body
	fn_lit := object.Function{
		parameters: params
		body: body
		env: env
	}
	return e.wrap_value(fn_lit)
}

pub fn (mut e Evaluator) eval_call_expression(expr ast.CallLiteral, mut env object.Environment) ?ObjectWrapper {
	function_obj := e.eval(expr.function, mut env) or { return none }

	if function_obj.get_obj() !is object.Function {
		e.make_expr_err(expr.token, 'Object is not a Function ${function_obj.get_obj().type_name()}')
		return none
	}

	function := function_obj.get_obj() as object.Function

	mut args := []ObjectWrapper{}

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
		ext_env.declare(param.value, args[i].get_obj(), false) or {
			e.make_expr_err(param.token, err.msg())
			return none
		}
	}

	f_res := e.eval(function.body, mut ext_env) or { return none }
	f_res_obj := f_res.get_obj()

	if f_res_obj is object.ReturnValue {
		return e.wrap_value(f_res_obj.value)
	}

	return f_res
}

pub fn (mut e Evaluator) eval_statement(stat ast.Statement, mut env object.Environment) ?ObjectWrapper {
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

pub fn (mut e Evaluator) eval_return_statement(stat ast.ReturnStatement, mut env object.Environment) ?ObjectWrapper {
	val := (e.eval(stat.value, mut env) or { return none }).get_obj()
	return e.wrap_value(object.ReturnValue{
		value: &val
	})
}

pub fn (mut e Evaluator) eval_var_statement(stat ast.VarStatement, mut env object.Environment) ?ObjectWrapper {
	mutable := stat.token.literal == 'let'
	name := stat.name.value
	val := e.eval(stat.value, mut env) or { return none }

	env.declare(name, val.get_obj(), mutable) or {
		e.make_expr_err(stat.token, err.msg())
		return none
	}

	return e.get_null_wrapped()
}

pub fn (mut e Evaluator) eval_assign_statement(stat ast.AssignStatement, mut env object.Environment) ?ObjectWrapper {
	name := stat.name.value
	val := e.eval(stat.value, mut env) or { return none }

	env.set(name, val.get_obj()) or {
		e.make_expr_err(stat.token, err.msg())
		return none
	}

	return e.get_null_wrapped()
}

pub fn (mut e Evaluator) eval_block(block ast.BlockStatement, mut env object.Environment) ?ObjectWrapper {
	mut result := e.get_null_wrapped()

	for stat in block.statements {
		result = e.eval(stat, mut env) or { e.get_null_wrapped() }

		if result.get_obj() is object.ReturnValue {
			return result
		}
	}

	return result
}

pub fn (mut e Evaluator) eval_program(prog ast.Program, mut env object.Environment) ?ObjectWrapper {
	mut result := e.get_null_wrapped()
	e.scope_errors.clear()

	for stat in prog.statements {
		if e.eval_errors.len >= 1 {
			return none
		}
		result = e.eval(stat, mut env) or { e.get_null_wrapped() }
		result_obj := result.get_obj()
		if result_obj is object.ReturnValue {
			return e.wrap_value(result_obj.value)
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

pub fn new_evaluator(src string, track bool, strat string) Evaluator {
	println('new EVAL')

	if strat !in evaluator.allow_ostrat {
		panic('Object stratergy ${strat} is invalid. Allowed stratergies: ${evaluator.allow_ostrat.join(', ')}')
	}

	mut e := Evaluator{
		source_code: src
		true_ptr: get_null_ptr()
		false_ptr: get_null_ptr()
		null_ptr: get_null_ptr()
		obj_track: track
		strat: strat
	}

	tp := e.make_val_literal(true).get_obj()
	e.true_ptr = &tp
	fp := e.make_val_literal(false).get_obj()
	e.false_ptr = &fp

	return e
}
