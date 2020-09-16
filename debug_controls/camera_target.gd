extends Spatial

# Debug camera movement
# - Camera movement tied to physics delta with interpolated camera so
#   that the amount of movement is relative to absolute key press time
#   instead of fps press time but interpolation is smoothed with fps
# - CameraTarget.speed controls how far the camera travels relative to
#   key press time while InterpolatedCamera.speed controls smoothing

export var speed: = 0.8
export var rotation_speed: = 2

var ID_PLANE = Vector3(1, 0, 1)

func _physics_process(delta):
	if get_parent().enabled:
		var absolute_movement = speed * delta
		
		# Movement horizontally (x/z-axis) is relative to rotation on plane
		var basis_x = transform.basis.x.normalized()
		var basis_z = transform.basis.z.normalized()
		
		if basis_x == Vector3.ZERO:
			basis_x = Vector3.AXIS_X
		# Godot uses Y-is-down convention, z-axis movement is "inverted"
		# Negative z-axis is away from you, i.e. forward
		if basis_z == Vector3.ZERO:
			basis_z = -Vector3.AXIS_Z 

		if Input.is_action_pressed('debug_camera_right'):
			transform.origin += basis_x * ID_PLANE * absolute_movement
		if Input.is_action_pressed('debug_camera_left'):
			transform.origin -= basis_x * ID_PLANE * absolute_movement
		if Input.is_action_pressed('debug_camera_forward'):
			transform.origin -= basis_z * ID_PLANE * absolute_movement
		if Input.is_action_pressed('debug_camera_backward'):
			transform.origin += basis_z * ID_PLANE * absolute_movement
		
		# Movement down/up is absolute
		if Input.is_action_pressed('debug_camera_up'):
			transform.origin.y += absolute_movement
		if Input.is_action_pressed('debug_camera_down'):
			transform.origin.y -= absolute_movement
		
		# Rotations relative to object but around Y axis only
		var absolute_rotation = rotation_speed * delta
		if Input.is_action_pressed('debug_camera_rotate_right'):
			rotate(Vector3(0, -1, 0), absolute_rotation)
		if Input.is_action_pressed('debug_camera_rotate_left'):
			rotate(Vector3(0, 1, 0), absolute_rotation)

