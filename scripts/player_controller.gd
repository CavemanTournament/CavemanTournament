extends KinematicBody

export (int) var speed = 20
export (int) var gravity = 20

const DEAD_ZONE := 0.15
const use_keyboard := true

var velocity := Vector3()

onready var model: Spatial = get_node("Model")

func get_joystick_input():
	velocity = Vector3()

	var left_stick_vector: Vector2 = get_joy_axis_vector_for_player(0, 0, 1)
	var right_stick_vector: Vector2 = get_joy_axis_vector_for_player(0, 2, 3)

	if left_stick_vector.length() > DEAD_ZONE:
		velocity.x = left_stick_vector.x
		velocity.z = left_stick_vector.y

	if right_stick_vector.length() > DEAD_ZONE:
		# TODO: make this in a more sensible way
		model.rotation.y = Vector2(right_stick_vector.x, -right_stick_vector.y).angle() + PI / 2

	velocity = velocity.normalized() * speed

func get_keyboard_input():
	var velocity_y = velocity.y
	velocity = Vector3()

	if Input.is_action_pressed('right'):
		velocity.x += speed
	if Input.is_action_pressed('left'):
		velocity.x -= speed
	if Input.is_action_pressed('down'):
		velocity.z += speed
	if Input.is_action_pressed('up'):
		velocity.z -= speed

	if velocity.length() > 0:
		model.rotation.y = Vector2(velocity.x, -velocity.z).angle() + PI / 2

	velocity = velocity.normalized() * speed
	velocity.y = velocity_y

# Gets joystick axis as Vector2
func get_joy_axis_vector_for_player(player_id: int, horizontal_axis: int, vertical_axis: int) -> Vector2:
	var axis_vector = Vector2()
	axis_vector.x = Input.get_joy_axis(player_id, horizontal_axis)
	axis_vector.y = Input.get_joy_axis(player_id, vertical_axis)

	return axis_vector


func _physics_process(delta):
	get_joystick_input() if !use_keyboard else get_keyboard_input()

#	velocity.y -= delta * gravity
	velocity = move_and_slide(velocity, Vector3(0, 1, 0))
