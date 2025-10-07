extends Control

const PORT: int = 12345
const MAX_PLAYERS: int = 32

var ip_addr: String = "127.0.0.1"
var nickname: String = ""

var packed_main: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	if OS.has_feature("server"):
		var main_instance = packed_main.instantiate()
		get_tree().root.add_child.call_deferred(main_instance)
		queue_free()
		main_instance.call_deferred("init_server", PORT, MAX_PLAYERS, false, nickname)

func _on_join_button_button_down() -> void:
	var main_instance = packed_main.instantiate()
	get_tree().root.add_child(main_instance)
	queue_free()
	main_instance.call_deferred("init_client", ip_addr, PORT, nickname)

func _on_host_button_button_down() -> void:
	var main_instance = packed_main.instantiate()
	get_tree().root.add_child(main_instance)
	queue_free()
	main_instance.call_deferred("init_server", PORT, MAX_PLAYERS, true, nickname)

func _on_input_ip_text_changed(new_text: String) -> void:
	ip_addr = new_text

func _on_input_nickname_text_changed(new_text: String) -> void:
	nickname = new_text

func _on_quit_button_down() -> void:
	get_tree().quit()

func _on_single_player_button_down() -> void:
	nickname = "Player"
	var main_instance = packed_main.instantiate()
	get_tree().root.add_child(main_instance)
	queue_free()
	main_instance.call_deferred("init_server", randi_range(12346, 45321), 1, true, nickname)

func _on_local_co_op_button_down() -> void:
	$ServerRemoteSettings.visible = false
	$GeneralSettings.visible = false
	$LocalRemoteSettings.visible = true

func get_mock(encoded: String) -> String:
	var decoded = ""
	for c in encoded:
		decoded += char((ord(c) - 3) % 256)
	return decoded

func _on_multi_player_button_down() -> void:
	ip_addr = get_mock("48;15531<;183")
	$LocalRemoteSettings.visible = false
	$GeneralSettings.visible = false
	$ServerRemoteSettings.visible = true

func _on_back_button_button_down() -> void:
	$LocalRemoteSettings.visible = false
	$ServerRemoteSettings.visible = false
	$GeneralSettings.visible = true
