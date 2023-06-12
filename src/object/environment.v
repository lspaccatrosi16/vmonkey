module object

[heap]
struct VarInt {
	mutable bool
mut:
	val &Object
}

[heap]
pub struct Environment {
mut:
	store map[string]VarInt
	outer &Environment
}

pub fn (e Environment) get(name string) !&Object {
	if v := e.store[name] {
		return v.val
	} else if unsafe { e.outer != 0 } {
		return e.outer.get(name)
	}

	return error('value ${name} is not defined')
}

pub fn (mut e Environment) declare(name string, val &Object, mutable bool) !&Object {
	if name in e.store {
		return error('cannot redeclare var ${name}')
	}

	unsafe { // Evaluator is [heap] so safe

		e.store[name] = VarInt{mutable, val}
		return val
	}
}

pub fn (mut e Environment) set(name string, val &Object) !&Object {
	if name in e.store {
		if !e.store[name].mutable {
			return error('cannot assign to constant var ${name}')
		} else {
			unsafe {
				e.store[name].val = val
				return val
			}
		}
	} else if unsafe { e.outer != 0 } {
		return e.outer.set(name, val)
	}
	return error('cannot assign to unitialised var ${name}')
}
