extends KinematicBody

const damagable_type := "actor"
var health : int

func _take_damage(damage_amount : int, damage_type : String):
	print("_take_damage")
	if damage_type == "kinetic":
		health -=damage_amount
	
	if health <= 0:
		queue_free()
