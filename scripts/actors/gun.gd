extends Spatial
class_name Gun

export (NodePath) var barrel_nodepath

onready var barrel: Spatial = get_node(barrel_nodepath)
onready var Bullet = preload("res://scenes/actors/bullet.tscn")

const test_weapon_cooldown := 2
var test_weapon_cooldown_counter = 0.0

func shoot():
	if test_weapon_cooldown_counter > test_weapon_cooldown:
		var bullet = Bullet.instance()
		bullet.global_transform = Transform(self.global_transform.basis, self.barrel.global_transform.origin)
		get_tree().get_root().add_child(bullet)
		test_weapon_cooldown_counter = 0

func _physics_process(delta):
	test_weapon_cooldown_counter += delta
