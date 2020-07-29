extends "res://addons/gut/test.gd"

func test_find_generated_rectangles():
	var num_search_rects = 100
	var num_test_rects = 100

	var rng = RandomNumberGenerator.new()
	rng.set_seed(3) # Set seed to get predictable results

	var tree = RTree.new()

	# Generate random rectangles to be searched for
	var data_rects = []
	for i in num_test_rects:
		var rect = generate_rect(rng)
		data_rects.append(rect)
		tree.insert(i, rect)

	for i in num_search_rects:
		var expected = []

		# Generate random rectangle to search with
		var search_rect = generate_rect(rng)

		for j in num_test_rects:
			if search_rect.intersects(data_rects[j]):
				expected.append(j)

		var found = tree.find_overlapping(search_rect)

		assert_eq(expected.size(), found.size())
		for id in found:
			assert_has(expected, id)

func test_update_generated_rectangles():
	var num_full_updates = 100
	var num_test_rects = 1000

	var rng = RandomNumberGenerator.new()
	rng.set_seed(3) # Set seed to get predictable results

	var tree = RTree.new()

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

		var found = tree.find_overlapping(search_rect)

		assert_eq(expected.size(), found.size())
		for id in found:
			assert_has(expected, id)

func generate_rect(rng):
	return Rect2(
		rng.randf_range(-100, 100),
		rng.randf_range(-100, 100),
		rng.randf_range(5, 10),
		rng.randf_range(5, 10)
	)
