extends CharacterBody3D

var is_local_player: bool = false
var player_id: int = 0
var nickname: String = "Player"

const MOUSE_SENSITIVITY: float = 0.05

const THROTTLE_SENSITIVITY: float = 0.25
const MAX_THROTTLE: float = 50.0

const ROTATION_SENSITIVITY: float = 0.01

var throttle: float = 0.0

const SHOOT_COOLDOWN: float = 0.4
@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@export var bullet_cooldown: float
var last_shot_time: float = -1.0

var score: int = 0
var _last_score: int = 0

func shoot_bullets() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_shot_time >= SHOOT_COOLDOWN:
		for gun in $Guns.get_children():
			var bullet = bullet_scene.instantiate()
			get_parent().add_child(bullet)
			bullet.global_transform = gun.global_transform
			bullet.linear_velocity = -bullet.transform.basis.z * bullet.SPEED
		last_shot_time = now

func add_score(value: int) -> void:
	if not is_local_player:
		return
	score += value
	if score != _last_score:
		$UI/Score.text = "Score: " + str(score)
		_last_score = score

func _send_network_transform() -> void:
	if not is_inside_tree():
		return
	
	if multiplayer.multiplayer_peer == null:
		return
		
	var main_path = get_node_or_null("/root/Main")
	if main_path == null or not is_instance_valid(main_path):
		return
		
	main_path.rpc("network_update_transform", player_id, global_transform)

func _ready() -> void:
	if not is_local_player:
		return
	var img = preload("res://assets/ui/crosshair2.png").get_image()
	img.resize(32, 32, Image.INTERPOLATE_BILINEAR)
	DisplayServer.cursor_set_custom_image(img, DisplayServer.CURSOR_ARROW, Vector2(16, 16))
	$UI/Nickname.text = nickname
	$NickNameTag.text = nickname

func _input(event: InputEvent) -> void:
	if not is_local_player:
		return
	if event.is_action_released("shoot"):
		shoot_bullets()

var rot_vector: Vector2 = Vector2.ZERO

var _sync_timer: float = 0.0
var _sync_interval: float = 0.02

func _physics_process(delta: float) -> void:
	if not is_local_player:
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
		_send_network_transform()
