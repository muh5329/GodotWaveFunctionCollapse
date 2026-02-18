class_name WaveFunctionCollapse3D
extends Node3D

class Tile3D:
	var id: int
	var mesh: Mesh
	var sockets: Dictionary  # Keys are directions, values are Arrays of compatible socket IDs
	var weight: float = 1.0
	var can_rotate: bool = true
	var rotation: int  # Rotation in Degrees
	
	func _init(_id: int, _mesh: Mesh, _sockets: Dictionary, _weight: float = 1.0, _rotation: int = 0):
		id = _id
		mesh = _mesh
		sockets = _sockets
		weight = _weight
		rotation = _rotation
		
class Cell3D:
	var possible_tiles: Array = []
	var collapsed: bool = false
	var tile_id: int = -1
	
	func _init(all_tile_ids: Array):
		possible_tiles = all_tile_ids.duplicate()
	
	func get_entropy() -> float:
		if collapsed:
			return 0.0
		return possible_tiles.size() + randf() * 0.1

var tiles: Array[Tile3D] = []
var grid: Array = []
var width: int
var height: int
var depth: int
var tile_registry: Dictionary = {}

const NORTH = Vector3i(0, 0, -1)
const SOUTH = Vector3i(0, 0, 1)
const EAST = Vector3i(1, 0, 0)
const WEST = Vector3i(-1, 0, 0)
const UP = Vector3i(0, 1, 0)
const DOWN = Vector3i(0, -1, 0)

var directions = {
	"north": NORTH,
	"south": SOUTH,
	"east": EAST,
	"west": WEST,
	"up": UP,
	"down": DOWN
}

func initialize(w: int, h: int, d: int):
	width = w
	height = h
	depth = d
	grid = []
	
	var all_tile_ids: Array = []
	for tile in tiles:
		all_tile_ids.append(tile.id)
	
	for z in range(depth):
		var layer = []
		for y in range(height):
			var row = []
			for x in range(width):
				var cell = Cell3D.new(all_tile_ids)
				row.append(cell)
			layer.append(row)
		grid.append(layer)

func add_tile(tile: Tile3D):
	tiles.append(tile)
	tile_registry[tile.id] = tile

func collapse():
	var iterations = 0
	var max_iterations = width * height * depth * 2
	
	while iterations < max_iterations:
		iterations += 1
		
		var min_cell_pos = find_minimum_entropy_cell()
		if min_cell_pos == null:
			print("WFC Complete! Iterations: ", iterations)
			return
		
		if not collapse_cell(min_cell_pos):
			print("Contradiction at iteration ", iterations)
			return
		
		if not propagate(min_cell_pos):
			print("Propagation failed at iteration ", iterations)
			return
	
	push_error("WFC failed to complete")

func find_minimum_entropy_cell():
	var min_entropy = INF
	var candidates = []
	
	for z in range(depth):
		for y in range(height):
			for x in range(width):
				var cell = grid[z][y][x]
				if not cell.collapsed:
					var entropy = cell.get_entropy()
					if entropy < min_entropy and entropy > 0:
						min_entropy = entropy
						candidates = [Vector3i(x, y, z)]
					elif abs(entropy - min_entropy) < 0.01 and entropy > 0:
						candidates.append(Vector3i(x, y, z))
	
	if candidates.is_empty():
		return null  
	
	return candidates[randi() % candidates.size()]

func collapse_cell(pos: Vector3i) -> bool:
	var cell = grid[pos.z][pos.y][pos.x]
	if cell.collapsed:
		return true
	
	if cell.possible_tiles.is_empty():
		return false
	
	var total_weight = 0.0
	var weights = []
	
	for tile_id in cell.possible_tiles:
		var weight = tile_registry[tile_id].weight
		weights.append(weight)
		total_weight += weight
	
	var random_value = randf() * total_weight
	var cumulative = 0.0
	var selected_id = cell.possible_tiles[0]
	
	for i in range(cell.possible_tiles.size()):
		cumulative += weights[i]
		if random_value <= cumulative:
			selected_id = cell.possible_tiles[i]
			break
	
	cell.tile_id = selected_id
	cell.possible_tiles = [selected_id]
	cell.collapsed = true
	
	return true

func propagate(start_pos: Vector3i) -> bool:
	var stack = [start_pos]
	var visited = {}
	
	while not stack.is_empty():
		var pos = stack.pop_back()
		var key = "%d,%d,%d" % [pos.x, pos.y, pos.z]
		
		if key in visited:
			continue
		visited[key] = true
		
		var cell = grid[pos.z][pos.y][pos.x]
		
		for dir_name in directions.keys():
			var dir = directions[dir_name]
			var neighbor_pos = pos + dir
			
			if not is_valid_position(neighbor_pos):
				continue
			
			var neighbor = grid[neighbor_pos.z][neighbor_pos.y][neighbor_pos.x]
			if neighbor.collapsed:
				continue
			
			var valid_neighbors = get_valid_neighbors(cell, dir_name)
			var old_count = neighbor.possible_tiles.size()
			
			var new_possible = []
			for tile_id in neighbor.possible_tiles:
				if tile_id in valid_neighbors:
					new_possible.append(tile_id)
			
			neighbor.possible_tiles = new_possible
			
			if neighbor.possible_tiles.size() < old_count:
				if neighbor.possible_tiles.is_empty():
					return false
				stack.append(neighbor_pos)
	
	return true

# FIXED: Proper socket compatibility checking
func get_valid_neighbors(cell: Cell3D, direction: String) -> Array:
	var valid = []
	var opposite_dir = get_opposite_direction(direction)
	
	# Collect all unique socket values that can emit from this cell in the given direction
	var valid_socket_values = []
	for tile_id in cell.possible_tiles:
		var tile = tile_registry[tile_id]
		var socket_array = tile.sockets.get(direction, [])
		for socket_val in socket_array:
			if socket_val not in valid_socket_values:
				valid_socket_values.append(socket_val)
	
	# Find all tiles whose opposite-direction sockets contain any of these values
	for other_tile in tiles:
		var other_socket_array = other_tile.sockets.get(opposite_dir, [])
		
		# Check if there's ANY overlap between the two socket arrays
		var has_overlap = false
		for socket_val in valid_socket_values:
			if socket_val in other_socket_array:
				has_overlap = true
				break
		
		if has_overlap and other_tile.id not in valid:
			valid.append(other_tile.id)
	
	return valid

func get_opposite_direction(dir: String) -> String:
	match dir:
		"north": return "south"
		"south": return "north"
		"east": return "west"
		"west": return "east"
		"up": return "down"
		"down": return "up"
	return ""

func is_valid_position(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < width and \
		   pos.y >= 0 and pos.y < height and \
		   pos.z >= 0 and pos.z < depth

func get_result() -> Array:
	return grid
