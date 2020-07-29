class_name RTree

var root: RTreeNode
var max_children: int
var nodes: Dictionary

func _init(_max_children: int = 9):
	self.root = RTreeNode.new()
	self.max_children = _max_children
	self.nodes = {}

func find_overlapping(rect: Rect2, include_borders: bool = false) -> Array:
	var overlapping: = []
	var stack: = [root]
	while stack.size() > 0:
		var node: RTreeNode = stack.pop_back()

		for child in node.children:
			if child.mbr.intersects(rect, include_borders):
				if child.is_leaf():
					overlapping.append(child.id)
				else:
					stack.append(child)

	return overlapping

func update(id: int, mbr: Rect2) -> void:
	assert(nodes.has(id))
	nodes[id].update_mbr(mbr)

func insert(id: int, mbr: Rect2, node: RTreeNode = self.root) -> void:
	if node.is_leaf():
		assert(!self.nodes.has(id))

		var parent: = node if node == root else node.parent
		var new_node: = RTreeNode.new(id, mbr)
		parent.insert(new_node)
		self.nodes[id] = new_node

		if parent.children.size() > max_children:
			_handle_overflow(parent)
	else:
		var n = _choose_subtree(mbr, node)
		insert(id, mbr, n)

func _handle_overflow(node: RTreeNode) -> void:
	var split: = _split_node(node)
	var new_nodes: = [RTreeNode.new(), RTreeNode.new()]
	new_nodes[0].insert_all(node.children.slice(0, split))
	new_nodes[1].insert_all(node.children.slice(split + 1, node.children.size() - 1))

	if node == root:
		var new_root: = RTreeNode.new()
		new_root.insert_all(new_nodes)

		root = new_root
	else:
		var parent: = node.parent
		parent.remove(node)
		parent.insert_all(new_nodes)

		if parent.children.size() > max_children:
			_handle_overflow(parent)

func _choose_subtree(mbr: Rect2, node: RTreeNode = self.root) -> RTreeNode:
	var min_increase: = INF
	var best_node: RTreeNode

	for child in node.children:
		var new_mbr: Rect2 = child.mbr.merge(mbr)
		var increase: = _perimeter(new_mbr) - _perimeter(child.mbr)
		if increase < min_increase:
			min_increase = increase
			best_node = child

	return best_node

func _split_node(node: RTreeNode) -> int:
	var splits: = []
	node.children.sort_custom(self, "_sort_rect_left")
	splits.append(_sorted_nodes_best_split(node.children))
	node.children.sort_custom(self, "_sort_rect_right")
	splits.append(_sorted_nodes_best_split(node.children))
	node.children.sort_custom(self, "_sort_rect_top")
	splits.append(_sorted_nodes_best_split(node.children))
	node.children.sort_custom(self, "_sort_rect_bottom")
	splits.append(_sorted_nodes_best_split(node.children))

	var best_perimeter_sum: = INF
	var best_split: = 0

	for split in splits:
		var perimeter_sum: = _split_perimeter_sum(node.children, split)
		if perimeter_sum < best_perimeter_sum:
			best_perimeter_sum = perimeter_sum
			best_split = split

	return best_split

func _sorted_nodes_best_split(nodes: Array) -> int:
	var best_perimeter_sum: = INF
	var best_split_idx: = 0

	var n: = ceil(0.4 * max_children)
	var node_range: = range(n, nodes.size() - n + 1)
	for i in node_range:
		var perimeter_sum: = _split_perimeter_sum(nodes, i)
		if perimeter_sum < best_perimeter_sum:
			best_perimeter_sum = perimeter_sum
			best_split_idx = i

	return best_split_idx

func _split_perimeter_sum(nodes: Array, split: int) -> float:
	var rect1: Rect2 = nodes[0].mbr
	var rect2: Rect2 = nodes[split + 1].mbr
	for i in range(1, split + 1):
		rect1 = rect1.merge(nodes[i].mbr)
	for i in range(split + 2, nodes.size()):
		rect2 = rect2.merge(nodes[i].mbr)

	return _perimeter(rect1) + _perimeter(rect2)

func _perimeter(mbr: Rect2) -> float:
	return (mbr.size.x + mbr.size.y) * 2

func _sort_rect_left(a: Rect2, b: Rect2) -> float:
	return a.position.x - b.position.x

func _sort_rect_right(a: Rect2, b: Rect2) -> float:
	return a.end.x - b.end.x

func _sort_rect_top(a: Rect2, b: Rect2) -> float:
	return a.position.y - b.position.y

func _sort_rect_bottom(a: Rect2, b: Rect2) -> float:
	return a.end.y - b.end.y

class RTreeNode:
	var children: Array
	var parent: RTreeNode
	var mbr # Minimum bounding rectangle that contains all children

	var id
	var base_mbr

	func _init(_id = null, _base_mbr = null):
		self.children = []
		self.parent = null
		self.id = _id
		self.base_mbr = _base_mbr
		self.mbr = _base_mbr

	func is_leaf() -> bool:
		return self.children.size() == 0

	func insert(node: RTreeNode) -> void:
		assert(self.id == null)

		self.children.append(node)
		node.parent = self

		_update_mbr_insert(node.mbr)

	func insert_all(nodes: Array) -> void:
		assert(self.id == null)

		for node in nodes:
			insert(node)

	func remove(node: RTreeNode) -> void:
		assert(self.id == null)

		var idx = self.children.find(node)
		assert(idx != -1)
		children.remove(idx)

		_update_mbr()

	func update_mbr(new_mbr: Rect2):
		assert(self.id != null)
		self.base_mbr = new_mbr
		_update_mbr()

	func _update_mbr_insert(new_mbr: Rect2) -> void:
		if self.mbr && self.mbr.encloses(new_mbr):
			return

		if self.mbr:
			self.mbr = self.mbr.merge(new_mbr)
		else:
			self.mbr = new_mbr

		if self.parent:
			self.parent._update_mbr_insert(new_mbr)

	func _update_mbr() -> void:
		if self.base_mbr:
			self.mbr = self.base_mbr
		elif self.children.size() > 0:
			self.mbr = self.children[0].mbr
		else:
			self.mbr = null

		for child in self.children:
			self.mbr = self.mbr.merge(child.mbr)

		if self.parent:
			self.parent._update_mbr()

