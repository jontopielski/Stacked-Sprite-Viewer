@tool
extends Button

@export var texture_normal : Texture :
	set(value):
		texture_normal = value
		render_sprites()

@export var texture_pressed : Texture :
	set(value):
		texture_pressed = value
		render_sprites()

@export var scale_factor : float = 1.25

@export var hint_text : String = "Placeholder hint"

@export var toggle_color : Color = Color.GRAY

@export var input_string : String = ""

@export var can_press_hotkey_while_window_open : bool = false

func render_sprites():
	if !has_node("StackedSprite"):
		return
	$StackedSprite.texture = texture_normal
	var frame_width = $StackedSprite.frame_width
	var frame_height = texture_normal.get_height()
	var frame_count = texture_normal.get_width() / frame_width
	$StackedSprite.position = Vector2i(frame_width / 2, (frame_height / 2) + frame_count - 1)
	custom_minimum_size = Vector2i(frame_width, frame_height + (frame_count - 1))

func is_in_hide_window_and_pressing_hide():
	return toggle_mode and name == "Hide" and button_pressed

func _process(delta):
	if !Engine.is_editor_hint() and !input_string.is_empty() and Input.is_action_just_pressed(input_string):
		if get_tree().current_scene.is_any_window_open() and !can_press_hotkey_while_window_open and !is_in_hide_window_and_pressing_hide():
			return
		var connections = get_signal_connection_list("pressed")
		if toggle_mode:
			connections = get_signal_connection_list("toggled")
		for connection in connections:
			var callable = connection.callable
			if callable.get_object().name == "Tool":
				if toggle_mode:
					button_pressed = !button_pressed
				else:
					_on_button_down()
	if !Engine.is_editor_hint() and !input_string.is_empty() and Input.is_action_just_released(input_string):
		if get_tree().current_scene.is_any_window_open() and !can_press_hotkey_while_window_open:
			return
		if toggle_mode:
			return
		var connections = get_signal_connection_list("pressed")
		for connection in connections:
			var callable = connection.callable
			if callable.get_object().name == "Tool":
				callable.call()
				_on_button_up()

func _on_mouse_entered():
	$StackedSprite.scale = Vector2(scale_factor, scale_factor)
	$AnimationPlayer.play("sway")
	get_tree().call_group("Tool", "set_terminal_text", hint_text)

func _on_mouse_exited():
	$StackedSprite.scale = Vector2(1, 1)
	$AnimationPlayer.play("RESET")
	if get_tree().current_scene.is_dimensions_open():
		get_tree().call_group("Tool", "set_terminal_text", "Push to confirm")
	else:
		get_tree().call_group("Tool", "set_terminal_text", "")

func _on_button_down():
	$StackedSprite.texture = texture_pressed

func _on_button_up():
	if toggle_mode and button_pressed:
		return
	$StackedSprite.texture = texture_normal

func _on_toggled(btn_pressed):
	if btn_pressed:
		$StackedSprite.texture = texture_pressed
		modulate = toggle_color
	else:
		$StackedSprite.texture = texture_normal
		modulate = Color.WHITE
	if !get_tree().current_scene.is_dimensions_open():
		get_tree().call_group("Tool", "hide_title")

func _on_pressed():
	if !get_tree().current_scene.is_dimensions_open():
		get_tree().call_group("Tool", "hide_title")
