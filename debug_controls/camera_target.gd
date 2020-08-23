extends Spatial

# Debug camera movement
# + Camera movement tied to physics delta with interpolated camera so
#   that the amount of movement is relative to absolute key press time
#   instead of fps press time but interpolation is smoothed with fps
# + CameraTarget.speed controls how far the camera travels relative to
#   key press time while InterpolatedCamera.speed controls smoothing

export var speed: = 0.8

func _physics_process(delta):
	if get_parent().enabled:
		var absolute_movement = speed * delta
		# Due to Godot Y-is-down convention, Z axis movement is "inverted"
		if Input.is_action_pressed('debug_camera_forward'):
			transform.origin.z -= absolute_movement
		if Input.is_action_pressed('debug_camera_back'):
			transform.origin.z += absolute_movement
		
		if Input.is_action_pressed('debug_camera_right'):
			transform.origin.x += absolute_movement
		if Input.is_action_pressed('debug_camera_left'):
			transform.origin.x -= absolute_movement
		if Input.is_action_pressed('debug_camera_up'):
			transform.origin.y += absolute_movement
		if Input.is_action_pressed('debug_camera_down'):
			transform.origin.y -= absolute_movement

