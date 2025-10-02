extends StaticBody3D

var input_color: Color = Color.BLACK

func _ready() -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = input_color
	mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	mat.distance_fade_min_distance = 3500.0
	mat.distance_fade_max_distance = 3000.0
	$Mesh.material_override = mat
