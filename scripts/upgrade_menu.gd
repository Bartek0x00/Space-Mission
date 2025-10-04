extends Control

func _ready() -> void:
	$ScoreLabel.text = "Score: %d" % get_node("../../..").score

func _on_return_button_button_down() -> void:
	get_node("../VBoxContainer").visible = true
	queue_free()
