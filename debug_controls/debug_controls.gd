extends Node

export var enabled: = true

# Simple world debug controls until some debug mode is implemented
func _unhandled_input(event):
	if enabled:
		if event.is_action_pressed("debug_exit_game"):
			get_tree().quit()
		if event.is_action_pressed("debug_reset_level") and \
			owner.has_method("reset_level"):
			owner.reset_level()
