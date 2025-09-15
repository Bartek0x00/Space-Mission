extends Node3D

var players = {}

@export var player_scene: PackedScene = preload("res://scenes/player.tscn")

func _ready() -> void:
	multiplayer.connected_to_server.connect(_spawn_local_player)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func init_server(port: int = 12345) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 32)
	if error != OK:
		push_error(error)
		return
	multiplayer.multiplayer_peer = peer
	_spawn_local_player()

func init_client(addr: String = "127.0.0.1", port: int = 12345) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(addr, port)
	if error != OK:
		push_error(error)
		return
	multiplayer.multiplayer_peer = peer


func _spawn_local_player() -> void:
	var my_id = multiplayer.get_unique_id()
	if players.has(my_id):
		return
	var player = player_scene.instantiate()
	player.is_local_player = true
	player.player_id = my_id
	add_child(player)
	players[my_id] = player

@rpc("any_peer", "call_local", "unreliable")
func network_update_transform(peer_id: int, xform: Transform3D) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	
	if not players.has(peer_id):
		var remote = player_scene.instantiate()
		remote.is_local_player = false
		remote.player_id = peer_id
		add_child(remote)
		players[peer_id] = remote
	
	players[peer_id].global_transform = xform

func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
