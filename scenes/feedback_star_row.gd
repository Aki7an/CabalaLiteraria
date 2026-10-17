extends Control
class_name FeedbackStarRow

signal rating_changed(value: int)

const MIN_VALUE := 1
const MAX_VALUE := 5
const KNOB_R := 22.0
const TRACK_H := 8.0
const FONT_REG := preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")
const FONT_BOLD := preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")

var question_stars: int = 3
var _dragging := false
var _marks: Array[Label] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 104)
	_build_marks()
	resized.connect(_place_marks)
	_refresh_marks()
	call_deferred("_place_marks")


func _build_marks() -> void:
	for value in range(MIN_VALUE, MAX_VALUE + 1):
		var mark := Label.new()
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.text = str(value)
		mark.add_theme_font_override("font", FONT_BOLD)
		mark.add_theme_font_size_override("font_size", 34)
		add_child(mark)
		_marks.append(mark)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_place_marks()


func _place_marks() -> void:
	var y := size.y - 42.0
	for i in _marks.size():
		var mark := _marks[i]
		var x := _x_for(MIN_VALUE + i)
		mark.size = Vector2(48, 40)
		mark.position = Vector2(x - mark.size.x * 0.5, y)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_set_from_x(event.position.x)
			accept_event()
		else:
			_dragging = false
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_set_from_x(event.position.x)
		accept_event()
	elif event is InputEventScreenTouch:
		_dragging = event.pressed
		if event.pressed:
			_set_from_x(event.position.x)
		accept_event()
	elif event is InputEventScreenDrag:
		_dragging = true
		_set_from_x(event.position.x)
		accept_event()


func _set_from_x(local_x: float) -> void:
	var left := _track_left()
	var span := maxf(_track_right() - left, 1.0)
	var t := (local_x - left) / span
	var value := clampi(int(round(t * float(MAX_VALUE - MIN_VALUE))) + MIN_VALUE, MIN_VALUE, MAX_VALUE)
	if value == question_stars:
		return
	question_stars = value
	_refresh_marks()
	queue_redraw()
	rating_changed.emit(value)
	SoundManager.play("ButtonClick")


func _refresh_marks() -> void:
	for i in _marks.size():
		var mark := _marks[i]
		var value := MIN_VALUE + i
		if value == question_stars:
			mark.add_theme_color_override("font_color", Color(0.86, 0.38, 0.06, 1))
		else:
			mark.add_theme_color_override("font_color", Color(0.28, 0.17, 0.1, 1))


func _track_left() -> float:
	return KNOB_R + 6.0


func _track_right() -> float:
	return maxf(size.x - KNOB_R - 6.0, _track_left() + 1.0)


func _x_for(value: int) -> float:
	return lerpf(_track_left(), _track_right(), float(value - MIN_VALUE) / float(MAX_VALUE - MIN_VALUE))


func _draw() -> void:
	var cy := 34.0
	var left := _track_left()
	var right := _track_right()
	var fill := GameManager.star_fill_color() if GameManager else Color(0.95, 0.55, 0.12, 1)
	draw_line(Vector2(left, cy), Vector2(right, cy), Color(0.78, 0.62, 0.4, 0.55), TRACK_H, true)
	var knob_x := _x_for(question_stars)
	if knob_x > left:
		draw_line(Vector2(left, cy), Vector2(knob_x, cy), fill, TRACK_H, true)
	for value in range(MIN_VALUE, MAX_VALUE + 1):
		var x := _x_for(value)
		draw_line(Vector2(x, cy - 13.0), Vector2(x, cy + 13.0), Color(0.28, 0.17, 0.1, 0.9), 3.0, true)
	draw_circle(Vector2(knob_x, cy), KNOB_R + 3.0, Color(0.42, 0.2, 0.05, 0.28))
	draw_circle(Vector2(knob_x, cy), KNOB_R, Color(0.96, 0.54, 0.1, 1))
	draw_circle(Vector2(knob_x, cy), KNOB_R - 7.0, Color(1, 0.93, 0.78, 1))
	draw_arc(Vector2(knob_x, cy), KNOB_R, 0.0, TAU, 40, Color(0.62, 0.28, 0.04, 1), 4.0, true)
