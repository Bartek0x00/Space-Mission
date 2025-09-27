extends Control

const PORT: int = 12345
var ip_addr: String = "127.0.0.1"
var nickname: String = ""

var packed_main: PackedScene = preload("res://scenes/main.tscn")

func _on_join_button_button_down() -> void:
	var main_instance = packed_main.instantiate()
	get_tree().root.add_child(main_instance)
	queue_free()
	main_instance.call_deferred("init_client", ip_addr, PORT, nickname)
	
func _on_host_button_button_down() -> void:
	var main_instance = packed_main.instantiate()
	get_tree().root.add_child(main_instance)
	queue_free()
	main_instance.call_deferred("init_server", PORT, nickname)

func _on_input_ip_text_changed(new_text: String) -> void:
	ip_addr = new_text

func _on_input_nickname_text_changed(new_text: String) -> void:
	nickname = new_text
