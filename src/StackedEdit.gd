@tool
extends Control

signal text_submitted(new_text)

var last_submitted_text = ""

@export var texture : Texture :
	set(value):
		texture = value
		render_sprites()

@export var frame_width : int = 16 :
	set(value):
		frame_width = value
		render_sprites()

func render_sprites():
	if !has_node("StackedSprite"):
		return
	$StackedSprite.texture = texture
	$StackedSprite.frame_width = frame_width
	var frame_height = texture.get_height()
	var frame_count = texture.get_width() / frame_width
	$StackedSprite.position = Vector2i(frame_width / 2, (frame_height / 2) + frame_count - 1)

func _on_line_edit_mouse_entered():
	$AnimationPlayer.play("sway")

func _on_line_edit_focus_exited():
	if $LineEdit.text != last_submitted_text:
		emit_signal("text_submitted", $LineEdit.text)
		last_submitted_text = $LineEdit.text
	$AnimationPlayer.play("RESET")

func _on_line_edit_mouse_exited():
	if !$LineEdit.has_focus():
		$AnimationPlayer.play("RESET")

func _on_line_edit_text_submitted(new_text):
	last_submitted_text = new_text
	emit_signal("text_submitted", new_text)
