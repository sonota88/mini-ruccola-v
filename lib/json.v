module lib

fn print_indent(lv int) {
	for _ in 0 .. lv {
		print('  ')
	}
}

fn json_print_node(node &Node, lv int) {
	print_indent(lv + 1)
	match node.get_type() {
		.int {
			n := node.intval
			print(n)
		}
		.str {
			s := node.strval
			print('"')
			print(s)
			print('"')
		}
		.list {
			json_print_list(node.listval, lv + 1)
		}
	}
}

fn json_print_list(xs &List, lv int) {
	println('[')

	for i in 0 .. xs.size() {
		if i > 0 {
			print(',')
			print('\n')
		}
		node := xs.get(i)
		json_print_node(node, lv)
	}

	print('\n')
	print_indent(lv)
	print(']')
}

pub fn json_print(xs &List) {
	json_print_list(xs, 0)
}

// --------------------------------

fn match_int(s string) int {
	return non_int_index(s)
}

fn json_parse_list(json string) (&List, int) {
	mut xs := list_new()

	mut pos := 1 // skip first char '['
	for pos < json.len {
		rest := json[pos..]

		if rest[0] == `]` {
			pos += 1
			break
		} else if rest[0] == ` ` {
			pos += 1
		} else if rest[0] == `,` {
			pos += 1
		} else if rest[0] == `\n` {
			pos += 1
		} else if 0 < match_int(rest) {
			size := match_int(rest)
			s := rest[0..size]
			xs.add_int(s.int())
			pos += size
		} else if rest[0] == `"` { // "
			size := match_str(rest)
			s := rest[1..1 + size]
			xs.add_str(s)
			pos += size + 2
		} else if rest[0] == `[` {
			inner_xs, size := json_parse_list(rest)
			xs.add_list(inner_xs)
			pos += size
		} else {
			eprintln(pos)
			eprintln('>>' + rest + '<<')
			panic('unexpected pattern')
		}
	}

	return xs, pos
}

pub fn json_parse(json string) &List {
	xs, _ := json_parse_list(json)
	return xs
}
