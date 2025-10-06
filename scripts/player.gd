class_name Player extends CharacterBody3D

var is_local: bool = false
var nickname: String = "Player"

const MOUSE_SENSITIVITY: float = 0.05
const ACCEL_SENSITIVITY: float = 0.005

const THROTTLE_SENSITIVITY: float = 1
const MAX_THROTTLE: float = 100.0
const ROTATION_SENSITIVITY: float = 0.01

var throttle: float = 0.0

const SHOOT_COOLDOWN: float = 0.4
var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var bullet_cooldown: float
var last_shot_time: float = -1.0

var score: int = 0
var health: int = 100

var stats: Array[StatContainer.StatData] = [
	StatContainer.StatData.new(
		[10, 20, 30],
		[0.5, 1.0, 1.5, 2.0]
	),
	StatContainer.StatData.new(
		[10, 20, 30, 40],
		[0.25, 0.5, 0.75, 1.0, 1.5]
	),
	StatContainer.StatData.new(
		[10, 20],
		[0.5, 1.0, 2.0]
	),
]

var global_seed: int = 123456789
var last_chunk: Vector3i = Vector3i(1 << 30, 1 << 30, 1 << 30)

var rot_vector: Vector2 = Vector2.ZERO
var accel_off: Vector3 = Vector3.ZERO

var _sync_timer: float = 0.0
var _sync_interval: float = 0.020

var is_paused: bool = false

func _ready() -> void:
	if is_local:
		var img = preload("res://assets/ui/crosshair2.png").get_image()
		img.resize(32, 32, Image.INTERPOLATE_BILINEAR)
		DisplayServer.cursor_set_custom_image(img, DisplayServer.CURSOR_ARROW, Vector2(16, 16))
		get_parent().rpc_id(1, "server_sync_nickname", multiplayer.get_unique_id(), nickname)
		if OS.has_feature("mobile"):
			_on_center_accel_pressed()
	$UI/Nickname.text = nickname
	$UI.visible = is_local
	
	$FloatingTag.visible = not is_local

func _on_tree_exiting() -> void:
	if is_local:
		DisplayServer.cursor_set_custom_image(null)

func _input(event: InputEvent) -> void:
	if not is_local:
		return
		
	if event.is_action_pressed("escape"):
		_toggle_pause_menu()
	
	if is_paused:
		return
	
	if event.is_action_released("shoot"):
		shoot_bullets()

func _get_normalized_mouse_pos() -> Vector2:
	var viewport = get_viewport()
	var vrect = viewport.get_visible_rect()
	var mouse_pos = viewport.get_mouse_position()
	
	if not vrect.has_point(mouse_pos):
		return Vector2.ZERO
	
	var center: Vector2 = vrect.position + vrect.size * 0.5
	var dir: Vector2 = mouse_pos - center
	
	return Vector2(-dir.x / vrect.size.x, -dir.y / vrect.size.y)

func _physics_process(delta: float) -> void:
	if not is_local:
		return
	if is_paused:
		return
	if OS.has_feature("mobile"):
		var accel = Input.get_accelerometer()
		rot_vector.x = (accel.x - accel_off.x) * ACCEL_SENSITIVITY
		rot_vector.y = (accel.z - accel_off.z) * ACCEL_SENSITIVITY
		#rot_vector.z = (accel.z - accel_off.z) * ACCEL_SENSITIVITY
	else:
		if get_window().has_focus():
			var pos = _get_normalized_mouse_pos()
			rot_vector.x = pos.x * MOUSE_SENSITIVITY
			rot_vector.y = pos.y * MOUSE_SENSITIVITY
	
	var local_right = (quaternion * Vector3.RIGHT).normalized()
	var local_up = (quaternion * Vector3.UP).normalized()
	var local_forward = (quaternion * Vector3.FORWARD).normalized()
	
	quaternion = Quaternion(local_right, rot_vector.y) * quaternion
	if OS.has_feature("mobile"):
		quaternion = Quaternion(local_forward, rot_vector.x) * quaternion
	else:
		quaternion = Quaternion(local_up, rot_vector.x) * quaternion
		quaternion = Quaternion(local_forward, -rot_vector.x * 0.00005) * quaternion
	
	if Input.is_action_pressed("ui_left"):
		quaternion = Quaternion(local_forward, -ROTATION_SENSITIVITY) * quaternion
	if Input.is_action_pressed("ui_right"):
		quaternion = Quaternion(local_forward, ROTATION_SENSITIVITY) * quaternion
	if Input.is_action_pressed("yaw_left"):
		quaternion = Quaternion(local_up, ROTATION_SENSITIVITY) * quaternion
	if Input.is_action_pressed("yaw_right"):
		quaternion = Quaternion(local_up, -ROTATION_SENSITIVITY) * quaternion
	quaternion = quaternion.normalized()
	
	if Input.is_action_pressed("throttle_down"):
		throttle = clamp(throttle - THROTTLE_SENSITIVITY, 0.0, MAX_THROTTLE)
		$UI/Throttle.value = throttle
	if Input.is_action_pressed("throttle_up"):
		throttle = clamp(throttle + THROTTLE_SENSITIVITY, 0.0, MAX_THROTTLE)
		$UI/Throttle.value = throttle
	
	var max_speed_stat = stats[StatContainer.StatType.MAX_SPEED]
	velocity = -basis.z * (throttle * max_speed_stat.mod_table[max_speed_stat.stage])
	move_and_slide()
	
	_sync_timer += delta
	if _sync_timer >= _sync_interval:
		_sync_timer = 0.0
		var snapshot = {
			"p": global_position,
			"q": quaternion
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
	get_parent().players[peer_id]._update_nickname(new_nickname)
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

@rpc("authority", "call_local", "reliable")
func client_set_score(peer_id: int, new_value: int) -> void:
	get_parent().players[peer_id].score = new_value
	redraw_scoreboard()

@rpc("authority", "call_local", "reliable")
func client_set_health(peer_id: int, new_value: int) -> void:
	if peer_id == multiplayer.multiplayer_peer.get_unique_id():
		if new_value <= 0:
			get_tree().change_scene_to_file("res://scenes/defeat.tscn")
			get_node("/root/Main").remove()
			return
	get_parent().players[peer_id].health = new_value
	redraw_healthbars(peer_id, new_value)

func shoot_bullets() -> void:
	if not is_local:
		return
	
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_shot_time >= SHOOT_COOLDOWN:
		for gun in $Guns.get_children():
			var gun_speed = abs(velocity.dot(-gun.global_transform.basis.z))
			get_parent().rpc_id(1, "server_spawn_bullet", multiplayer.get_unique_id(), gun.global_transform, gun_speed)
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
		label.add_theme_font_size_override("font_size", 36)
		label.text = "%s: %d" % [player.nickname, player.score]
		$UI/ScoreBoard.add_child(label)

func redraw_healthbars(peer_id: int, new_value: int) -> void:
	var sb = StyleBoxFlat.new()
	if new_value >= 60:
		sb.bg_color = Color.DARK_GREEN
	elif new_value >= 20:
		sb.bg_color = Color.YELLOW
	else:
		sb.bg_color = Color.RED
	
	if peer_id != multiplayer.multiplayer_peer.get_unique_id():
		var health_bar = get_parent().players[peer_id].get_node("TagViewport/Control/VBox/HealthBar")
		health_bar.add_theme_stylebox_override("fill", sb)
		health_bar.value = new_value
		return
	
	$UI/HealthBar.add_theme_stylebox_override("fill", sb)
	$UI/HealthBar.value = new_value
	$UI/HealthBar/Label.text = "%d HP" % new_value

func _toggle_pause_menu() -> void:
	$UI/PauseMenu.visible = !$UI/PauseMenu.visible
	is_paused = !is_paused
	
	if is_paused:
		DisplayServer.cursor_set_custom_image(null)
	else:
		var img = preload("res://assets/ui/crosshair2.png").get_image()
		img.resize(32, 32, Image.INTERPOLATE_BILINEAR)
		DisplayServer.cursor_set_custom_image(img, DisplayServer.CURSOR_ARROW, Vector2(16, 16))


func _on_center_accel_pressed() -> void:
	accel_off = Input.get_accelerometer()

func _update_nickname(new_nickname: String) -> void:
	nickname = new_nickname
	$TagViewport/Control/VBox/HBox/NicknameTag.text = new_nickname

func _on_throttle_value_changed(value: float) -> void:
	throttle = clamp(value, 0.0, MAX_THROTTLE)
