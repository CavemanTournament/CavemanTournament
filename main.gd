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
onready var navigation: = $Navigation
onready var player: = $Player
onready var enemies: = $Enemies

const Spider = preload("res://actors/spider_enemy.tscn")

func _ready():
	make_cells()

func cell_center(cell: DungeonCell):
	var top_left = self.gridmap.map_to_world(cell.rect.position.x, 0, cell.rect.position.y)
	var bottom_right = top_left + Vector3(cell.rect.size.x * self.gridmap.cell_size.x, 0, cell.rect.size.y * self.gridmap.cell_size.z)

	return Vector3((top_left.x + bottom_right.x) / 2, 4, (top_left.z + bottom_right.z) / 2)

func make_cells() -> void:
	self.debug_geom.clear()

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

	var rooms: = []
	var cells = dungeon.get_cells()

	for cell in cells:
		if cell.is_room():
			rooms.append(cell)

		if !cell.is_typeless():
			for x in Util.rangef(cell.rect.position.x, cell.rect.end.x):
				for y in Util.rangef(cell.rect.position.y, cell.rect.end.y):
					grid[Vector2(x + 0.5, y + 0.5)] = cell

	for vect in grid:
		self.gridmap.set_cell_item(vect.x, 0, vect.y, 0, 0)

		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var v = Vector2(vect.x + dx, vect.y + dy)
				if !grid.has(v) && !walls.has(v):
					walls[v] = true
					self.gridmap.set_cell_item(v.x, 0, v.y, 1, 0)

	var surface: = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertex_idx: = 0
	var indices: = {}

	for cell in cells:
		if cell.is_typeless():
			continue

		var cell_tl = self.gridmap.map_to_world(cell.rect.position.x + 0.5, 0, cell.rect.position.y + 0.5)
		var cell_br = self.gridmap.map_to_world(cell.rect.end.x + 0.5, 0, cell.rect.end.y + 0.5)

		var half_grid_x = self.gridmap.cell_size.x * 0.5
		var half_grid_z = self.gridmap.cell_size.z * 0.5
		var navmesh_y = 3.1

		var cell_x = cell.rect.position.x + 0.5
		for x in Util.rangef(cell_tl.x, cell_br.x, self.gridmap.cell_size.x):
			var cell_z = cell.rect.position.y + 0.5
			for z in Util.rangef(cell_tl.z, cell_br.z, self.gridmap.cell_size.z):
				var x1 = x - half_grid_x
				var x2 = x + half_grid_x
				var z1 = z - half_grid_z
				var z2 = z + half_grid_z

				var grid_l = Vector2(cell_x - 1, cell_z)
				var grid_r = Vector2(cell_x + 1, cell_z)
				var grid_t = Vector2(cell_x, cell_z - 1)
				var grid_b = Vector2(cell_x, cell_z + 1)
				var grid_tl = Vector2(cell_x - 1, cell_z - 1)
				var grid_tr = Vector2(cell_x + 1, cell_z - 1)
				var grid_bl = Vector2(cell_x - 1, cell_z + 1)
				var grid_br = Vector2(cell_x + 1, cell_z + 1)

				var inset_tl = walls.has(grid_tl) && !walls.has(grid_l) && !walls.has(grid_t)
				var inset_tr = walls.has(grid_tr) && !walls.has(grid_r) && !walls.has(grid_t)
				var inset_bl = walls.has(grid_bl) && !walls.has(grid_l) && !walls.has(grid_b)
				var inset_br = walls.has(grid_br) && !walls.has(grid_r) && !walls.has(grid_b)

				var offset_x1: float = 0
				var offset_z1: float = 0
				var offset_x2: float = 0
				var offset_z2: float = 0

				if walls.has(grid_l):
					offset_x1 = half_grid_x
				if walls.has(grid_r):
					offset_x2 = -half_grid_x
				if walls.has(grid_t):
					offset_z1 = half_grid_z
				if walls.has(grid_b):
					offset_z2 = -half_grid_z

				var vertices: PoolVector3Array = []

				if inset_tl:
					vertices = inset_quad(
						Vector3(x1, navmesh_y, z1),
						Vector3(x2, navmesh_y, z1),
						Vector3(x2, navmesh_y, z2),
						Vector3(x1, navmesh_y, z2)
					)
				elif inset_tr:
					vertices = inset_quad(
						Vector3(x2, navmesh_y, z1),
						Vector3(x2, navmesh_y, z2),
						Vector3(x1, navmesh_y, z2),
						Vector3(x1, navmesh_y, z1)
					)
				elif inset_br:
					vertices = inset_quad(
						Vector3(x2, navmesh_y, z2),
						Vector3(x1, navmesh_y, z2),
						Vector3(x1, navmesh_y, z1),
						Vector3(x2, navmesh_y, z1)
					)
				elif inset_bl:
					vertices = inset_quad(
						Vector3(x1, navmesh_y, z2),
						Vector3(x1, navmesh_y, z1),
						Vector3(x2, navmesh_y, z1),
						Vector3(x2, navmesh_y, z2)
					)
				else:
					vertices = quad(
						Vector3(x1 + offset_x1, navmesh_y, z1 + offset_z1),
						Vector3(x2 + offset_x2, navmesh_y, z1 + offset_z1),
						Vector3(x2 + offset_x2, navmesh_y, z2 + offset_z2),
						Vector3(x1 + offset_x1, navmesh_y, z2 + offset_z2)
					)

				for v in vertices:
					if !indices.has(v):
						surface.add_vertex(v)
						indices[v] = vertex_idx
						vertex_idx += 1

					surface.add_index(indices[v])

				cell_z += 1
			cell_x += 1

	var nav_mesh: = NavigationMesh.new()
	var mesh: = surface.commit()
	nav_mesh.create_from_mesh(mesh)

	var navmesh_instance: = NavigationMeshInstance.new()
	navmesh_instance.set_navigation_mesh(nav_mesh)
	navmesh_instance.set_enabled(true)

	self.navigation.add_child(navmesh_instance)

	if self.debug:
		for cell in dungeon.get_cells():
			draw_cell(cell)

	var start_room = rooms[randi() % rooms.size()]
	player.transform.origin = cell_center(start_room) - Vector3(6, 0, 0)

	var spider: = Spider.instance()
	spider.transform.origin = cell_center(start_room)
	spider.set_target(player)
	spider.set_navigation(self.navigation)
	self.enemies.add_child(spider)

func quad(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3) -> PoolVector3Array:
	var v: PoolVector3Array = [p1, p2, p4, p2, p3, p4]
	return v

func inset_quad(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3) -> PoolVector3Array:
	var first: Vector3 = (p1 + p2) * 0.5
	var last: Vector3 = (p1 + p4) * 0.5
	var mid: Vector3 = (p1 + p3) * 0.5

	var v: PoolVector3Array = [first, p2, mid, p2, p3, mid, p3, p4, mid, p4, last, mid]
	return v

func draw_mesh(mesh: Mesh) -> void:
	var faces: = mesh.get_faces()
	var idx = 0

	while idx < faces.size():
		self.debug_geom.begin(Mesh.PRIMITIVE_LINE_LOOP)
		self.debug_geom.set_color(Color(0.5, 0, 0))

		self.debug_geom.add_vertex(faces[idx])
		self.debug_geom.add_vertex(faces[idx + 1])
		self.debug_geom.add_vertex(faces[idx + 2])
		self.debug_geom.add_vertex(faces[idx])

		self.debug_geom.end()
		idx += 3


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

func reset_level():
  self.gridmap.clear()

  for node in self.enemies.get_children():
    node.queue_free()

  for node in self.navigation.get_children():
    node.queue_free()

  # Wait one frame for removed nodes to be cleared from tree
  yield(get_tree(), "idle_frame")
  make_cells()
  yield(get_tree(), "idle_frame")
