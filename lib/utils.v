module lib

pub fn panic(message string) {
	eprint('PANIC ')
	eprintln(message)
	exit(1)
}

pub fn read_stdin_all() string {
	mut cs := []byte{}
	for {
		c := C.getchar()
		if c == -1 {
			break
		}
		cs << c
	}
	return cs.bytestr()
}

pub fn indexof(s string, c u8) int {
	for i in 0 .. s.len {
		if s[i] == c {
			return i
		}
	}

	return -1
}

fn is_int_char(c u8) bool {
	return match c {
		`0`...`9`, `-` { true }
		else { false }
	}
}

pub fn non_int_index(str string) int {
	for i in 0 .. str.len {
		if !is_int_char(str[i]) {
			return i
		}
	}

	return str.len
}

pub fn match_str(s string) int {
	return indexof(s[1..], `"`) // "
}
