module evaluator

fn test_integer_eval() {
	tests := [IntTest{'10', 10}, IntTest{'5', 5}, IntTest{'0b10', 2},
		IntTest{'0o77', 63}, IntTest{'0xf2a', 3882}]

	for t in tests {
		evaluated := common(t.input)
		assert test_literal(evaluated, t.expected)
	}
}

fn test_float_eval() {
	tests := [FloatTest{'0.2', 0.2}, FloatTest{'1.2', 1.2}]

	for t in tests {
		evaluated := common(t.input)
		assert test_literal(evaluated, t.expected)
	}
}

fn test_bool_eval() {
	tests := [BoolTest{'true', true}, BoolTest{'false', false}]

	for t in tests {
		evaluated := common(t.input)
		assert test_literal(evaluated, t.expected)
	}
}

fn test_prefix_operators() {
	tests := [TestType(BoolTest{'!true', false}), BoolTest{'!false', true},
		BoolTest{'!!true', true}, IntTest{'-1', -1}, IntTest{'-0xff', -255},
		FloatTest{'-3.33', -3.33}]

	for t in tests {
		evaluated := common(t.input)
		assert test_literal(evaluated, t.expected())
	}
}

fn test_infix_operators() {
	tests := [TestType(IntTest{'1 + 2', 3}), IntTest{'2/1', 2},
		FloatTest{'2.23 + 2.11', 4.34}, IntTest{'0xff - 0o377', 0},
		FloatTest{'1.0/3.0', 0.3333333333333333}, IntTest{'2 * 3', 6},
		BoolTest{'1==1', true}, BoolTest{'2.1 > 2.0', true}, BoolTest{'0 >= 0', true},
		BoolTest{'5 != 1', true}, BoolTest{'2 < 1', false}, BoolTest{'3 >= 2', true},
		BoolTest{'true==true', true}, BoolTest{'false != false', false},
		BoolTest{'(1 < 2) == false', false}, BoolTest{'( ( 1 + 1 ) > 1) == true', true}]

	for t in tests {
		evaluated := common(t.input)
		assert test_literal(evaluated, t.expected())
	}
}
