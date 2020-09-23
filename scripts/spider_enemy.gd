extends "res://scripts/actor.gd"

onready var collider = $Collider
onready var animation_player = $AnimationPlayer
onready var vision = $Vision

export (int) var speed = 30
export (int) var gravity = 20
export (int) var fire_min_range = 30
export (int) var fire_max_range = 50

var target: Spatial
var nav: Navigation
var firing = false

var nav_path: = []

func _ready():
	health = 300
	self.animation_player.play("Activate")
	self.vision.add_exception(self.collider)

	while true:
		yield(get_tree().create_timer(0.2), "timeout")
		if self.target && self.nav:
			var path_begin: = self.nav.get_closest_point(self.global_transform.origin)
			var path_end: = self.nav.get_closest_point(self.target.global_transform.origin)

			var p = self.nav.get_simple_path(path_begin, path_end, true)
			self.nav_path = Array(p)
			self.nav_path.invert()

func set_target(_target: Spatial) -> void:
	self.target = _target

func set_navigation(_nav: Navigation) -> void:
	self.nav = _nav

func _physics_process(delta):
	if self.target:
		var pos = self.global_transform.origin
		var target_pos = self.target.global_transform.origin

		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(pos, target_pos, [self])

		if (result.has('collider') && result.collider == self.target):
			var d = pos.distance_to(target_pos)
			if !self.firing && d <= self.fire_min_range:
				self.firing = true
			elif d > self.fire_max_range:
				self.firing = false
		else:
			self.firing = false

	if !self.firing && self.nav_path.size() > 1:
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

		var look_transform = self.global_transform.looking_at(to_watch, Vector3.UP)
		var q = Quat(self.global_transform.basis).slerp(Quat(look_transform.basis), 6 * delta)
		self.global_transform.basis = Basis(q)

		if self.nav_path.size() > 1:
			self.global_transform.origin = pos
	elif firing:
		var look_transform = self.global_transform.looking_at(self.target.global_transform.origin, Vector3.UP)
		var q = Quat(self.global_transform.basis).slerp(Quat(look_transform.basis), 6 * delta)
		self.global_transform.basis = Basis(q)

	if firing:
		self.nav_path = []
		self.animation_player.play("Firing")
	else:
		self.animation_player.play("Walk")
