extends Node

var msg_lbl: Label

const PORT = 4213
const MAX_PLAYER_COUNT = 2

func start_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYER_COUNT)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int):
	msg_lbl.text = "Client connected: %d" % id
	await get_tree().create_timer(0.3).timeout
	rpc("broadcast_message", "Hello from server!")

func _on_peer_disconnected(id: int):
	msg_lbl.text = "Client disconnected: %d" % id

@rpc("any_peer")
func broadcast_message(msg: String):
		msg_lbl.text = "RPC received: " + msg
