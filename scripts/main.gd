extends Node3D

var players: Dictionary = {}

var local_nickname: String = "Player_1"

var player_scene: PackedScene = preload("res://scenes/player.tscn")
var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
var failure_scene: PackedScene = preload("res://scenes/connection_failed.tscn")
var waiting_scene: PackedScene = preload("res://scenes/waiting.tscn")

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
	get_tree().change_scene_to_packed(waiting_scene)
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

func _on_connected_to_server() -> void:
	get_node("/root/Waiting").queue_free()

func _on_peer_connected(peer_id: int) -> void:
	assert(multiplayer.is_server())
	rpc_id(peer_id, "spawn_player", peer_id, true)
	for id in players.keys():
		if id == peer_id:
			continue
		rpc_id(peer_id, "spawn_player", id, false)
	rpc("spawn_player", peer_id, false)

func _on_peer_disconnected(peer_id: int) -> void:
	assert(multiplayer.is_server())
	rpc("despawn_player", peer_id)

func _on_server_disconnected() -> void:
	get_tree().change_scene_to_packed(failure_scene)
	queue_free()

@rpc("authority", "call_local", "reliable")
func spawn_player(peer_id: int, is_local: bool) -> void:
	if players.has(peer_id):
		return
	var player = player_scene.instantiate()
	player.name = "Player_%d" % peer_id
	player.is_local = is_local
	if is_local:
		player.nickname = local_nickname
	add_child(player)
	player.global_position = Vector3(0, 8, 0)
	players[peer_id] = player

@rpc("authority", "call_local", "reliable")
func despawn_player(peer_id: int) -> void:
	if not players.has(peer_id):
		return
	players[peer_id].queue_free()
	players.erase(peer_id)

@rpc("any_peer", "call_local", "reliable")
func server_sync_nickname(peer_id: int, new_nickname: String) -> void:
	if not players.has(peer_id):
		return
	for id in players.keys():
		players[id].rpc_id(id, "client_sync_nickname", peer_id, new_nickname)

@rpc("any_peer", "call_local", "unreliable_ordered")
func server_sync_player(peer_id: int, state: Dictionary) -> void:
	if not players.has(peer_id):
		return
	players[peer_id].rpc("client_sync_player", peer_id, state)

@rpc("any_peer", "unreliable")
func network_update_transform(peer_id: int, xform: Transform3D) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	
	if not players.has(peer_id):
		var remote = player_scene.instantiate()
		remote.is_local_player = false
		remote.player_id = peer_id
		remote.get_node("NickNameTag").visible = true
		add_child(remote)
		players[peer_id] = remote
	players[peer_id].global_transform = xform

@rpc("authority")
func server_add_score(peer_id: int, value: int) -> void:
	if not multiplayer.is_server():
		return
	
	if not players.has(peer_id):
		return
	
	players[peer_id].score += value
	var new_score = players[peer_id].score
	rpc("update_score", peer_id, new_score)

@rpc("any_peer", "call_local")
func update_score(peer_id: int, new_score: int) -> void:
	if not players.has(peer_id):
		return
	
	players[peer_id].score = new_score
	if players[peer_id].has_method("_on_score_updated"):
		players[peer_id]._on_score_updated(new_score)

@rpc("authority")
func server_request_shoot(player_id: int, gun_transform: Transform3D) -> void:
	if not multiplayer.is_server():
		return
	rpc("spawn_bullet", player_id, gun_transform)

@rpc("any_peer", "call_local", "unreliable")
func spawn_bullet(_player_id: int, gun_transform: Transform3D) -> void:
	if bullet_scene == null:
		return
	
	var bullet = bullet_scene.instantiate()
	add_child(bullet)
	bullet.global_transform = gun_transform
	if "linear_velocity" in bullet:
		bullet.linear_velocity = -bullet.transform.basis.z * bullet.SPEED
