@tool
extends Control

@export var line_color := Color(0.29, 0.21, 0.15, 0.88)
@export var line_width := 5.0
@export var dash_length := 8.0
@export var gap_length := 6.0
@export var corner_radius := 20.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)


func _draw() -> void:
	var inset := line_width * 0.5 + 1.0
	var rect := Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0)
	if rect.size.x < 8.0 or rect.size.y < 8.0:
		return
	_draw_dashed_rounded_rect(rect)


func _draw_dashed_rounded_rect(rect: Rect2) -> void:
	var pts := _rounded_rect_points(rect, corner_radius)
	if pts.size() < 2:
		return
	var on := true
	var leftover := dash_length
	for i in range(pts.size() - 1):
		var start: Vector2 = pts[i]
		var stop: Vector2 = pts[i + 1]
		var remaining := start.distance_to(stop)
		if remaining <= 0.001:
			continue
		var dir := (stop - start) / remaining
		var pos := start
		while remaining > 0.001:
			var step := minf(remaining, leftover)
			var nxt := pos + dir * step
			if on:
				draw_line(pos, nxt, line_color, line_width, true)
			remaining -= step
			leftover -= step
			pos = nxt
			if leftover <= 0.001:
				on = not on
				leftover = dash_length if on else gap_length


func _rounded_rect_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [
		[rect.position + Vector2(rect.size.x - r, r), -PI * 0.5, 0.0],
		[rect.position + Vector2(rect.size.x - r, rect.size.y - r), 0.0, PI * 0.5],
		[rect.position + Vector2(r, rect.size.y - r), PI * 0.5, PI],
		[rect.position + Vector2(r, r), PI, PI * 1.5],
	]
	for corner in corners:
		var center: Vector2 = corner[0]
		var from_a: float = corner[1]
		var to_a: float = corner[2]
		for step in range(7):
			var t := float(step) / 6.0
			var angle := lerpf(from_a, to_a, t)
			pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	if pts.size() > 0:
		pts.append(pts[0])
	return pts
