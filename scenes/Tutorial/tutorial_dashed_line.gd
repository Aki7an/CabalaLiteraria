@tool
extends Control

@export var dash_color := Color(0.72, 0.58, 0.38, 0.62)
@export var dash_length := 16.0
@export var gap_length := 12.0
@export var line_width := 3.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var y := size.y * 0.5
	var x := 0.0
	while x < size.x:
		draw_line(
			Vector2(x, y),
			Vector2(minf(x + dash_length, size.x), y),
			dash_color,
			line_width,
			true
		)
		x += dash_length + gap_length
