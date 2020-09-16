extends Agent
class_name Player

export (int) var speed = 20
export (int) var gravity = 20

onready var model: Spatial = get_node("Model")
onready var state_machine: AnimationNodeStateMachinePlayback = get_node("AnimationTree")["parameters/playback"]

var velocity := Vector3()
const DEAD_ZONE := 0.15

var dodge_speed := 50.0
var dodge_duration := 0.4
var dodge_timer := 0.0
var is_dodging := false

const use_keyboard := true

onready var PlayerCamera = preload("res://scenes/actors/player_camera.tscn")
onready var weapon_hand: Spatial = get_node("Model/Weapon_Slot")
var items = []

func _ready():
	health = 1000
	var camera = PlayerCamera.instance()
	camera.my_player = self
	self.get_parent().call_deferred("add_child", camera)

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
		shoot()
	if velocity.length() > 0:
		self.rotation.y = Vector2(velocity.x, -velocity.z).angle() + PI / 2

	velocity = velocity.normalized() * speed
	velocity.y = velocity_y


# Gets joystick axis as Vector2
func get_joy_axis_vector_for_player(player_id: int, horizontal_axis: int, vertical_axis: int) -> Vector2:
	var axis_vector = Vector2()
	axis_vector.x = Input.get_joy_axis(player_id, horizontal_axis)
	axis_vector.y = Input.get_joy_axis(player_id, vertical_axis)

	return axis_vector

func shoot():
	weapon_hand.get_child(0).shoot()

func handle_dodge(_delta: float):
	if Input.is_action_just_pressed('dodge') && !is_dodging:
		is_dodging = true
		dodge_timer = 0
		state_machine.travel('dodge')

	if is_dodging:
		dodge_timer += _delta
		velocity = velocity.normalized() * dodge_speed
	
	if dodge_timer > dodge_duration:
		is_dodging = false

func _physics_process(_delta):
	if !is_dodging:
		get_joystick_input() if !use_keyboard else get_keyboard_input()

	handle_dodge(_delta)

	velocity.y -= delta * gravity
	velocity = move_and_slide(velocity, Vector3(0, 1, 0))
