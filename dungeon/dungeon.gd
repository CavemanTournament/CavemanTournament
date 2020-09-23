extends Spatial
class_name Dungeon

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
var cell_positions: Dictionary
var cell_id_map: Dictionary
var cell_distances: Dictionary

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
	_build_cell_id_map()
	_build_gridmap()
	_build_nav()

	add_child(self.nav)

func _build_cell_id_map():
	self.cell_id_map = {}

	for cell in self.cells:
		self.cell_id_map[cell.id] = cell

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
	enemy.set_dungeon(self)
	self.enemies.add_child(enemy)

func get_cell_at(pos: Vector3):
	var cell_pos = self.gridmap.world_to_map(Vector3(pos.x, 0, pos.z))
	return self.cell_positions[Vector2(cell_pos.x, cell_pos.z)]

func get_players() -> Array:
	return self.players.get_children()

func get_navigation() -> Navigation:
	return self.nav

func _build_gridmap() -> void:
	self.gridmap.clear()

	self.cell_positions = {}
	var walls: Dictionary
	var rooms: = []

	for cell in self.cells:
		if cell.is_room():
			rooms.append(cell)

		if !cell.is_typeless():
			for x in Util.rangef(cell.rect.position.x, cell.rect.end.x):
				for y in Util.rangef(cell.rect.position.y, cell.rect.end.y):
					self.cell_positions[Vector2(x + 0.5, y + 0.5)] = cell

	for vect in self.cell_positions:
		self.gridmap.set_cell_item(vect.x, 0, vect.y, GRIDMAP_FLOOR, 0)

		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var v = Vector2(vect.x + dx, vect.y + dy)
				if !self.cell_positions.has(v) && !walls.has(v):
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
	var surface: = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertex_idx: = 0
	var indices: = {}
	var navmesh_y = 3.1
	var half_grid_x = self.gridmap.cell_size.x * 0.5
	var half_grid_z = self.gridmap.cell_size.z * 0.5

	for grid_pos in self.gridmap.get_used_cells():
		if self.gridmap.get_cell_item(grid_pos.x, grid_pos.y, grid_pos.z) == GRIDMAP_WALL:
			continue

		var cell_pos = self.gridmap.map_to_world(grid_pos.x, grid_pos.y, grid_pos.z)

		var vertices: PoolVector3Array = _quad(
			Vector3(cell_pos.x - half_grid_x, navmesh_y, cell_pos.z - half_grid_z),
			Vector3(cell_pos.x + half_grid_x, navmesh_y, cell_pos.z - half_grid_z),
			Vector3(cell_pos.x + half_grid_x, navmesh_y, cell_pos.z + half_grid_z),
			Vector3(cell_pos.x - half_grid_x, navmesh_y, cell_pos.z + half_grid_z)
		)

		for v in vertices:
			if !indices.has(v):
				surface.add_vertex(v)
				indices[v] = vertex_idx
				vertex_idx += 1

			surface.add_index(indices[v])

	var navmesh: = NavigationMesh.new()
	var mesh: = surface.commit()
	navmesh.create_from_mesh(mesh)

	return navmesh

func _quad(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3) -> PoolVector3Array:
	var v: PoolVector3Array = [p1, p2, p4, p2, p3, p4]
	return v
