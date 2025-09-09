extends Node

var msg_lbl: Label

const IP_ADDR = "127.0.0.1"
const PORT = 4213

func start_client():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDR, PORT)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	msg_lbl.text = "Connecting to a server..."

func _on_connected():
	msg_lbl.text = "Connected to server!"
	await get_tree().create_timer(0.3).timeout
	rpc("broadcast_message", "Hello from client!")

func _on_connection_failed():
	msg_lbl.text  = "Connection failed!"

func _on_server_disconnected():
	msg_lbl.text = "Disconnected from server!"

@rpc("any_peer")
func broadcast_message(msg: String):
		msg_lbl.text = "RPC received: " + msg
