module object

pub fn new_null_value() Object {
	null := Null{}
	return Object(null)
}

fn make_incompat_error_str(op string, obj Object) string {
	return 'Cannot apply ${op} to ${obj.type_name()}'
}

fn make_mismatch_error_str(l Object, r Object) string {
	return 'LHS ${l.type_name()} does not match RHS ${r.type_name()}'
}
