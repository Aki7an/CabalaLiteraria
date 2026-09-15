extends VBoxContainer

const HAND_MOVE := 0.48
const TAP_DOWN := 0.09
const TAP_UP := 0.12
const PAUSE_START := 0.35
const PAUSE_MID := 0.4
const PAUSE_END := 1.5
const LOOP_DURATION := PAUSE_START + HAND_MOVE + TAP_DOWN + TAP_UP + PAUSE_MID + HAND_MOVE + TAP_DOWN + TAP_UP + PAUSE_END
const ICON_PAUSE := "⏸"
const ICON_PLAY := "▶"

@export var style_tile_normal: StyleBoxFlat
@export var style_tile_empty_a: StyleBoxFlat
@export var style_tile_selected: StyleBoxFlat
@export var style_key_normal: StyleBoxFlat
@export var style_key_used: StyleBoxFlat
@export var style_key_pressed: StyleBoxFlat

@onready var _page_title: Label = %PageTitle
@onready var _title_1: Label = %Title1
@onready var _body_1: Label = %Body1
@onready var _caption_1: Label = %Caption1
@onready var _title_2: Label = %Title2
@onready var _body_2: Label = %Body2
@onready var _demo: Control = %Demo
@onready var _hand: TextureRect = %Hand
@onready var _key_a: Panel = %KeyA
@onready var _demo_a1: VBoxContainer = %DemoA1
@onready var _demo_a2: VBoxContainer = %DemoA2
@onready var _bar2: ProgressBar = %AnimBar2
@onready var _pause_btn: Button = %Pause2

var _active := false
var _loop_token := 0
var _paused := false
var _tweens: Array[Tween] = []


func _ready() -> void:
	apply_locale()
	_pause_btn.pressed.connect(_toggle_pause)
	visibility_changed.connect(_on_visibility_changed)
	set_active(visible)


func apply_locale() -> void:
	_page_title.text = tr("HowToPlay").to_upper()
	_title_1.text = tr("TutC1Title").to_upper()
	_body_1.text = tr("TutC1Body")
	_caption_1.text = tr("TutC1Caption")
	_title_2.text = tr("TutC2Title").to_upper()
	_body_2.text = tr("TutC2Body")


func set_active(active: bool) -> void:
	_active = active
	_loop_token += 1
	_paused = false
	_kill_tweens()
	_sync_pause_button()
	if active:
		_run_loop(_loop_token)


func _on_visibility_changed() -> void:
	set_active(is_visible_in_tree())


func _a_tiles() -> Array[VBoxContainer]:
	return [_demo_a1, _demo_a2]


func _tile_panel(tile: VBoxContainer) -> Panel:
	return tile.get_node("Panel") as Panel


func _tile_letter(tile: VBoxContainer) -> Label:
	var nested := tile.get_node_or_null("Panel/HBoxContainer/Letter")
	if nested:
		return nested as Label
	return tile.get_node("Panel/Letter") as Label


func _run_loop(token: int) -> void:
	if not await _await_frame():
		return
	if not await _await_frame():
		return
	while _active and token == _loop_token:
		_reset_demo()
		_fill_bar(_bar2, LOOP_DURATION)
		await _pause(PAUSE_START)
		if not _still(token):
			return
		await _move_hand(_tile_panel(_demo_a1))
		if not _still(token):
			return
		await _tap_hand()
		_select_a_cells(true)
		await _pause(PAUSE_MID)
		if not _still(token):
			return
		await _move_hand(_key_a)
		if not _still(token):
			return
		_key_a.add_theme_stylebox_override("panel", style_key_pressed)
		await _tap_hand()
		_fill_a_letters()
		await _pause(PAUSE_END)


func _still(token: int) -> bool:
	return _active and token == _loop_token and is_inside_tree()


func _reset_demo() -> void:
	_clear_ripples()
	for tile in _a_tiles():
		_tile_letter(tile).text = ""
		_tile_panel(tile).add_theme_stylebox_override("panel", style_tile_normal)
	_key_a.add_theme_stylebox_override("panel", style_key_normal)
	_hand.position = _hand_pos(_tile_panel(_demo_a1))


func _select_a_cells(selected: bool) -> void:
	var style := style_tile_selected if selected else style_tile_normal
	for tile in _a_tiles():
		_tile_panel(tile).add_theme_stylebox_override("panel", style)


func _fill_a_letters() -> void:
	for tile in _a_tiles():
		_tile_letter(tile).text = "A"
		_tile_panel(tile).add_theme_stylebox_override("panel", style_tile_normal)
	_key_a.add_theme_stylebox_override("panel", style_key_used)


func _hand_pos(target: Control) -> Vector2:
	var rect := target.get_global_rect()
	var tip := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.28)
	var local: Vector2 = _demo.get_global_transform_with_canvas().affine_inverse() * tip
	var size := _hand.size if _hand.size.x > 1.0 else _hand.custom_minimum_size
	return local - Vector2(size.x * 0.22, size.y * 0.04)


func _hand_tip() -> Vector2:
	var size := _hand.size if _hand.size.x > 1.0 else _hand.custom_minimum_size
	return _hand.position + Vector2(size.x * 0.22, size.y * 0.04)


func _move_hand(target: Control) -> void:
	var tween := _anim_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_hand, "position", _hand_pos(target), HAND_MOVE)
	await _await_tween(tween)


func _tap_hand() -> void:
	_play_ripples(_hand_tip())
	var start := _hand.scale
	var tween := _anim_tween()
	tween.tween_property(_hand, "scale", start * 0.88, TAP_DOWN)
	tween.tween_property(_hand, "scale", start, TAP_UP)
	await _await_tween(tween)


func _play_ripples(origin: Vector2) -> void:
	for index in 3:
		var ring := _make_ripple_ring()
		_demo.add_child(ring)
		ring.position = origin - ring.pivot_offset
		ring.scale = Vector2(0.2, 0.2)
		ring.modulate.a = 0.0
		var delay := index * 0.08
		var grow := 1.35 + index * 0.45
		var peak := 0.7 - index * 0.12
		var tween := _anim_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func() -> void:
			if is_instance_valid(ring):
				ring.modulate.a = peak
		)
		tween.set_parallel(true)
		tween.tween_property(ring, "scale", Vector2(grow, grow), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(ring, "modulate:a", 0.0, 0.45)
		tween.set_parallel(false)
		tween.tween_callback(func() -> void:
			if is_instance_valid(ring):
				ring.queue_free()
		)


func _make_ripple_ring() -> Panel:
	var ring := Panel.new()
	ring.add_to_group("howto_ripples")
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.z_index = 19
	ring.size = Vector2(96, 96)
	ring.pivot_offset = Vector2(48, 48)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.62, 0.28, 0.12)
	style.set_border_width_all(6)
	style.border_color = Color(0.86, 0.52, 0.22, 0.9)
	style.set_corner_radius_all(48)
	ring.add_theme_stylebox_override("panel", style)
	return ring


func _clear_ripples() -> void:
	if _demo == null:
		return
	for child in _demo.get_children():
		if child.is_in_group("howto_ripples"):
			child.queue_free()


func _pause(seconds: float) -> void:
	var tween := _anim_tween()
	tween.tween_interval(seconds)
	await _await_tween(tween)


func _fill_bar(bar: ProgressBar, duration: float) -> void:
	var previous: Variant = bar.get_meta("bar_tween", null)
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	bar.value = 0.0
	var tween := _anim_tween()
	bar.set_meta("bar_tween", tween)
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	tween.tween_property(bar, "value", 1.0, duration)


func _toggle_pause() -> void:
	_set_paused(not _paused)


func _set_paused(paused: bool) -> void:
	_paused = paused
	_sync_pause_button()
	var index := _tweens.size() - 1
	while index >= 0:
		var tween := _tweens[index]
		if not tween.is_valid():
			_tweens.remove_at(index)
		elif paused:
			tween.pause()
		else:
			tween.play()
		index -= 1


func _sync_pause_button() -> void:
	_pause_btn.text = ICON_PLAY if _paused else ICON_PAUSE
	_pause_btn.modulate.a = 0.95 if _paused else 0.7


func _anim_tween() -> Tween:
	var tween := create_tween()
	_tweens.append(tween)
	if _paused:
		tween.pause()
	return tween


func _await_frame() -> bool:
	if not is_inside_tree():
		return false
	var tree := get_tree()
	if tree == null:
		return false
	await tree.process_frame
	return is_inside_tree()


func _await_tween(tween: Tween) -> void:
	while tween.is_valid():
		if not await _await_frame():
			return


func _kill_tweens() -> void:
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_clear_ripples()
