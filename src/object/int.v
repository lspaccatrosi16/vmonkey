module object

pub struct Integer {
pub:
	value i64
}

pub fn (i Integer) str() string {
	return '${i.value}'
}

pub fn (i Integer) negate() i64 {
	return -i.value
}

pub fn (i Integer) arithmetic(op string, right Integer) i64 {
	return match op {
		'-' { i.value - right.value }
		'+' { i.value + right.value }
		'*' { i.value * right.value }
		'/' { i.value / right.value }
		else { 0 }
	}
}

pub fn (i Integer) gt_lt(op string, right Integer) bool {
	return match op {
		'>' { i.value > right.value }
		'<' { i.value < right.value }
		'>=' { i.value >= right.value }
		'<=' { i.value <= right.value }
		else { false }
	}
}
