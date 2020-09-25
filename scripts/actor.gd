extends KinematicBody

class_name Actor

const damagable_type := "actor"
var health : int

func take_damage(damage_amount : int, damage_type : String):
	if damage_type == "kinetic":
		health -=damage_amount
	
	if health <= 0:
		queue_free()
