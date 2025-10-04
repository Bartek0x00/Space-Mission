extends VBoxContainer

enum StatType {
	MAX_SPEED = 0
}

@export var stat_type: StatType
@export var cost_table: Array[int]

var stage: int = 0
var max_stage: int = 0

func _ready() -> void:
	max_stage = cost_table.size()
	set_stage(get_node("../../../../..").stats[stat_type])

func set_stage(new_stage: int) -> void:
	if (new_stage < 0) && (new_stage > max_stage):
		return
	stage = new_stage
	$ColorRect/VBoxContainer/UpgradeLevel.text = "(%d / %d)" % [new_stage, max_stage]
	$ColorRect/VBoxContainer/UpgradeCost.text = "Cost (%d)" % cost_table[new_stage]

func _on_upgrade_button_button_down() -> void:
	if (stage >= max_stage):
		return
	rpc_id(1, "server_change_stat", multiplayer.multiplayer_peer.get_unique_id(), stat_type, stage + 1)

func _on_downgrade_button_button_down() -> void:
	if (stage <= 0):
		return
	rpc_id(1, "server_change_stat", multiplayer.multiplayer_peer.get_unique_id(), stat_type, stage - 1)

@rpc("any_peer", "call_local", "reliable")
func server_change_stat(peer_id: int, type: StatType, new_stage: int) -> void:
	rpc("client_change_stat", peer_id, type, new_stage)

@rpc("authority", "call_local", "reliable")
func client_change_stat(peer_id: int, type: StatType, new_stage: int) -> void:
	get_node("/root/Main").players[peer_id].stats[type] = new_stage
	if peer_id == multiplayer.multiplayer_peer.get_unique_id():
		if stat_type == type:
			set_stage(new_stage)
