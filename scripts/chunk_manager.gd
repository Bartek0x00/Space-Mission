extends Node3D

const CHUNK_SIZE: int = 1000
const VIEW_DISTANCE: int = 3

const SCENES: Dictionary = {
	"Collectable": preload("res://scenes/collectable.tscn"),
	"Asteroid": preload("res://scenes/asteroid.tscn"),
	"Bullet": preload("res://scenes/bullet.tscn"),
	"Planet": preload("res://scenes/planet.tscn"),
	"Enemy": preload("res://scenes/enemy.tscn")
}
var loaded_chunks: Dictionary = {}

const SPAWN_PADDING: float = 32.0

func get_chunk_coords(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		int(floor(world_pos.x / CHUNK_SIZE)),
		int(floor(world_pos.y / CHUNK_SIZE)),
		int(floor(world_pos.z / CHUNK_SIZE))
	)

func generate_chunk(global_seed: int, player_global_position: Vector3) -> void:
	var center_chunk: Vector3i = get_chunk_coords(player_global_position)
	for cx in range(center_chunk.x - VIEW_DISTANCE, center_chunk.x + VIEW_DISTANCE + 1):
		for cy in range(center_chunk.y - VIEW_DISTANCE, center_chunk.y + VIEW_DISTANCE + 1):
			for cz in range(center_chunk.z - VIEW_DISTANCE, center_chunk.z + VIEW_DISTANCE + 1):
				var coord = Vector3i(cx, cy, cz)
				if not loaded_chunks.has(coord):
					_load_chunk(coord, global_seed)
	
	var to_unload = []
	for coord in loaded_chunks.keys():
		var dx = abs(coord.x - center_chunk.x)
		var dy = abs(coord.y - center_chunk.y)
		var dz = abs(coord.z - center_chunk.z)
		if dx > VIEW_DISTANCE or dy > VIEW_DISTANCE or dz > VIEW_DISTANCE:
			to_unload.append(coord)
	
	for coord in to_unload:
		_unload_chunk(coord)

func _load_chunk(chunk_coord: Vector3i, global_seed: int) -> void:
	var container = Node3D.new()
	container.name = "chunk_%d_%d_%d" % [chunk_coord.x, chunk_coord.y, chunk_coord.z]
	add_child(container)
	container.position = Vector3(chunk_coord.x * CHUNK_SIZE, chunk_coord.y * CHUNK_SIZE, chunk_coord.z * CHUNK_SIZE)
	loaded_chunks[chunk_coord] = container
	
	var rng = _rng_for_chunk(global_seed, chunk_coord.x, chunk_coord.y, chunk_coord.z)
	
	_spawn_planets(container, rng, chunk_coord)
	#_spawn_asteroids(container, rng, chunk_coord)
	#_spawn_collectables(container, rng, chunk_coord)
	#_spawn_enemies(container, rng, chunk_coord)

func _unload_chunk(chunk_coord: Vector3i) -> void:
	var container = loaded_chunks.get(chunk_coord, null)
	if container:
		container.queue_free()
	loaded_chunks.erase(chunk_coord)

func _rng_for_chunk(global_seed: int, cx: int, cy: int, cz: int) -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	
	var combined = int(global_seed) ^ (cx * 73856093) ^ (cy * 19349663) ^ (cz * 83492791)
	if combined < 0:
		combined = -combined
	rng.seed = combined
	return rng

func _rand_local_pos_with_padding(rng: RandomNumberGenerator) -> Vector3:
	var x = rng.randf_range(-SPAWN_PADDING, CHUNK_SIZE + SPAWN_PADDING)
	var y = rng.randf_range(-SPAWN_PADDING, CHUNK_SIZE + SPAWN_PADDING)
	var z = rng.randf_range(-SPAWN_PADDING, CHUNK_SIZE + SPAWN_PADDING)
	return Vector3(x, y, z)

func _world_pos(chunk_coord: Vector3i, local_pos: Vector3) -> Vector3:
	return Vector3(chunk_coord.x * CHUNK_SIZE, chunk_coord.y * CHUNK_SIZE, chunk_coord.z * CHUNK_SIZE) + local_pos

func _spawn_planets(root_container: Node3D, rng: RandomNumberGenerator, chunk_coord: Vector3i) -> void:
	var container = Node3D.new()
	container.name = "Planets"
	root_container.add_child(container)
	
	var count = rng.randi_range(0, 2)
	for i in range(count):
		var local = _rand_local_pos_with_padding(rng)
		var world_pos = _world_pos(chunk_coord, local)
		if get_chunk_coords(world_pos) != chunk_coord:
			continue
		var obj = SCENES["Planet"].instantiate()
		var color_component = rng.randf()
		obj.input_color = Color(
			color_component, 
			clamp(0.123 + (color_component / 2), 0.0, 1.0),
			clamp(0.919 - (color_component / 3), 0.0, 1.0), 
			1
		)
		container.add_child(obj)
		obj.global_position = world_pos

func _spawn_asteroids(root_container: Node3D, rng: RandomNumberGenerator, chunk_coord: Vector3i) -> void:
	var container = Node3D.new()
	container.name = "Asteroids"
	root_container.add_child(container)
	
	var count = rng.randi_range(1, 6)
	for i in range(count):
		var local = _rand_local_pos_with_padding(rng)
		var world_pos = _world_pos(chunk_coord, local)
		if get_chunk_coords(world_pos) != chunk_coord:
			continue
		var obj = SCENES["Asteroid"].instantiate()
		var rand_axis = rng.randf_range(0.5, 0.6) * 49
		var linear_vec = Vector3(rand_axis, (-rand_axis / 3) + 0.3, 0)
		var rotation_vec = Vector3(rand_axis * 0.123, -rand_axis, 1.58).normalized()
		obj.linear_velocity = linear_vec.rotated(rotation_vec, rng.randf_range(0.0, 90.0))
		obj.angular_velocity = rotation_vec
		container.add_child(obj)
		obj.global_position = world_pos

func _spawn_collectables(root_container: Node3D, rng: RandomNumberGenerator, chunk_coord: Vector3i) -> void:
	var container = Node3D.new()
	container.name = "Collectables"
	root_container.add_child(container)
	
	var count = rng.randi_range(0, 6)
	for i in range(count):
		if get_chunk_coords(chunk_coord) != chunk_coord:
			continue
		var obj = SCENES["Collectable"].instantiate()
		var local = _rand_local_pos_with_padding(rng)
		container.add_child(obj)
		obj.global_position = container.to_local(_world_pos(chunk_coord, local))

func _spawn_enemies(root_container: Node3D, rng: RandomNumberGenerator, chunk_coord: Vector3i) -> void:
	var container = Node3D.new()
	container.name = "Enemies"
	root_container.add_child(container)
	
	var count = rng.randi_range(0, 4)
	for i in range(count):
		if get_chunk_coords(chunk_coord) != chunk_coord:
			continue
		var obj = SCENES["Enemy"].instantiate()
		var local = _rand_local_pos_with_padding(rng)
		container.add_child(obj)
		obj.global_position = container.to_local(_world_pos(chunk_coord, local))
