extends KinematicBody

export (int) var speed = 20
export (int) var gravity = 20

const DEAD_ZONE := 0.15
const use_keyboard := true
const test_weapon_cooldown := 2

onready var bullet = preload("res://actors/bullet.tscn")
onready var camera = preload("res://actors/player_camera.tscn")

var velocity := Vector3()
var test_weapon_cooldown_counter = 0.0

func _ready():
	var my_camera = camera.instance()
	my_camera.my_player = self #my_camera contains var to know whom to follow
	self.get_parent().call_deferred("add_child", my_camera)


func get_joystick_input():
	velocity = Vector3()

	var left_stick_vector: Vector2 = get_joy_axis_vector_for_player(0, 0, 1)
	var right_stick_vector: Vector2 = get_joy_axis_vector_for_player(0, 2, 3)

	if left_stick_vector.length() > DEAD_ZONE:
		velocity.x = left_stick_vector.x
		velocity.z = left_stick_vector.y

	if right_stick_vector.length() > DEAD_ZONE:
		# TODO: make this in a more sensible way
		self.rotation.y = Vector2(right_stick_vector.x, -right_stick_vector.y).angle() + PI / 2

	velocity = velocity.normalized() * speed

func get_keyboard_input(delta):
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
	if Input.is_action_pressed('shoot'):
		print(delta)
		print(test_weapon_cooldown_counter)
		if(test_weapon_cooldown_counter>test_weapon_cooldown):
			shoot()
	if velocity.length() > 0:
		self.rotation.y = Vector2(velocity.x, -velocity.z).angle() + PI / 2

	velocity = velocity.normalized() * speed
	velocity.y = velocity_y

func get_joy_axis_vector_for_player(player_id: int, horizontal_axis: int, vertical_axis: int) -> Vector2:
	var axis_vector = Vector2()
	axis_vector.x = Input.get_joy_axis(player_id, horizontal_axis)
	axis_vector.y = Input.get_joy_axis(player_id, vertical_axis)

	return axis_vector

func shoot():
	var shot = bullet.instance()
	shot.set_global_transform(self.global_transform)
	shot.transform.origin = self.transform.origin+Vector3(0,2,0)
	shot.my_shooter = self
	self.get_parent().add_child(shot)
	test_weapon_cooldown_counter = 0

func _physics_process(delta):
	test_weapon_cooldown_counter += delta
	get_joystick_input() if !use_keyboard else get_keyboard_input(delta)

	velocity.y -= delta * gravity
	velocity = move_and_slide(velocity, Vector3(0, 1, 0))
