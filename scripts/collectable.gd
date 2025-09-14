extends RigidBody3D

@export var MAX_ROTATION_SPEED: float = 10.0
@export var SCORE: int = 50

func _ready() -> void:
	angular_velocity = Vector3(
		randf() * 2 - 1,
		randf() * 2 - 1,
		randf() * 2 - 1
	) * randf() * MAX_ROTATION_SPEED



func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.add_score(SCORE)
		queue_free()
