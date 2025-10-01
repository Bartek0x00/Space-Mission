extends RigidBody3D

@export var stage: int = 2
@export var asteroid_scene: PackedScene = preload("res://scenes/asteroid.tscn")

func resize(ratio: float) -> void:
	$Mesh.scale *= ratio
	$Collision.shape.radius *= ratio

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("bullet"):
		return

	if stage > 0:
		var hit_dir = (global_position - body.global_position).normalized()
		var perp = Vector3(-hit_dir.y, hit_dir.x, hit_dir.z)

		for offset in [-1, 1]:
			var asteroid = asteroid_scene.instantiate()
			get_parent().add_child(asteroid)
			
			asteroid.resize(0.5)
			asteroid.stage = stage - 1
			
			asteroid.global_position = global_position + perp * offset
			asteroid.linear_velocity = linear_velocity + perp * (2 * offset)
	queue_free()
