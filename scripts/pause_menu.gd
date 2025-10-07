extends Control

var upgrade_menu_scene: PackedScene = preload("res://scenes/upgrade_menu.tscn")

enum SubSetting {
	NONE,
	UPGRADE
}

var current_setting: SubSetting = SubSetting.NONE

func toggle_visible() -> void:
	if visible:
		visible = false
		if current_setting == SubSetting.UPGRADE:
			$UpgradeMenu.queue_free()
			current_setting = SubSetting.NONE
	else:
		visible = true
		get_node("VBoxContainer").visible = true

func _on_menu_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
	get_node("/root/Main").remove()

func _on_upgrade_button_button_down() -> void:
	current_setting = SubSetting.UPGRADE
	$VBoxContainer.visible = false
	var upgrade_menu_obj = upgrade_menu_scene.instantiate()
	upgrade_menu_obj.name = "UpgradeMenu"
	add_child(upgrade_menu_obj)
	call_deferred("_update_score")

func _update_score() -> void:
	get_node("UpgradeMenu").update_score()

func _on_resume_button_button_down() -> void:
	get_node("../../.")._toggle_pause_menu()
