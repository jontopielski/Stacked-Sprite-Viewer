extends Node2D

@export var color : Color = Color(0, 0, 0, .20)

@export var frame_width : float = 16 :
	set(value):
		frame_width = value
		queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, (frame_width / 2) - (frame_width / 10), color)
