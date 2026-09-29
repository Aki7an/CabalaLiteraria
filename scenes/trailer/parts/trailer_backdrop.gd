extends Control

@export var start_offset := Vector2(0, 0)
@export var end_offset := Vector2(584, -1200)
@export var travel_sec := 20.0
@export var speed_scale := 0.5
@export var ping_pong := true

static var _origin_msec := -1


func _ready() -> void:
	if _origin_msec < 0:
		_origin_msec = Time.get_ticks_msec()
	visibility_changed.connect(_on_visibility_changed)
	_apply_offset(_elapsed())


func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_apply_offset(_elapsed())


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_apply_offset(_elapsed())


func _elapsed() -> float:
	return (Time.get_ticks_msec() - _origin_msec) / 1000.0 * speed_scale


func _apply_offset(elapsed: float) -> void:
	var layer := get_node_or_null("Container")
	if layer == null:
		return
	layer.position = _offset_at(elapsed)


func _offset_at(elapsed: float) -> Vector2:
	var duration := maxf(travel_sec, 0.001)
	var u := 0.0
	if ping_pong:
		var period := duration * 2.0
		var phase := fposmod(elapsed, period)
		if phase <= duration:
			u = phase / duration
		else:
			u = 1.0 - (phase - duration) / duration
	else:
		u = fposmod(elapsed, duration) / duration
	return start_offset.lerp(end_offset, u)
