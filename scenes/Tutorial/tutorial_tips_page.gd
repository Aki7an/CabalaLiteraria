extends VBoxContainer

const HAND_MOVE := 0.5
const TAP_DOWN := 0.09
const TAP_UP := 0.12
const HAND_TAP := TAP_DOWN + TAP_UP
const PAUSE_START := 0.4
const PAUSE_MID := 0.32
const PAUSE_END := 1.15
const ICON_PAUSE := "⏸"
const ICON_PLAY := "▶"
const LocaleDemo := preload("res://scenes/Tutorial/tutorial_locale_demo.gd")

@export var style_tile_normal: StyleBoxFlat
@export var style_tile_selected: StyleBoxFlat
@export var style_color1: StyleBoxFlat
@export var style_color2: StyleBoxFlat
@export var style_key_normal: StyleBoxFlat
@export var style_key_used: StyleBoxFlat
@export var style_key_pressed: StyleBoxFlat

@onready var _page_title: Label = %PageTitle
@onready var _title_1: Label = %Title1
@onready var _body_1: Label = %Body1
@onready var _title_2: Label = %Title2
@onready var _body_2: Label = %Body2
@onready var _demo: Control = %Demo
@onready var _hand: TextureRect = %Hand
@onready var _key_a: Panel = %KeyA
@onready var _key_r: Panel = %KeyR
@onready var _chip1: Panel = %Chip1
@onready var _chip2: Panel = %Chip2
@onready var _bar: ProgressBar = %AnimBar5
@onready var _pause_btn: Button = %Pause5
@onready var _phrase: HBoxContainer = $Card1/Box/Demo/Col/Phrase
@onready var _keyboard: Control = $Card1/Box/Demo/Col/Keyboard
@onready var _whale_phrase: HBoxContainer = $Card2/Box/Phrase

var _active := false
var _loop_token := 0
var _paused := false
var _tweens: Array[Tween] = []
var _phrase_tiles: Array[VBoxContainer] = []
var _a_tiles: Array[VBoxContainer] = []
var _r_tiles: Array[VBoxContainer] = []
var _used_keys: Array[Panel] = []
var _color1_letter := "A"
var _color2_letter := "R"
var _gift_letters: PackedStringArray = PackedStringArray()
var _whale_green: StyleBoxFlat


func _ready() -> void:
	var green_tile := $Card2/Box/Phrase/WA1 as VBoxContainer
	if green_tile:
		var panel := LocaleDemo.tile_panel(green_tile)
		if panel:
			var box := panel.get_theme_stylebox("panel")
			if box is StyleBoxFlat:
				_whale_green = box as StyleBoxFlat
	apply_locale()
	_pause_btn.pressed.connect(_toggle_pause)
	visibility_changed.connect(_on_visibility_changed)
	set_active(visible)


func apply_locale() -> void:
	_page_title.text = tr("HowToPlay").to_upper()
	_title_1.text = tr("TutC3Title").to_upper()
	_body_1.text = tr("TutC3Body")
	_title_2.text = tr("TutC4Title").to_upper()
	_body_2.text = tr("TutC4Body")
	var word := LocaleDemo.demo_word()
	var repeats := LocaleDemo.repeating_letters(word)
	_color1_letter = repeats[0] if repeats.size() > 0 else "A"
	_color2_letter = repeats[1] if repeats.size() > 1 else (repeats[0] if repeats.size() > 0 else "R")
	_phrase_tiles = LocaleDemo.fill_phrase(_phrase, word, "", false)
	_a_tiles = LocaleDemo.tiles_with_letter(_phrase_tiles, _color1_letter)
	_r_tiles = LocaleDemo.tiles_with_letter(_phrase_tiles, _color2_letter)
	_gift_letters = PackedStringArray()
	var seen := {}
	for i in word.length():
		var ch := word.substr(i, 1)
		if ch == _color1_letter or ch == _color2_letter or seen.has(ch):
			continue
		seen[ch] = true
		_gift_letters.append(ch)
		if _gift_letters.size() >= 3:
			break
	for tile in _phrase_tiles:
		var ch := str(tile.get_meta("demo_letter"))
		var show := ch in _gift_letters
		LocaleDemo.letter_label(tile).text = ch if show else ""
	_key_a = LocaleDemo.find_key(_keyboard, _color1_letter)
	_key_r = LocaleDemo.find_key(_keyboard, _color2_letter)
	_used_keys.clear()
	for ch in _gift_letters:
		var key := LocaleDemo.find_key(_keyboard, ch)
		if key:
			_used_keys.append(key)
	LocaleDemo.sync_keyboard(_keyboard)
	var whale := LocaleDemo.whale_word()
	LocaleDemo.fill_whale(_whale_phrase, whale, style_tile_normal, _whale_green if _whale_green else style_tile_normal)


func set_active(active: bool) -> void:
	_active = active
	_loop_token += 1
	_paused = false
	_kill_tweens()
	_sync_pause_button()
	if active:
		_run_loop(_loop_token)
	else:
		_reset_demo()


func _on_visibility_changed() -> void:
	set_active(is_visible_in_tree())


func _tile_panel(tile: VBoxContainer) -> Panel:
	return tile.get_node("Panel") as Panel


func _tile_letter(tile: VBoxContainer) -> Label:
	return tile.get_node("Panel/HBoxContainer/Letter") as Label


func _loop_duration() -> float:
	return PAUSE_START + 7.0 * (HAND_MOVE + HAND_TAP + PAUSE_MID) + PAUSE_END


func _run_loop(token: int) -> void:
	if not await _await_frame():
		return
	if not await _await_frame():
		return
	while _active and token == _loop_token:
		_reset_demo()
		_fill_bar(_loop_duration())
		await _pause(PAUSE_START)
		if not _still(token):
			return
		if _a_tiles.is_empty() or _r_tiles.is_empty():
			await _pause(PAUSE_END)
			continue
		await _move_hand(_tile_panel(_a_tiles[0]))
		if not _still(token):
			return
		await _tap_hand()
		_paint_tiles(_a_tiles, style_tile_selected)
		await _pause(PAUSE_MID)
		if not _still(token):
			return
		await _move_hand(_chip1)
		if not _still(token):
			return
		await _tap_hand()
		_paint_tiles(_a_tiles, style_color1)
		await _pause(PAUSE_MID)
		if not _still(token):
			return
		await _move_hand(_tile_panel(_r_tiles[0]))
		if not _still(token):
			return
		await _tap_hand()
		_paint_tiles(_r_tiles, style_tile_selected)
		await _pause(PAUSE_MID)
		if not _still(token):
			return
		await _move_hand(_chip2)
		if not _still(token):
			return
		await _tap_hand()
		_paint_tiles(_r_tiles, style_color2)
		await _pause(PAUSE_MID)
		if not _still(token):
			return
		await _move_hand(_key_r)
		if not _still(token):
			return
		_set_key_style(_key_r, style_key_pressed, false)
		await _tap_hand()
		_fill_tiles(_r_tiles, _color2_letter, style_color2)
		_set_key_style(_key_r, style_key_used, true)
		await _pause(PAUSE_MID)
		if not _still(token):
			return
		await _move_hand(_tile_panel(_a_tiles[0]))
		if not _still(token):
			return
		await _tap_hand()
		_paint_tiles(_a_tiles, style_tile_selected)
		await _pause(PAUSE_MID)
		if not _still(token):
			return
		await _move_hand(_key_a)
		if not _still(token):
			return
		_set_key_style(_key_a, style_key_pressed, false)
		await _tap_hand()
		_fill_tiles(_a_tiles, _color1_letter, style_color1)
		_set_key_style(_key_a, style_key_used, true)
		await _pause(PAUSE_END)


func _still(token: int) -> bool:
	return _active and token == _loop_token and is_inside_tree()


func _reset_demo() -> void:
	_clear_ripples()
	for tile in _phrase_tiles:
		var ch := str(tile.get_meta("demo_letter")) if tile.has_meta("demo_letter") else ""
		_tile_letter(tile).text = ch if ch in _gift_letters else ""
		_tile_panel(tile).add_theme_stylebox_override("panel", style_tile_normal)
	if _key_a:
		_set_key_style(_key_a, style_key_normal, false)
	if _key_r:
		_set_key_style(_key_r, style_key_normal, false)
	for key in _used_keys:
		_set_key_style(key, style_key_used, true)
	_hand.modulate.a = 1.0
	_hand.position = _hand_start()


func _set_key_style(key: Panel, style: StyleBoxFlat, used: bool) -> void:
	if key == null or style == null:
		return
	key.add_theme_stylebox_override("panel", style)
	var letter := key.get_node("Letter") as Label
	if letter == null:
		return
	if used:
		letter.add_theme_color_override("font_color", Color(0.99, 0.94, 0.86, 1))
	else:
		letter.add_theme_color_override("font_color", Color(0.28, 0.16, 0.09, 1))


func _paint_tiles(tiles: Array[VBoxContainer], style: StyleBoxFlat) -> void:
	if style == null:
		return
	for tile in tiles:
		_tile_panel(tile).add_theme_stylebox_override("panel", style)


func _fill_tiles(tiles: Array[VBoxContainer], letter: String, style: StyleBoxFlat) -> void:
	for tile in tiles:
		_tile_letter(tile).text = letter
		_tile_panel(tile).add_theme_stylebox_override("panel", style)


func _hand_start() -> Vector2:
	var size := _hand.size if _hand.size.x > 1.0 else _hand.custom_minimum_size
	return Vector2(_demo.size.x - size.x * 0.04, _demo.size.y - size.y * 0.16)


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
	if target == null:
		return
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
	ring.add_to_group("tips_ripples")
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
		if child.is_in_group("tips_ripples"):
			child.queue_free()


func _pause(seconds: float) -> void:
	var tween := _anim_tween()
	tween.tween_interval(seconds)
	await _await_tween(tween)


func _fill_bar(duration: float) -> void:
	var previous: Variant = _bar.get_meta("bar_tween", null)
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	_bar.value = 0.0
	var tween := _anim_tween()
	_bar.set_meta("bar_tween", tween)
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	tween.tween_property(_bar, "value", 1.0, duration)


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
