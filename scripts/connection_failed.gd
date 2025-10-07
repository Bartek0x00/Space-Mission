extends Control

func _on_try_again_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
	queue_free()
