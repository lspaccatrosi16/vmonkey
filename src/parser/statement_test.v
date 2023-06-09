module parser

import ast

struct VarTest {
	name     string
	val      string
	var_type string
}

struct RetTest {
	val      string
	var_type string
}

fn test_var() {
	input := '
	let x = 5;
	const y = 10.0;
	let foobar = 0xffff;
	'

	statements := common(input, 3)

	exp_idents := [VarTest{
		name: 'x'
		val: '5'
		var_type: 'IntegerLiteral'
	}, VarTest{
		name: 'y'
		val: '10.0'
		var_type: 'FloatLiteral'
	}, VarTest{
		name: 'foobar'
		val: '0xffff'
		var_type: 'IntegerLiteral'
	}]

	for i, tt in exp_idents {
		stmt := statements[i]
		assert var_statement_test(stmt, tt.name, tt.val, tt.var_type), 'TEST ${i + 1} FAILED'
	}
}

fn var_statement_test(s ast.Statement, name string, val string, t string) bool {
	if s is ast.VarStatement {
		assert s.name.literal() == name, 'Expected name ${name}, Got: ${s.name.literal()}'
		assert test_expression(s.value, LiteralSpec{val, t})
		return true
	} else {
		assert false, 'Not let statement: ${s.type_name()}'
		return false
	}
}

fn test_return() {
	input := '
	return 5;
	return 10;
	return 69.420;
	'
	statements := common(input, 3)

	exp_vals := [RetTest{
		val: '5'
		var_type: 'IntegerLiteral'
	}, RetTest{
		val: '10'
		var_type: 'IntegerLiteral'
	}, RetTest{
		val: '69.420'
		var_type: 'FloatLiteral'
	}]

	for i, tt in exp_vals {
		stmt := statements[i]
		assert ret_statement_test(stmt, tt.val, tt.var_type)
	}
}

fn ret_statement_test(s ast.Statement, val string, t string) bool {
	if s is ast.ReturnStatement {
		assert test_expression(s.value, LiteralSpec{val, t})
		return true
	} else {
		assert false, 'Not return statement: ${s.type_name()}'
		return false
	}
}
