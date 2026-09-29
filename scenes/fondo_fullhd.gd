extends Control

const SIZE := Vector2i(1920, 1080)
const PATTERN := preload("res://images/Fondo.png")
const TINT := Color(0.59, 0.377403, 0.3127, 0.101961)
const PATTERN_SCALE := 3.81806
const PATTERN_ROT := 0.523598
const START_POS := Vector2(640, 1260)
const END_POS := Vector2(1280, -180)
const TRAVEL_SEC := 60.0

var _field: Node2D


func _enter_tree() -> void:
	_apply_fullhd()


func _ready() -> void:
	_apply_fullhd()
	_silence()
	_hide_overlays()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_pattern_field()
	_play_drift()


func _apply_fullhd() -> void:
	var win := get_window()
	if win == null:
		return
	win.mode = Window.MODE_WINDOWED
	win.min_size = SIZE
	win.size = SIZE
	win.content_scale_size = SIZE
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _build_pattern_field() -> void:
	if _field and is_instance_valid(_field):
		_field.queue_free()
	_field = Node2D.new()
	_field.name = "PatternField"
	add_child(_field)
	var sprite := Sprite2D.new()
	sprite.texture = PATTERN
	sprite.modulate = TINT
	sprite.rotation = PATTERN_ROT
	sprite.scale = Vector2(PATTERN_SCALE, PATTERN_SCALE)
	sprite.position = START_POS
	_field.add_child(sprite)


func _play_drift() -> void:
	if _field == null:
		return
	var tw := create_tween()
	tw.tween_property(_field, "position", END_POS - START_POS, TRAVEL_SEC).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)


func _silence() -> void:
	for bus_i in AudioServer.bus_count:
		AudioServer.set_bus_mute(bus_i, true)


func _hide_overlays() -> void:
	for path in ["/root/TransitionScreen", "/root/StarCollectOverlay"]:
		var node := get_node_or_null(path)
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		if node is Node:
			node.process_mode = Node.PROCESS_MODE_DISABLED
