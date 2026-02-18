extends Node

## Input Setup Helper
## Run this once to automatically configure all required input actions
## After running, you can remove this autoload

func _ready() -> void:
	setup_input_actions()
	print("Free Flight Camera inputs configured successfully!")
	print("You can now remove this autoload from Project Settings.")


func setup_input_actions() -> void:
	# Movement actions
	add_action_if_missing("move_forward", KEY_W)
	add_action_if_missing("move_backward", KEY_S)
	add_action_if_missing("move_left", KEY_A)
	add_action_if_missing("move_right", KEY_D)
	add_action_if_missing("move_up", KEY_E)
	add_action_if_missing("move_down", KEY_Q)
	
	# Alternative up/down (Space and Ctrl)
	add_key_to_action("move_up", KEY_SPACE)
	add_key_to_action("move_down", KEY_CTRL)
	
	# Speed modifiers
	add_action_if_missing("move_sprint", KEY_SHIFT)
	add_action_if_missing("move_slow", KEY_ALT)


func add_action_if_missing(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event = InputEventKey.new()
		event.keycode = key
		InputMap.action_add_event(action_name, event)
		print("Added action: ", action_name, " (", OS.get_keycode_string(key), ")")


func add_key_to_action(action_name: String, key: Key) -> void:
	if InputMap.has_action(action_name):
		# Check if this key is already assigned
		var events = InputMap.action_get_events(action_name)
		for event in events:
			if event is InputEventKey and event.keycode == key:
				return  # Already exists
		
		var event = InputEventKey.new()
		event.keycode = key
		InputMap.action_add_event(action_name, event)
		print("Added ", OS.get_keycode_string(key), " to action: ", action_name)
