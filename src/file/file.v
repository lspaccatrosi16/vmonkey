module file

import os
import runner
import object

pub fn run(path string, track bool) {
	if !path.ends_with('.vmk') {
		panic('File is not a vmonkey file')
	}
	contents := os.read_file(path) or {
		panic(err.msg())
	}


	if contents.trim('\n') == '' {
		panic('cannot have empty file')
	}

	mut env := object.new_environment()


	runner.run(contents, track, mut env)



}