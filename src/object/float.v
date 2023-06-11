module object

pub struct Float {
pub:
	value f64
}

pub fn (f Float) str() string {
	return '${f.value}'
}

pub fn (f Float) negate() f64 {
	return -f.value
}

pub fn (f Float) arithmetic(op string, right Float) f64 {
	return match op {
		'+' { f.value + right.value }
		'-' { f.value - right.value }
		'*' { f.value * right.value }
		'/' { f.value / right.value }
		else { 0.0 }
	}
}

pub fn (f Float) gt_lt(op string, right Float) bool {
	return match op {
		'>' { f.value > right.value }
		'<' { f.value < right.value }
		'>=' { f.value >= right.value }
		'<=' { f.value <= right.value }
		else { false }
	}
}
