extends Node3D

signal player_connected(peer_id, player_info)

var players = {}
var players_count: int = 0

var player_info = {"nickname": "Rafau"}

func _ready() -> void:
	player_connected.connect(_on_player_connected)

func init_server(port: int = 12345) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 32)
	if error:
		print(error)
	else:
		print("Server waiting for connection...")
		multiplayer.multiplayer_peer = peer
		players[1] = player_info
		player_connected.emit(1, player_info)

func init_client(addr: String = "127.0.0.1", port: int = 12345) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(addr, port)
	if error:
		print(error)
	else:
		print("Connected to the server")
		multiplayer.multiplayer_peer = peer

func _on_player_connected(peer_id, player_info) -> void:
	print("Player %s (%d) connected", player_info.nickname, peer_id)
