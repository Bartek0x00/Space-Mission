extends RigidBody3D

@export var stage: int = 3
@export var asteroid_scene: PackedScene = preload("res://scenes/asteroid.tscn")

const SCORE: int = 10

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("bullet"):
		return

	if stage > 0:
		var hit_dir = (global_position - body.global_position).normalized()
		var perp = Vector3(-hit_dir.y, hit_dir.x, hit_dir.z)
		for offset in [-1, 1]:
			var asteroid = asteroid_scene.instantiate()
			asteroid.get_node("Mesh").scale = $Mesh.scale * 0.5
			asteroid.get_node("Collision").shape.radius = $Collision.shape.radius * 0.5
			asteroid.stage = stage - 1
			get_parent().add_child(asteroid)
			asteroid.global_position = global_position + perp * offset
			asteroid.linear_velocity = linear_velocity + perp * (2 * offset)
	else:
		var player = get_node("/root/Main").players[body.player_id]
		if not player.is_local:
			return
		get_node("/root/Main").rpc_id(1, "server_add_score", player.multiplayer.get_unique_id(), SCORE)
	queue_free()
