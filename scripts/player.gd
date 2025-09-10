extends CharacterBody3D

const MOUSE_SENSITIVITY: float = 0.003

const THROTTLE_SENSITIVITY: float = 4.0
const MAX_THROTTLE: float = 10.0

const ROTATION_SENSITIVITY: float = 0.005

var throttle: float = 0.0
var line: Line2D

var yaw: float = 0.0
var pitch: float = 0.0
var roll: float = 0.0

func _ready() -> void:
	var img = preload("res://assets/crosshair2.png").get_image()
	img.resize(32, 32, Image.INTERPOLATE_BILINEAR)
	DisplayServer.cursor_set_custom_image(img, DisplayServer.CURSOR_ARROW, Vector2(16, 16))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("throttle_down"):
		throttle -= THROTTLE_SENSITIVITY
		throttle = clamp(throttle, 0.0, MAX_THROTTLE)
	if event.is_action_pressed("throttle_up"):
		throttle += THROTTLE_SENSITIVITY
		throttle = clamp(throttle, 0.0, MAX_THROTTLE)
	
	if event.is_action_pressed("escape"):
		if get_tree().root.process_mode != Node.PROCESS_MODE_DISABLED:
			get_tree().root.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			get_tree().root.process_mode = Node.PROCESS_MODE_INHERIT

func _physics_process(delta: float) -> void:
	var screen_center = get_window().size * 0.5
	var mouse_pos = get_viewport().get_mouse_position()
	var rot_vector = (mouse_pos - screen_center) * Vector2(-1, -1)
	
	rotation_degrees.y += rot_vector.x * MOUSE_SENSITIVITY
	rotation_degrees.x += rot_vector.y * MOUSE_SENSITIVITY
	
	if Input.is_action_pressed("ui_left"):
		rotation_degrees.z += ROTATION_SENSITIVITY
	if Input.is_action_pressed("ui_right"):
		rotation_degrees.z -= ROTATION_SENSITIVITY
	
	velocity = -transform.basis.z * throttle
	move_and_slide()
