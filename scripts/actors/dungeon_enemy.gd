extends Agent
class_name DungeonEnemy

export (int) var speed = 30
export (int) var gravity = 20
export (int) var attack_min_range = 30
export (int) var attack_max_range = 50
export (int) var hunt_min_range = 50
export (int) var hunt_max_range = 150

const STATE_IDLE = 0
const STATE_RETURN = 1
const STATE_HUNT = 2
const STATE_ATTACK = 3

const PATH_UPDATE_INTERVAL: = 1.0

var dungeon: Dungeon
var spawn_point: Vector3
var state: int

var acceleration: = GSAITargetAcceleration.new()

onready var agent: = GSAIKinematicBody3DAgent.new(self)
onready var target_agent: = GSAIAgentLocation.new()
onready var proximity: = GSAICollisionProximity.new(agent, self)

# Enemy should follow path
onready var path_following_behavior: = GSAIFollowPath.new(
	agent,
	GSAIPath.new([self.global_transform.origin, self.global_transform.origin]),
	6.0
)

# Enemy should look where it's going
onready var look_behavior: = GSAILookWhereYouGo.new(agent, true)

# Enemy should avoid collisions
onready var avoidance_behavior: = GSAIAvoidCollisions.new(agent, proximity)

# Enemy should separate from other enemies
onready var separation_behavior: = GSAISeparation.new(agent, proximity)

# Enemy should face the player when attacking
onready var face_behavior: = GSAIFace.new(agent, target_agent, true)

onready var movement_steering: = GSAIBlend.new(agent)
onready var attack_steering: = GSAIBlend.new(agent)

func _ready():
	_setup_agent()
	self.spawn_point = self.global_transform.origin

func _setup_agent():
	# Setup movement steering (behavior when hunting or returning to spawn)
	self.look_behavior.alignment_tolerance = deg2rad(5)
	self.movement_steering.add(self.avoidance_behavior, 10)
	self.movement_steering.add(self.separation_behavior, 5)
	self.movement_steering.add(self.path_following_behavior, 1)
	self.movement_steering.add(self.look_behavior, 1)

	# Setup attack steering (behavior when attacking)
	self.face_behavior.alignment_tolerance = deg2rad(5)
	self.attack_steering.add(self.face_behavior, 1)

	self.agent.linear_speed_max = self.speed
	self.agent.linear_acceleration_max = self.speed * 10
	self.agent.linear_drag_percentage = 0.1
	self.agent.angular_speed_max = deg2rad(10000)
	self.agent.angular_acceleration_max = deg2rad(10000)
	self.agent.angular_drag_percentage = 0.5
	self.agent.bounding_radius = 2.0

	# Setup proximity collision shape. The shape needs to exist in scene tree.
	var proximity_shape = CylinderShape.new()
	proximity_shape.radius = self.agent.bounding_radius * 6
	proximity_shape.height = 0.1
	var proximity_collider = CollisionShape.new()
	proximity_collider.shape = proximity_shape
	var proximity_collider_node = Node.new()
	proximity_collider_node.add_child(proximity_collider)
	add_child(proximity_collider_node)

	self.proximity.shape = proximity_shape

func _update_target_agent():
	self.target_agent.position = get_player().global_transform.origin

func set_dungeon(_dungeon: Dungeon) -> void:
	self.dungeon = _dungeon

func get_navigation() -> Navigation:
	if !self.dungeon:
		return null

	return self.dungeon.get_navigation()

func get_player() -> Spatial:
	if !self.dungeon:
		return null

	return self.dungeon.get_players()[0]

func get_target() -> Vector3:
	if !self.dungeon || (self.state != STATE_HUNT && self.state != STATE_ATTACK):
		return get_navigation().get_closest_point(self.spawn_point)

	return get_navigation().get_closest_point(get_player().global_transform.origin)

func update_path(path: Array):
	self.path_following_behavior.path = GSAIPath.new(path, true)

func _is_target_visible() -> bool:
	if !get_player():
		return false

	var pos = self.global_transform.origin + Vector3(0, 1, 0)
	var target_pos = get_player().global_transform.origin + Vector3(0, 1, 0)
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(pos, target_pos, [self])

	return result.has('collider') && result.collider == get_player()

func _get_state() -> int:
	if !get_player():
		return STATE_IDLE

	var target_distance = self.global_transform.origin.distance_to(get_player().global_transform.origin)
	var spawn_distance = self.global_transform.origin.distance_to(self.spawn_point)

	var player_spawn_distance = get_player().global_transform.origin.distance_to(self.spawn_point)
	var target_visible = _is_target_visible()
	var within_min_hunt_range = player_spawn_distance <= self.hunt_min_range
	var within_max_hunt_range = player_spawn_distance <= self.hunt_max_range
	var within_attack_min_range = target_distance <= self.attack_min_range
	var within_attack_max_range = target_distance <= self.attack_max_range

	if self.state == STATE_IDLE:
		if target_visible && within_min_hunt_range && within_attack_min_range:
			return STATE_ATTACK
		if target_visible && within_min_hunt_range:
			return STATE_HUNT

	if self.state == STATE_RETURN:
		if target_visible && within_max_hunt_range && within_attack_max_range:
			return STATE_ATTACK
		if target_visible && within_max_hunt_range:
			return STATE_HUNT
		if spawn_distance < 3:
			return STATE_IDLE

	if self.state == STATE_HUNT:
		if !within_max_hunt_range:
			return STATE_RETURN
		if target_visible && within_attack_min_range:
			return STATE_ATTACK

	if self.state == STATE_ATTACK:
		if !target_visible && within_max_hunt_range:
			return STATE_HUNT
		if !within_attack_max_range && within_max_hunt_range:
			return STATE_HUNT
		if !within_max_hunt_range:
			return STATE_RETURN

	return self.state

func _physics_process(delta):
	_update_target_agent()

	self.state = _get_state()

	# Apply gravity
	self.acceleration.linear.y += self.gravity * delta

	if (self.state == STATE_HUNT || self.state == STATE_RETURN) && self.path_following_behavior.path.length > 0:
		self.movement_steering.calculate_steering(self.acceleration)
		self.agent._apply_steering(self.acceleration, delta)

	if self.state == STATE_ATTACK:
		self.attack_steering.calculate_steering(self.acceleration)
		self.agent._apply_steering(self.acceleration, delta)
