extends StaticBody3D

class PlanetData:
	var rand_weight: int
	var material: ShaderMaterial
	var scale: float
	
	func _init(_rand_weight: int, _material: ShaderMaterial, _scale: float) -> void:
		self.rand_weight = _rand_weight
		self.material = _material
		self.scale = _scale

var PLANET_TYPES: Array[PlanetData] = [
	PlanetData.new(
		40,
		preload("res://assets/planets/planet_sand_mat.tres"),
		64.0
	),
	PlanetData.new(
		40,
		preload("res://assets/planets/planet_ice_mat.tres"),
		96.0
	),
	PlanetData.new(
		10,
		preload("res://assets/planets/planet_gaseous_mat.tres"),
		512.0
	),
	PlanetData.new(
		30,
		preload("res://assets/planets/planet_lava_mat.tres"),
		128.0
	),
	PlanetData.new(
		4,
		preload("res://assets/planets/planet_terrestrial_mat.tres"),
		96.0
	),
	PlanetData.new(
		1,
		preload("res://assets/planets/star_mat.tres"),
		2048.0
	)
]

var rng: RandomNumberGenerator
var planet_type: PlanetData


func _ready() -> void:
	$Mesh.material_override = planet_type.material
	scale *= planet_type.scale

func pick_planet() -> PlanetData:
	var total_weight = 0
	for entry in PLANET_TYPES:
		total_weight += entry.rand_weight
	
	var choice := rng.randi_range(1, total_weight)
	var cumulative := 0
	
	for entry in PLANET_TYPES:
		cumulative += entry.rand_weight
		if choice <= cumulative:
			return entry
	
	return PLANET_TYPES.back()
