extends CharacterBody3D

var is_local: bool = false
var nickname: String = "Player"

const MOUSE_SENSITIVITY: float = 0.05
const THROTTLE_SENSITIVITY: float = 0.5
const MAX_THROTTLE: float = 50.0
const ROTATION_SENSITIVITY: float = 0.01

var throttle: float = 0.0

const SHOOT_COOLDOWN: float = 0.4
var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var bullet_cooldown: float
var last_shot_time: float = -1.0

var score: int = 0

var global_seed: int = 123456789
var last_chunk: Vector3i = Vector3i(1 << 30, 1 << 30, 1 << 30)

var rot_vector: Vector2 = Vector2.ZERO

var _sync_timer: float = 0.0
var _sync_interval: float = 0.020

func _ready() -> void:
	if is_local:
		var img = preload("res://assets/ui/crosshair2.png").get_image()
		img.resize(32, 32, Image.INTERPOLATE_BILINEAR)
		DisplayServer.cursor_set_custom_image(img, DisplayServer.CURSOR_ARROW, Vector2(16, 16))
		get_parent().rpc_id(1, "server_sync_nickname", multiplayer.get_unique_id(), nickname)
	
	$UI/Nickname.text = nickname
	$UI.visible = is_local
	
	$NickNameTag.text = nickname
	$NickNameTag.visible = not is_local

func _on_tree_exiting() -> void:
	if is_local:
		DisplayServer.cursor_set_custom_image(null)

func _input(event: InputEvent) -> void:
	if not is_local:
		return
	
	if event.is_action_released("shoot"):
		shoot_bullets()

func _physics_process(delta: float) -> void:
	if not is_local:
		return
	
	if get_window().has_focus():
		var mouse_pos = get_viewport().get_mouse_position()
		var screen_center = get_window().size * 0.5
		if get_viewport().get_visible_rect().has_point(mouse_pos):
			rot_vector = (mouse_pos - screen_center) * Vector2(-1, -1)
		var screen_size = get_viewport().get_visible_rect().size
		rot_vector.x /= screen_size.x
		rot_vector.y /= screen_size.y
	
	var local_right = (quaternion * Vector3.RIGHT).normalized()
	var local_up = (quaternion * Vector3.UP).normalized()
	var local_forward = (quaternion * Vector3.FORWARD).normalized()
	
	quaternion = Quaternion(local_up, rot_vector.x * MOUSE_SENSITIVITY) * quaternion
	quaternion = Quaternion(local_right, rot_vector.y * MOUSE_SENSITIVITY) * quaternion
	quaternion = Quaternion(local_forward, -rot_vector.x * 0.00005) * quaternion
	
	if Input.is_action_pressed("ui_left"):
		quaternion = Quaternion(local_forward, -ROTATION_SENSITIVITY) * quaternion
	if Input.is_action_pressed("ui_right"):
		quaternion = Quaternion(local_forward, ROTATION_SENSITIVITY) * quaternion
	
	quaternion = quaternion.normalized()
	
	if Input.is_action_pressed("throttle_down"):
		throttle -= THROTTLE_SENSITIVITY
		throttle = clamp(throttle, 0.0, MAX_THROTTLE)
		$UI/Throttle.value = throttle
	if Input.is_action_pressed("throttle_up"):
		throttle += THROTTLE_SENSITIVITY
		throttle = clamp(throttle, 0.0, MAX_THROTTLE)
		$UI/Throttle.value = throttle
	
	velocity = -basis.z * throttle
	move_and_slide()
	
	_sync_timer += delta
	if _sync_timer >= _sync_interval:
		_sync_timer = 0.0
		var snapshot = {
			"t": Time.get_ticks_msec(),
			"p": global_position,
			"q": quaternion,
			"v": velocity
		}
		get_parent().rpc_id(1, "server_sync_player", multiplayer.get_unique_id(), snapshot)
	
	var current_chunk = get_parent().get_node("ChunkManager").get_chunk_coords(global_transform.origin)
	if current_chunk != last_chunk:
		get_parent().get_node("ChunkManager").generate_chunk(global_seed, global_transform.origin)
		last_chunk = current_chunk

@rpc("authority", "call_local", "reliable")
func client_request_nickname() -> void:
	get_parent().rpc_id(1, "server_sync_nickname", multiplayer.get_unique_id(), nickname)

@rpc("authority", "call_local", "reliable")
func client_sync_nickname(peer_id: int, new_nickname: String) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	if not get_parent().players.has(peer_id):
		return
	get_parent().players[peer_id].nickname = new_nickname
	get_parent().players[peer_id].get_node("NickNameTag").text = new_nickname
	redraw_scoreboard()

@rpc("authority", "call_local", "unreliable_ordered")
func client_sync_player(peer_id: int, state: Dictionary) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	var tmp_players = get_parent().players
	if not tmp_players.has(peer_id):
		return
	tmp_players[peer_id].global_position = state["p"]
	tmp_players[peer_id].quaternion = state["q"]
	tmp_players[peer_id].velocity = state["v"]

@rpc("authority", "call_local", "reliable")
func client_set_score(peer_id: int, new_value: int) -> void:
	get_parent().players[peer_id].score = new_value
	redraw_scoreboard()

func shoot_bullets() -> void:
	if not is_local:
		return
	
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_shot_time >= SHOOT_COOLDOWN:
		for gun in $Guns.get_children():
			get_parent().rpc_id(1, "server_spawn_bullet", multiplayer.get_unique_id(), gun.global_transform)
		last_shot_time = now

func redraw_scoreboard() -> void:
	if not is_local:
		return
	for label in $UI/ScoreBoard.get_children():
		label.queue_free()
	
	var list = get_parent().players.values()
	list.sort_custom(func (a, b): return a.score > b.score)
	for player in list:
		var label = Label.new()
		label.text = "%s: %d" % [player.nickname, player.score]
		$UI/ScoreBoard.add_child(label)
