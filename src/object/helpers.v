module object

pub fn new_null_value() Object {
	null := Null{}
	return Object(null)
}

pub fn new_environment() &Environment {
	return &Environment{
		outer: 0
	}
}

pub fn new_enclosed_environment(outer &Environment) &Environment {
	dump(gc_memory_use())
	// dump(gc_heap_usage())
	return &Environment{
		outer: outer
	}
}

fn make_incompat_error_str(op string, obj Object) string {
	return 'Cannot apply ${op} to ${obj.type_name()}'
}

fn make_mismatch_error_str(l Object, r Object) string {
	return 'LHS ${l.type_name()} does not match RHS ${r.type_name()}'
}
