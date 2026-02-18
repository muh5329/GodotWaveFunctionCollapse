extends Camera3D

## Free Flight Camera Controller
## Mouse look + WASD/QE movement for unrestricted 3D navigation

# Movement settings
@export var movement_speed: float = 10.0
@export var sprint_multiplier: float = 2.5
@export var slow_multiplier: float = 0.3
@export var acceleration: float = 20.0
@export var deceleration: float = 15.0

# Mouse look settings
@export var mouse_sensitivity: float = 0.003
@export var max_pitch: float = 89.0  # Degrees up/down

# Input settings
@export var invert_y: bool = false
@export var enable_smoothing: bool = true

# Internal state
var _velocity: Vector3 = Vector3.ZERO
var _pitch: float = 0.0
var _yaw: float = 0.0
var _mouse_captured: bool = false


func _ready() -> void:
	# Optionally capture mouse on start
	# capture_mouse()
	pass


func _input(event: InputEvent) -> void:
	# Toggle mouse capture with right click or Escape
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			toggle_mouse_capture()
	
	if event.is_action_pressed("ui_cancel"):  # Escape key
		release_mouse()
	
	# Mouse look (only when captured)
	if event is InputEventMouseMotion and _mouse_captured:
		_handle_mouse_look(event.relative)


func _process(delta: float) -> void:
	if _mouse_captured:
		_handle_movement(delta)


func _handle_mouse_look(relative_motion: Vector2) -> void:
	# Update yaw (horizontal rotation)
	_yaw -= relative_motion.x * mouse_sensitivity
	
	# Update pitch (vertical rotation)
	var pitch_delta = relative_motion.y * mouse_sensitivity
	if invert_y:
		pitch_delta = -pitch_delta
	_pitch -= pitch_delta
	
	# Clamp pitch to prevent camera flipping
	_pitch = clamp(_pitch, deg_to_rad(-max_pitch), deg_to_rad(max_pitch))
	
	# Apply rotation
	rotation.y = _yaw
	rotation.x = _pitch


func _handle_movement(delta: float) -> void:
	# Get input direction
	var input_dir := Vector3.ZERO
	
	# Forward/backward
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.z += 1
	
	# Left/right
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	# Up/down
	if Input.is_action_pressed("move_up"):
		input_dir.y += 1
	if Input.is_action_pressed("move_down"):
		input_dir.y -= 1
	
	# Normalize to prevent faster diagonal movement
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
	
	# Transform input to camera's local space
	var direction := transform.basis * input_dir
	
	# Calculate target speed with modifiers
	var target_speed := movement_speed
	if Input.is_action_pressed("move_sprint"):
		target_speed *= sprint_multiplier
	if Input.is_action_pressed("move_slow"):
		target_speed *= slow_multiplier
	
	# Calculate target velocity
	var target_velocity := direction * target_speed
	
	# Apply acceleration/deceleration
	if enable_smoothing:
		if input_dir.length() > 0:
			_velocity = _velocity.lerp(target_velocity, acceleration * delta)
		else:
			_velocity = _velocity.lerp(Vector3.ZERO, deceleration * delta)
	else:
		_velocity = target_velocity
	
	# Apply movement
	global_position += _velocity * delta


func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true


func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_captured = false


func toggle_mouse_capture() -> void:
	if _mouse_captured:
		release_mouse()
	else:
		capture_mouse()


func set_position_and_look_at(pos: Vector3, target: Vector3) -> void:
	"""Helper function to position camera and look at a target"""
	global_position = pos
	look_at(target, Vector3.UP)
	
	# Extract pitch and yaw from new rotation
	_pitch = rotation.x
	_yaw = rotation.y
