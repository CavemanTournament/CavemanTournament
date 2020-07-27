class_name DungeonGenerator

var num_cells: int # Number of initially generated cells

# Cell size is generated from a normally distributed rng
var cell_size_mean: int
var cell_size_deviation: int

var min_room_size: int # Turn all cells at least this big into rooms
var corridor_width: int
var cell_height: int

var rng: RandomNumberGenerator
var cells: Dictionary

var next_cell_id = 0

func _init(
	_num_cells,
	_cell_size_mean,
	_cell_size_deviation,
	_min_room_size,
	_corridor_width,
	_cell_height
):
	num_cells = _num_cells
	cell_size_mean = _cell_size_mean
	cell_size_deviation = _cell_size_deviation
	min_room_size = _min_room_size
	corridor_width = _corridor_width
	cell_height = _cell_height

	rng = RandomNumberGenerator.new()
	rng.randomize()


func generate():
	cells = {}
	next_cell_id = 0

	# Generate randomly sized and positioned cells, and separate them
	for i in range(num_cells):
		var cell = generate_random_cell()
		separate_cell(cell)
		cells[cell.id] = cell

		# Set cell type to room if it's big enough
		if cell.rect.size.x >= min_room_size:
			cell.set_type(DungeonVariables.CELL_TYPE_ROOM)

	# Get a graph of linked rooms
	var room_graph = get_room_graph()

	var link_paths = []

	for cell1_id in room_graph.nodes:
		for cell2_id in room_graph.edges[cell1_id]:
			link_paths.append(get_cell_link_path(cell1_id, cell2_id))

	# Add siderooms between linked rooms
	for path in link_paths:
		create_siderooms(path)

	# Add corridors between linked rooms
	for path in link_paths:
		var corridors = create_corridors(path, corridor_width)
		#for corridor in corridors:
			#cells[corridor.id] = corridor

	# Return rooms, siderooms and corridors
	var assigned_cells = []
	for cell in cells.values():
		if cell.type != DungeonVariables.CELL_TYPE_NONE:
			assigned_cells.append(cell)

	return assigned_cells

func get_unused_cell_id():
	var id = next_cell_id
	next_cell_id += 1
	return id

func create_siderooms(_path):
	for cell in cells.values():
		var is_typeless = cell.type == DungeonVariables.CELL_TYPE_NONE
		if is_typeless && path_overlaps_cell(_path, cell, corridor_width):
			cell.set_type(DungeonVariables.CELL_TYPE_SIDEROOM)

func create_corridors(_path, _width):
	var prev_corridor = null

	for point_idx in range(_path.size() - 1):
		var p1 = _path[point_idx]
		var p2 = _path[point_idx + 1]

		assert(p1.x == p2.x || p1.z == p2.z) # Straight lines only

		var pos = p1

		while true:
			# As we follow the path, we want to add corridors with certain width
			# at every position. We do this by following the middle of the path,
			# and adding corridors on both sides of the path. `width_range` is
			# how many corridors should be added on both sides.
			var width_range = (_width - 1) / 2

			if width_range == 0:
				# When `width_range` is 0, we only consider the current position
				# for the corridor. We're not adding more to the sides.

				var overlaps = false

				# Check if current position is occupied by other cells
				for cell in cells.values():
					var is_typeless = cell.type == DungeonVariables.CELL_TYPE_NONE
					if !is_typeless && point_overlaps_cell(pos, cell):
						overlaps = true
						break

				# Add corridor cell at current position if the position is unoccupied
				if !overlaps:
					var corridor = DungeonCell.new(get_unused_cell_id())
					corridor.set_size(Vector3(1, cell_height, 1))
					corridor.set_position(pos)
					corridor.set_type(DungeonVariables.CELL_TYPE_CORRIDOR)

					var corridor_expanded = false

					if prev_corridor:
						var rect_eq = Util.rect2_component_equality(prev_corridor.rect, corridor.rect)
						if prev_corridor && p1.x != p2.x && rect_eq.y:
							prev_corridor.set_rect(prev_corridor.rect.merge(corridor.rect))
							corridor_expanded = true
						elif prev_corridor && p1.z != p2.z && rect_eq.x:
							prev_corridor.set_rect(prev_corridor.rect.merge(corridor.rect))
							corridor_expanded = true

					if !corridor_expanded:
						prev_corridor = corridor
						cells[corridor.id] = corridor
			else:
				# We want a corridor with extra width. We figure out the extents
				# of the corridor, and then create a path that follows the corridor
				# piece from one wall to the other. We then create one tile wide
				# corridors along this path.

				var delta_min = -floor(width_range)
				var delta_max = ceil(width_range)

				# If the path goes horizontally, then the corridor-width-path
				# should go vertically, and vice versa
				var x_multi = 0 if p1.x != p2.x else 1
				var z_multi = 0 if p1.z != p2.z else 1

				var p = [
					pos + Vector3(delta_min * x_multi, 0, delta_min * z_multi),
					pos + Vector3(delta_max * x_multi, 0, delta_max * z_multi)
				]

				var corridor_expanded = false
				var corridor = create_corridors(p, 1)

				if corridor && prev_corridor:
					var rect_eq = Util.rect2_component_equality(prev_corridor.rect, corridor.rect)

					if p1.x != p2.x && rect_eq.y:
						prev_corridor.set_rect(prev_corridor.rect.merge(corridor.rect))
						cells.erase(corridor.id)
						corridor_expanded = true
					elif p1.z != p2.z && rect_eq.x:
						prev_corridor.set_rect(prev_corridor.rect.merge(corridor.rect))
						cells.erase(corridor.id)
						corridor_expanded = true

				if !corridor_expanded:
					prev_corridor = corridor

			if pos == p2:
				break

			pos = pos.move_toward(p2, 1)

	return prev_corridor

func generate_random_cell():
	var cell = DungeonCell.new(get_unused_cell_id())

	var cell_size_base = rng.randfn(cell_size_mean, cell_size_deviation)
	var cell_size_ratio = rng.randf_range(0.5, 1.5)
	var cell_width = round(cell_size_base)
	var cell_length = round(cell_size_base * cell_size_ratio)

	# Making all cell dimensions odd makes positioning them in a grid easier
	cell_width += 1 - fmod(cell_width, 2)
	cell_length += 1 - fmod(cell_length, 2)

	cell.set_size(Vector3(cell_width, cell_height, cell_length))

	var cell_pos = Util.random_point_in_circle(40).round()
	cell.move(Vector3(cell_pos.x, 0, cell_pos.y))

	return cell

func separate_cell(cell):
	var cell_placement_dir = Vector3(rand_range(-1, 1), 0, rand_range(-1, 1))

	while true:
		var overlapping_cell = get_overlapping_cell(cell)
		if !overlapping_cell:
			break

		separate_cells(cell, overlapping_cell, cell_placement_dir)

func delaunay_triangulate_cells(_cells: Array):
	var room_points = PoolVector2Array()
	for cell in _cells:
		room_points.append(Vector2(cell.transform.origin.x, cell.transform.origin.z))

	var triangulated_indices = Geometry.triangulate_delaunay_2d(room_points)

	var triangulated_cells = []
	for idx in triangulated_indices:
		triangulated_cells.append(_cells[idx])

	return triangulated_cells

func get_room_graph():
	var rooms = []
	var room_graph = Graph.new()

	for cell in cells.values():
		if cell.type == DungeonVariables.CELL_TYPE_ROOM:
			rooms.append(cell)
			room_graph.add_node(cell.id)

	var triangulated_rooms = delaunay_triangulate_cells(rooms)

	var i = 0
	while i < triangulated_rooms.size():
		var room0 = triangulated_rooms[i]
		var room1 = triangulated_rooms[i + 1]
		var room2 = triangulated_rooms[i + 2]
		var w01 = room0.distance_to(room1)
		var w12 = room1.distance_to(room2)
		var w20 = room2.distance_to(room0)
		room_graph.add_edge(room0.id, room1.id, w01)
		room_graph.add_edge(room1.id, room2.id, w12)
		room_graph.add_edge(room2.id, room0.id, w20)
		i += 3

	var mst = room_graph.mst()

	i = 0
	while i < triangulated_rooms.size():
		if !mst.edges[triangulated_rooms[i].id].has(triangulated_rooms[i + 1].id):
			if randf() < 0.2:
				mst.add_edge(triangulated_rooms[i].id, triangulated_rooms[i + 1].id)
		i += 3

	return mst

func get_cell_link_path(_cell1_id, _cell2_id):
	var path = []

	var cell1 = cells[_cell1_id]
	var cell2 = cells[_cell2_id]

	var x1 = max(cell1.rect.position.x, cell2.rect.position.x)
	var x2 = min(cell1.rect.end.x, cell2.rect.end.x)
	var overlap_x = x2 - x1

	var z1 = max(cell1.rect.position.y, cell2.rect.position.y)
	var z2 = min(cell1.rect.end.y, cell2.rect.end.y)
	var overlap_z = z2 - z1

	if overlap_x >= 5:
		if cell1.rect.intersects(cell2.rect, true):
			return path

		var mid_x = round((x1 + x2) / 2)
		path.append(Vector3(mid_x, 0, ceil(z1 + 1)))
		path.append(Vector3(mid_x, 0, floor(z2 - 1)))
	elif overlap_z >= 5:
		if cell1.rect.intersects(cell2.rect, true):
			return path

		var mid_z = round((z1 + z2) / 2)
		path.append(Vector3(ceil(x1 + 1), 0, mid_z))
		path.append(Vector3(floor(x2 - 1), 0, mid_z))
	else:
		var cell1_x = floor(cell1.rect.end.x - 1) if cell1.rect.position.x < cell2.rect.position.x else ceil(cell1.rect.position.x + 1)
		var cell1_z = floor(cell1.rect.end.y - 1) if cell1.rect.position.y < cell2.rect.position.y else ceil(cell1.rect.position.y + 1)
		var cell2_x = floor(cell2.rect.end.x - 1) if cell2.rect.position.x < cell1.rect.position.x else ceil(cell2.rect.position.x + 1)
		var cell2_z = floor(cell2.rect.end.y - 1) if cell2.rect.position.y < cell1.rect.position.y else ceil(cell2.rect.position.y + 1)

		var temp_path1 = [
			Vector3(cell1.transform.origin.x, 0, cell1_z),
			Vector3(cell1.transform.origin.x, 0, cell2.transform.origin.z),
			Vector3(cell2_x, 0, cell2.transform.origin.z)
		]

		var temp_path2 = [
			Vector3(cell1_x, 0, cell1.transform.origin.z),
			Vector3(cell2.transform.origin.x, 0, cell1.transform.origin.z),
			Vector3(cell2.transform.origin.x, 0, cell2_z)
		]

		var temp_path1_overlaps = 0
		var temp_path2_overlaps = 0

		# We can't always avoid overlaps, but we want to at least minimize them
		for cell in cells.values():
			if cell.type == DungeonVariables.CELL_TYPE_ROOM:
				if path_overlaps_cell(temp_path1, cell):
					temp_path1_overlaps += 1
				if path_overlaps_cell(temp_path2, cell):
					temp_path2_overlaps += 1

		path = temp_path1 if temp_path1_overlaps < temp_path2_overlaps else temp_path2

	return path

func separate_cells(_cell1, _cell2, _dir):
	var angle = _dir.angle_to(Vector3.RIGHT)

	var cell1_corner = Vector3.ZERO
	var cell2_corner = Vector3.ZERO

	if _dir.x <= 0:
		cell1_corner.x = _cell1.rect.end.x
		cell2_corner.x = _cell2.rect.position.x
	else:
		cell1_corner.x = _cell1.rect.position.x
		cell2_corner.x = _cell2.rect.end.x

	if _dir.z <= 0:
		cell1_corner.z = _cell1.rect.end.y
		cell2_corner.z = _cell2.rect.position.y
	else:
		cell1_corner.z = _cell1.rect.position.y
		cell2_corner.z = _cell2.rect.end.y

	var dist_horizontal = cell2_corner.x - cell1_corner.x
	var dist_vertical = cell2_corner.z - cell1_corner.z

	var delta1 = Vector3(tan(angle) * dist_vertical, 0, dist_vertical).round()
	var delta2 = Vector3(dist_horizontal, 0, tan(angle - PI / 2) * dist_horizontal).round()

	if delta1.length() < delta2.length():
		_cell1.move(delta1)
	else:
		_cell1.move(delta2)

func get_overlapping_cell(_cell1):
	for cell2 in cells.values():
		if _cell1.id != cell2.id && _cell1.rect.intersects(cell2.rect):
			return cell2
	return null

func path_overlaps_cell(_path, _cell, _line_width = 1):
	for i in range(_path.size() - 1):
		var path_p1 = Vector2(_path[i].x, _path[i].z)
		var path_p2 = Vector2(_path[i + 1].x, _path[i + 1].z)
		return Util.segment_intersects_rect2(path_p1, path_p2, _cell.rect, _line_width)

	return false

func point_overlaps_cell(_point: Vector3, _cell: DungeonCell):
	return _cell.rect.has_point(Vector2(_point.x, _point.z))
