extends Spatial

export var tile_size: = 8.0
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
onready var rooms: = $Rooms
onready var siderooms: = $Siderooms
onready var corridors: = $Corridors

func _ready():
	make_cells()

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

	for cell in dungeon.get_cells():
		cell.set_size(cell.get_size() * self.tile_size)
		cell.set_position(cell.transform.origin * self.tile_size)

		if cell.is_room():
			self.rooms.add_child(cell)
		if cell.is_sideroom():
			self.siderooms.add_child(cell)
		if cell.is_corridor():
			self.corridors.add_child(cell)

	self.debug_geom.clear()

	if self.debug:
		for cell in dungeon.get_cells():
			draw_cell(cell)

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

	var y = cell_height * tile_size

	var p1 = Vector3(cell.rect.position.x, y, cell.rect.position.y)
	var p2 = Vector3(cell.rect.end.x, y, cell.rect.position.y)
	var p3 = Vector3(cell.rect.end.x, y, cell.rect.end.y)
	var p4 = Vector3(cell.rect.position.x, y, cell.rect.end.y)

	self.debug_geom.add_vertex(p1)
	self.debug_geom.add_vertex(p2)
	self.debug_geom.add_vertex(p3)
	self.debug_geom.add_vertex(p4)
	self.debug_geom.add_vertex(p1)
	self.debug_geom.end()

func _input(event):
	if event.is_action_pressed('ui_select'):
		var room_objs = self.rooms.get_children()
		var sideroom_objs = self.siderooms.get_children()
		var corridor_objs = self.corridors.get_children()
		for n in room_objs + sideroom_objs + corridor_objs:
			n.queue_free()

		# Wait one frame for cells to be cleared from tree
		yield(get_tree(), "idle_frame")
		make_cells()
		yield(get_tree(), "idle_frame")
