extends Control
class_name StatsLineChart

@export var line_color := Color(0.165, 0.655, 0.647, 1)
@export var point_fill := Color(0.98, 0.97, 0.93, 1)
@export var grid_color := Color(0.45, 0.32, 0.22, 0.18)
@export var label_color := Color(0.45, 0.32, 0.22, 0.72)
@export var values: Array[float] = []:
	set(v):
		values = v
		queue_redraw()

var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	resized.connect(queue_redraw)
	queue_redraw()


func set_values(series: Array) -> void:
	var next: Array[float] = []
	for item in series:
		next.append(float(item))
	values = next


func _draw() -> void:
	var left := 54.0
	var right := size.x - 8.0
	var top := 10.0
	var bottom := size.y - 10.0
	if right <= left or bottom <= top:
		return

	var y_marks := [4.0, 6.0, 8.0]
	var y_min := 2.0
	var y_max := 10.0
	if not values.is_empty():
		var local_min := values[0]
		var local_max := values[0]
		for value in values:
			local_min = minf(local_min, value)
			local_max = maxf(local_max, value)
		y_min = minf(2.0, floor(local_min) - 1.0)
		y_max = maxf(8.0, ceil(local_max) + 1.0)
		y_marks = [
			lerpf(y_min, y_max, 0.2),
			lerpf(y_min, y_max, 0.5),
			lerpf(y_min, y_max, 0.8),
		]

	for mark in y_marks:
		var y := _map_y(mark, y_min, y_max, top, bottom)
		draw_line(Vector2(left, y), Vector2(right, y), grid_color, 2.0, true)
		var label := _format_minutes(mark)
		draw_string(_font, Vector2(4, y + 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, label_color)

	# Mid guideline near 6 min when in range.
	if y_min < 6.0 and y_max > 6.0:
		var mid_y := _map_y(6.0, y_min, y_max, top, bottom)
		draw_dashed_line(
			Vector2(left, mid_y),
			Vector2(right, mid_y),
			Color(line_color.r, line_color.g, line_color.b, 0.35),
			2.0,
			10.0,
			true,
			true
		)

	if values.size() < 2:
		return

	var points := PackedVector2Array()
	for i in range(values.size()):
		var t := float(i) / float(values.size() - 1)
		var x := lerpf(left, right, t)
		var y := _map_y(values[i], y_min, y_max, top, bottom)
		points.append(Vector2(x, y))

	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], line_color, 4.0, true)

	for point in points:
		draw_circle(point, 7.0, line_color, true, -1.0, true)
		draw_circle(point, 3.5, point_fill, true, -1.0, true)


func _map_y(value: float, y_min: float, y_max: float, top: float, bottom: float) -> float:
	var span := maxf(y_max - y_min, 0.001)
	var t := clampf((value - y_min) / span, 0.0, 1.0)
	return lerpf(bottom, top, t)


func _format_minutes(value: float) -> String:
	var minutes := int(round(value))
	return "%d min" % minutes
