extends RigidBody3D

const MAX_ROTATION_SPEED: float = 10.0
const SCORE: int = 5

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	queue_free()
	if not body.is_local:
		return
	get_node("/root/Main").rpc_id(1, "server_add_score", body.multiplayer.get_unique_id(), SCORE)
