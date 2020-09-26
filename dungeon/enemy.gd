extends KinematicBody
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

var dungeon: Dungeon
var spawn_point: Vector3
var player_spawn_distance: float
var state: int
var collider: CollisionShape

var nav_path: = []
var path_update_timer: float

func _ready():
	self.path_update_timer = 0
	self.spawn_point = get_navigation().get_closest_point(self.global_transform.origin)

	# Search for collision shape in scene
	for node in get_children():
		if node is CollisionShape:
			self.collider = node
			break

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
		return self.spawn_point

	return get_navigation().get_closest_point(get_player().global_transform.origin)

func _update_path():
	if !get_player() || !get_navigation():
		self.nav_path = []
		return

	var path_start: = get_navigation().get_closest_point(self.global_transform.origin)
	var path_end: = get_target()

	var p = get_navigation().get_simple_path(path_start, path_end, true)
	self.nav_path = _fix_path(p)
	self.nav_path.invert()

	var player_point = get_navigation().get_closest_point(get_player().global_transform.origin)
	var player_to_spawn = get_navigation().get_simple_path(player_point, self.spawn_point, true)

	self.player_spawn_distance = 0
	for i in range(0, player_to_spawn.size() - 1):
		self.player_spawn_distance += (player_to_spawn[i] - player_to_spawn[i + 1]).length()

# Fixes navigation path so that agents don't get stuck in corners. The problem
# is pretty well described in https://github.com/godotengine/godot/issues/1887.
# Usually the solution is to shrink the navigation mesh, but that doesn't work
# well if there are agents of different size.
func _fix_path(p: PoolVector3Array) -> Array:
	var path = Array(p)

	# Can't fix anything without a collision shape
	if !self.collider:
		return path

	# Build a parameter object needed for collision checks
	var space_state: = get_world().direct_space_state
	var qr = PhysicsShapeQueryParameters.new()
	qr.set_shape(self.collider.shape)
	qr.exclude = [self, get_player()]

	# For each point in the path, test if the agent would collide with a wall
	# at that point. If it would, then we move the point away from the wall until
	# there would be no collisions.
	for i in path.size():
		# We don't know the exact size of this agent, so we move it little by
		# little until it doesn't collide.
		while true:
			qr.transform = Transform(self.global_transform.basis, path[i] + Vector3(0, 3, 0))
			var rest_info = space_state.get_rest_info(qr)

			if !rest_info.has('collider_id'):
				# No collisions, so we can skip this point
				break

			# The surface normal sometimes has a non-zero y-value for whatever reason
			var normal = rest_info.normal
			normal.y = 0
			normal = normal.normalized()

			# Move the point away from the wall
			path[i] += rest_info.normal

	return path

func _is_target_visible() -> bool:
	if !get_player():
		return false

	var pos = self.global_transform.origin
	var target_pos = get_player().global_transform.origin
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(pos, target_pos, [self])

	return result.has('collider') && result.collider == get_player()

func _get_state() -> int:
	if !get_player():
		return STATE_IDLE

	var target_visible = _is_target_visible()
	var target_distance = self.global_transform.origin.distance_to(get_player().global_transform.origin)
	var spawn_distance = self.global_transform.origin.distance_to(self.spawn_point)

	var within_min_hunt_range = self.player_spawn_distance <= self.hunt_min_range
	var within_max_hunt_range = self.player_spawn_distance <= self.hunt_max_range
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

func rotate_towards(pos: Vector3, delta):
	var look_transform = self.global_transform.looking_at(pos, Vector3.UP)
	var q = Quat(self.global_transform.basis).slerp(Quat(look_transform.basis), 6 * delta)
	self.global_transform.basis = Basis(q)

func follow_path(delta):
	var to_walk = self.speed * delta

	while to_walk > 0 && self.nav_path.size() > 1:
		var from = self.nav_path[self.nav_path.size() - 1]
		var to = self.nav_path[self.nav_path.size() - 2]
		var dist = from.distance_to(to)

		if dist <= to_walk:
			self.nav_path.remove(self.nav_path.size() - 1)
			to_walk -= dist
		else:
			self.nav_path[self.nav_path.size() - 1] = from.linear_interpolate(to, to_walk / dist)
			to_walk = 0

	var pos = self.nav_path[self.nav_path.size() - 1]
	pos.y = self.global_transform.origin.y

	var to_watch = Vector3() + self.nav_path[self.nav_path.size() - 2]
	to_watch.y = self.global_transform.origin.y

	rotate_towards(to_watch, delta)

	if self.nav_path.size() > 1:
		self.global_transform.origin = pos

func _physics_process(delta):
	# Update navigation path every 0.5 seconds
	self.path_update_timer -= delta
	if self.path_update_timer <= 0:
		_update_path()
		self.path_update_timer = 0.5

	self.state = _get_state()

	if self.state == STATE_HUNT || self.state == STATE_RETURN:
		follow_path(delta)

	if self.state == STATE_ATTACK:
		rotate_towards(get_player().global_transform.origin, delta)
