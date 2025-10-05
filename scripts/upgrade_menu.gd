extends Control

var score: int

func _ready() -> void:
	update_score()

func update_score() -> void:
	score = get_node("../../..").score
	$ScoreLabel.text = "Score: %d" % score

func _on_return_button_button_down() -> void:
	get_node("../VBoxContainer").visible = true
	queue_free()
