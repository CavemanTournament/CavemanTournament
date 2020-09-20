extends Spatial

const GRIDMAP_FLOOR = 0
const GRIDMAP_WALL = 1

export var num_cells: = 100
export var cell_size_mean: = 10
export var cell_size_deviation: = 4
export var cell_position_range: = 40
export var min_room_size: = 10
export var corridor_width: = 3
export var cell_height: = 1
export var fast_separation: = false

onready var gridmap = $GridMap
onready var nav = $Navigation
onready var players = $Players
onready var enemies = $Enemies

var gen: DungeonGenerator

var cells: Array

func _init():
	self.gen = DungeonGenerator.new(
		self.num_cells,
		self.cell_size_mean,
		self.cell_size_deviation,
		self.cell_position_range,
		self.min_room_size,
		self.corridor_width,
		self.cell_height,
		self.fast_separation
	)

func _ready():
	build()

func build() -> void:
	for child in self.players.get_children() + self.enemies.get_children():
		child.queue_free()

	self.cells = self.gen.generate_cells()
	_build_gridmap()
	_build_nav()

	add_child(self.nav)

func get_room_rects() -> Array:
	var rects: Array

	var cell_half = self.gridmap.cell_size * 0.5
	cell_half.y = 0

	for cell in self.cells:
		if !cell.is_room():
			continue

		# Tile positions in GridMap are centered
		var tile_start = cell.rect.position + Vector2(0.5, 0.5)
		var tile_end = cell.rect.end - Vector2(0.5, 0.5)

		var cell_start = self.gridmap.map_to_world(tile_start.x, 0, tile_start.y) - cell_half
		var cell_end = self.gridmap.map_to_world(tile_end.x, 0, tile_end.y) + cell_half

		var cell_start2 = Vector2(cell_start.x, cell_start.z)
		var cell_end2 = Vector2(cell_end.x, cell_end.z)

		rects.append(Rect2(cell_start2, cell_end2 - cell_start2))

	return rects

func add_player(player: Spatial) -> void:
	self.players.add_child(player)

func add_enemy(enemy: Spatial) -> void:
	enemy.set_target(self.players.get_children()[0])
	enemy.set_navigation(self.nav)
	self.enemies.add_child(enemy)

func _build_gridmap() -> void:
	self.gridmap.clear()

	var grid: Dictionary
	var walls: Dictionary
	var rooms: = []

	for cell in self.cells:
		if cell.is_room():
			rooms.append(cell)

		if !cell.is_typeless():
			for x in Util.rangef(cell.rect.position.x, cell.rect.end.x):
				for y in Util.rangef(cell.rect.position.y, cell.rect.end.y):
					grid[Vector2(x + 0.5, y + 0.5)] = cell

	for vect in grid:
		self.gridmap.set_cell_item(vect.x, 0, vect.y, GRIDMAP_FLOOR, 0)

		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var v = Vector2(vect.x + dx, vect.y + dy)
				if !grid.has(v) && !walls.has(v):
					walls[v] = true
					self.gridmap.set_cell_item(v.x, 0, v.y, GRIDMAP_WALL, 0)

func _build_nav() -> void:
	for child in self.nav.get_children():
		child.queue_free()

	var navmesh: = _build_navmesh()

	var navmesh_instance: = NavigationMeshInstance.new()
	navmesh_instance.set_navigation_mesh(navmesh)
	navmesh_instance.set_enabled(true)

	self.nav.add_child(navmesh_instance)

func _build_navmesh() -> NavigationMesh:
	var floors: Dictionary
	var walls: Dictionary

	for pos in self.gridmap.get_used_cells():
		var type = self.gridmap.get_cell_item(pos.x, pos.y, pos.z)

		if type == GRIDMAP_FLOOR:
			floors[Vector2(pos.x, pos.z)] = true
		if type == GRIDMAP_WALL:
			walls[Vector2(pos.x, pos.z)] = true

	var surface: = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertex_idx: = 0
	var indices: = {}

	for cell in self.cells:
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
					vertices = _inset_quad(
						Vector3(x1, navmesh_y, z1),
						Vector3(x2, navmesh_y, z1),
						Vector3(x2, navmesh_y, z2),
						Vector3(x1, navmesh_y, z2)
					)
				elif inset_tr:
					vertices = _inset_quad(
						Vector3(x2, navmesh_y, z1),
						Vector3(x2, navmesh_y, z2),
						Vector3(x1, navmesh_y, z2),
						Vector3(x1, navmesh_y, z1)
					)
				elif inset_br:
					vertices = _inset_quad(
						Vector3(x2, navmesh_y, z2),
						Vector3(x1, navmesh_y, z2),
						Vector3(x1, navmesh_y, z1),
						Vector3(x2, navmesh_y, z1)
					)
				elif inset_bl:
					vertices = _inset_quad(
						Vector3(x1, navmesh_y, z2),
						Vector3(x1, navmesh_y, z1),
						Vector3(x2, navmesh_y, z1),
						Vector3(x2, navmesh_y, z2)
					)
				else:
					vertices = _quad(
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

	var navmesh: = NavigationMesh.new()
	var mesh: = surface.commit()
	navmesh.create_from_mesh(mesh)

	return navmesh

func _quad(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3) -> PoolVector3Array:
	var v: PoolVector3Array = [p1, p2, p4, p2, p3, p4]
	return v

func _inset_quad(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3) -> PoolVector3Array:
	var first: Vector3 = (p1 + p2) * 0.5
	var last: Vector3 = (p1 + p4) * 0.5
	var mid: Vector3 = (p1 + p3) * 0.5

	var v: PoolVector3Array = [first, p2, mid, p2, p3, mid, p3, p4, mid, p4, last, mid]
	return v
