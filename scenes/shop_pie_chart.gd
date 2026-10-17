@tool
extends Control

@export var color_cita := Color(0.106, 0.541, 0.812, 1):
	set(value):
		color_cita = value
		queue_redraw()
@export var color_curio := Color(0.812, 0.463, 0.176, 1):
	set(value):
		color_curio = value
		queue_redraw()
@export var color_frag := Color(0.4, 0.824, 0.698, 1):
	set(value):
		color_frag = value
		queue_redraw()
@export var color_efem := Color(0.812, 0.408, 0.38, 1):
	set(value):
		color_efem = value
		queue_redraw()
@export var divider_color := Color(1, 1, 1, 0.92):
	set(value):
		divider_color = value
		queue_redraw()
@export var divider_width := 6.0:
	set(value):
		divider_width = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	if radius <= 2.0:
		return
	_draw_slice(center, radius, 180.0, 270.0, color_cita)
	_draw_slice(center, radius, 270.0, 360.0, color_curio)
	_draw_slice(center, radius, 0.0, 90.0, color_frag)
	_draw_slice(center, radius, 90.0, 180.0, color_efem)
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), divider_color, divider_width)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), divider_color, divider_width)


func _draw_slice(center: Vector2, radius: float, start_deg: float, end_deg: float, color: Color) -> void:
	var points := PackedVector2Array()
	points.append(center)
	var steps := 28
	for i in range(steps + 1):
		var angle := deg_to_rad(lerpf(start_deg, end_deg, float(i) / float(steps)))
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
