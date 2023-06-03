import lib {
	TokenKind,
}

fn print_token(kind TokenKind, val string, lineno int) {
	kind_str := lib.to_str(kind)
	println('[${lineno}, "${kind_str}", "${val}"]')
}

fn is_ident_char(c u8) bool {
	return match c {
		`a`...`z`, `0`...`9`, `_` { true }
		else { false }
	}
}

fn non_ident_index(str string) int {
	for i in 0 .. str.len {
		if !is_ident_char(str[i]) {
			return i
		}
	}

	return str.len
}

fn match_ident(rest string) int {
	return non_ident_index(rest)
}

fn match_sym(rest string) int {
	return match rest[0] {
		`=` {
			if rest[1] == `=` {
				2
			} else {
				1
			}
		}
		`!` {
			if rest[1] == `=` {
				2
			} else {
				0
			}
		}
		`(`, `)`, `{`, `}`, `;`, `,`, `+`, `*` {
			1
		}
		else {
			0
		}
	}
}

fn match_int(rest string) int {
	return lib.non_int_index(rest)
}

fn match_comment(rest string) int {
	if rest.len < 2 {
		return 0
	}
	if rest[0..2] != '//' {
		return 0
	}
	return lib.indexof(rest, `\n`)
}

fn is_kw(s string) bool {
	return match s {
		'func', 'var', 'set', 'call', 'call_set', 'return', 'while', 'case', 'when', '_cmt',
		'_debug' {
			true
		}
		else {
			false
		}
	}
}

fn main() {
	src := lib.read_stdin_all()
	mut lineno := 1

	mut pos := 0
	for pos < src.len {
		rest := src[pos..]

		if rest[0] == `\n` {
			lineno++
			pos++
		} else if rest[0] == `"` { // "
			size := lib.match_str(rest)
			s := rest[1..1 + size]
			print_token(TokenKind.str, s, lineno)
			pos += size + 2
		} else if 0 < match_comment(rest) {
			size := match_comment(rest)
			pos += size
		} else if 0 < match_int(rest) {
			size := match_int(rest)
			val := rest[0..size]
			print_token(TokenKind.int, val, lineno)
			pos += size
		} else if 0 < match_ident(rest) {
			size := match_ident(rest)
			val := rest[0..size]
			mut kind := TokenKind.ident
			if is_kw(val) {
				kind = TokenKind.kw
			}
			print_token(kind, val, lineno)
			pos += size
		} else if 0 < match_sym(rest) {
			size := match_sym(rest)
			val := rest[0..size]
			print_token(TokenKind.sym, val, lineno)
			pos += size
		} else if rest[0] == ` ` {
			pos++
		} else {
			eprintln('unexpected pattern')
			eprintln(pos)
			eprintln('>>' + rest + '<<')
			exit(1)
		}
	}
}
