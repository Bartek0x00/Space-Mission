class_name StatContainer extends VBoxContainer

enum StatType {
	MAX_SPEED = 0,
	BULLET_SPEED,
	BULLET_DAMAGE
}

class StatData:
	var cost_table: Array[int]
	var mod_table: Array[float]
	var max_stage: int
	var stage: int
	var bought_stage: int
	
	func _init(_cost_table: Array[int], _mod_table: Array[float]) -> void:
		self.cost_table = _cost_table
		self.mod_table = _mod_table
		self.max_stage = _mod_table.size() - 1
		self.stage = 0
		self.bought_stage = 0

@export var stat_type: StatType
@export var stat_name: String
@export var bg_color: Color

var stat_data: StatData

@onready var upgrade_name = $ColorRect/VBoxContainer/UpgradeName
@onready var upgrade_level = $ColorRect/VBoxContainer/UpgradeLevel
@onready var upgrade_cost = $ColorRect/VBoxContainer/UpgradeCost

func _ready() -> void:
	get_node("/root/Main").stat_changed.connect(_on_stat_changed)
	_on_stat_changed(stat_type)

func _on_stat_changed(_stat_type: StatType) -> void:
	if _stat_type != stat_type:
		return
	stat_data = get_node("../../../../..").stats[_stat_type]
	set_ui()

func set_ui() -> void:
	$ColorRect.color = bg_color
	get_node("../..").update_score()
	upgrade_name.text = stat_name
	upgrade_level.text = "(%d / %d)" % [stat_data.stage, stat_data.max_stage]
	if stat_data.stage < stat_data.max_stage:
		if stat_data.stage == stat_data.bought_stage:
			upgrade_cost.text = "Cost (%d)" % stat_data.cost_table[stat_data.stage]
			return
	
	upgrade_cost.text = ""

func _on_upgrade_button_button_down() -> void:
	if stat_data.stage >= stat_data.max_stage:
		return
	if stat_data.stage == stat_data.bought_stage:
		if stat_data.cost_table[stat_data.stage] > get_node("../..").score:
			return
	get_node("/root/Main").rpc_id(1, "server_change_stat", multiplayer.multiplayer_peer.get_unique_id(), stat_type, stat_data.stage + 1)

func _on_downgrade_button_button_down() -> void:
	if stat_data.stage <= 0:
		return
	get_node("/root/Main").rpc_id(1, "server_change_stat", multiplayer.multiplayer_peer.get_unique_id(), stat_type, stat_data.stage - 1)
