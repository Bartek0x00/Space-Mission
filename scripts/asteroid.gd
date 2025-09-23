extends RigidBody3D

const MULTIPLIER: float = 20.0
@export var stage: int = 2
@export var asteroid_scene: PackedScene = preload("res://scenes/asteroid.tscn")

func get_random_vec3(max_val: float) -> Vector3:
	return Vector3(randf() * max_val, randf() * max_val, randf() * max_val) * max_val

func resize(ratio: float) -> void:
	$Mesh.scale *= ratio
	$Collision.shape.radius *= ratio

func _ready() -> void:
	linear_velocity.z = randf() * MULTIPLIER
	#angular_velocity = get_random_vec3(MULTIPLIER / 4)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("bullet"):
		return
	if stage > 0:
		for i in range((randi() % 3) + 1):
			var asteroid = asteroid_scene.instantiate()
			get_node("/root/Main").add_child(asteroid)
			asteroid.global_position = global_position + get_random_vec3(2.0)
			asteroid.resize(0.5)
			asteroid.stage = stage - 1
	queue_free()
