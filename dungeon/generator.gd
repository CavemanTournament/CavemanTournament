class_name DungeonGenerator

var num_cells: int # Number of initially generated cells

# Cell size is generated from a normally distributed rng
var cell_size_mean: int
var cell_size_deviation: int

var cell_position_range: int # Range of possible initial cell positions

var min_room_size: int # Turn all cells at least this big into rooms
var corridor_width: int
var cell_height: int

var fast_separation: bool # Use separation with better performance but worse quality

var rng: RandomNumberGenerator

var dungeon: Dungeon

func _init(
	_num_cells: int,
	_cell_size_mean: int,
	_cell_size_deviation: int,
	_cell_position_range: int,
	_min_room_size: int,
	_corridor_width: int,
	_cell_height: int,
	_fast_separation: bool
):
	self.num_cells = _num_cells
	self.cell_size_mean = _cell_size_mean
	self.cell_size_deviation = _cell_size_deviation
	self.cell_position_range = _cell_position_range
	self.min_room_size = _min_room_size
	self.corridor_width = _corridor_width
	self.cell_height = _cell_height
	self.fast_separation = _fast_separation

	self.dungeon = Dungeon.new()

	self.rng = RandomNumberGenerator.new()
	self.rng.randomize()

func generate(debug_separation: = false) -> Dungeon:
	# Generate randomly sized and positioned cells, and separate them
	for _i in range(num_cells):
		var cell: = generate_random_cell()

		# Set cell type to room if it's big enough
		if cell.rect.size.x >= min_room_size || debug_separation:
			cell.set_type(DungeonVariables.CellType.ROOM)

	if self.fast_separation:
		separate_cells_fast()
	else:
		separate_cells()

	remove_overlapping_cells()

	if !debug_separation:
		# Get a graph of linked rooms
		var room_graph: = get_room_graph()
		var link_paths: = []

		for cell1_id in room_graph.nodes:
			for cell2_id in room_graph.edges[cell1_id]:
				link_paths.append(get_cell_link_path(cell1_id, cell2_id))

		# Add siderooms between linked rooms
		for path in link_paths:
			create_siderooms(path)

		# Add corridors between linked rooms
		for path in link_paths:
			create_corridors(path, corridor_width)

	return self.dungeon

func remove_overlapping_cells():
	var overlaps = true
	while overlaps:
		overlaps = false
		for cell1 in self.dungeon.get_cells():
			if self.dungeon.cells_overlapping_cell(cell1.id).size() > 1:
				self.dungeon.remove_cell(cell1.id)
				overlaps = true
				break

func create_siderooms(path: Array):
	for id in self.dungeon.cells_overlapping_path(path, self.corridor_width):
		var cell: = self.dungeon.get_cell(id)
		if cell.is_typeless():
			cell.set_type(DungeonVariables.CellType.SIDEROOM)

func create_corridors(path: Array, path_width: int) -> DungeonCell:
	var prev_corridor: DungeonCell

	for point_idx in range(path.size() - 1):
		var p1: Vector3 = path[point_idx]
		var p2: Vector3 = path[point_idx + 1]

		assert(p1.x == p2.x || p1.z == p2.z) # Straight lines only

		if p1 == p2:
			# No need to add corridors when the segment has zero length
			continue

		var pos = p1

		while true:
			# As we follow the path, we want to add corridors with certain width
			# at every position. We do this by following the middle of the path,
			# and adding corridors on both sides of the path. `width_range` is
			# how many corridors should be added on both sides.
			var width_range: float = (path_width - 1) / 2

			if width_range == 0:
				# When `width_range` is 0, we only consider the current position
				# for the corridor. We're not adding more to the sides.

				var overlapping = false
				for id in self.dungeon.cells_overlapping_point(pos):
					if !self.dungeon.get_cell(id).is_typeless():
						overlapping = true
						break

				# Add corridor cell at current position if the position is unoccupied
				if !overlapping:
					var size = Vector3(1, cell_height, 1)
					var rect = Rect2(pos.x - (size.x / 2), pos.z - (size.z / 2), size.x, size.z)

					# Merge new corridor with previous one if possible to reduce
					# resulting game objects
					if !prev_corridor || !self.dungeon.merge_cell(prev_corridor.id, rect):
						var corridor = self.dungeon.add_cell(pos, size)
						corridor.set_type(DungeonVariables.CellType.CORRIDOR)
						prev_corridor = corridor
			else:
				# We want a corridor with extra width. We figure out the extents
				# of the corridor, and then create a path that follows the corridor
				# piece from one wall to the other. We then create one tile wide
				# corridors along this path.

				var delta_min: = -floor(width_range)
				var delta_max: = ceil(width_range)

				# If the path goes horizontally, then the corridor-width-path
				# should go vertically, and vice versa
				var x_multi: = 0 if p1.x != p2.x else 1
				var z_multi: = 0 if p1.z != p2.z else 1

				var corridor_width_path: = [
					pos + Vector3(delta_min * x_multi, 0, delta_min * z_multi),
					pos + Vector3(delta_max * x_multi, 0, delta_max * z_multi)
				]

				var corridor: = create_corridors(corridor_width_path, 1)

				# Merge new wide corridor with previous one if possible to
				# reduce resulting game objects
				if prev_corridor && corridor && self.dungeon.merge_cell(prev_corridor.id, corridor.rect):
					self.dungeon.remove_cell(corridor.id)
				else:
					prev_corridor = corridor

			if pos == p2:
				break

			pos = pos.move_toward(p2, 1)

	return prev_corridor

func generate_random_cell() -> DungeonCell:
	var cell_size_base: = rng.randfn(cell_size_mean, cell_size_deviation)
	var cell_size_ratio: = rng.randf_range(0.5, 1.5)
	var cell_width: = round(cell_size_base)
	var cell_length: = round(cell_size_base * cell_size_ratio)

	cell_width = max(corridor_width + 2, cell_width)
	cell_length = max(corridor_width + 2, cell_length)

	# Making all cell dimensions odd makes positioning them in a grid easier
	cell_width += 1 - fmod(cell_width, 2)
	cell_length += 1 - fmod(cell_length, 2)

	var pos2d: = Util.random_point_in_circle(self.cell_position_range).round()

	var pos: = Vector3(pos2d.x, 0, pos2d.y)
	var size: = Vector3(cell_width, cell_height, cell_length)

	return self.dungeon.add_cell(pos, size)

func delaunay_triangulate_cells(cells: Array) -> Array:
	var points: = PoolVector2Array()
	for cell in cells:
		points.append(Vector2(cell.transform.origin.x, cell.transform.origin.z))

	var triangulated_indices: = Geometry.triangulate_delaunay_2d(points)

	var triangulated_cells: = []
	for idx in triangulated_indices:
		triangulated_cells.append(cells[idx])

	return triangulated_cells

func get_room_graph() -> Graph:
	var rooms: = []
	var room_graph: = Graph.new()

	for cell in self.dungeon.get_cells():
		if cell.is_room():
			rooms.append(cell)
			room_graph.add_node(cell.id)

	# Get a list of triangular paths between rooms, where none of the paths overlap
	var triangulated_rooms: = delaunay_triangulate_cells(rooms)

	var i: = 0
	while i < triangulated_rooms.size():
		var room0: DungeonCell = triangulated_rooms[i]
		var room1: DungeonCell = triangulated_rooms[i + 1]
		var room2: DungeonCell = triangulated_rooms[i + 2]
		var w01: = room0.distance_to(room1)
		var w12: = room1.distance_to(room2)
		var w20: = room2.distance_to(room0)
		room_graph.add_edge(room0.id, room1.id, w01)
		room_graph.add_edge(room1.id, room2.id, w12)
		room_graph.add_edge(room2.id, room0.id, w20)
		i += 3

	# Create a minimum spanning tree graph from the triangulated graph. In this
	# graph there is only one path between two rooms, i.e. there are no loops.
	var mst: = room_graph.mst()

	# Add some extra loops to the graph from the original triangulated graph
	i = 0
	while i < triangulated_rooms.size():
		if !mst.edges[triangulated_rooms[i].id].has(triangulated_rooms[i + 1].id):
			if randf() < 0.2:
				mst.add_edge(triangulated_rooms[i].id, triangulated_rooms[i + 1].id)
		i += 3

	return mst

func get_cell_link_path(cell1_id, cell2_id):
	var path: = []

	var cell1: DungeonCell = self.dungeon.get_cell(cell1_id)
	var cell2: DungeonCell = self.dungeon.get_cell(cell2_id)

	var x1: = max(cell1.rect.position.x, cell2.rect.position.x)
	var x2: = min(cell1.rect.end.x, cell2.rect.end.x)
	var overlap_x: = x2 - x1

	var z1: = max(cell1.rect.position.y, cell2.rect.position.y)
	var z2: = min(cell1.rect.end.y, cell2.rect.end.y)
	var overlap_z: = z2 - z1

	if overlap_x >= corridor_width + 2:
		# Get straight horizontal path

		if cell1.rect.intersects(cell2.rect, true):
			return path

		var mid_x: = round((x1 + x2) / 2)
		path.append(Vector3(mid_x, 0, ceil(z1 + 1)))
		path.append(Vector3(mid_x, 0, floor(z2 - 1)))
	elif overlap_z >= corridor_width + 2:
		# Get straight vertical path

		if cell1.rect.intersects(cell2.rect, true):
			return path

		var mid_z: = round((z1 + z2) / 2)
		path.append(Vector3(ceil(x1 + 1), 0, mid_z))
		path.append(Vector3(floor(x2 - 1), 0, mid_z))
	else:
		# Get L-shaped path

		var cell1_x: = floor(cell1.rect.end.x - 1) if cell1.rect.position.x < cell2.rect.position.x else ceil(cell1.rect.position.x + 1)
		var cell1_z: = floor(cell1.rect.end.y - 1) if cell1.rect.position.y < cell2.rect.position.y else ceil(cell1.rect.position.y + 1)
		var cell2_x: = floor(cell2.rect.end.x - 1) if cell2.rect.position.x < cell1.rect.position.x else ceil(cell2.rect.position.x + 1)
		var cell2_z: = floor(cell2.rect.end.y - 1) if cell2.rect.position.y < cell1.rect.position.y else ceil(cell2.rect.position.y + 1)

		var temp_path1: = [
			Vector3(cell1.transform.origin.x, 0, cell1_z),
			Vector3(cell1.transform.origin.x, 0, cell2.transform.origin.z),
			Vector3(cell2_x, 0, cell2.transform.origin.z)
		]

		var temp_path2: = [
			Vector3(cell1_x, 0, cell1.transform.origin.z),
			Vector3(cell2.transform.origin.x, 0, cell1.transform.origin.z),
			Vector3(cell2.transform.origin.x, 0, cell2_z)
		]

		var temp_path1_overlaps: = 0
		var temp_path2_overlaps: = 0

		# We can't always avoid overlaps, but we want to at least minimize them
		for id in self.dungeon.cells_overlapping_path(temp_path1, self.corridor_width):
			if self.dungeon.get_cell(id).is_room():
				temp_path1_overlaps += 1
		for id in self.dungeon.cells_overlapping_path(temp_path2, self.corridor_width):
			if self.dungeon.get_cell(id).is_room():
				temp_path2_overlaps += 1

		path = temp_path1 if temp_path1_overlaps < temp_path2_overlaps else temp_path2

	return path

func separate_cells():
	var ticks = 0
	var overlaps = true

	while overlaps && ticks < 200:
		overlaps = false
		for cell1 in self.dungeon.get_cells():
			var v = Vector3.ZERO
			var overlapping_cells = self.dungeon.cells_overlapping_cell(cell1.id)

			for cell2_id in overlapping_cells:
				if cell1.id != cell2_id:
					var delta = self.dungeon.get_cell(cell2_id).vector_to(cell1)
					# Close rectangles should affect movement more than far away rectangles
					var inv_sqr = 5.0 / (delta.length_squared() + 0.01)
					v += delta * inv_sqr

			if overlapping_cells.size() > 1:
				v *= -1

				if v.length() < 0.25:
					v = v.normalized() * 0.25
				if v.length() > 2:
					v = v.normalized() * 2

				self.dungeon.move_cell(cell1.id, v)
				overlaps = true
			else:
				var snapped = cell1.transform.origin.round()
				if cell1.transform.origin != snapped:
					self.dungeon.position_cell(cell1.id, snapped)

		ticks += 1

	# Make sure all cells are snapped to grid
	for cell in self.dungeon.get_cells():
		var snapped = cell.transform.origin.round()
		if cell.transform.origin != snapped:
			self.dungeon.position_cell(cell.id, snapped)

func separate_cells_fast():
	var separated = []

	for cell1 in self.dungeon.get_cells():
		var dir: Vector3 = cell1.transform.origin.normalized()
		var angle: = dir.angle_to(Vector3.RIGHT)

		while true:
			var cell2: DungeonCell

			for cell in self.dungeon.get_cells():
				if cell1.id != cell.id && cell1.rect.intersects(cell.rect):
					cell2 = cell
					break

			if !cell2:
				break

			var cell1_corner: = Vector3.ZERO
			cell1_corner.x = cell1.rect.end.x if dir.x <= 0 else cell1.rect.position.x
			cell1_corner.z = cell1.rect.end.y if dir.z <= 0 else cell1.rect.position.y

			var cell2_corner: = Vector3.ZERO
			cell2_corner.x = cell2.rect.position.x if dir.x <= 0 else cell2.rect.end.x
			cell2_corner.z = cell2.rect.position.y if dir.z <= 0 else cell2.rect.end.y

			var dist_horizontal: = cell2_corner.x - cell1_corner.x
			var dist_vertical: = cell2_corner.z - cell1_corner.z

			var delta1: = Vector3(tan(angle) * dist_vertical, 0, dist_vertical)
			var delta2: = Vector3(dist_horizontal, 0, tan(angle - PI / 2) * dist_horizontal)
			var delta = delta1 if delta1.length() < delta2.length() else delta2

			assert(delta.length() > 0)

			self.dungeon.move_cell(cell1.id, delta.round())

		separated.append(cell1)
