extends Node

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if get_node("/root/Main").process_mode != Node.PROCESS_MODE_DISABLED:
			get_node("/root/Main").process_mode = Node.PROCESS_MODE_DISABLED
		else:
			get_node("/root/Main").process_mode = Node.PROCESS_MODE_INHERIT
