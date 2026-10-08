extends Control
class_name DottedStarFrame

@export var line_color := Color(0.78, 0.52, 0.16, 0.95)
@export var dash := 7.0
@export var gap := 5.0
@export var thickness := 3.0
@export var inset := 6.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var radius := (minf(size.x, size.y) - inset * 2.0 - thickness) * 0.5
	if radius <= 2.0:
		return
	var center := size * 0.5
	var circumference := TAU * radius
	var traveled := 0.0
	var draw_dash := true
	while traveled < circumference:
		var piece := dash if draw_dash else gap
		var next := minf(traveled + piece, circumference)
		if draw_dash:
			var from_angle := traveled / radius - PI * 0.5
			var to_angle := next / radius - PI * 0.5
			draw_arc(center, radius, from_angle, to_angle, 10, line_color, thickness, true)
		traveled = next
		draw_dash = not draw_dash
