extends Panel

@onready var thumb: Panel = $Thumb
@onready var page_up: Button = $PageUp
@onready var page_down: Button = $PageDown
@onready var canvas: Control = $"../CanvasJuego"

var _dragging := false
var _drag_offset_y := 0.0


func _ready() -> void:
	thumb.mouse_filter = Control.MOUSE_FILTER_STOP
	thumb.mouse_default_cursor_shape = Control.CURSOR_DRAG
	thumb.gui_input.connect(_on_thumb_gui_input)
	await get_tree().process_frame
	_sync_thumb_to_canvas()


func _process(_delta: float) -> void:
	if not _dragging:
		_sync_thumb_to_canvas()


func _on_thumb_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		_dragging = mouse_event.pressed
		if _dragging:
			_drag_offset_y = mouse_event.position.y
		thumb.accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		_move_thumb_to(thumb.position.y + motion.position.y - _drag_offset_y)
		thumb.accept_event()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_dragging = touch.pressed
		if _dragging:
			_drag_offset_y = touch.position.y
		thumb.accept_event()
	elif event is InputEventScreenDrag and _dragging:
		var drag := event as InputEventScreenDrag
		_move_thumb_to(thumb.position.y + drag.position.y - _drag_offset_y)
		thumb.accept_event()


func _move_thumb_to(target_y: float) -> void:
	var limits := _thumb_limits()
	thumb.position.y = clampf(target_y, limits.x, limits.y)
	var travel := limits.y - limits.x
	var normalized := 0.0 if travel <= 0.0 else (thumb.position.y - limits.x) / travel
	canvas.call("set_scroll_normalized", normalized)


func _sync_thumb_to_canvas() -> void:
	if not canvas.has_method("get_scroll_normalized"):
		return
	var limits := _thumb_limits()
	var normalized: float = clampf(float(canvas.call("get_scroll_normalized")), 0.0, 1.0)
	thumb.position.y = lerpf(limits.x, limits.y, normalized)


func _thumb_limits() -> Vector2:
	var top := page_up.position.y + page_up.size.y + 14.0
	var bottom := page_down.position.y - thumb.size.y - 14.0
	return Vector2(top, maxf(top, bottom))
