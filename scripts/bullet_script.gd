class_name bullet
extends Area

var speed = 80
var life_time = 3
var my_shooter
onready var timer = get_node("Timer")

func _ready():
	timer.set_wait_time(life_time)
	timer.start()
	

func _physics_process(delta):
	self.transform.origin += self.transform.basis.z * speed * delta


func _on_bullet_body_entered(body):
	print("blet")
	if body != my_shooter:
		print("oo o o o")
		queue_free()


func _on_Timer_timeout():
	queue_free()
