extends Panel

@onready var thumb: Control = $Thumb
@onready var thumb_visual: Panel = $Thumb/Visual
@onready var canvas: Control = $"../CanvasJuego"

const THUMB_MIN_HEIGHT := 240.0
const VISUAL_WIDTH := 46.0
const EDGE_PADDING := 4.0
const RAIL_PADDING := 8.0

var _dragging := false
var _drag_offset_y := 0.0
var _active_touch_index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	thumb.mouse_filter = Control.MOUSE_FILTER_STOP
	thumb.mouse_default_cursor_shape = Control.CURSOR_DRAG
	if thumb_visual != null:
		thumb_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.gui_input.connect(_on_thumb_gui_input)
	gui_input.connect(_on_rail_gui_input)
	await get_tree().process_frame
	_ensure_thumb_size()
	_sync_thumb_to_canvas()


func _process(_delta: float) -> void:
	if not _dragging:
		_sync_thumb_to_canvas()


func _on_rail_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			return
		_begin_drag_at(mouse_event.position.y)
		accept_event()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed:
			return
		_active_touch_index = touch.index
		_begin_drag_at(touch.position.y)
		accept_event()


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
		_active_touch_index = touch.index if touch.pressed else -1
		if _dragging:
			_drag_offset_y = touch.position.y
		thumb.accept_event()
	elif event is InputEventScreenDrag and _dragging:
		var drag := event as InputEventScreenDrag
		if _active_touch_index >= 0 and drag.index != _active_touch_index:
			return
		_move_thumb_to(thumb.position.y + drag.position.y - _drag_offset_y)
		thumb.accept_event()


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			_dragging = false
	elif event is InputEventMouseMotion:
		_move_thumb_to(get_local_mouse_position().y - _drag_offset_y)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed and (_active_touch_index < 0 or touch.index == _active_touch_index):
			_dragging = false
			_active_touch_index = -1
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _active_touch_index >= 0 and drag.index != _active_touch_index:
			return
		_move_thumb_to(drag.position.y - global_position.y - _drag_offset_y)
		get_viewport().set_input_as_handled()


func _begin_drag_at(local_y: float) -> void:
	_ensure_thumb_size()
	_dragging = true
	_drag_offset_y = thumb.size.y * 0.5
	_move_thumb_to(local_y - _drag_offset_y)


func _ensure_thumb_size() -> void:
	var hit_width := maxf(size.x - RAIL_PADDING * 2.0, VISUAL_WIDTH)
	var height := maxf(thumb.size.y, THUMB_MIN_HEIGHT)
	thumb.size = Vector2(hit_width, height)
	thumb.position.x = (size.x - hit_width) * 0.5
	if thumb_visual != null:
		var visual_width := minf(VISUAL_WIDTH, hit_width)
		thumb_visual.size = Vector2(visual_width, height)
		thumb_visual.position = Vector2((hit_width - visual_width) * 0.5, 0.0)


func _move_thumb_to(target_y: float) -> void:
	_ensure_thumb_size()
	var limits := _thumb_limits()
	thumb.position.y = clampf(target_y, limits.x, limits.y)
	var travel := limits.y - limits.x
	var normalized := 0.0 if travel <= 0.0 else (thumb.position.y - limits.x) / travel
	canvas.call("set_scroll_normalized", normalized)


func _sync_thumb_to_canvas() -> void:
	if not canvas.has_method("get_scroll_normalized"):
		return
	_ensure_thumb_size()
	var limits := _thumb_limits()
	var normalized: float = clampf(float(canvas.call("get_scroll_normalized")), 0.0, 1.0)
	thumb.position.y = lerpf(limits.x, limits.y, normalized)


func _thumb_limits() -> Vector2:
	var top := EDGE_PADDING
	var bottom := size.y - thumb.size.y - EDGE_PADDING
	return Vector2(top, maxf(top, bottom))
