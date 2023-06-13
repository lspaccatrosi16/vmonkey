module main

import repl
import file
import cli
import os

fn main() {
	mut app := cli.Command{
		name: 'vmonkey'
		description: 'vmonkey interpreter / REPL',
		usage: '<file>'
		execute: run
	}

	app.add_flag(cli.Flag{
		name: 'track'
		flag: .bool
	})

	app.setup()
	app.parse(os.args)

	// mut track := false

	// for arg in os.args {
	// 	if arg == '--track' {
	// 		track = true
	// 	}
	// }
}

fn run(cmd cli.Command) ! {
	track := cmd.flags.get_bool('track') or { false }
	
	if cmd.args.len >= 1 {
		file.run(cmd.args[0], track)
	} else {
		run_repl(track)
	}
	
}

fn run_repl(track bool) {
	println('vmonkey REPL')
	if track {
		println('object tracking enabled')
	}

	repl.start(track)
}