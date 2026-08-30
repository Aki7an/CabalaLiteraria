extends Control

@export_range(0.0, 100.0, 1.0) var progress_value := 0.0:
	set(value):
		progress_value = clampf(value, 0.0, 100.0)
		queue_redraw()

@export var track_color := Color(0.86, 0.74, 0.55, 0.32)
@export var fill_color := Color(0.23, 0.64, 0.54, 1.0)
@export_range(2.0, 30.0, 1.0) var line_width := 16.0


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func set_progress_value(value: float) -> void:
	progress_value = value


func _draw() -> void:
	var center := size * 0.5
	var radius := maxf(1.0, minf(size.x, size.y) * 0.5 - line_width)
	var start_angle := -PI * 0.5
	var end_angle := start_angle + TAU
	draw_arc(center, radius, start_angle, end_angle, 96, track_color, line_width, true)
	if progress_value <= 0.0:
		return
	var fill_end := start_angle + TAU * (progress_value / 100.0)
	draw_arc(center, radius, start_angle, fill_end, 96, fill_color, line_width, true)
	if progress_value < 100.0:
		var cap_radius := line_width * 0.5
		var start_point := center + Vector2(cos(start_angle), sin(start_angle)) * radius
		var end_point := center + Vector2(cos(fill_end), sin(fill_end)) * radius
		draw_circle(start_point, cap_radius, fill_color, true)
		draw_circle(end_point, cap_radius, fill_color, true)
