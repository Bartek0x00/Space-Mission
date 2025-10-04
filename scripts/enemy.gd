extends RigidBody3D

enum Mode {
	PATROL,
	FOLLOW,
	RETURN
}

var target: Node3D = null
var mode: Mode = Mode.PATROL

const DAMAGE: int = 70

const SPEED: float = 5.0
const ROTATION_SPEED: float = 5.0

var path_follow: PathFollow3D

func _ready() -> void:
	path_follow = get_parent().get_node("EnemyPath/EnemyPathFollow")
	global_position = path_follow.global_position

func _physics_process(delta: float) -> void:
	match mode:
		Mode.PATROL:
			_patrol(delta)
		Mode.FOLLOW:
			_follow(delta)
		Mode.RETURN:
			_return(delta)

func _on_range_cone_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	target = body
	mode = Mode.FOLLOW

func _on_range_cone_body_exited(body: Node3D) -> void:
	if body != target:
		return
	target = null
	mode = Mode.RETURN

func _patrol(delta: float) -> void:
	path_follow.progress += SPEED * delta
	var dir = (path_follow.global_transform.origin - global_transform.origin)
	if dir.length() > 0.1:
		dir = dir.normalized()
		linear_velocity = dir * SPEED
		_rotate_towards(path_follow.global_transform.basis, delta)

func _follow(delta: float) -> void:
	var dir = (target.global_transform.origin - global_transform.origin)
	if dir.length() > 0.1:
		dir = dir.normalized()
		linear_velocity = dir * SPEED
		var from = Transform3D(global_transform.basis, global_transform.origin)
		var target_basis = from.looking_at(target.global_transform.origin, Vector3.UP, true).basis
		_rotate_towards(target_basis, delta)

func _return(delta: float) -> void:
	var dir = (path_follow.global_transform.origin - global_transform.origin)
	if dir.length() > 0.1:
		dir = dir.normalized()
		linear_velocity = dir * SPEED
		_rotate_towards(path_follow.global_transform.basis, delta)
	else:
		mode = Mode.PATROL

func _rotate_towards(target_basis: Basis, delta: float) -> void:
	var current_q = global_transform.basis.get_rotation_quaternion()
	var target_q = target_basis.get_rotation_quaternion()
	var rot = current_q.slerp(target_q, ROTATION_SPEED * delta)
	var angular = (rot * current_q.inverse()).get_euler()
	angular_velocity = angular / delta

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	queue_free()
	if not body.is_local:
		return
	print("Body %d collided with Enemy" % body.multiplayer.get_unique_id())
	get_node("/root/Main").rpc_id(1, "server_sub_health", body.multiplayer.get_unique_id(), DAMAGE)
