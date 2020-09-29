extends Spatial
class_name Dungeon

const GRIDMAP_FLOOR = 0
const GRIDMAP_WALL = 1

const DetourNavigation: NativeScript = preload("res://addons/godotdetour/detournavigation.gdns")
const DetourNavigationParameters: NativeScript = preload("res://addons/godotdetour/detournavigationparameters.gdns")
const DetourNavigationMesh: NativeScript = preload("res://addons/godotdetour/detournavigationmesh.gdns")
const DetourNavigationMeshParameters: NativeScript = preload("res://addons/godotdetour/detournavigationmeshparameters.gdns")

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
var navigation: DetourNavigation

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

#	add_child(self.nav)

func get_room_rects() -> Array:
	var rects: Array

	var cell_half = self.gridmap.cell_size * 0.5
	cell_half.y = 0

	for cell in self.cells:
		if !cell.is_room() && !cell.is_sideroom():
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

func get_players() -> Array:
	return self.players.get_children()

func get_enemies() -> Array:
	return self.enemies.get_children()

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

	# Create the navigation parameters
	var nav_params = DetourNavigationParameters.new()
	nav_params.ticksPerSecond = 60 # How often the navigation is updated per second in its own thread
	nav_params.maxObstacles = 128 # How many dynamic obstacles can be present at the same time

	# Create the parameters for the navmesh
	var nav_mesh_params = DetourNavigationMeshParameters.new()
	nav_mesh_params.cellSize = Vector2(0.5, 0.2)
	nav_mesh_params.maxNumAgents = 256
	nav_mesh_params.maxAgentSlope = 40.0
	nav_mesh_params.maxAgentHeight = 2.0
	nav_mesh_params.maxAgentClimb = 0.75
	nav_mesh_params.maxAgentRadius = 2.0
	nav_mesh_params.maxEdgeLength = 12.0
	nav_mesh_params.maxSimplificationError = 1.3
	nav_mesh_params.minNumCellsPerIsland = 8
	nav_mesh_params.minCellSpanCount = 20
	nav_mesh_params.maxVertsPerPoly = 6
	nav_mesh_params.tileSize = 60
	nav_mesh_params.layersPerTile = 1
	nav_mesh_params.detailSampleDistance = 6.0
	nav_mesh_params.detailSampleMaxError = 1.0
	nav_params.navMeshParameters.append(nav_mesh_params)

	var navmesh: = _build_navmesh()

	self.navigation = DetourNavigation.new()
	self.navigation.initialize(navmesh, nav_params)

	var weights: Dictionary = {}
	weights[0] = 10.0   # Ground
	weights[1] = 100.0 # Road
	weights[2] = 100.0 # Water
	weights[3] = 100.0 # Door
	weights[4] = 100.0 # Grass
	weights[5] = 100.0 # Jump
	self.navigation.setQueryFilter(0, "default", weights)

#	var debugMeshInstance: MeshInstance = navigation.createDebugMesh(0, false)
#	debugMeshInstance.translation = Vector3(0.0, 0.05, 0.0)
#	add_child(debugMeshInstance)

func _build_navmesh() -> MeshInstance:
	var surface: = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertex_idx: = 0
	var indices: = {}
	var navmesh_y = 0.1
	var half_tile = self.gridmap.cell_size * 0.5

	for cell in self.cells:
		if cell.is_typeless():
			continue

		var position = self.gridmap.map_to_world(cell.rect.position.x + 0.5, 0, cell.rect.position.y + 0.5) - half_tile
		var end = self.gridmap.map_to_world(cell.rect.end.x - 0.5, 0, cell.rect.end.y - 0.5) + half_tile

		var vertices: PoolVector3Array = _quad(
			Vector3(position.x, navmesh_y, position.z),
			Vector3(end.x, navmesh_y, position.z),
			Vector3(end.x, navmesh_y, end.z),
			Vector3(position.x, navmesh_y, end.z)
		)

		for v in vertices:
			if !indices.has(v):
				surface.add_vertex(v)
				indices[v] = vertex_idx
				vertex_idx += 1

			surface.add_index(indices[v])

	var mesh: = surface.commit()

	var mesh_inst: = MeshInstance.new()
	mesh_inst.set_mesh(mesh)

	return mesh_inst

func _quad(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3) -> PoolVector3Array:
	var v: PoolVector3Array = [p1, p2, p4, p2, p3, p4]
	return v
