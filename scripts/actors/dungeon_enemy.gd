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

const DetourCrowdAgent: NativeScript = preload("res://addons/godotdetour/detourcrowdagent.gdns")
const DetourCrowdAgentParameters: NativeScript = preload("res://addons/godotdetour/detourcrowdagentparameters.gdns")

var dungeon: Dungeon
var spawn_point: Vector3
var state: int
var nav_path: = []
var player_visible: bool
var g: ImmediateGeometry

var detour_agent

func _ready() -> void:
	var params = DetourCrowdAgentParameters.new()
	params.position = self.global_transform.origin
	params.radius = 1.0
	params.height = 1.0
	params.maxAcceleration = 100.0
	params.maxSpeed = 20.0
	params.filterName = "default"
	params.anticipateTurns = false
	params.optimizeVisibility = false
	params.optimizeTopology = false
	params.avoidObstacles = true
	params.avoidOtherAgents = true
	params.obstacleAvoidance = 10
	params.separationWeight = 1.0
	self.detour_agent = self.dungeon.navigation.addAgent(params)
	self.spawn_point = self.global_transform.origin

	var timer = Timer.new()
	timer.connect("timeout", self, "_on_timer_update_target")
	timer.set_wait_time(0.5)
	add_child(timer)
	timer.start()

#	self.g = ImmediateGeometry.new()
#	var m = SpatialMaterial.new()
#	m.vertex_color_use_as_albedo = true
#	self.g.set_material_override(m)
#	get_parent().add_child(self.g)

func _on_timer_update_target():
	self.player_visible = _is_player_visible()

	if self.state == STATE_HUNT:
		self.detour_agent.moveTowards(get_player().global_transform.origin)
	if self.state == STATE_RETURN:
		self.detour_agent.moveTowards(self.spawn_point)
	if self.state == STATE_ATTACK && self.detour_agent.isMoving:
		self.detour_agent.stop()
	if self.state == STATE_IDLE && self.detour_agent.isMoving:
		self.detour_agent.stop()

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

func get_enemies() -> Array:
	if !self.dungeon:
		return []

	return self.dungeon.get_enemies()

func get_target() -> Vector3:
	if !self.dungeon || (self.state != STATE_HUNT && self.state != STATE_ATTACK):
		return self.spawn_point

	return get_navigation().get_closest_point(get_player().global_transform.origin)

func _is_player_visible() -> bool:
	if !get_player():
		return false

	var pos = self.global_transform.origin + Vector3(0, 1, 0)
	var target_pos = get_player().global_transform.origin + Vector3(0, 1, 0)
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(pos, target_pos, get_enemies())

	return result.has('collider') && result.collider == get_player()

func _get_state() -> int:
	if !get_player():
		return STATE_IDLE

	var target_distance = self.global_transform.origin.distance_to(get_player().global_transform.origin)
	var spawn_distance = self.global_transform.origin.distance_to(self.spawn_point)
	var player_spawn_distance = get_player().global_transform.origin.distance_to(self.spawn_point)

	var within_min_hunt_range = player_spawn_distance <= self.hunt_min_range
	var within_max_hunt_range = player_spawn_distance <= self.hunt_max_range
	var within_attack_min_range = target_distance <= self.attack_min_range
	var within_attack_max_range = target_distance <= self.attack_max_range

#	if within_min_hunt_range:
#		self.g.clear()
#		self.g.begin(Mesh.PRIMITIVE_LINES)
#		if target_visible:
#			self.g.set_color(Color(0, 1, 0))
#		else:
#			self.g.set_color(Color(1, 0, 0))
#		self.g.add_vertex(self.global_transform.origin + Vector3(0, 1, 0))
#		self.g.add_vertex(get_player().global_transform.origin + Vector3(0, 1, 0))
#		self.g.end()

	if self.state == STATE_IDLE:
		if self.player_visible && within_min_hunt_range && within_attack_min_range:
			return STATE_ATTACK
		if self.player_visible && within_min_hunt_range:
			return STATE_HUNT

	if self.state == STATE_RETURN:
		if self.player_visible && within_max_hunt_range && within_attack_max_range:
			return STATE_ATTACK
		if self.player_visible && within_max_hunt_range:
			return STATE_HUNT
		if spawn_distance < 3:
			return STATE_IDLE

	if self.state == STATE_HUNT:
		if !within_max_hunt_range:
			return STATE_RETURN
		if self.player_visible && within_attack_min_range:
			return STATE_ATTACK

	if self.state == STATE_ATTACK:
		if !self.player_visible && within_max_hunt_range:
			return STATE_HUNT
		if !within_attack_max_range && within_max_hunt_range:
			return STATE_HUNT
		if !within_max_hunt_range:
			return STATE_RETURN

	return self.state

func rotate_towards(pos: Vector3, delta):
	var look_transform = self.global_transform.looking_at(pos, Vector3.UP)
	var q = Quat(self.global_transform.basis).slerp(Quat(look_transform.basis), 6 * delta)
	self.global_transform.basis = Basis(q)

func _process(delta):
	if !self.detour_agent:
		return

	self.global_transform.origin = self.detour_agent.position

	if self.state == STATE_ATTACK:
		rotate_towards(get_player().global_transform.origin, delta)
	elif self.detour_agent.isMoving:
		look_at(self.global_transform.origin + self.detour_agent.velocity, self.global_transform.basis.y)

func _physics_process(delta):
	if !self.detour_agent:
		return

	self.state = _get_state()

