module lib

// --------------------------------

pub enum NodeType as u8 {
	int
	str
	list
}

pub struct Node {
pub mut:
	ty      NodeType [required]
	intval  int
	strval  string
	listval List
}

fn node_new(ty NodeType) &Node {
	return &Node{
		ty: ty // undef
		intval: 0
		strval: ''
		listval: &List{[]}
	}
}

pub fn node_new_int(n int) &Node {
	mut node := node_new(NodeType.int)
	node.intval = n
	return node
}

pub fn node_new_str(s string) &Node {
	mut node := node_new(NodeType.str)
	node.strval = s
	return node
}

pub fn node_new_list(xs &List) &Node {
	mut node := node_new(NodeType.list)
	node.listval = xs
	return node
}

pub fn (self Node) get_type() NodeType {
	return self.ty
}

// --------------------------------

pub struct List {
pub mut:
	nodes []Node [required]
}

pub fn list_new() &List {
	return &List{[]}
}

pub fn (self List) size() int {
	return self.nodes.len
}

pub fn (self List) get(i int) &Node {
	return &self.nodes[i]
}

pub fn (mut xs List) add(node &Node) {
	xs.nodes << node
}

pub fn (mut xs List) add_int(val int) {
	mut node := node_new(NodeType.int)
	node.intval = val
	xs.add(node)
}

pub fn (mut xs List) add_str(val string) {
	mut node := node_new(NodeType.str)
	node.strval = val
	xs.add(node)
}

pub fn (mut xs List) add_list(val &List) {
	mut node := node_new(NodeType.list)
	node.listval = val
	xs.add(node)
}

pub fn (mut self List) add_all(xs &List) {
	mut i := 0
	for i < xs.size() {
		self.add(xs.get(i))
		i++
	}
}

// --------------------------------

pub enum TokenKind as u8 {
	int
	str
	sym
	ident
	kw
}

pub fn to_kind(s string) TokenKind {
	return match s {
		'int' {
			TokenKind.int
		}
		'str' {
			TokenKind.str
		}
		'sym' {
			TokenKind.sym
		}
		'ident' {
			TokenKind.ident
		}
		'kw' {
			TokenKind.kw
		}
		else {
			panic('unsupported token kind string')
			exit(1)
		}
	}
}

pub fn to_str(kind TokenKind) string {
	return match kind {
		.int { 'int' }
		.str { 'str' }
		.sym { 'sym' }
		.ident { 'ident' }
		.kw { 'kw' }
	}
}

pub struct Token {
pub mut:
	kind   TokenKind [required]
	val    string
	lineno int
}

// --------------------------------

pub struct Names {
pub mut:
	xs List
}

pub fn names_new(xs List) &Names {
	return &Names{xs}
}

pub fn (mut self Names) add(name string) {
	self.xs.add_str(name)
}

pub fn (self Names) index(name string) int {
	for i in 0 .. self.xs.size() {
		if self.xs.get(i).strval == name {
			return i
		}
	}

	return -1
}
