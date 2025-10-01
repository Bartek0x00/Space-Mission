extends StaticBody3D

var input_color: Color = Color.BLACK

func _ready() -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = input_color
	$Mesh.material_override = mat
