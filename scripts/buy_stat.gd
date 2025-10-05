class_name StatContainer extends VBoxContainer

enum StatType {
	MAX_SPEED = 0
}

class StatData:
	var cost_table: Array[int]
	var mod_table: Array[float]
	var max_stage: int
	var stage: int
	
	func _init(_cost_table: Array[int], _mod_table: Array[float]) -> void:
		assert(_cost_table.size() == _mod_table.size())
		self.cost_table = _cost_table
		self.mod_table = _mod_table
		self.max_stage = _cost_table.size() - 1
		self.stage = 0

@export var stat_type: StatType

var stat_data: StatData

func _ready() -> void:
	stat_data = get_node("../../../..").stats[stat_type]

func set_stage(new_stage: int) -> void:
	if (new_stage < 0) && (new_stage > max_stage):
		return
	stage = new_stage
	$ColorRect/VBoxContainer/UpgradeLevel.text = "(%d / %d)" % [new_stage, max_stage]
	$ColorRect/VBoxContainer/UpgradeCost.text = "Cost (%d)" % cost_table[new_stage - 1]

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
