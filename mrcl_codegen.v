import lib {
	List,
	Names,
	Node,
	list_new,
	names_new,
}

__global (
	g_label_id = 0
)

// --------------------------------

fn get_label_id() int {
	g_label_id++
	return g_label_id
}

fn rest(xs &List) &List {
	mut newxs := list_new()
	for i in 1 .. xs.size() {
		newxs.add(xs.get(i))
	}
	return newxs
}

fn to_fn_arg_disp(names &Names, name string) int {
	mut i := names.index(name)
	if i == -1 {
		panic('function argument not found')
	}
	return i + 2
}

fn to_lvar_disp(names Names, name string) int {
	mut i := names.index(name)
	if i == -1 {
		panic('local variable not found')
	}
	return -(i + 1)
}

fn asm_prologue() {
	println('  push bp')
	println('  cp sp bp')
}

fn asm_epilogue() {
	println('  cp bp sp')
	println('  pop bp')
}

// --------------------------------

fn gen_expr_add() {
	println('  pop reg_b')
	println('  pop reg_a')
	println('  add_ab')
}

fn gen_expr_mult() {
	println('  pop reg_b')
	println('  pop reg_a')
	println('  mult_ab')
}

fn gen_expr_eq() {
	label_id := get_label_id()

	label_end := 'end_eq_${label_id}'
	label_then := 'then_${label_id}'

	println('  pop reg_b')
	println('  pop reg_a')

	println('  compare')
	println('  jump_eq ${label_then}')

	println('  cp 0 reg_a')
	println('  jump ${label_end}')

	println('label ${label_then}')
	println('  cp 1 reg_a')

	println('label ${label_end}')
}

fn gen_expr_neq() {
	label_id := get_label_id()

	label_end := 'end_neq_${label_id}'
	label_then := 'then_${label_id}'

	println('  pop reg_b')
	println('  pop reg_a')

	println('  compare')
	println('  jump_eq ${label_then}')

	println('  cp 1 reg_a')
	println('  jump ${label_end}')

	println('label ${label_then}')
	println('  cp 0 reg_a')

	println('label ${label_end}')
}

fn gen_expr_binop(fn_arg_names &Names, lvar_names &Names, xs &List) {
	op := xs.get(0).strval
	lhs := xs.get(1)
	rhs := xs.get(2)

	gen_expr(fn_arg_names, lvar_names, lhs)
	println('  push reg_a')
	gen_expr(fn_arg_names, lvar_names, rhs)
	println('  push reg_a')

	match op {
		'+' {
			gen_expr_add()
		}
		'*' {
			gen_expr_mult()
		}
		'==' {
			gen_expr_eq()
		}
		'!=' {
			gen_expr_neq()
		}
		else {
			panic('unsupported binary operator')
		}
	}
}

fn gen_expr(fn_arg_names &Names, lvar_names &Names, expr &Node) {
	match expr.get_type() {
		.int {
			n := expr.intval
			println('  cp ${n} reg_a')
		}
		.str {
			str := expr.strval
			if 0 <= lvar_names.index(str) {
				disp := to_lvar_disp(lvar_names, str)
				println('  cp [bp:${disp}] reg_a')
			} else if 0 <= fn_arg_names.index(str) {
				disp := to_fn_arg_disp(fn_arg_names, str)
				println('  cp [bp:${disp}] reg_a')
			} else {
				println('  no such function argument or local variable (${str})')
			}
		}
		.list {
			gen_expr_binop(fn_arg_names, lvar_names, expr.listval)
		}
	}
}

fn gen_set_(fn_arg_names &Names, lvar_names &Names, var_name string, expr &Node) {
	gen_expr(fn_arg_names, lvar_names, expr)

	if 0 <= lvar_names.index(var_name) {
		disp := to_lvar_disp(lvar_names, var_name)
		println('  cp reg_a [bp:${disp}]')
	} else {
		panic('unsupported')
	}
}

fn gen_set(fn_arg_names &Names, lvar_names &Names, stmt &List) {
	var_name := stmt.get(1).strval
	expr := stmt.get(2)

	gen_set_(fn_arg_names, lvar_names, var_name, expr)
}

// (call fn ...)
fn gen_funcall(fn_arg_names &Names, lvar_names &Names, funcall &List) {
	fn_name := funcall.get(0).strval
	args := rest(funcall)

	mut i := args.size() - 1
	for i >= 0 {
		arg := args.get(i)
		gen_expr(fn_arg_names, lvar_names, arg)
		println('  push reg_a')
		i--
	}

	gen_vm_comment_('call  ${fn_name}')
	println('  call ${fn_name}')
	println('  add_sp ${args.size()}')
}

fn gen_call(fn_arg_names &Names, lvar_names &Names, stmt &List) {
	funcall := rest(stmt)
	gen_funcall(fn_arg_names, lvar_names, funcall)
}

fn gen_call_set(fn_arg_names &Names, lvar_names &Names, stmt &List) {
	var_name := stmt.get(1).strval
	funcall := stmt.get(2).listval

	gen_funcall(fn_arg_names, lvar_names, funcall)

	disp := to_lvar_disp(lvar_names, var_name)
	println('  cp reg_a [bp:${disp}]')
}

fn gen_return(fn_arg_names &Names, lvar_names &Names, stmt &List) {
	expr := stmt.get(1)
	gen_expr(fn_arg_names, lvar_names, expr)
}

fn gen_while(fn_arg_names &Names, lvar_names &Names, stmt &List) {
	expr := stmt.get(1)
	stmts := stmt.get(2).listval

	label_id := get_label_id()

	label_begin := 'while_${label_id}'
	label_end := 'end_while_${label_id}'

	println('label ${label_begin}')

	gen_expr(fn_arg_names, lvar_names, expr)

	println('  cp 0 reg_b')
	println('  compare')
	println('  jump_eq ${label_end}')

	gen_stmts(fn_arg_names, lvar_names, stmts)

	println('  jump ${label_begin}')
	println('label ${label_end}')
}

fn gen_case(fn_arg_names &Names, lvar_names &Names, stmt &List) {
	when_clauses := rest(stmt)

	label_id := get_label_id()

	label_end := 'end_case_${label_id}'
	label_end_when_head := 'end_when_${label_id}'

	mut when_idx := 0
	for when_idx < when_clauses.size() {
		when_clause := when_clauses.get(when_idx).listval

		cond := when_clause.get(0)
		stmts := rest(when_clause)

		gen_expr(fn_arg_names, lvar_names, cond)

		println('  cp 0 reg_b')
		println('  compare')

		println('  jump_eq ${label_end_when_head}_${when_idx}')

		gen_stmts(fn_arg_names, lvar_names, stmts)

		println('  jump ${label_end}')

		println('label ${label_end_when_head}_${when_idx}')

		when_idx++
	}

	println('label ${label_end}')
}

fn print_vm_comment(s string) {
	for i in 0 .. s.len {
		match s[i] {
			` ` { print('~') }
			else { C.putchar(s[i]) }
		}
	}
}

fn gen_vm_comment_(comment string) {
	print('  _cmt ')
	print_vm_comment(comment)
	print('\n')
}

fn gen_vm_comment(stmt &List) {
	comment := stmt.get(1).strval
	gen_vm_comment_(comment)
}

fn gen_debug() {
	println('  _debug')
}

fn gen_stmt(fn_arg_names &Names, lvar_names &Names, stmt &List) {
	stmt_head := stmt.get(0).strval
	match stmt_head {
		'set' {
			gen_set(fn_arg_names, lvar_names, stmt)
		}
		'call' {
			gen_call(fn_arg_names, lvar_names, stmt)
		}
		'call_set' {
			gen_call_set(fn_arg_names, lvar_names, stmt)
		}
		'return' {
			gen_return(fn_arg_names, lvar_names, stmt)
		}
		'while' {
			gen_while(fn_arg_names, lvar_names, stmt)
		}
		'case' {
			gen_case(fn_arg_names, lvar_names, stmt)
		}
		'_cmt' {
			gen_vm_comment(stmt)
		}
		'_debug' {
			gen_debug()
		}
		else {
			panic('unsupported statement (${stmt})')
		}
	}
}

fn gen_stmts(fn_arg_names &Names, lvar_names &Names, stmts &List) {
	for i in 0 .. stmts.size() {
		stmt := stmts.get(i).listval
		gen_stmt(fn_arg_names, lvar_names, stmt)
	}
}

fn gen_var(fn_arg_names &Names, lvar_names &Names, stmt &List) {
	println('  add_sp -1')

	if stmt.size() == 3 {
		var_name := stmt.get(1).strval
		expr := stmt.get(2)
		gen_set_(fn_arg_names, lvar_names, var_name, expr)
	}
}

fn gen_func_def(func_def &List) {
	fn_name := func_def.get(1).strval
	fn_arg_names := names_new(func_def.get(2).listval)

	stmts := func_def.get(3).listval

	println('label ${fn_name}')
	asm_prologue()

	mut lvar_names := names_new(list_new())

	for i in 0 .. stmts.size() {
		stmt := stmts.get(i).listval
		match stmt.get(0).strval {
			'var' {
				lvar_names.add(stmt.get(1).strval)
				gen_var(fn_arg_names, lvar_names, stmt)
			}
			else {
				gen_stmt(fn_arg_names, lvar_names, stmt)
			}
		}
	}

	asm_epilogue()
	println('  ret')
}

fn gen_top_stmts(top_stmts &List) {
	for i in 1 .. top_stmts.size() {
		top_stmt := top_stmts.get(i).listval
		gen_func_def(top_stmt)
	}
}

fn gen_builtin_set_vram() {
	println('label set_vram')
	asm_prologue()
	println('  set_vram [bp:2] [bp:3]') // vram_addr value
	asm_epilogue()
	println('  ret')
}

fn gen_builtin_get_vram() {
	println('label get_vram')
	asm_prologue()
	println('  get_vram [bp:2] reg_a') // vram_addr dest
	asm_epilogue()
	println('  ret')
}

fn codegen(ast &List) {
	println('  call main')
	println('  exit')

	gen_top_stmts(ast)

	println('#>builtins')
	gen_builtin_set_vram()
	gen_builtin_get_vram()
	println('#<builtins')
}

pub fn main() {
	src := lib.read_stdin_all()
	ast := lib.json_parse(src)
	codegen(ast)
}
