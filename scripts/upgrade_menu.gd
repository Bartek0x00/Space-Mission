extends Control

var score: int

func update_score() -> void:
	score = get_node("../../..").score
	$ScoreLabel.text = "Score: %d" % score

func _on_return_button_button_down() -> void:
	get_node("../VBoxContainer").visible = true
	get_parent().current_setting = get_parent().SubSetting.NONE
	queue_free()
