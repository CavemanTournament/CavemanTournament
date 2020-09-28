extends Camera

var my_player
var relative_pos = Vector3(0,33,15) # Position in relation to player

func _physics_process(delta):
	self.translation = my_player.transform.origin + relative_pos
