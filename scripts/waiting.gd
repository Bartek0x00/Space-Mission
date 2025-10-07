extends Control

@export var timeout: float = 6.0

var _current_time: float = 0.0

func _process(delta: float) -> void:
	_current_time += delta
	$VBoxContainer/Counter.text = "(%ds / %ds)" % [int(_current_time), int(timeout)]
	if (_current_time >= timeout):
		get_node("/root/Main").multiplayer.multiplayer_peer = null
		get_tree().change_scene_to_file("res://scenes/connection_failed.tscn")
		queue_free()
