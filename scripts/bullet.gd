extends RigidBody3D

const SPEED: float = 80.0
const DAMAGE: float = 10.0
const TIMEOUT: float = 4.0

var player_id: int

func _ready() -> void:
	await get_tree().create_timer(TIMEOUT).timeout
	queue_free()

func _on_body_entered(body: Node) -> void:
	queue_free()
	
	if not body.is_in_group("player"):
		return
	if body.multiplayer.multiplayer_peer.get_unique_id() == player_id:
		return
	var bullet_damage_stat = get_node("/root/Main").players[player_id].stats[StatContainer.StatType.BULLET_DAMAGE]
	var damage_mul = bullet_damage_stat.mod_table[bullet_damage_stat.stage]
	get_node("/root/Main").rpc_id(1, "server_sub_health", body.multiplayer.get_unique_id(), (DAMAGE * damage_mul))
