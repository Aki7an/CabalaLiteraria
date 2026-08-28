@tool
extends Control

@export var line_color := Color("#FFF7DB")
@export_range(4.0, 30.0, 1.0) var stroke_width := 14.0:
	set(value):
		stroke_width = value
		queue_redraw()
@export_range(0.1, 0.8, 0.01) var tip_x_ratio := 0.18:
	set(value):
		tip_x_ratio = value
		queue_redraw()
@export_range(0.2, 0.9, 0.01) var shaft_end_ratio := 0.82:
	set(value):
		shaft_end_ratio = value
		queue_redraw()
@export_range(0.1, 0.5, 0.01) var head_length_ratio := 0.34:
	set(value):
		head_length_ratio = value
		queue_redraw()
@export_range(0.1, 0.5, 0.01) var head_spread_ratio := 0.28:
	set(value):
		head_spread_ratio = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var center_y := size.y * 0.5
	var tip := Vector2(size.x * tip_x_ratio, center_y)
	var shaft_end := Vector2(size.x * shaft_end_ratio, center_y)
	var head_x := tip.x + size.x * head_length_ratio
	var head_spread := size.y * head_spread_ratio
	var upper := Vector2(head_x, center_y - head_spread)
	var lower := Vector2(head_x, center_y + head_spread)

	_draw_rounded_segment(tip, shaft_end)
	_draw_rounded_segment(tip, upper)
	_draw_rounded_segment(tip, lower)
	draw_circle(tip, stroke_width * 0.5, line_color, true, -1.0, true)


func _draw_rounded_segment(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, line_color, stroke_width, true)
	draw_circle(to, stroke_width * 0.5, line_color, true, -1.0, true)
