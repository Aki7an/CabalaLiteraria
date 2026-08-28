@tool
extends Control

## Línea ornamental que gana grosor y opacidad al acercarse al texto.

@export var flip_horizontal := false
@export var line_color := Color(0.67, 0.49, 0.29, 1.0)
@export_range(0.5, 6.0, 0.1) var outer_thickness := 0.8
@export_range(0.5, 6.0, 0.1) var inner_thickness := 2.8
@export_range(0.0, 1.0, 0.01) var outer_alpha := 0.16
@export_range(0.0, 1.0, 0.01) var inner_alpha := 0.58
@export_range(8, 96, 1) var segments := 48


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var center_y := size.y * 0.5
	var segment_width := size.x / float(segments)

	for index in segments:
		var t := (float(index) + 0.5) / float(segments)
		var toward_text := 1.0 - t if flip_horizontal else t
		var thickness := lerpf(outer_thickness, inner_thickness, toward_text)
		var alpha := lerpf(outer_alpha, inner_alpha, toward_text)
		var x_start := float(index) * segment_width
		var x_end := minf(size.x, x_start + segment_width + 1.0)
		var color := Color(line_color.r, line_color.g, line_color.b, alpha)
		draw_line(
			Vector2(x_start, center_y),
			Vector2(x_end, center_y),
			color,
			thickness,
			true
		)
