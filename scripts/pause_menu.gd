extends Control

func _on_menu_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
	get_node("/root/Main").remove()

func _on_unpause_button_button_down() -> void:
	get_node("../../.")._toggle_pause_menu()
