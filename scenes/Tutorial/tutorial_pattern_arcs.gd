@tool
extends Control

@export var tile_a_names: PackedStringArray = ["PatA1", "PatA2"]
@export var arc_color := Color(0.18, 0.72, 0.68, 0.9)
@export var dash_length := 8.0
@export var gap_length := 6.0
@export var line_width := 3.2
@export var arc_depth := -38.0
@export var from_top := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	set_notify_transform(true)
	if not Engine.is_editor_hint():
		var tree := get_tree()
		if tree == null:
			return
		await tree.process_frame
		if not is_inside_tree():
			return
		tree = get_tree()
		if tree == null:
			return
		await tree.process_frame
		if is_inside_tree():
			queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()


func _draw() -> void:
	if owner == null:
		return
	var points: Array[Vector2] = []
	for name in tile_a_names:
		var tile := owner.get_node_or_null("%" + name) as Control
		if tile == null:
			return
		var rect := tile.get_global_rect()
		var y := 4.0 if from_top else rect.size.y - 2.0
		var tip := rect.position + Vector2(rect.size.x * 0.5, y)
		points.append(get_global_transform_with_canvas().affine_inverse() * tip)
	if points.size() < 2:
		return
	for index in range(points.size() - 1):
		_draw_dashed_arc(points[index], points[index + 1])


func _draw_dashed_arc(start: Vector2, end: Vector2) -> void:
	var mid := (start + end) * 0.5 + Vector2(0.0, arc_depth)
	var previous := start
	var traveled := 0.0
	var drawing := true
	var steps := 28
	for step in range(1, steps + 1):
		var t := float(step) / float(steps)
		var point := _quad(start, mid, end, t)
		var segment := previous.distance_to(point)
		if drawing:
			draw_line(previous, point, arc_color, line_width, true)
		traveled += segment
		if drawing and traveled >= dash_length:
			drawing = false
			traveled = 0.0
		elif not drawing and traveled >= gap_length:
			drawing = true
			traveled = 0.0
		previous = point


func _quad(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * start + 2.0 * u * t * control + t * t * end
