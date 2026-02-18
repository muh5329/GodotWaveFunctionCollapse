extends Node3D

var wfc: WaveFunctionCollapse3D
var tile_size: float = 1.0
var tile_index: int = 0

func _ready():
	generate_terrain()

func generate_terrain():
	wfc = WaveFunctionCollapse3D.new()
	add_child(wfc)
	
	# Define 3D block tiles
	generate_tile_sets()
	
	# Generate
	wfc.initialize(10, 5, 10)  # 10x5x10 grid
	wfc.collapse()
	
	# Render
	render_terrain()

func create_tile(sockets: Dictionary = {
			"north": [0], "south": [0], "east": [0],
			"west": [0], "up": [0], "down": [0]
		}, weight = 100.0, rotation = 0, mesh = null):
	var tile = WaveFunctionCollapse3D.Tile3D.new(
		tile_index,
		mesh,
		sockets,
		weight,
		rotation
	)
	tile.can_rotate = false
	wfc.add_tile(tile)
	tile_index += 1

func generate_tile_sets() -> void:
	# Socket ID legend:
	# 0 = air/empty (can connect to anything)
	# 1 = floor surface
	# 2 = wall surface
	# 3 = roof surface
	
	# Air block (empty) - index = 0
	# Can connect to anything (all sockets = [0])
	create_tile(generate_sockets({}), 100.0, 0, null)
	
	# Floor tile - index = 1
	# Bottom emits "floor surface" (1), top can accept air or walls
	# Horizontal sides can connect to air, other floors, or walls
	create_tile(generate_sockets({
		"north": [0, 1, 2],   # Can connect to air, floors, walls
		"south": [0, 1, 2], 
		"east": [0, 1, 2],
		"west": [0, 1, 2],
		"up": [0, 2],         # Top accepts air or walls
		"down": [0, 1]        # Bottom emits floor surface
	}), 100.0, 0, get_scene_mesh("floor"))
	
	# Wall tile - index = 2 (renamed from wall_pane_wood)
	# Bottom connects to floors, top connects to roofs or more walls
	# Horizontal sides connect to air or other walls
	create_tile(generate_sockets({
		"north": [0, 2],      # Connects to air or walls
		"south": [0, 2], 
		"east": [0, 2],
		"west": [0, 2],
		"up": [0, 2, 3],      # Top can have air, more walls, or roof
		"down": [1, 2]        # Bottom needs floor or wall below
	}), 50.0, 0, get_scene_mesh("wall_pane_wood"))
	
	# Roof tile - index = 3
	# Bottom needs walls below, top is air
	# Horizontal sides connect to air or other roofs
	create_tile(generate_sockets({
		"north": [0, 3],      # Connects to air or other roofs
		"south": [0, 3], 
		"east": [0, 3],
		"west": [0, 3],
		"up": [0],            # Top is always air
		"down": [2, 3]        # Bottom needs walls or other roofs
	}), 50.0, 0, get_scene_mesh("roof"))

func generate_sockets(directions := {}) -> Dictionary:
	var sockets = {
		"north": [0], "south": [0], "east": [0],
		"west": [0], "up": [0], "down": [0]
	}
	for key in directions:
		if sockets.has(key):
			sockets[key] = directions[key]
	return sockets

func get_scene_mesh(name: String) -> Mesh:
	var scene = load("res://tiles/" + name + ".tscn")
	var instance = scene.instantiate()
	var node = instance.get_node(name)
	if node is MeshInstance3D:
		var result = node.mesh
		instance.queue_free()  # Clean up the instance
		return result
	else:
		push_error("Node '%s' is not a MeshInstance3D" % name)
		instance.queue_free()
		return null

func render_terrain():
	for z in range(wfc.depth):
		for y in range(wfc.height):
			for x in range(wfc.width):
				var cell = wfc.grid[z][y][x]
				if cell.collapsed and cell.tile_id > 0:  # Skip air
					var tile = wfc.tile_registry[cell.tile_id]
					if tile.mesh != null:
						var mesh_instance = MeshInstance3D.new()
						mesh_instance.mesh = tile.mesh
						mesh_instance.position = Vector3(x, y, z) * tile_size
						
						# Apply rotation
						mesh_instance.rotation_degrees.y = tile.rotation * 90 
						
						add_child(mesh_instance)
