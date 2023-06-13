module object

pub struct Null {
}

pub fn (n Null) str() string {
	return 'null'
}

pub struct ReturnValue {
pub:
	value &Object
}

pub type Object = Boolean | Float | Function | Integer | Null | ReturnValue
pub type Literal = bool | f64 | i64

pub type PrefixOperation = fn (right Object) !Literal

pub type InfixOperation = fn (op string, left Object, right Object) !Literal

pub fn (o Object) string() string {
	if o is Integer {
		return o.str()
	} else if o is Float {
		return o.str()
	} else if o is Boolean {
		return o.str()
	} else if o is Null {
		return o.str()
	} else if o is Function {
		return o.str()
	}

	return 'Unknown object type'
}

pub fn (o Object) is_null() bool {
	return o is Null
}
pub fn (o Object) compare(r Object) !bool {
	if o.type_name() != r.type_name() {
		return error(make_mismatch_error_str(o, r))
	}

	return match o {
		Integer {o.value == (r as Integer).value}
		Float {o.value == (r as Float).value}
		Boolean {o.value == (r as Boolean).value}
		else {o.string() == r.string()}
	}
}

pub fn bang(o Object) !Literal {
	if o is Boolean {
		return o.bang()
	} else {
		return error(make_incompat_error_str('!', o))
	}
}

pub fn negate(o Object) !Literal {
	if o is Float {
		return o.negate()
	} else if o is Integer {
		return o.negate()
	} else {
		return error(make_incompat_error_str('-', o))
	}
}


pub fn arithmetic(op string, l Object, r Object) !Literal {
	if l.type_name() != r.type_name() {
		return error(make_mismatch_error_str(l, r))
	}

	if l is Float {
		return l.arithmetic(op, r as Float)
	} else if l is Integer {
		return l.arithmetic(op, r as Integer)
	} else {
		return error(make_incompat_error_str(op, l))
	}
}

pub fn gt_lt(op string, l Object, r Object) !Literal {
	if l.type_name() != r.type_name() {
		return error(make_mismatch_error_str(l, r))
	}
	if l is Float {
		return l.gt_lt(op, r as Float)
	} else if l is Integer {
		return l.gt_lt(op, r as Integer)
	} else {
		return error(make_incompat_error_str(op, l))
	}
}
