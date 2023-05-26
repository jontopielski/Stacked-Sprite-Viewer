extends Control

enum ShadowMode {
	NONE,
	SILHOUETTE,
	CIRCLE,
}

var ROTATION_SPEED = 0.5

@export var backgrounds: Array[Resource] = []
@export var palettes: Array[Resource] = []
@export var outline_shader = Resource
@export var shadow_shader = Resource
@export var palette_shader = Resource

var bg_index = 0
var palette_index = 0
var current_file = ""
var last_modified_time = 0
var current_rotation = 0
var is_paused = false
var shadow_mode = ShadowMode.NONE

func _ready():
	show_hide_initial_elements()
	setup_default_button_presses()
	render_initial_stack()
	render_background()
	render_palette()
	get_window().files_dropped.connect(_on_Window_files_dropped)

func show_hide_initial_elements():
	$UI/Bot/Play.hide()
	$Stacked/PixelatedSprite.hide()
	$UI/Dimensions.hide()
	$UI/Instructions.hide()
	$DimensionsBg.hide()

func setup_default_button_presses():
	$UI/Top/AlwaysTop.button_pressed = true
	$UI/Top/Listen.button_pressed = true

func hide_title():
	if $TitleFadeTimer.is_stopped():
		$UI/Texts/Title.hide()
		$UI/Texts/TitleShadow.hide()

func _process(delta):
	handle_rotation(delta)
	if Input.is_action_just_pressed("zoom_in"):
		_on_zoom_in_pressed()
	if Input.is_action_just_pressed("zoom_out"):
		_on_zoom_out_pressed()
	if Input.is_action_just_pressed("screenshot") and OS.is_debug_build():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("C:\\Users\\jonto\\Desk$UI/Top\\Game_Screenshot_%s.png" % str(randi() % 1000))
	if Input.is_action_just_pressed("left"):
		_on_left_pressed()
	if Input.is_action_just_pressed("right"):
		_on_right_pressed()
	if Input.is_action_just_pressed("pause_play"):
		if is_paused:
			is_paused = false
			$UI/Bot/Pause.show()
			$UI/Bot/Pause._on_mouse_exited()
			$UI/Bot/Play.hide()
		else:
			is_paused = true
			$UI/Bot/Play.show()
			$UI/Bot/Play._on_mouse_exited()
			$UI/Bot/Pause.hide()

func _unhandled_input(event):
	if event.is_pressed():
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_on_zoom_in_pressed()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_on_zoom_out_pressed()

func handle_rotation(delta):
	if is_paused:
		return
	current_rotation += delta * ROTATION_SPEED
	if current_rotation > (2 * PI):
		current_rotation = 0
	update_rotations()

func update_rotations():
	$Stacked/StackedSprite.sprite_rotation = current_rotation
	$Stacked/PixelatedSprite/View/StackedSprite.sprite_rotation = current_rotation
	$Stacked/StackedShadow.sprite_rotation = current_rotation
	$Stacked/PixelatedSprite/View/StackedShadow.sprite_rotation = current_rotation
#	$Stacked/Shadow.rotation = current_rotation + deg_to_rad(-40)
#	$Stacked/PixelatedSprite/View/Shadow.rotation = current_rotation + deg_to_rad(-40)
	for stack in $Stacked/StackOutlines.get_children():
		stack.sprite_rotation = current_rotation
	for stack in $Stacked/PixelatedSprite/View/StackOutlines.get_children():
		stack.sprite_rotation = current_rotation

func render_initial_stack():
	var texture_width = $Stacked/StackedSprite.frame_width
	var zoom_count = get_initial_zoom(texture_width)
	$Stacked/StackedSprite.scale = Vector2(zoom_count, zoom_count)
	$Stacked/StackedShadow.scale = Vector2(zoom_count, zoom_count)
	for stack in $Stacked/StackOutlines.get_children():
		stack.scale = $Stacked/StackedSprite.scale
	$Stacked/Shadow.scale = $Stacked/StackedSprite.scale
	$Stacked/PixelatedSprite.stretch_shrink = zoom_count
	$Background/SubViewport/Camera2D.zoom = $Stacked/StackedSprite.scale
	render_stack()

func get_initial_zoom(texture_width):
	var zoom_count = 1
	while texture_width * zoom_count < get_viewport_rect().size.x / 4:
		zoom_count += 1
	return zoom_count

func offset_outlined_sprites(sprites, ref_position):
	var offsets = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0), Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	for i in range(0, len(sprites)):
		var next_sprite = sprites[i]
		next_sprite.position = ref_position + offsets[i]

func render_stack():
	var largest_dimension = max($Stacked/StackedSprite.frame_width, $Stacked/StackedSprite.texture.get_height()) * 2
	var sprite_edge_offset = Vector2(largest_dimension, largest_dimension) + Vector2(2, 2)
	$Stacked/StackedSprite.position = get_viewport_rect().size / 2
	$Stacked/StackedSprite.position.y += int($Stacked/StackedSprite.get_frame_count() * $Stacked/StackedSprite.y_offset * .85) * $Stacked/StackedSprite.scale.y / 2
	$Stacked/StackedSprite.position = Vector2(int($Stacked/StackedSprite.position.x), int($Stacked/StackedSprite.position.y))
	$Stacked/StackedShadow.position = $Stacked/StackedSprite.position + Vector2(0, 1)
	offset_outlined_sprites($Stacked/StackOutlines.get_children(), $Stacked/StackedSprite.position)
	$Stacked/PixelatedSprite.position = $Stacked/StackedSprite.position - (sprite_edge_offset * $Stacked/PixelatedSprite.stretch_shrink)
	$Stacked/PixelatedSprite/View/StackedSprite.position = sprite_edge_offset
	$Stacked/PixelatedSprite/View/Shadow.position = $Stacked/PixelatedSprite/View/StackedSprite.position
	$Stacked/PixelatedSprite/View/StackedShadow.position = $Stacked/PixelatedSprite/View/StackedSprite.position + Vector2(0, 1)
	offset_outlined_sprites($Stacked/PixelatedSprite/View/StackOutlines.get_children(), $Stacked/PixelatedSprite/View/StackedSprite.position)
	$Stacked/Shadow.position = $Stacked/StackedSprite.position
	$Stacked/Shadow.frame_width = $Stacked/StackedSprite.frame_width
	$Stacked/PixelatedSprite/View/Shadow.frame_width = $Stacked/StackedSprite.frame_width
	$Stacked/PixelatedSprite/View/StackedShadow.frame_width = $Stacked/StackedSprite.frame_width
	if $UI/Top/Pixelate.button_pressed:
		$Stacked/PixelatedSprite.show()
		$Stacked/StackedSprite.hide()
	else:
		$Stacked/PixelatedSprite.hide()
		$Stacked/StackedSprite.show()
	render_shadows()

func _on_Window_files_dropped(files):
	current_file = files[0]
	FileAccess.open(current_file, FileAccess.READ)
	last_modified_time = FileAccess.get_modified_time(current_file)
	load_image_at_current_file(true)
	show_dimensions_window()

func show_dimensions_window():
	$UI/Help.hide()
	$UI/Top.hide()
	$UI/Bot.hide()
	$UI/Hide.hide()
	$DimensionsBg.show()
	$UI/Dimensions.show()
	$UI/Texts/Title.show()
	$UI/Texts/Title.text = "Specify width and height"
	$UI/Texts/TitleShadow.show()
	$UI/Texts/TitleShadow.text = "Specify width and height"
	$UI/Texts/Terminal.show()
	$UI/Texts/Terminal.text = "Push to confirm"
	$UI/Texts/TerminalShadow.show()
	$UI/Texts/TerminalShadow.text = "Push to confirm"
	$UI/Dimensions/Width.value = $Stacked/StackedSprite.frame_width
	$UI/Dimensions/Height.value = $Stacked/StackedSprite.frame_width

func load_image_at_current_file(is_initial_load = false):
	var placeholder_image = Image.new()
	var final_texture = ImageTexture.new()
	placeholder_image.load(current_file)
	final_texture = ImageTexture.create_from_image(placeholder_image)
	if !final_texture:
		return
	$Stacked/StackedSprite.texture = final_texture
	$Stacked/StackedShadow.texture = final_texture
	$Stacked/PixelatedSprite/View/StackedShadow.texture = final_texture
	for stack in $Stacked/StackOutlines.get_children():
		stack.texture = final_texture
	$Stacked/PixelatedSprite/View/StackedSprite.texture = final_texture
	for stack in $Stacked/PixelatedSprite/View/StackOutlines.get_children():
		stack.texture = final_texture
	if is_initial_load:
		render_initial_stack()
	else:
		render_stack()
	if $UI/Texts/Title.visible:
		$UI/Texts/Title.hide()
		$UI/Texts/TitleShadow.hide()

func _on_zoom_in_pressed():
	if $Stacked/StackedSprite.scale > Vector2(10, 10):
		return
	$Stacked/StackedSprite.scale += Vector2.ONE
	$Stacked/Shadow.scale = $Stacked/StackedSprite.scale
	$Stacked/StackedShadow.scale = $Stacked/StackedSprite.scale
	for stack in $Stacked/StackOutlines.get_children():
		stack.scale = $Stacked/StackedSprite.scale
	$Stacked/PixelatedSprite.stretch_shrink += 1
	$Background/SubViewport/Camera2D.zoom = $Stacked/StackedSprite.scale
	render_stack()

func _on_zoom_out_pressed():
	if $Stacked/StackedSprite.scale > Vector2.ONE:
		$Stacked/StackedSprite.scale -= Vector2.ONE
	if $Stacked/PixelatedSprite.stretch_shrink > 1:
		$Stacked/PixelatedSprite.stretch_shrink -= 1
	for stack in $Stacked/StackOutlines.get_children():
		stack.scale = $Stacked/StackedSprite.scale
	$Stacked/Shadow.scale = $Stacked/StackedSprite.scale
	$Stacked/StackedShadow.scale = $Stacked/StackedSprite.scale
	$Background/SubViewport/Camera2D.zoom = $Stacked/StackedSprite.scale
	render_stack()

func _on_pixelate_toggled(_button_pressed):
	render_stack()

func _on_stacked_edit_text_submitted(new_text):
	if int(new_text) > 0:
		var frame_width = int(new_text)
		$Stacked/StackedSprite.frame_width = frame_width
		$Stacked/StackedShadow.frame_width = frame_width
		$Stacked/PixelatedSprite/View/StackedSprite.frame_width = frame_width
		$Stacked/PixelatedSprite/View/StackedShadow.frame_width = frame_width

func set_terminal_text(text):
	$UI/Texts/Terminal.text = text
	$UI/Texts/TerminalShadow.text = text

func _on_bg_button_pressed():
	bg_index += 1
	if bg_index >= len(backgrounds):
		bg_index = 0
	render_background()

func render_background():
	var current_background = backgrounds[bg_index]
	$Background/SubViewport/Pattern.texture = current_background.texture
	$Background/SubViewport/Camera2D.enabled = current_background.zoom_enabled
	$Stacked/PixelatedSprite/View/Shadow.color = current_background.shadow_color
	$Stacked/Shadow.color = current_background.shadow_color
	shadow_shader.set_shader_parameter("color", current_background.shadow_color)
	if $UI/Top/Outline.button_pressed:
		outline_shader.set_shader_parameter("color", current_background.enabled_outline_color)
	else:
		outline_shader.set_shader_parameter("color", current_background.disabled_outline_color)
	render_shadows()

func _on_pause_pressed():
	is_paused = true
	$UI/Bot/Pause.hide()
	$UI/Bot/Play/AnimationPlayer.play("sway")
	$UI/Bot/Play.show()

func _on_play_pressed():
	is_paused = false
	$UI/Bot/Pause/AnimationPlayer.play("sway")
	$UI/Bot/Pause.show()
	$UI/Bot/Play.hide()

func _on_always_top_toggled(button_pressed):
	get_window().always_on_top = button_pressed

func _on_expand_pressed():
	var base_resolution = Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), \
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	var current_resolution = get_window().size
	if current_resolution == base_resolution * 2:
		get_window().size = base_resolution * 3
	else:
		get_window().size = base_resolution * 2

func _on_left_pressed():
	is_paused = true
	$UI/Bot/Pause.hide()
	$UI/Bot/Play.show()
	$UI/Bot/Play/AnimationPlayer.play("RESET")
	$UI/Bot/Play/StackedSprite.scale = Vector2(1, 1)
	var degree_rotation = rad_to_deg($Stacked/StackedSprite.sprite_rotation)
	var rad_rotation = 0
	if int(degree_rotation) % 45 == 0:
		rad_rotation = deg_to_rad(int(degree_rotation + 45) % 360)
	else:
		rad_rotation = deg_to_rad(snapped(rad_to_deg($Stacked/StackedSprite.sprite_rotation), 45))
		if deg_to_rad(rad_rotation) > degree_rotation:
			rad_rotation += deg_to_rad(45)
	$Stacked/StackedSprite.sprite_rotation = rad_rotation
	$Stacked/StackedShadow.sprite_rotation = rad_rotation
	$Stacked/PixelatedSprite/View/StackedSprite.sprite_rotation = rad_rotation
	$Stacked/PixelatedSprite/View/StackedShadow.sprite_rotation = rad_rotation
	for stack in $Stacked/StackOutlines.get_children():
		stack.sprite_rotation = rad_rotation
	for stack in $Stacked/PixelatedSprite/View/StackOutlines.get_children():
		stack.sprite_rotation = rad_rotation
	current_rotation = rad_rotation

func _on_right_pressed():
	is_paused = true
	$UI/Bot/Pause.hide()
	$UI/Bot/Play.show()
	$UI/Bot/Play/AnimationPlayer.play("RESET")
	$UI/Bot/Play/StackedSprite.scale = Vector2(1, 1)
	var degree_rotation = rad_to_deg($Stacked/StackedSprite.sprite_rotation)
	var rad_rotation = 0
	if int(degree_rotation) % 45 == 0:
		rad_rotation = deg_to_rad(int(degree_rotation - 45) % 360)
	else:
		rad_rotation = deg_to_rad(snapped(rad_to_deg($Stacked/StackedSprite.sprite_rotation), 45))
		if deg_to_rad(rad_rotation) < degree_rotation:
			rad_rotation -= deg_to_rad(45)
	$Stacked/StackedSprite.sprite_rotation = rad_rotation
	$Stacked/StackedShadow.sprite_rotation = rad_rotation
	$Stacked/PixelatedSprite/View/StackedSprite.sprite_rotation = rad_rotation
	$Stacked/PixelatedSprite/View/StackedShadow.sprite_rotation = rad_rotation
	for stack in $Stacked/StackOutlines.get_children():
		stack.sprite_rotation = rad_rotation
	for stack in $Stacked/PixelatedSprite/View/StackOutlines.get_children():
		stack.sprite_rotation = rad_rotation
	current_rotation = rad_rotation

func _on_hide_toggled(button_pressed):
	if button_pressed:
		$UI/Texts.hide()
		$UI/Help.hide()
		$UI/Top.hide()
		$UI/Bot.hide()
	else:
		$UI/Help.show()
		$UI/Texts.show()
		$UI/Top.show()
		$UI/Bot.show()

func _on_outline_toggled(button_pressed):
	render_background()

func _on_file_listener_timeout():
	if current_file != "" and $UI/Top/Listen.button_pressed:
		FileAccess.open(current_file, FileAccess.READ)
		var current_modified = FileAccess.get_modified_time(current_file)
		if current_modified > last_modified_time:
			last_modified_time = current_modified
			load_image_at_current_file(false)

func _on_listen_toggled(button_pressed):
	if button_pressed:
		_on_file_listener_timeout()

func _on_confirm_pressed():
	update_stack_frame_width($UI/Dimensions/Width.value)
	$DimensionsBg.hide()
	$UI/Dimensions.hide()
	$UI/Help.show()
	$UI/Top.show()
	$UI/Bot.show()
	$UI/Hide.show()
	$UI/Texts/Title.text = ""
	$UI/Texts/Title.hide()
	$UI/Texts/TitleShadow.text = ""
	$UI/Texts/TitleShadow.hide()
	$UI/Texts/Terminal.text = ""
	$UI/Texts/TerminalShadow.text = ""

func update_stack_frame_width(frame_width):
	$Stacked/StackedSprite.frame_width = frame_width
	$Stacked/StackedShadow.frame_width = frame_width
	for stack in $Stacked/StackOutlines.get_children():
		stack.frame_width = frame_width
	$Stacked/PixelatedSprite/View/StackedSprite.frame_width = frame_width
	$Stacked/PixelatedSprite/View/StackedShadow.frame_width = frame_width
	for stack in $Stacked/PixelatedSprite/View/StackOutlines.get_children():
		stack.frame_width = frame_width
	render_stack()

func _on_dimensions_pressed():
	$UI/Top/Dimensions._on_mouse_exited()
	show_dimensions_window()

func _on_width_value_changed(value):
	update_stack_frame_width(value)

func _on_mouse_block_pressed():
	pass

func _on_speed_toggled(button_pressed):
	if button_pressed:
		ROTATION_SPEED = 1.0
	else:
		ROTATION_SPEED = 0.5

func _on_offset_toggled(button_pressed):
	var offset = 2 if button_pressed else 1
	$Stacked/StackedSprite.y_offset = offset
	for stack in $Stacked/StackOutlines.get_children():
		stack.y_offset = offset
	$Stacked/PixelatedSprite/View/StackedSprite.y_offset = offset
	for stack in $Stacked/PixelatedSprite/View/StackOutlines.get_children():
		stack.y_offset = offset
	render_stack()

func _on_help_toggled(button_pressed):
	if button_pressed:
		$Stacked.hide()
		$UI/Top.hide()
		$UI/Bot.hide()
		$UI/Hide.hide()
		$UI/Texts.hide()
		$UI/Instructions.show()
	else:
		$Stacked.show()
		$UI/Top.show()
		$UI/Bot.show()
		$UI/Hide.show()
		$UI/Texts.show()
		$UI/Instructions.hide()

func hide_all_shadows():
	$Stacked/Shadow.hide()
	$Stacked/StackedShadow.hide()
	$Stacked/PixelatedSprite/View/Shadow.hide()
	$Stacked/PixelatedSprite/View/StackedShadow.hide()

func render_palette():
	var current_palette = palettes[palette_index]
	palette_shader.set_shader_parameter("next_white_color", current_palette.white)
	palette_shader.set_shader_parameter("next_light_gray_color", current_palette.light_gray)
	palette_shader.set_shader_parameter("next_medium_gray_color", current_palette.dark_gray)
	palette_shader.set_shader_parameter("next_black_color", current_palette.black)

func render_shadows():
	hide_all_shadows()
	match shadow_mode:
		ShadowMode.NONE:
			pass
		ShadowMode.SILHOUETTE:
			if $UI/Top/Pixelate.button_pressed:
				$Stacked/PixelatedSprite/View/StackedShadow.show()
			else:
				$Stacked/StackedShadow.show()
		ShadowMode.CIRCLE:
			if $UI/Top/Pixelate.button_pressed:
				$Stacked/PixelatedSprite/View/Shadow.show()
			else:
				$Stacked/Shadow.show()

func _on_shadow_pressed():
	match shadow_mode:
		ShadowMode.NONE:
			shadow_mode = ShadowMode.SILHOUETTE
		ShadowMode.SILHOUETTE:
			shadow_mode = ShadowMode.CIRCLE
		ShadowMode.CIRCLE:
			shadow_mode = ShadowMode.NONE
	render_shadows()

func _on_palette_pressed():
	palette_index += 1
	if palette_index >= len(palettes):
		palette_index = 0
	render_palette()
