module evaluator

import object
import lexer
import parser

struct IntTest {
	input    string
	expected i64
}

struct FloatTest {
	input    string
	expected f64
}

struct BoolTest {
	input    string
	expected bool
}

type TestType = BoolTest | FloatTest | IntTest
type LiteralTestable = bool | f64 | i64

fn (t TestType) expected() LiteralTestable {
	if t is BoolTest {
		return t.expected
	} else if t is FloatTest {
		return t.expected
	} else if t is IntTest {
		return t.expected
	}
	return LiteralTestable(0.0)
}

fn common(input string) &object.Object {
	mut l := lexer.new_lexer(input)
	tkns := l.run_lexer()

	for err in l.lex_errors {
		println(err.str())
	}

	assert l.lex_errors.len == 0
	mut p := parser.new_parser(tkns, input)

	program := p.parse_program()

	for err in p.parse_errors {
		println(err.str())
	}

	assert p.parse_errors.len == 0

	mut eval := new_evaluator(input)

	obj := eval.eval(program)

	for err in eval.eval_errors {
		println(err.str())
	}

	assert eval.eval_errors.len == 0

	return obj
}

fn assert_val_match[T](exp T, actual T) {
	assert exp == actual, 'Expected ${exp}, got ${actual}'
}

fn test_integer_object(obj object.Object, exp i64) bool {
	if obj is object.Integer {
		assert_val_match(exp, obj.value)
		return true
	} else {
		assert false, 'object is not integer: ${obj.type_name()}'
		return false
	}
}

fn test_float_object(obj object.Object, exp f64) bool {
	if obj is object.Float {
		assert_val_match(exp, obj.value)
		return true
	} else {
		assert false, 'object is not float: ${obj.type_name()}'
		return false
	}
}

fn test_boolean_object(obj object.Object, exp bool) bool {
	if obj is object.Boolean {
		assert_val_match(exp, obj.value)
		return true
	} else {
		assert false, 'object is not bool: ${obj.type_name()}'
		return false
	}
}

fn test_literal(obj object.Object, exp LiteralTestable) bool {
	return match exp {
		bool { test_boolean_object(obj, exp) }
		f64 { test_float_object(obj, exp) }
		i64 { test_integer_object(obj, exp) }
	}
}
