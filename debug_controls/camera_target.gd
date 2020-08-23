extends Spatial

# Debug camera movement
# + Camera movement tied to physics delta with interpolated camera so
#   that the amount of movement is relative to absolute key press time
#   instead of fps press time but interpolation is smoothed with fps
# + CameraTarget.speed controls how far the camera travels relative to
#   key press time while InterpolatedCamera.speed controls smoothing

export var speed: = 0.8
export var rotation_speed: = 2

var ID_PLANE = Vector3(1, 0, 1)
# TODO: Z_MULTI should probably be replaced by scaling with rotation of camera..
var Z_MULTI = 1.5

func _physics_process(delta):
	if get_parent().enabled:
		var absolute_movement = speed * delta
		# Movement horizontally is relative to rotation on plane
		if Input.is_action_pressed('debug_camera_right'):
			transform.origin += transform.basis.x * ID_PLANE * absolute_movement
		if Input.is_action_pressed('debug_camera_left'):
			transform.origin -= transform.basis.x * ID_PLANE * absolute_movement
		# Due to Godot Y-is-down convention, Z axis movement is "inverted"
		if Input.is_action_pressed('debug_camera_forward'):
			transform.origin -= \
				transform.basis.z * ID_PLANE * absolute_movement * Z_MULTI
		if Input.is_action_pressed('debug_camera_backward'):
			transform.origin += \
				transform.basis.z * ID_PLANE * absolute_movement * Z_MULTI
		
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

