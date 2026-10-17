extends Control

signal flipped

const CAP := Color(0.353, 0.196, 0.078, 1)
const OUTLINE := Color(0.29, 0.165, 0.071, 1)
const SAND := Color(0.941, 0.627, 0.125, 1)
## Height fraction of the top chamber filled at the start of each minute.
## The remaining 20% is an air gap under the top cap.
const INITIAL_TOP_FILL := 0.80

var _progress := 0.0
var _flipping := false
var _flip_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_center_pivot)
	_center_pivot()
	queue_redraw()


func is_flipping() -> bool:
	return _flipping


func set_sand_progress(value: float) -> void:
	if _flipping:
		return
	var next := clampf(value, 0.0, 1.0)
	if is_equal_approx(next, _progress):
		return
	_progress = next
	queue_redraw()


func play_flip() -> void:
	if _flipping:
		return
	_flipping = true
	_progress = 1.0
	queue_redraw()
	_center_pivot()
	rotation = 0.0
	if _flip_tween != null and _flip_tween.is_valid():
		_flip_tween.kill()
	_flip_tween = create_tween()
	_flip_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_flip_tween.tween_property(self, "rotation", PI, 0.55)
	await _flip_tween.finished
	rotation = 0.0
	_progress = 0.0
	queue_redraw()
	_flipping = false
	flipped.emit()


func _center_pivot() -> void:
	pivot_offset = size * 0.5


func _draw() -> void:
	var s := minf(size.x, size.y)
	if s <= 1.0:
		return
	var origin := (size - Vector2(s, s)) * 0.5
	var u := s / 96.0

	var top_cap := Rect2(origin + Vector2(22, 10) * u, Vector2(52, 10) * u)
	var bot_cap := Rect2(origin + Vector2(22, 76) * u, Vector2(52, 10) * u)
	draw_rect(top_cap, CAP, true)
	draw_rect(bot_cap, CAP, true)

	var a := origin + Vector2(31, 21) * u
	var b := origin + Vector2(65, 21) * u
	var c := origin + Vector2(48, 47.5) * u
	var d := origin + Vector2(31, 75) * u
	var e := origin + Vector2(65, 75) * u
	var f := origin + Vector2(48, 48.5) * u

	var p := clampf(_progress, 0.0, 1.0)
	var air0 := 1.0 - INITIAL_TOP_FILL
	# 0 = full to the rim; air0 = 20% gap at top; 1 = empty.
	var top_t := lerpf(air0, 1.0, p)
	if top_t < 0.995:
		var left := a.lerp(c, top_t)
		var right := b.lerp(c, top_t)
		draw_colored_polygon(PackedVector2Array([left, right, c]), SAND)

	# Sand that left the top collects in the bottom, same height fraction.
	var bot_t := lerpf(0.0, INITIAL_TOP_FILL, p)
	if bot_t > 0.02:
		var left_b := d.lerp(f, bot_t)
		var right_b := e.lerp(f, bot_t)
		draw_colored_polygon(PackedVector2Array([d, e, right_b, left_b]), SAND)

	if top_t < 0.995:
		var stream_w := maxf(2.2 * u, 1.6)
		draw_line(c, f, SAND, stream_w, true)

	var outline_w := maxf(3.2 * u, 2.2)
	draw_polyline(PackedVector2Array([a, c, b]), OUTLINE, outline_w, true)
	draw_polyline(PackedVector2Array([d, f, e]), OUTLINE, outline_w, true)
	draw_line(a, b, OUTLINE, outline_w, true)
	draw_line(d, e, OUTLINE, outline_w, true)
