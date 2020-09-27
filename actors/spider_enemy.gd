extends DungeonEnemy

onready var animation_player = $AnimationPlayer

func _ready():
	self.health = 300
	self.animation_player.play("Activate")

func _physics_process(delta):
	if self.state == STATE_HUNT || self.state == STATE_RETURN:
		self.animation_player.play("Walk")

	if self.state == STATE_ATTACK:
		self.animation_player.play("Firing")

	if self.state == STATE_IDLE:
		self.animation_player.play("Idle")
