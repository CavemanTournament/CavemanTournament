extends Spatial

export var debug = false
export var debug_separation = false

onready var debug_geom: = $ImmediateGeometry
onready var dungeon: = $Dungeon

const Player = preload("res://scenes/actors/player.tscn")
const Spider = preload("res://scenes/actors/spider_enemy.tscn")

func _ready():
	_spawn_agents()

func _rect_center(rect: Rect2) -> Vector3:
	return Vector3((rect.position.x + rect.end.x) / 2, 4, (rect.position.y + rect.end.y) / 2)

func _spawn_agents() -> void:
	var rects = self.dungeon.get_room_rects()
	var start_room = randi() % rects.size()

	var player = Player.instance()
	player.transform.origin = _rect_center(rects[start_room]) - Vector3(1, 0, 0)
	self.dungeon.add_player(player)

	var cell_size: Vector3 = self.dungeon.gridmap.cell_size
	var half_cell: Vector3 = cell_size * 0.5

	for idx in range(0, rects.size()):
		if idx != start_room:
			var rect = rects[idx]
			var tiles_x = rect.size.x / cell_size.x
			var tiles_z = rect.size.y / cell_size.y
			var num_enemies = 1

			var room_positions: = []
			for x in range(rect.position.x, rect.end.x, cell_size.x):
				for z in range(rect.position.y, rect.end.y, cell_size.y):
					room_positions.append(Vector3(x + half_cell.x, 0.1, z + half_cell.y))

			room_positions.shuffle()

			for k in range(0, num_enemies):
				var enemy = Spider.instance()
				enemy.transform.origin = room_positions[k]
				self.dungeon.add_enemy(enemy)

func _input(event):
	if event.is_action_pressed('ui_select'):
		# Wait one frame for removed nodes to be cleared from tree
		yield(get_tree(), "idle_frame")
		self.dungeon.build()
		_spawn_agents()
		yield(get_tree(), "idle_frame")
