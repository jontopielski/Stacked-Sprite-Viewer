@tool
extends Node2D

@export var texture : Texture = null :
	set(value):
		texture = value
		estimate_frame_width()
		render_sprites()

@export var frame_width : int = 16 :
	set(value):
		frame_width = value
		if !is_estimating_frame_width():
			render_sprites()

@export var sprite_rotation : float = 0 :
	set(value):
		sprite_rotation = value
		for sprite in get_children():
			sprite.rotation = sprite_rotation

@export var shader : Resource = null :
	set(value):
		shader = value
		render_sprites()

@export var y_offset : int = 1 :
	set(value):
		y_offset = value
		render_sprites()

func _ready():
	render_sprites()

func get_frame_dimensions():
	return Vector2(frame_width, texture.get_height())

func get_frame_count():
	return int(texture.get_width() / frame_width)

func estimate_frame_width():
	frame_width = texture.get_height()

func is_estimating_frame_width():
	var stack_array = get_stack()
	for stack_dict in stack_array:
		for key in stack_dict.keys():
			if key == "function":
				if stack_dict[key] == "estimate_frame_width":
					return true
	return false

func clear_sprites():
	for sprite in get_children():
		sprite.queue_free()

func render_sprites():
	clear_sprites()
	var hframes = int(texture.get_width() / frame_width)
	for i in range(0, hframes):
		var next_sprite = Sprite2D.new()
		next_sprite.texture = texture
		next_sprite.hframes = hframes
		next_sprite.frame = i
		next_sprite.position = Vector2i(0, -i*y_offset)
		next_sprite.rotation = sprite_rotation
		if shader:
			next_sprite.material = shader
		add_child(next_sprite)
