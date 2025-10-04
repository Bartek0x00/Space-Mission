extends Control

var upgrade_menu_scene: PackedScene = preload("res://scenes/upgrade_menu.tscn")

func _on_menu_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
	get_node("/root/Main").remove()

func _on_upgrade_button_button_down() -> void:
	$VBoxContainer.visible = false
	add_child(upgrade_menu_scene.instantiate())

func _on_resume_button_button_down() -> void:
	get_node("../../.")._toggle_pause_menu()
