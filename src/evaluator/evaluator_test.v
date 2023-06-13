module evaluator

fn test_integer_eval() {
	tests := [TestType(IntTest{'10', 10}), IntTest{'5', 5}, IntTest{'0b10', 2},
		IntTest{'0o77', 63}, IntTest{'0xf2a', 3882}]

	run_tests(tests)
}

fn test_float_eval() {
	tests := [TestType(FloatTest{'0.2', 0.2}), FloatTest{'1.2', 1.2}]

	run_tests(tests)
}

fn test_bool_eval() {
	tests := [TestType(BoolTest{'true', true}), BoolTest{'false', false}]

	run_tests(tests)
}

fn test_prefix_operators() {
	tests := [TestType(BoolTest{'!true', false}), BoolTest{'!false', true},
		BoolTest{'!!true', true}, IntTest{'-1', -1}, IntTest{'-0xff', -255},
		FloatTest{'-3.33', -3.33}]

	run_tests(tests)
}

fn test_infix_operators() {
	tests := [TestType(IntTest{'1 + 2', 3}), IntTest{'2/1', 2},
		FloatTest{'2.23 + 2.11', 4.34}, IntTest{'0xff - 0o377', 0},
		FloatTest{'1.0/3.0', 0.3333333333333333}, IntTest{'2 * 3', 6},
		BoolTest{'1==1', true}, BoolTest{'2.1 > 2.0', true}, BoolTest{'0 >= 0', true},
		BoolTest{'5 != 1', true}, BoolTest{'2 < 1', false}, BoolTest{'3 >= 2', true},
		BoolTest{'true==true', true}, BoolTest{'false != false', false},
		BoolTest{'(1 < 2) == false', false}, BoolTest{'( ( 1 + 1 ) > 1) == true', true}]

	run_tests(tests)
}

fn test_if_expression() {
	tests := [TestType(IntTest{'if (true) {10}', 10}), IntTest{'if (false) {10} else {20}', 20},
		BoolTest{'if (2 > 1) { false } else {true}', false}]
	run_tests(tests)
}

fn test_return_statement() {
	tests := [TestType(IntTest{'return 10;', 10}), IntTest{'2; return 2 * 2;', 4},
		IntTest{'return 2; 4', 2}, IntTest{'4; return (3 * 4) / 6; 4;', 2},
		IntTest{'if(true) { if (true) {return 10;} return 1;}', 10}]
	run_tests(tests)
}

fn test_let_statement() {
	tests := [TestType(IntTest{'let a = 10; a;', 10}), IntTest{'let a = 5 * 5; a;', 25},
		IntTest{'let a = 2; let b = a; b;', 2},
		IntTest{'let a = 2; let b = a + 1; let c = a + b + 4; c;', 9}]

	run_tests(tests)
}

fn test_const_statement() {
	tests := [TestType(IntTest{'const a = 10; a;', 10}), IntTest{'const a = 5 * 5; a;', 25},
		IntTest{'const a = 2; const b = a; b;', 2},
		IntTest{'const a = 2; const b = a + 1; const c = a + b + 4; c;', 9}]

	run_tests(tests)
}

fn test_function() {
	tests := [TestType(IntTest{'const a = fn() {2}; a()', 2}),
		FloatTest{'const i = fn (x) {return x}; i(4.44)', 4.44},
		IntTest{'const a = fn(x,y) {x + y}; a(2, 3)', 5}, BoolTest{'fn(x) {x;}(true)', true},
		IntTest{'const add = fn(a,b){a + b}; add(5, add(5, 5));', 15}]
	run_tests(tests)
}

fn test_closure() {
	tests := [
		TestType(IntTest{'const newAdder = fn (x) {fn(y){x + y}}; const addTwo = newAdder(2); addTwo(2);', 4}),
	]
	run_tests(tests)
}

fn test_assign() {
	tests := [TestType(IntTest{'let a = 2; a = 3; a;', 3})]
	run_tests(tests)
}

fn test_recursion() {
	tests := [
		TestType(BoolTest{'const c = fn(x, y) {if (x > y) {return true} else {c(x + 1, y)}} c(0, 1000)', true}),
	]

	run_tests(tests)
}

fn run_tests(tests []TestType) {
	print('RUN: ')
	for i, t in tests {
		print('${i + 1}, ')
		evaluated := common(t.input)
		assert test_literal(evaluated, t.expected())
	}
	println('\nALL TESTS RUN')
}
