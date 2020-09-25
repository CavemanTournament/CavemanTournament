extends Area

class_name Item

var picked = false


func _on_Gun_area_entered(area):
	if picked: pass
	else:
		var player = area.get_parent()
		if player.get('actor_type') != null:
			player.pickup_weapon(self)
