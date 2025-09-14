extends Control

const PORT: int = 12345
const IP_ADDR: String = "127.0.0.1"

var packed_main: PackedScene = preload("res://scenes/main.tscn")

func _on_join_button_button_down() -> void:
	var main_instance = packed_main.instantiate()
	get_tree().root.add_child(main_instance)
	queue_free()
	main_instance.call_deferred("init_client", IP_ADDR, PORT)
	
func _on_host_button_button_down() -> void:
	var main_instance = packed_main.instantiate()
	get_tree().root.add_child(main_instance)
	queue_free()
	main_instance.call_deferred("init_server", PORT)
