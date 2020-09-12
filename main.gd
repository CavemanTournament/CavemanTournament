extends Spatial

export var num_cells: = 100
export var cell_size_mean: = 10
export var cell_size_deviation: = 4
export var cell_position_range: = 40
export var min_room_size: = 10
export var corridor_width: = 3
export var cell_height: = 1
export var fast_separation: = false

export var debug = false
export var debug_separation = false

onready var debug_geom: = $ImmediateGeometry
onready var gridmap: = $GridMap
onready var player: = $Player

func _ready():
	make_cells()

func cell_center(cell: DungeonCell):
	var mid_x = round((cell.rect.end.x + cell.rect.position.x) / 2)
	var mid_y = round((cell.rect.end.y + cell.rect.position.y) / 2)
	return self.gridmap.map_to_world(mid_x, 0, mid_y)

func make_cells() -> void:
	var dungeon_generator = DungeonGenerator.new(
		self.num_cells,
		self.cell_size_mean,
		self.cell_size_deviation,
		self.cell_position_range,
		self.min_room_size,
		self.corridor_width,
		self.cell_height,
		self.fast_separation
	)

	var dungeon = dungeon_generator.generate(self.debug_separation)

	var grid: Dictionary
	var walls: Dictionary

	var rooms := []

	for cell in dungeon.get_cells():
		if cell.is_room():
			rooms.append(cell)

		if !cell.is_typeless():
			for x in range(cell.rect.position.x, cell.rect.end.x):
				for y in range(cell.rect.position.y, cell.rect.end.y):
					grid[Vector2(x, y)] = cell

	for vect in grid:
		self.gridmap.set_cell_item(vect.x, 0, vect.y, 0, 0)

		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var v = Vector2(vect.x + dx, vect.y + dy)
				if !grid.has(v) && !walls.has(v):
					walls[v] = true
					self.gridmap.set_cell_item(v.x, 0, v.y, 1, 0)

	self.debug_geom.clear()

	if self.debug:
		for cell in dungeon.get_cells():
			draw_cell(cell)

	var start_room = rooms[randi() % rooms.size()]
	player.transform.origin = cell_center(start_room)


func draw_cell(cell) -> void:
	self.debug_geom.begin(Mesh.PRIMITIVE_LINE_LOOP)
	if cell.is_typeless():
		self.debug_geom.set_color(Color(0, 0, 0))
	if cell.is_room():
		self.debug_geom.set_color(Color(0.5, 0, 0))
	if cell.is_sideroom():
		self.debug_geom.set_color(Color(0.2, 0.2, 0.5))
	if cell.is_corridor():
		self.debug_geom.set_color(Color(0, 0, 0.5))

	var p1 = Vector3(cell.rect.position.x, 5, cell.rect.position.y)
	var p2 = Vector3(cell.rect.end.x, 5, cell.rect.position.y)
	var p3 = Vector3(cell.rect.end.x, 5, cell.rect.end.y)
	var p4 = Vector3(cell.rect.position.x, 5, cell.rect.end.y)

	self.debug_geom.add_vertex(p1)
	self.debug_geom.add_vertex(p2)
	self.debug_geom.add_vertex(p3)
	self.debug_geom.add_vertex(p4)
	self.debug_geom.add_vertex(p1)
	self.debug_geom.end()

func _input(event):
	if event.is_action_pressed('ui_select'):
		self.gridmap.clear()

		# Wait one frame for removed nodes to be cleared from tree
		yield(get_tree(), "idle_frame")
		make_cells()
		yield(get_tree(), "idle_frame")
