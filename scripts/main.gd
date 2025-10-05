extends Node3D

signal stat_changed(stat_type: StatContainer.StatType)

var players: Dictionary = {}

var local_nickname: String = "Player_1"

const SCENES: Dictionary = {
	"Player": preload("res://scenes/player.tscn"),
	"Collectable": preload("res://scenes/collectable.tscn"),
	"Asteroid": preload("res://scenes/asteroid.tscn"),
	"Bullet": preload("res://scenes/bullet.tscn"),
	"Failure": preload("res://scenes/connection_failed.tscn"),
	"Waiting": preload("res://scenes/waiting.tscn"),
	"Planet": preload("res://scenes/planet.tscn")
}

const STAT_COSTS: = [
	[10, 20, 30],
	[10, 20, 30, 40],
	[10, 20]
]

func init_server(port: int, nickname: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 32)
	if error != OK:
		push_error("Failed to create server: %s" % str(error))
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	if nickname.length() > 0:
		local_nickname = nickname
	else:
		local_nickname = "Player_%d" % peer.get_unique_id()
	spawn_player(1, true)

func init_client(addr: String, port: int, nickname: String) -> void:
	get_tree().change_scene_to_packed(SCENES["Waiting"])
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(addr, port)
	if error != OK:
		push_error("Failed to create client: %s" % str(error))
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	if nickname.length() > 0:
		local_nickname = nickname
	else:
		local_nickname = "Player_%d" % peer.get_unique_id()

func remove() -> void:
	multiplayer.multiplayer_peer = null
	queue_free()

func _on_connected_to_server() -> void:
	get_node("/root/Waiting").queue_free()

func _on_peer_connected(peer_id: int) -> void:
	assert(multiplayer.is_server())
	rpc_id(peer_id, "spawn_player", peer_id, true)
	for id in players.keys():
		if id == peer_id:
			continue
		rpc_id(id, "spawn_player", peer_id, false)
		rpc_id(peer_id, "spawn_player", id, false)
		players[peer_id].rpc_id(peer_id, "client_set_score", id, players[id].score)
		players[peer_id].rpc_id(peer_id, "client_set_health", id, players[id].health)
	players[peer_id].rpc_id(peer_id, "client_request_nickname")

func _on_peer_disconnected(peer_id: int) -> void:
	assert(multiplayer.is_server())
	rpc("despawn_player", peer_id)

func _on_server_disconnected() -> void:
	get_tree().change_scene_to_packed(SCENES["Failure"])
	queue_free()

@rpc("authority", "call_local", "reliable")
func spawn_player(peer_id: int, is_local: bool) -> void:
	if players.has(peer_id):
		return
	var player = SCENES["Player"].instantiate()
	player.name = "Player_%d" % peer_id
	player.is_local = is_local
	if is_local:
		player.nickname = local_nickname
	add_child(player)
	player.global_position = Vector3(0, 8, 0)
	players[peer_id] = player
	players[multiplayer.get_unique_id()].redraw_scoreboard()

@rpc("authority", "call_local", "reliable")
func despawn_player(peer_id: int) -> void:
	if not players.has(peer_id):
		return
	players[peer_id].queue_free()
	players.erase(peer_id)
	players[multiplayer.get_unique_id()].redraw_scoreboard()

@rpc("any_peer", "call_local", "unreliable_ordered")
func server_sync_player(peer_id: int, state: Dictionary) -> void:
	if not players.has(peer_id):
		return
	players[peer_id].rpc("client_sync_player", peer_id, state)

@rpc("any_peer", "call_local", "reliable")
func server_sync_nickname(peer_id: int, new_nickname: String) -> void:
	if players.has(peer_id):
		players[peer_id].nickname = new_nickname
	for id in players.keys():
		players[peer_id].rpc_id(peer_id, "client_sync_nickname", id, players[id].nickname)
		players[id].rpc_id(id, "client_sync_nickname", peer_id, new_nickname)

@rpc("any_peer", "call_local", "reliable")
func server_add_score(peer_id: int, value: int) -> void:
	if not players.has(peer_id):
		return
	var new_score = players[peer_id].score + value
	for id in players.keys():
		players[id].rpc_id(id, "client_set_score", peer_id, new_score)

@rpc("any_peer", "call_local", "reliable")
func server_sub_health(peer_id: int, value: int) -> void:
	if not players.has(peer_id):
		return
	var new_health = players[peer_id].health - value
	for id in players.keys():
		players[id].rpc_id(id, "client_set_health", peer_id, new_health)

@rpc("any_peer", "call_local", "reliable")
func server_spawn_bullet(peer_id: int, gun_transform: Transform3D, gun_speed: float) -> void:
	rpc("spawn_bullet", peer_id, gun_transform, gun_speed)

@rpc("authority", "call_local", "unreliable")
func spawn_bullet(peer_id: int, gun_transform: Transform3D, gun_speed: float) -> void:
	var bullet = SCENES["Bullet"].instantiate()
	bullet.player_id = peer_id
	add_child(bullet)
	bullet.global_transform = gun_transform
	var max_bullet_speed_stat = players[peer_id].stats[StatContainer.StatType.BULLET_SPEED]
	bullet.linear_velocity = -bullet.transform.basis.z * (gun_speed + (bullet.SPEED * max_bullet_speed_stat.mod_table[max_bullet_speed_stat.stage]))

@rpc("any_peer", "call_local", "reliable")
func server_change_stat(peer_id: int, type: StatContainer.StatType, new_stage: int) -> void:
	var stats = players[peer_id].stats[type]
	
	if (stats.bought_stage < new_stage):
		if (STAT_COSTS[type][stats.stage] <= players[peer_id].score):
			var new_score = players[peer_id].score - STAT_COSTS[type][stats.stage]
			for id in players.keys():
				players[id].rpc_id(id, "client_set_score", peer_id, new_score)
	rpc("client_change_stat", peer_id, type, new_stage)

@rpc("authority", "call_local", "reliable")
func client_change_stat(peer_id: int, type: StatContainer.StatType, new_stage: int) -> void:
	var tmp = get_node("/root/Main").players[peer_id].stats[type]
	tmp.stage = new_stage
	tmp.bought_stage = max(tmp.bought_stage, new_stage)
	if peer_id == multiplayer.multiplayer_peer.get_unique_id():
		stat_changed.emit(type)
