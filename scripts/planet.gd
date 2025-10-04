extends StaticBody3D

const PLANET_TYPES = [
	{
		"w": 40,
		"m": preload("res://assets/planets/planet_sand_mat.tres"),
		"s": 64.0
	},
	{
		"w": 40,
		"m": preload("res://assets/planets/planet_ice_mat.tres"),
		"s": 96.0
	},
	{
		"w": 10,
		"m": preload("res://assets/planets/planet_gaseous_mat.tres"),
		"s": 512.0
	},
	{
		"w": 30,
		"m": preload("res://assets/planets/planet_lava_mat.tres"),
		"s": 128.0
	},
	{
		"w": 4,
		"m": preload("res://assets/planets/planet_terrestrial_mat.tres"),
		"s": 96.0
	},
	{
		"w": 1,
		"m": preload("res://assets/planets/star_mat.tres"),
		"s": 2048.0
	}
]

var rng: RandomNumberGenerator

func _ready() -> void:
	var planet_type := _pick_planet()
	$Mesh.material_override = planet_type["m"]
	scale *= planet_type["s"]

func _pick_planet() -> Dictionary:
	var total_weight = 0
	for entry in PLANET_TYPES:
		total_weight += entry["w"]
	
	var choice := rng.randi_range(1, total_weight)
	var cumulative := 0
	
	for entry in PLANET_TYPES:
		cumulative += entry["w"]
		if choice <= cumulative:
			return entry
	
	return PLANET_TYPES.back()
