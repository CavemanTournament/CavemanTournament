extends Spatial

export var debug = false
export var debug_separation = false

onready var debug_geom: = $ImmediateGeometry
onready var dungeon: = $Dungeon

const Player = preload("res://actors/player.tscn")
const Spider = preload("res://actors/spider_enemy.tscn")

func _ready():
	reset_actors()

func rect_center(rect: Rect2) -> Vector3:
	return Vector3((rect.position.x + rect.end.x) / 2, 4, (rect.position.y + rect.end.y) / 2)

func reset_actors():
	var rooms = self.dungeon.get_room_rects()
	var start_room = rooms[randi() % rooms.size()]

	var player = Player.instance()
	player.transform.origin = rect_center(start_room) - Vector3(6, 0, 0)
	self.dungeon.add_player(player)

	var spider: = Spider.instance()
	spider.transform.origin = rect_center(start_room)
	self.dungeon.add_enemy(spider)


func _input(event):
	if event.is_action_pressed('ui_select'):
		# Wait one frame for removed nodes to be cleared from tree
		yield(get_tree(), "idle_frame")
		self.dungeon.build()
		reset_actors()
		yield(get_tree(), "idle_frame")
