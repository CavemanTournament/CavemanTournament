extends "res://addons/gut/test.gd"

# Set seed to get predictable results
var gen_seed: = 123456789
var tree_max_children: = 9

func test_find_generated_rectangles():
	var num_search_rects = 100
	var num_test_rects = 100

	var rng = RandomNumberGenerator.new()
	rng.set_seed(gen_seed)

	var tree = RTree.new(tree_max_children)

	# Generate random rectangles to be searched for
	var data_rects = []
	for i in num_test_rects:
		var rect = generate_rect(rng)
		data_rects.append(rect)
		tree.insert(i, rect)

	_assert_tree_height(tree.root, _get_tree_height(tree))
	_assert_tree_balance(tree.root, 9)

	for i in num_search_rects:
		var expected = []

		# Generate random rectangle to search with
		var search_rect = generate_rect(rng)

		for j in num_test_rects:
			if search_rect.intersects(data_rects[j]):
				expected.append(j)

		var found = tree.query_rect2(search_rect)

		assert_eq(expected.size(), found.size())
		for id in found:
			assert_has(expected, id)

func test_update_generated_rectangles():
	var num_full_updates = 100
	var num_test_rects = 1000

	var rng = RandomNumberGenerator.new()
	rng.set_seed(gen_seed)

	var tree = RTree.new(tree_max_children)

	# Generate random rectangles to be searched for
	var data_rects = []
	for i in num_test_rects:
		var rect = generate_rect(rng)
		data_rects.append(rect)
		tree.insert(i, rect)

	for i in num_full_updates:
		for id in num_test_rects:
			var rect = generate_rect(rng)
			data_rects[id] = rect
			tree.update(id, rect)

		var expected = []

		# Generate random rectangle to search with
		var search_rect = generate_rect(rng)

		for j in num_test_rects:
			if search_rect.intersects(data_rects[j]):
				expected.append(j)

		var found = tree.query_rect2(search_rect)

		assert_eq(expected.size(), found.size())
		for id in found:
			assert_has(expected, id)

func test_remove_generated_rectangles():
	var num_search_rects = 100
	var num_test_rects = 1000
	var num_remove_rects = 200

	var rng = RandomNumberGenerator.new()
	rng.set_seed(gen_seed)

	var tree = RTree.new(tree_max_children)

	# Generate random rectangles to be searched for
	var data_rects = {}
	for i in num_test_rects:
		var rect = generate_rect(rng)
		data_rects[i] = rect
		tree.insert(i, rect)

	for i in num_remove_rects:
		data_rects.erase(i)
		tree.remove(i)

	_assert_tree_height(tree.root, _get_tree_height(tree))
	_assert_tree_balance(tree.root, 9)

	for i in num_search_rects:
		var expected = []

		# Generate random rectangle to search with
		var search_rect = generate_rect(rng)

		for j in range(num_remove_rects, num_test_rects):
			if search_rect.intersects(data_rects[j]):
				expected.append(j)

		var found = tree.query_rect2(search_rect)

		assert_eq(expected.size(), found.size())
		for id in found:
			assert_has(expected, id)

func _get_tree_height(tree: RTree) -> int:
	var node = tree.root
	var height: = 0

	while !node.is_leaf():
		node = node.children[0]
		height += 1

	return height

func _assert_tree_height(node, expected_height: int, current_height: int = 0):
	if node.is_leaf():
		assert_eq(expected_height, current_height)
	else:
		for child in node.children:
			_assert_tree_height(child, expected_height, current_height + 1)

func _assert_tree_balance(node, max_children: int):
	var is_root = node.parent == null && node.children.size() == 0 && node.id == null

	if !node.is_leaf():
		assert_true(node.children.size() <= max_children)
		assert_true(is_root || node.children.size() >= ceil(0.4 * max_children))
	else:
		for child in node.children:
			_assert_tree_balance(child, max_children)

func generate_rect(rng):
	return Rect2(
		rng.randf_range(-100, 100),
		rng.randf_range(-100, 100),
		rng.randf_range(5, 10),
		rng.randf_range(5, 10)
	)
