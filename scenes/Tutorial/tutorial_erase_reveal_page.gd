extends VBoxContainer

const STAR_ON := preload("res://images/estrella_plano.png")
const LocaleDemo := preload("res://scenes/Tutorial/tutorial_locale_demo.gd")
const LETTER_BLACK := Color(0.08, 0.07, 0.06, 1)
const LETTER_GREEN := Color(0.12, 0.58, 0.32, 1)
const LETTER_RED := Color(0.72, 0.16, 0.16, 1)
const STAR_YELLOW := Color(1, 0.86, 0.2, 1)
const HAND_MOVE := 0.48
const TAP_DOWN := 0.09
const TAP_UP := 0.12
const HAND_TAP := TAP_DOWN + TAP_UP
const ERASE_PAUSE_START := 0.35
const ERASE_PAUSE_SELECT := 0.35
const ERASE_PAUSE_AFTER := 0.2
const ERASE_PAUSE_END := 1.1
const ERASE_DURATION := ERASE_PAUSE_START + HAND_MOVE + HAND_TAP + ERASE_PAUSE_SELECT + HAND_MOVE + HAND_TAP + ERASE_PAUSE_AFTER + ERASE_PAUSE_END
const FADE_IN := 0.18
const PRE_TAP := 0.28
const FADE_OUT := 0.16
const TAP_REVEAL := FADE_IN + PRE_TAP + HAND_TAP + FADE_OUT
const BLINK_HALF := 0.16
const BLINK_TILES := BLINK_HALF * 2.0
const PAINT_GAP := 0.36
const GREEN_GROUP := BLINK_TILES + PAINT_GAP
const CORRECT_POP := 0.18
const CORRECT_BLINK := 0.16
const CORRECT_AGAIN := 0.14
const CORRECT_SETTLE := 0.14
const SHOW_CORRECT := CORRECT_POP + CORRECT_BLINK + CORRECT_AGAIN + CORRECT_SETTLE
const WRONG_SCALE := 0.14
const WRONG_TIMES := 3
const WRONG_BLINK := WRONG_TIMES * (WRONG_SCALE * 2.0)
const INCORRECT_POP := 0.18
const LOST_SCALE := 0.16
const LOST_TIMES := 3
const LOST_FADE := 0.2
const SHOW_INCORRECT := INCORRECT_POP + LOST_TIMES * (LOST_SCALE * 2.0) + LOST_FADE
const WRONG_GROUP := WRONG_BLINK + SHOW_INCORRECT
const OK_GROUPS := 8
const BAD_GREEN_GROUPS := 8
const REVEAL_START := 0.3
const REVEAL_MID := 0.45
const REVEAL_END := 0.5
const REVEAL_DURATION := REVEAL_START + TAP_REVEAL + OK_GROUPS * GREEN_GROUP + SHOW_CORRECT + REVEAL_MID + TAP_REVEAL + BAD_GREEN_GROUPS * GREEN_GROUP + WRONG_GROUP + REVEAL_END
const ICON_PAUSE := "⏸"
const ICON_PLAY := "▶"
const GROUP_ERASE := "erase"
const GROUP_REVEAL := "reveal"

@export var style_tile_normal: StyleBoxFlat
@export var style_tile_selected: StyleBoxFlat
@export var style_tile_empty: StyleBoxFlat
@export var style_erase_pressed: StyleBoxFlat
@export var style_erase_normal: StyleBoxFlat
@export var style_wrong: StyleBoxFlat
@export var style_reveal_pressed: StyleBoxFlat
@export var style_reveal_normal: StyleBoxFlat

@onready var _page_title: Label = %PageTitle
@onready var _title_1: Label = %Title1
@onready var _body_1: Label = %Body1
@onready var _title_2: Label = %Title2
@onready var _body_2: Label = %Body2
@onready var _correct_prefix: Label = %CorrectPrefix
@onready var _correct_rest: Label = %CorrectRest
@onready var _wrong_prefix: Label = %WrongPrefix
@onready var _wrong_rest: Label = %WrongRest
@onready var _erase_label: Label = %EraseLabel
@onready var _reveal_title: Label = %RevealTitle
@onready var _demo: Control = %Demo
@onready var _demo2: Control = %Demo2
@onready var _hand: TextureRect = %Hand
@onready var _hand2: TextureRect = %Hand2
@onready var _tile_p: VBoxContainer = %TileP
@onready var _erase_button: Panel = %EraseButton
@onready var _reveal_button: Button = %RevealButton
@onready var _correct_col: Control = %CorrectCol
@onready var _wrong_col: Control = %WrongCol
@onready var _lost_star: TextureRect = %LostStar
@onready var _phrase2: Control = %Phrase2
@onready var _bar3: ProgressBar = %AnimBar3
@onready var _bar4: ProgressBar = %AnimBar4
@onready var _pause3: Button = %Pause3
@onready var _pause4: Button = %Pause4
@onready var _phrase_erase: HBoxContainer = $Card1/Box/Demo/Col/Phrase
@onready var _phrase_ok: HBoxContainer = $Card2/Box/Demo2/Col/Phrase
@onready var _phrase_bad: HBoxContainer = $Card2/Box/Demo2/Col/Phrase2
@onready var _correct_stars: Array[TextureRect] = []
@onready var _wrong_stars: Array[TextureRect] = []
@onready var _ok_tiles: Array[VBoxContainer] = []
@onready var _bad_tiles: Array[VBoxContainer] = []
var _ok_letters: Array = []
var _bad_letters: Array = []
var _wrong_index := 3
var _erase_wrong := "P"

var _active := false
var _loop_token := 0
var _erase_paused := false
var _reveal_paused := false
var _erase_tweens: Array[Tween] = []
var _reveal_tweens: Array[Tween] = []


func _ready() -> void:
	_correct_stars = [%CorrectStar1, %CorrectStar2, %CorrectStar3, %CorrectStar4, %CorrectStar5]
	_wrong_stars = [%WrongStar1, %WrongStar2, %WrongStar3, %WrongStar4]
	_prepare_stars()
	apply_locale()
	_pause3.pressed.connect(_toggle_erase_pause)
	_pause4.pressed.connect(_toggle_reveal_pause)
	visibility_changed.connect(_on_visibility_changed)
	set_active(visible)


func apply_locale() -> void:
	_page_title.text = tr("HowToPlay").to_upper()
	_title_1.text = tr("TutEraseTitle").to_upper()
	_body_1.text = tr("TutEraseBody")
	_title_2.text = tr("TutRevealSolTitle").to_upper()
	_body_2.text = tr("TutRevealSolBody")
	_correct_prefix.text = tr("TutAllCorrect")
	_correct_rest.text = tr("TutNoStarCost")
	_wrong_prefix.text = tr("TutEachWrong")
	_wrong_rest.text = tr("TutLoseStar")
	_erase_label.text = tr("TutEraseButton")
	_reveal_title.text = tr("TutReveal")
	_apply_demo_words()


func _apply_demo_words() -> void:
	var word := LocaleDemo.demo_word()
	var erase_tiles := LocaleDemo.fill_phrase(_phrase_erase, word)
	var repeats := LocaleDemo.repeating_letters(word)
	var erase_letter := repeats[1] if repeats.size() > 1 else (repeats[0] if repeats.size() > 0 else word.substr(mini(3, word.length() - 1), 1))
	var erase_index := word.find(erase_letter)
	if erase_index < 0:
		erase_index = mini(3, word.length() - 1)
		erase_letter = word.substr(erase_index, 1)
	_erase_wrong = LocaleDemo.wrong_letter(erase_letter, word)
	if erase_index < erase_tiles.size():
		_tile_p = erase_tiles[erase_index]
		LocaleDemo.letter_label(_tile_p).text = _erase_wrong
	_ok_letters.clear()
	_bad_letters.clear()
	for i in word.length():
		_ok_letters.append(word.substr(i, 1))
		_bad_letters.append(word.substr(i, 1))
	_wrong_index = erase_index
	if _wrong_index >= word.length():
		_wrong_index = mini(3, word.length() - 1)
	_bad_letters[_wrong_index] = LocaleDemo.wrong_letter(str(_ok_letters[_wrong_index]), word)
	var bad_word := ""
	for ch in _bad_letters:
		bad_word += str(ch)
	_ok_tiles = LocaleDemo.fill_phrase(_phrase_ok, word)
	_bad_tiles = LocaleDemo.fill_phrase(_phrase_bad, bad_word)


func set_active(active: bool) -> void:
	_active = active
	_loop_token += 1
	_erase_paused = false
	_reveal_paused = false
	_kill_group_tweens(GROUP_ERASE)
	_kill_group_tweens(GROUP_REVEAL)
	_sync_pause_button(_pause3, false)
	_sync_pause_button(_pause4, false)
	if active:
		_run_erase_loop(_loop_token)
		_run_reveal_loop(_loop_token)


func _on_visibility_changed() -> void:
	set_active(is_visible_in_tree())


func _tile_panel(tile: VBoxContainer) -> Panel:
	return tile.get_node("Panel") as Panel


func _tile_letter(tile: VBoxContainer) -> Label:
	return tile.get_node("Panel/HBoxContainer/Letter") as Label


func _still(token: int) -> bool:
	return _active and token == _loop_token and is_inside_tree()


func _run_erase_loop(token: int) -> void:
	if not await _await_frame():
		return
	if not await _await_frame():
		return
	while _active and token == _loop_token:
		_reset_erase()
		_fill_bar(_bar3, ERASE_DURATION, GROUP_ERASE)
		await _pause(ERASE_PAUSE_START, GROUP_ERASE)
		if not _still(token):
			return
		await _move_hand(_demo, _hand, _tile_panel(_tile_p), GROUP_ERASE)
		if not _still(token):
			return
		await _tap_hand(_demo, _hand, GROUP_ERASE)
		_tile_panel(_tile_p).add_theme_stylebox_override("panel", style_tile_selected)
		await _pause(ERASE_PAUSE_SELECT, GROUP_ERASE)
		if not _still(token):
			return
		await _move_hand(_demo, _hand, _erase_button, GROUP_ERASE)
		if not _still(token):
			return
		_erase_button.add_theme_stylebox_override("panel", style_erase_pressed)
		await _tap_hand(_demo, _hand, GROUP_ERASE)
		_erase_p()
		await _pause(ERASE_PAUSE_AFTER, GROUP_ERASE)
		_erase_button.add_theme_stylebox_override("panel", style_erase_normal)
		await _pause(ERASE_PAUSE_END, GROUP_ERASE)


func _run_reveal_loop(token: int) -> void:
	if not await _await_frame():
		return
	if not await _await_frame():
		return
	while _active and token == _loop_token:
		_reset_reveal()
		_fill_bar(_bar4, REVEAL_DURATION, GROUP_REVEAL)
		await _pause(REVEAL_START, GROUP_REVEAL)
		if not _still(token):
			return
		await _tap_reveal(token, false)
		if not _still(token):
			return
		await _paint_pass(token, _ok_tiles, _ok_letters, -1)
		if not _still(token):
			return
		await _show_correct()
		if not _still(token):
			return
		await _pause(REVEAL_MID, GROUP_REVEAL)
		if not _still(token):
			return
		await _tap_reveal(token, true)
		if not _still(token):
			return
		await _paint_pass(token, _bad_tiles, _bad_letters, _wrong_index)
		if not _still(token):
			return
		await _pause(REVEAL_END, GROUP_REVEAL)


func _tap_reveal(token: int, show_second_row: bool) -> void:
	if show_second_row:
		_phrase2.visible = true
	_hand2.position = _hand_pos(_demo2, _hand2, _reveal_button)
	_hand2.modulate.a = 0.0
	var fade_in := _anim_tween(GROUP_REVEAL)
	fade_in.tween_property(_hand2, "modulate:a", 1.0, FADE_IN)
	await _await_tween(fade_in)
	if not _still(token):
		return
	await _pause(PRE_TAP, GROUP_REVEAL)
	if not _still(token):
		return
	_reveal_button.add_theme_stylebox_override("normal", style_reveal_pressed)
	await _tap_hand(_demo2, _hand2, GROUP_REVEAL)
	_reveal_button.add_theme_stylebox_override("normal", style_reveal_normal)
	var fade_out := _anim_tween(GROUP_REVEAL)
	fade_out.tween_property(_hand2, "modulate:a", 0.0, FADE_OUT)
	await _await_tween(fade_out)


func _reset_erase() -> void:
	_clear_ripples(_demo)
	_tile_letter(_tile_p).text = _erase_wrong
	_tile_panel(_tile_p).add_theme_stylebox_override("panel", style_tile_empty)
	_erase_button.add_theme_stylebox_override("panel", style_erase_normal)
	_hand.position = _hand_start_erase()


func _erase_p() -> void:
	_tile_letter(_tile_p).text = ""
	_tile_panel(_tile_p).add_theme_stylebox_override("panel", style_tile_normal)


func _reset_reveal() -> void:
	_clear_ripples(_demo2)
	_reset_tiles(_ok_tiles, _ok_letters)
	_reset_tiles(_bad_tiles, _bad_letters)
	_correct_col.visible = false
	_wrong_col.visible = false
	_phrase2.visible = false
	_reset_stars()
	_hand2.modulate.a = 0.0
	_hand2.position = _hand_pos(_demo2, _hand2, _reveal_button)


func _reset_tiles(tiles: Array[VBoxContainer], letters: Array) -> void:
	for index in tiles.size():
		var tile := tiles[index]
		_tile_letter(tile).text = str(letters[index])
		_tile_letter(tile).add_theme_color_override("font_color", LETTER_BLACK)
		_tile_panel(tile).add_theme_stylebox_override("panel", style_tile_normal)
		tile.scale = Vector2.ONE


func _paint_pass(token: int, tiles: Array[VBoxContainer], letters: Array, wrong_index: int) -> void:
	var done: Dictionary = {}
	for index in letters.size():
		if not _still(token):
			return
		if done.get(index, false):
			continue
		if index == wrong_index:
			await _paint_wrong(token, tiles[index])
			done[index] = true
			continue
		var group := _same_indices(letters, index)
		for other in group:
			_set_green(tiles[other])
			done[other] = true
		await _blink_tiles(_tiles_from(tiles, group))
		await _pause(PAINT_GAP, GROUP_REVEAL)


func _tiles_from(tiles: Array[VBoxContainer], indices: Array[int]) -> Array[Control]:
	var out: Array[Control] = []
	for index in indices:
		out.append(tiles[index])
	return out


func _same_indices(letters: Array, index: int) -> Array[int]:
	var out: Array[int] = []
	var letter := str(letters[index])
	for other in letters.size():
		if str(letters[other]) == letter:
			out.append(other)
	return out


func _set_green(tile: VBoxContainer) -> void:
	_tile_panel(tile).add_theme_stylebox_override("panel", style_tile_normal)
	_tile_letter(tile).add_theme_color_override("font_color", LETTER_GREEN)


func _paint_wrong(token: int, tile: VBoxContainer) -> void:
	_tile_panel(tile).add_theme_stylebox_override("panel", style_wrong)
	_tile_letter(tile).add_theme_color_override("font_color", LETTER_RED)
	await _blink_tile(tile, WRONG_TIMES)
	if not _still(token):
		return
	await _show_incorrect()


func _blink_tiles(tiles: Array[Control]) -> void:
	for tile in tiles:
		tile.pivot_offset = tile.size * 0.5
	var tween := _anim_tween(GROUP_REVEAL)
	tween.set_parallel(true)
	for tile in tiles:
		tween.tween_property(tile, "scale", Vector2(1.22, 1.22), BLINK_HALF)
	await _await_tween(tween)
	if not _active:
		return
	var back := _anim_tween(GROUP_REVEAL)
	back.set_parallel(true)
	for tile in tiles:
		back.tween_property(tile, "scale", Vector2.ONE, BLINK_HALF)
	await _await_tween(back)


func _blink_tile(tile: Control, times: int) -> void:
	tile.pivot_offset = tile.size * 0.5
	for _i in times:
		if not _active:
			return
		var tween := _anim_tween(GROUP_REVEAL)
		tween.tween_property(tile, "scale", Vector2(1.28, 1.28), WRONG_SCALE)
		tween.tween_property(tile, "scale", Vector2.ONE, WRONG_SCALE)
		await _await_tween(tween)


func _show_correct() -> void:
	_correct_col.visible = true
	for star in _correct_stars:
		star.texture = STAR_ON
		star.modulate = STAR_YELLOW
		star.scale = Vector2(0.45, 0.45)
		star.pivot_offset = star.custom_minimum_size * 0.5
	var pop := _anim_tween(GROUP_REVEAL)
	pop.set_parallel(true)
	for star in _correct_stars:
		pop.tween_property(star, "scale", Vector2(1.22, 1.22), CORRECT_POP).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _await_tween(pop)
	if not _active:
		return
	var blink := _anim_tween(GROUP_REVEAL)
	blink.set_parallel(true)
	for star in _correct_stars:
		blink.tween_property(star, "scale", Vector2.ONE, CORRECT_BLINK)
	await _await_tween(blink)
	if not _active:
		return
	var again := _anim_tween(GROUP_REVEAL)
	again.set_parallel(true)
	for star in _correct_stars:
		again.tween_property(star, "scale", Vector2(1.18, 1.18), CORRECT_AGAIN)
	await _await_tween(again)
	if not _active:
		return
	var settle := _anim_tween(GROUP_REVEAL)
	settle.set_parallel(true)
	for star in _correct_stars:
		settle.tween_property(star, "scale", Vector2.ONE, CORRECT_SETTLE)
	await _await_tween(settle)


func _show_incorrect() -> void:
	_wrong_col.visible = true
	var stars: Array[TextureRect] = []
	stars.append_array(_wrong_stars)
	stars.append(_lost_star)
	for star in stars:
		star.texture = STAR_ON
		star.modulate = STAR_YELLOW
		star.scale = Vector2(0.45, 0.45)
		star.pivot_offset = star.custom_minimum_size * 0.5
	var pop := _anim_tween(GROUP_REVEAL)
	pop.set_parallel(true)
	for star in stars:
		pop.tween_property(star, "scale", Vector2.ONE, INCORRECT_POP).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _await_tween(pop)
	await _blink_lost_star()


func _prepare_stars() -> void:
	for star in _all_stars():
		star.pivot_offset = star.custom_minimum_size * 0.5


func _all_stars() -> Array[TextureRect]:
	var stars: Array[TextureRect] = []
	stars.append_array(_correct_stars)
	stars.append_array(_wrong_stars)
	stars.append(_lost_star)
	return stars


func _reset_stars() -> void:
	_prepare_stars()
	for star in _all_stars():
		star.texture = STAR_ON
		star.modulate = STAR_YELLOW
		star.scale = Vector2.ONE


func _blink_lost_star() -> void:
	_lost_star.pivot_offset = _lost_star.size * 0.5 if _lost_star.size.x > 1.0 else _lost_star.custom_minimum_size * 0.5
	for _i in LOST_TIMES:
		if not _active:
			return
		var tween := _anim_tween(GROUP_REVEAL)
		tween.tween_property(_lost_star, "scale", Vector2(1.35, 1.35), LOST_SCALE)
		tween.tween_property(_lost_star, "scale", Vector2.ONE, LOST_SCALE)
		await _await_tween(tween)
	var fade := _anim_tween(GROUP_REVEAL)
	fade.tween_property(_lost_star, "modulate:a", 0.0, LOST_FADE)
	await _await_tween(fade)


func _hand_start_erase() -> Vector2:
	var at_erase := _hand_pos(_demo, _hand, _erase_button)
	var size := _hand.size if _hand.size.x > 1.0 else _hand.custom_minimum_size
	var x := _demo.size.x - size.x - 40.0
	return Vector2(x, at_erase.y)


func _hand_pos(demo: Control, hand: TextureRect, target: Control) -> Vector2:
	var rect := target.get_global_rect()
	var tip := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.28)
	var local: Vector2 = demo.get_global_transform_with_canvas().affine_inverse() * tip
	var size := hand.size if hand.size.x > 1.0 else hand.custom_minimum_size
	return local - Vector2(size.x * 0.22, size.y * 0.04)


func _hand_tip(hand: TextureRect) -> Vector2:
	var size := hand.size if hand.size.x > 1.0 else hand.custom_minimum_size
	return hand.position + Vector2(size.x * 0.22, size.y * 0.04)


func _move_hand(demo: Control, hand: TextureRect, target: Control, group: String) -> void:
	var tween := _anim_tween(group)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hand, "position", _hand_pos(demo, hand, target), HAND_MOVE)
	await _await_tween(tween)


func _tap_hand(demo: Control, hand: TextureRect, group: String) -> void:
	_play_ripples(demo, _hand_tip(hand), group)
	var start := hand.scale
	var tween := _anim_tween(group)
	tween.tween_property(hand, "scale", start * 0.88, TAP_DOWN)
	tween.tween_property(hand, "scale", start, TAP_UP)
	await _await_tween(tween)


func _play_ripples(demo: Control, origin: Vector2, group: String) -> void:
	for index in 3:
		var ring := _make_ripple_ring()
		demo.add_child(ring)
		ring.position = origin - ring.pivot_offset
		ring.scale = Vector2(0.2, 0.2)
		ring.modulate.a = 0.0
		var delay := index * 0.08
		var grow := 1.35 + index * 0.45
		var peak := 0.7 - index * 0.12
		var tween := _anim_tween(group)
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
	ring.add_to_group("erase_ripples")
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


func _clear_ripples(demo: Control) -> void:
	if demo == null:
		return
	for child in demo.get_children():
		if child.is_in_group("erase_ripples"):
			child.queue_free()


func _pause(seconds: float, group: String) -> void:
	var tween := _anim_tween(group)
	tween.tween_interval(seconds)
	await _await_tween(tween)


func _fill_bar(bar: ProgressBar, duration: float, group: String) -> void:
	var previous: Variant = bar.get_meta("bar_tween", null)
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
	bar.value = 0.0
	var tween := _anim_tween(group)
	bar.set_meta("bar_tween", tween)
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	tween.tween_property(bar, "value", 1.0, duration)


func _toggle_erase_pause() -> void:
	_set_group_paused(GROUP_ERASE, not _erase_paused)


func _toggle_reveal_pause() -> void:
	_set_group_paused(GROUP_REVEAL, not _reveal_paused)


func _set_group_paused(group: String, paused: bool) -> void:
	if group == GROUP_ERASE:
		_erase_paused = paused
		_apply_pause(_erase_tweens, paused)
		_sync_pause_button(_pause3, paused)
	else:
		_reveal_paused = paused
		_apply_pause(_reveal_tweens, paused)
		_sync_pause_button(_pause4, paused)


func _apply_pause(tweens: Array[Tween], paused: bool) -> void:
	var index := tweens.size() - 1
	while index >= 0:
		var tween := tweens[index]
		if not tween.is_valid():
			tweens.remove_at(index)
		elif paused:
			tween.pause()
		else:
			tween.play()
		index -= 1


func _sync_pause_button(button: Button, paused: bool) -> void:
	button.text = ICON_PLAY if paused else ICON_PAUSE
	button.modulate.a = 0.95 if paused else 0.7


func _anim_tween(group: String) -> Tween:
	var tween := create_tween()
	if group == GROUP_ERASE:
		_erase_tweens.append(tween)
		if _erase_paused:
			tween.pause()
	else:
		_reveal_tweens.append(tween)
		if _reveal_paused:
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


func _kill_group_tweens(group: String) -> void:
	var tweens := _erase_tweens if group == GROUP_ERASE else _reveal_tweens
	for tween in tweens:
		if tween.is_valid():
			tween.kill()
	tweens.clear()
	if group == GROUP_ERASE:
		_clear_ripples(_demo)
	else:
		_clear_ripples(_demo2)
