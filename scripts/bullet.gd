extends RigidBody3D

@export var SPEED: float = 30.0
@export var TIMEOUT: float = 4.0

func _ready() -> void:
	await get_tree().create_timer(TIMEOUT).timeout
	queue_free()
