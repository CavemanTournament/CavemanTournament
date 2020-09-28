class_name Bullet
extends Area

onready var timer = $Timer

var speed = 80
var lifetime = 3

func _ready():
	timer.set_wait_time(lifetime)
	timer.start()

func _physics_process(delta):
	self.transform.origin += self.transform.basis.z * speed * delta

func _on_bullet_body_entered(body):
	queue_free()

func _on_Timer_timeout():
	queue_free()

func _on_bullet_area_entered(area):
	var target = area.get_parent()
	if target is Agent:
		target.take_damage(100, "kinetic")
		queue_free()
