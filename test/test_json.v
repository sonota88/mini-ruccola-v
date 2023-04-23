import lib

fn test_1() {
	xs := lib.list_new()
	lib.json_print(xs)
}

fn test_2() {
	mut xs := lib.list_new()
	xs.add_int(1)
	lib.json_print(xs)
}

fn test_3() {
	mut xs := lib.list_new()
	xs.add_str('fdsa')
	lib.json_print(xs)
}

fn test_4() {
	mut xs := lib.list_new()
	xs.add_int(-123)
	lib.json_print(xs)
}

fn test_5() {
	mut xs := lib.list_new()
	xs.add_int(123)
	xs.add_str('fdsa')
	lib.json_print(xs)
}

fn test_6() {
	mut xs := lib.list_new()
	xs.add_list(lib.list_new())
	lib.json_print(xs)
}

fn test_7() {
	mut xs := lib.list_new()
	xs.add_int(1)
	xs.add_str('a')

	mut xs_inner := lib.list_new()
	xs_inner.add_int(2)
	xs_inner.add_str('b')
	xs.add_list(xs_inner)

	xs.add_int(3)
	xs.add_str('c')
	lib.json_print(xs)
}

fn test_8() {
	mut xs := lib.list_new()
	xs.add_str('漢字')
	lib.json_print(xs)
}

fn main() {
	// test_1()
	// test_2()
	// test_3()
	// test_4()
	// test_5()
	// test_6()
	// test_7()
	// test_8()

	json := lib.read_stdin_all()
	xs := lib.json_parse(json)
	lib.json_print(xs)
}
