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
onready var floors: = $Floors
onready var walls: = $Walls
onready var floorGridmap: = $FloorGridMap
onready var wallGridmap: = $WallGridMap

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
	var grid: Dictionary

	for cell in dungeon.get_cells():
		if !cell.is_typeless():
			for x in range(cell.rect.position.x, cell.rect.end.x):
				for y in range(cell.rect.position.y, cell.rect.end.y):
					grid[Vector2(x, y)] = cell

	for vect in grid:
#		var floorInst = Floor.instance()
#		var floorAabb: AABB = floorInst.get_node("Cube2").get_aabb()
#		var x = floorAabb.size.x * vect.x
#		var y = floorAabb.size.y * vect.y
#		floorInst.transform.origin = Vector3(x, 0, y)
#		self.floors.add_child(floorInst)
		self.floorGridmap.set_cell_item(vect.x, 0, vect.y, 0, 0)

		var hasLeft = grid.has(Vector2(vect.x - 1, vect.y))
		var hasRight = grid.has(Vector2(vect.x + 1, vect.y))
		var hasUp = grid.has(Vector2(vect.x, vect.y - 1))
		var hasDown = grid.has(Vector2(vect.x, vect.y + 1))
		var hasLeftUp = grid.has(Vector2(vect.x - 1, vect.y - 1))
		var hasRightUp = grid.has(Vector2(vect.x + 1, vect.y - 1))
		var hasLeftDown = grid.has(Vector2(vect.x - 1, vect.y + 1))
		var hasRightDown = grid.has(Vector2(vect.x + 1, vect.y + 1))

#		var leftUpCorner = Vector3(x - (floorAabb.size.x / 2), 0, y - (floorAabb.size.y / 2))
#		var rightUpCorner = Vector3(x + (floorAabb.size.x / 2), 0, y - (floorAabb.size.y / 2))
#		var leftDownCorner = Vector3(x - (floorAabb.size.x / 2), 0, y + (floorAabb.size.y / 2))
#		var rightDownCorner = Vector3(x + (floorAabb.size.x / 2), 0, y + (floorAabb.size.y / 2))

		# Add walls
		if !hasLeft:
			self.wallGridmap.set_cell_item(vect.x, 0, vect.y, 1, 0)
#
#		if !hasRight && hasUp && !hasRightUp:
#			var wallInst = Wall.instance()
#			wallInst.transform.origin = rightUpCorner
#			self.walls.add_child(wallInst)
#
#		if !hasUp && hasRight && !hasRightUp:
#			var wallInst = Wall.instance()
#			wallInst.rotate_y(deg2rad(90))
#			wallInst.transform.origin = rightUpCorner
#			self.walls.add_child(wallInst)
#
#		if !hasDown && hasRight && !hasRightDown:
#			var wallInst = Wall.instance()
#			wallInst.rotate_y(deg2rad(90))
#			wallInst.transform.origin = rightDownCorner
#			self.walls.add_child(wallInst)
#
#		# Add inward corners
#		if !hasDown && !hasLeft:
#			var cornerInst = Corner.instance()
#			cornerInst.transform.origin = leftDownCorner
#			self.walls.add_child(cornerInst)
#
#		if !hasDown && !hasRight:
#			var cornerInst = Corner.instance()
#			cornerInst.rotate_y(deg2rad(90))
#			cornerInst.transform.origin = rightDownCorner
#			self.walls.add_child(cornerInst)
#
#		if !hasUp && !hasLeft:
#			var cornerInst = Corner.instance()
#			cornerInst.rotate_y(deg2rad(270))
#			cornerInst.transform.origin = leftUpCorner
#			self.walls.add_child(cornerInst)
#
#		if !hasUp && !hasRight:
#			var cornerInst = Corner.instance()
#			cornerInst.rotate_y(deg2rad(180))
#			cornerInst.transform.origin = rightUpCorner
#			self.walls.add_child(cornerInst)
#
#		# Add outward corners
#		if hasUp && hasRight && !hasRightUp:
#			var cornerInst = Corner.instance()
#			cornerInst.transform.origin = rightUpCorner
#			self.walls.add_child(cornerInst)
#
#		if hasUp && hasLeft && !hasLeftUp:
#			var cornerInst = Corner.instance()
#			cornerInst.rotate_y(deg2rad(90))
#			cornerInst.transform.origin = leftUpCorner
#			self.walls.add_child(cornerInst)
#
#		if hasDown && hasRight && !hasRightDown:
#			var cornerInst = Corner.instance()
#			cornerInst.rotate_y(deg2rad(270))
#			cornerInst.transform.origin = rightDownCorner
#			self.walls.add_child(cornerInst)
#
#		if hasDown && hasLeft && !hasLeftDown:
#			var cornerInst = Corner.instance()
#			cornerInst.rotate_y(deg2rad(180))
#			cornerInst.transform.origin = leftDownCorner
#			self.walls.add_child(cornerInst)

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
		var floor_objs = self.floors.get_children()
		var wall_objs = self.walls.get_children()
		for n in floor_objs + wall_objs:
			n.queue_free()

		self.floorGridmap.clear()
		self.wallGridmap.clear()

		# Wait one frame for cells to be cleared from tree
		yield(get_tree(), "idle_frame")
		make_cells()
		yield(get_tree(), "idle_frame")

#func _process(delta):
#	if delta > 0:
#		print(1 / delta)
