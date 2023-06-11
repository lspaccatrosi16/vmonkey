module object

pub struct Boolean {
pub mut:
	value bool
}

pub fn (b Boolean) str() string {
	return '${b.value}'
}

pub fn (b Boolean) bang() bool {
	return !b.value
}
