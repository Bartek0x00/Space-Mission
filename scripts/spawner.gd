class_name Spawner extends Node3D
 
# Variables
@export var minDistance : float = 200 ## Minimum distance between points
@export var sampleAttempts : int = 2   ## Number of attempts to place a point around an active point, avoids infinite loops
@export var maxDistanceMultiplier : float = 2 ## Multiplied to the minimum distance to get the max distance it'll look for a location from the point
@export var chunkSize : Vector3 = Vector3(1000, 1000, 1000)
@export var pointOffset : Vector3 = Vector3(0, 0, 0) ## Adds an offset to the final position if needed

@export_group("Debug")
@export var debugMode : bool = true
@export var pointDebug : PackedScene ## This is just a Node3D circle mesh with a collider that does nothin, but simply is there to help visualize the distance between the points and make sure there's no overlap

var grid : Array = []
var gridCellSize : float
var activeList : Array = [] ## Used for when generating the list of points
var points : Array = [] ## Stores the final points
var usedPoints : Array = []

func _initialize_grid() -> void:
	## Get grid sizing
	gridCellSize = minDistance / sqrt(2)
	var gridWidth : int = int(ceil(chunkSize.x / gridCellSize))
	var gridHeight : int = int(ceil(chunkSize.y / gridCellSize))
	var gridDepth: int = int(ceil(chunkSize.z / gridCellSize))
	
	## Create 3D grid array
	grid = []
	for i in range(gridWidth):
		grid.append([])
		for j in range(gridHeight):
			grid[i].append([])
			for k in range(gridDepth):
				grid[i][j].append(null)

func _generate_points():
	## Start with a random point
	var firstPoint : Vector3 = Vector3(randf_range(0, chunkSize.x), randf_range(0, chunkSize.y), randf_range(0, chunkSize.z))
	_add_point(firstPoint)

	
	## Find all valid points
	while activeList.size() > 0:
		var point : Vector3 = activeList.pick_random()
		var isFound : bool = false
		
		for i in range(0, sampleAttempts):
			var newPoint : Vector3 = _generate_random_point_around(point)
			
			if _is_valid_point(newPoint):
				_add_point(newPoint)
				isFound = true
				break
		
		if !isFound:
			activeList.erase(point)

func _add_point(_point: Vector3):
	points.append(_point)
	activeList.append(_point)
	var gridPos = _point_to_gridPos(_point) ## Convert the position into a grid cell ID
	grid[gridPos.x][gridPos.y][gridPos.z] = _point

func _point_to_gridPos(_point: Vector3) -> Vector3:
	return Vector3(int(_point.x / gridCellSize), int(_point.y / gridCellSize), int(_point.z / gridCellSize))

func _generate_random_point_around(_point: Vector3) -> Vector3:
	var r = randf_range(minDistance, maxDistanceMultiplier * minDistance)
	var angle_x = randf() * TAU
	var angle_y = randf() * TAU
	return _point + Vector3(cos(angle_x), sin(angle_x), sin(angle_y)) * r

func _is_valid_point(_point: Vector3) -> bool:
	## Check if the point is within chunk bounds
	if _point.x < 0 or _point.x >= chunkSize.x or _point.y < 0 or _point.y >= chunkSize.y or _point.z < 0 or _point.z >= chunkSize.z:
		return false
	
	var gridPos = _point_to_gridPos(_point)
	
	## Check neighboring cells in the grid
	for i in range(-1, 2):
		for j in range(-1, 2):
			for k in range(-1, 2):
				var neighborPos = gridPos + Vector3(i, j, k)
				if neighborPos.x >= 0 and neighborPos.x < grid.size() and neighborPos.y >= 0 and neighborPos.y < grid[0].size() and neighborPos.z >= 0 and neighborPos.z < grid[0][0].size():
					var neighborPoint = grid[neighborPos.x][neighborPos.y][neighborPos.z]
					if neighborPoint != null:
						if _point.distance_to(neighborPoint) < minDistance:
							return false
	
	return true

func _draw_points():
	## Draw the generated points as circle mesh instances
	for point in points:
		var newPoint = pointDebug.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		self.add_child(newPoint)
		newPoint.global_position = Vector3(point.x - pointOffset.x, point.y - pointOffset.y, point.z - pointOffset.z) ## Add an offset to the location

func poisson_disc_sampling_algorithm() -> void:
	_initialize_grid()
	_generate_points()
	
	if debugMode:
		spawn_planet()


var vectors = []
 
func load_coords():
	var x: float = randf_range(-2.0, 2.0)
	var y: float = randf_range(-2.0, 2.0)
	var z: float = randf_range(-2.0, 2.0)
	while true:
		for vector in vectors:
			if (vector.x -0.5 < x < 0.5 + vector.x or vector.y -0.5 < y < 0.5 + vector.y or vector.z -0.5 < z < 0.5 + vector.z):
				x = randf_range(-2.0, 2.0)
				y = randf_range(-2.0, 2.0)
				z = randf_range(-2.0, 2.0)
			else: break
	return Vector3(x, y, z)
 
 
func spawn_planet():
	for point in points:
		var radius = randf_range(1, 50)
		var rigid_body = StaticBody3D.new()
		
		rigid_body.collision_layer = 1 << 4
		rigid_body.collision_mask = 0
		
		var collision = CollisionShape3D.new()
		collision.shape = SphereShape3D.new()
		collision.shape.radius = radius
		
		var mesh = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = radius
		sphere_mesh.height = radius * 2
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(randf_range(0,1), randf_range(0,1), randf_range(0,1))
		mesh.material_override = material
		mesh.mesh = sphere_mesh
		
		rigid_body.add_child(mesh)
		rigid_body.add_child(collision)
		add_child(rigid_body)

		rigid_body.position = Vector3(point.x - pointOffset.x, point.y - pointOffset.y, point.z - pointOffset.z) ## Add an offset to the location

func _ready():
	poisson_disc_sampling_algorithm()		
