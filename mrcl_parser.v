import lib {
	List,
	Node,
	Token,
	TokenKind,
	list_new,
	node_new_int,
	node_new_list,
	node_new_str,
}

__global (
	g_tokens = []Token{}
	g_pos    int
)

fn read_line(s string) string {
	i := lib.indexof(s, `\n`)
	if 0 <= i {
		return s[0..i + 1]
	} else {
		return ''
	}
}

fn read_tokens(src string) []Token {
	mut tokens := []Token{}

	mut rest := src
	for {
		line := read_line(rest)
		if line.len == 0 {
			break
		}
		xs := lib.json_parse(line)
		lineno := xs.get(0).intval
		kind_str := xs.get(1).strval
		val := xs.get(2).strval
		tokens << Token{
			kind: lib.to_kind(kind_str)
			val: val
			lineno: lineno
		}

		rest = rest[line.len..]
	}

	return tokens
}

// --------------------------------

fn peek(offset int) &Token {
	return &g_tokens[g_pos + offset]
}

fn assert_val(expected string, actual string) {
	match actual {
		expected {
			// ok
		}
		else {
			panic('assertion failed: expected (${expected}) actual (${actual})')
		}
	}
}

fn consume_kw(expected string) {
	if peek(0).kind != TokenKind.kw {
		eprintln('token (${peek(0)})')
		panic('should be kw')
	}
	assert_val(expected, peek(0).val)

	g_pos++
}

fn consume_sym(expected string) {
	if peek(0).kind != TokenKind.sym {
		eprintln('token (${peek(0)})')
		panic('should be sym')
	}
	assert_val(expected, peek(0).val)

	g_pos++
}

// --------------------------------

fn parse_arg() &Node {
	match peek(0).kind {
		.int {
			node := node_new_int(peek(0).val.int())
			g_pos++
			return node
		}
		.ident {
			node := node_new_str(peek(0).val)
			g_pos++
			return node
		}
		else {
			eprintln(peek(0))
			panic('unsupported')
		}
	}
}

fn parse_args() &List {
	mut args := list_new()

	if peek(0).val == ')' {
		return args
	}

	args.add(parse_arg())

	for peek(0).val == ',' {
		consume_sym(',')
		args.add(parse_arg())
	}

	return args
}

fn parse_expr_factor() &Node {
	match peek(0).kind {
		.sym {
			consume_sym('(')
			expr := parse_expr()
			consume_sym(')')
			return expr
		}
		.int {
			n := peek(0).val.int()
			g_pos++
			expr := node_new_int(n)
			return expr
		}
		.ident {
			str := peek(0).val
			g_pos++
			expr := node_new_str(str)
			return expr
		}
		else {
			panic('unexpected token kind')
		}
	}
}

fn is_binop(t &Token) bool {
	return match t.val {
		'+', '*', '==', '!=' { true }
		else { false }
	}
}

fn parse_expr() &Node {
	mut expr := parse_expr_factor()

	for is_binop(peek(0)) {
		op := peek(0).val
		g_pos++
		rhs := parse_expr_factor()
		mut xs := list_new()
		xs.add_str(op)
		xs.add(expr)
		xs.add(rhs)
		expr = node_new_list(xs)
	}

	return expr
}

fn parse_set() &List {
	consume_kw('set')

	var_name := peek(0).val
	g_pos++

	consume_sym('=')
	expr := parse_expr()
	consume_sym(';')

	mut stmt := list_new()
	stmt.add_str('set')
	stmt.add_str(var_name)
	stmt.add(expr)
	return stmt
}

fn parse_funcall() &List {
	fn_name := peek(0).val
	g_pos++

	consume_sym('(')
	args := parse_args()
	consume_sym(')')

	mut funcall := list_new()
	funcall.add_str(fn_name)
	funcall.add_all(args)
	return funcall
}

fn parse_call() &List {
	consume_kw('call')

	funcall := parse_funcall()

	consume_sym(';')

	mut stmt := list_new()
	stmt.add_str('call')
	stmt.add_all(funcall)
	return stmt
}

fn parse_call_set() &List {
	consume_kw('call_set')

	var_name := peek(0).val
	g_pos++

	consume_sym('=')
	funcall := parse_funcall()
	consume_sym(';')

	mut stmt := list_new()
	stmt.add_str('call_set')
	stmt.add_str(var_name)
	stmt.add_list(funcall)
	return stmt
}

fn parse_return() &List {
	consume_kw('return')

	expr := parse_expr()

	consume_sym(';')

	mut stmt := list_new()
	stmt.add_str('return')
	stmt.add(expr)
	return stmt
}

fn parse_while() &List {
	consume_kw('while')

	consume_sym('(')
	expr := parse_expr()
	consume_sym(')')

	consume_sym('{')
	stmts := parse_stmts()
	consume_sym('}')

	mut stmt := list_new()
	stmt.add_str('while')
	stmt.add(expr)
	stmt.add_list(stmts)
	return stmt
}

fn parse_when_clause() &List {
	consume_kw('when')

	consume_sym('(')
	expr := parse_expr()
	consume_sym(')')

	consume_sym('{')
	stmts := parse_stmts()
	consume_sym('}')

	mut stmt := list_new()
	stmt.add(expr)
	stmt.add_all(stmts)
	return stmt
}

fn parse_case() &List {
	consume_kw('case')

	mut stmt := list_new()
	stmt.add_str('case')

	for peek(0).val == 'when' {
		when_clause := parse_when_clause()
		stmt.add_list(when_clause)
	}

	return stmt
}

fn parse_vm_comment() &List {
	consume_kw('_cmt')
	consume_sym('(')

	cmt := peek(0).val
	g_pos++

	consume_sym(')')
	consume_sym(';')

	mut stmt := list_new()
	stmt.add_str('_cmt')
	stmt.add_str(cmt)
	return stmt
}

fn parse_debug() &List {
	consume_kw('_debug')
	consume_sym('(')
	consume_sym(')')
	consume_sym(';')

	mut stmt := list_new()
	stmt.add_str('_debug')
	return stmt
}

fn parse_stmt() &List {
	t := peek(0)
	return match t.val {
		'set' {
			parse_set()
		}
		'call' {
			parse_call()
		}
		'call_set' {
			parse_call_set()
		}
		'return' {
			parse_return()
		}
		'while' {
			parse_while()
		}
		'case' {
			parse_case()
		}
		'_cmt' {
			parse_vm_comment()
		}
		'_debug' {
			parse_debug()
		}
		else {
			panic('unsupported statement (${t})')
		}
	}
}

fn parse_stmts() &List {
	mut stmts := list_new()

	for peek(0).val != '}' {
		stmts.add_list(parse_stmt())
	}

	return stmts
}

fn parse_var() &List {
	consume_kw('var')

	mut stmt := list_new()
	stmt.add_str('var')

	var_name := peek(0).val
	g_pos++
	stmt.add_str(var_name)

	match peek(0).val {
		'=' {
			consume_sym('=')
			stmt.add(parse_expr())
			consume_sym(';')
		}
		';' {
			consume_sym(';')
		}
		else {
			panic('unsupported token (${peek(0)})')
		}
	}

	return stmt
}

fn parse_func_def() &List {
	consume_kw('func')
	t := peek(0) // fn name
	g_pos++
	fn_name := t.val

	consume_sym('(')
	args := parse_args()
	consume_sym(')')
	consume_sym('{')

	mut stmts := list_new()
	for peek(0).val != '}' {
		if peek(0).val == 'var' {
			stmts.add_list(parse_var())
		} else {
			stmts.add_list(parse_stmt())
		}
	}

	consume_sym('}')

	mut func_def := list_new()
	func_def.add_str('func')
	func_def.add_str(fn_name)
	func_def.add_list(args)
	func_def.add_list(stmts)
	return func_def
}

fn parse() &List {
	g_pos = 0
	mut ast := list_new()
	ast.add_str('top_stmts')
	for g_pos < g_tokens.len {
		func_def := parse_func_def()
		ast.add_list(func_def)
	}
	return ast
}

pub fn main() {
	src := lib.read_stdin_all()
	g_tokens = read_tokens(src)
	// eprintln(g_tokens)

	ast := parse()
	lib.json_print(ast)
}
