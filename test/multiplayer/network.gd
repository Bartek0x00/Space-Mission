extends Control

@onready var msg_lbl: Label = $Label

func _ready():
	var args = OS.get_cmdline_args()
	if "--server" in args:
		var server = load("res://test/multiplayer/server.gd").new()
		add_child(server)
		server.msg_lbl = msg_lbl
		server.start_server()
	else:
		var client = load("res://test/multiplayer/client.gd").new()
		add_child(client)
		client.msg_lbl = msg_lbl
		client.start_client()
		
