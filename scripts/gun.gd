extends Spatial

class_name Gun

const test_weapon_cooldown := 2

var test_weapon_cooldown_counter = 0.0
onready var barrel: Spatial = get_child(1)

onready var bullet = preload("res://actors/bullet.tscn")

func shoot():
	if(test_weapon_cooldown_counter>test_weapon_cooldown):
		var shot = bullet.instance()
		shot.set_global_transform(self.global_transform)
		shot.transform.origin = barrel.global_transform.origin
		get_tree().get_root().get_child(1).add_child(shot) #Expects Main to be second child of root
		test_weapon_cooldown_counter = 0

func _physics_process(delta):
	test_weapon_cooldown_counter += delta
