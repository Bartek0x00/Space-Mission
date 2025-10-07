@tool
extends EditorScript

var save_path: String = "res://assets/enemy_path_curves/curve.tres"
var a: float = 360.0    # ellipse radius on X axis
var b: float = 360.0    # ellipse radius on Z axis
var y: float = 0.0    # vertical offset (Y)
var bake_interval: float = 0.05  # sampling resolution used by Curve3D when baking
var use_bezier: bool = true  # if true uses 4-cubic-bezier approximation, otherwise sampled points
var sampled_segments: int = 128  # only used when use_bezier == false

func _run() -> void:
	print("Generating ellipse Curve3D -> ", save_path)

	var curve := Curve3D.new()
	curve.bake_interval = bake_interval

	if use_bezier:
		_make_bezier_ellipse(curve, a, b, y)
	else:
		_make_sampled_ellipse(curve, a, b, y, sampled_segments)

	var err := ResourceSaver.save(curve, save_path)
	if err == OK:
		print("Saved ellipse Curve3D to: ", save_path)
	else:
		printerr("Failed to save resource (error code): ", err)

func _make_sampled_ellipse(curve: Curve3D, a: float, b: float, y: float, points: int) -> void:
	if points < 4:
		points = 4
	for i in range(points):
		var t := TAU * (float(i) / float(points))
		var x := a * cos(t)
		var z := b * sin(t)
		curve.add_point(Vector3(x, y, z))


func _make_bezier_ellipse(curve: Curve3D, a: float, b: float, y: float) -> void:
	var k := 4.0 * (sqrt(2.0) - 1.0) / 3.0  # ≈ 0.5522847498

	# Quadrant points in XZ plane (clockwise)
	var p0 := Vector3( a, y,  0)
	var p1 := Vector3( 0, y,  b)
	var p2 := Vector3(-a, y,  0)
	var p3 := Vector3( 0, y, -b)

	# Each add_point takes: position, in_tangent (relative), out_tangent (relative)
	curve.add_point(p0, Vector3(0,0,-k * b), Vector3(0,0,k * b))
	curve.add_point(p1, Vector3(k * a,0,0), Vector3(-k * a,0,0))
	curve.add_point(p2, Vector3(0,0,k * b), Vector3(0,0,-k * b))
	curve.add_point(p3, Vector3(-k * a,0,0), Vector3(k * a,0,0))
	
	curve.add_point(p0, Vector3(0,0,-k*b), Vector3(0,0,k*b))
