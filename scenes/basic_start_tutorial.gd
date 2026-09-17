extends Control

const FONT: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const FONT_FILE: FontFile = preload("res://fonts/Fonts/Rubik-SemiBold.ttf")
const HAND: Texture2D = preload("res://images/tutorial/hand_pointer.png")
const STAR_TEX: Texture2D = preload("res://images/estrella_plano.png")
const TUTORIAL_ICON: Texture2D = preload("res://images/Tutorial.png")
const TUTORIAL_SHADOW: Texture2D = preload("res://images/TutorialShadow.png")
const VOWELS := ["A", "E", "I", "O", "U"]
const FILTER := Color(1, 1, 1, 0.92)
const INK := Color(0.24, 0.14, 0.08, 1)
const INK_SOFT := Color(0.38, 0.24, 0.14, 0.92)
const ORANGE := Color(0.96, 0.51, 0.01, 1)
const HAND_SIZE := Vector2(258, 330)
const HAND_SIZE_SMALL := Vector2(181, 231)
const CARD_SIDE := 70.0
const BODY_FONT := 44
const NOTE_FONT := 34
const HERO_FONT := 88
const PROMPT_FONT := 52
const PROMPT_MIN_H := 160.0
const BAR_H := 22.0
const STAR_SIZE := Vector2(90, 90)
const STAR_SLASH_SIZE := Vector2(110, 110)
const STAR_YELLOW := Color(1.0, 0.88, 0.12, 1)
const LETTER_GAP := 32.0
const EXAMPLE_GAP := 28.0
const EXAMPLE_LEAD_FONT := 56
const EXAMPLE_NUM_FONT := 120
const EXAMPLE_ARROW_FONT := 96
const EXAMPLE_LETTER_FONT := 128
const EXAMPLE_ROW_H := 148.0
const SKIP_CHECK_SIZE := 56.0
const STEP_COUNT := 6
const FOOTER_LIFT_SEC := 0.5
const FOOTER_REST_BOTTOM := -36.0
const FOOTER_REST_TOP := -520.0
const STEP1_BUTTON_GAP := 72.0
const STEP4_FADE_SEC := 2.0
const STEP4_HAND_SEC := 1.5
const PLAY_FADE_SEC := 0.75
const TUTORIAL_PHRASE := "CIFRALETRA ES UN JUEGO DE CRIPTOGRAMAS EN EL QUE HAS DE DESCUBRIR QUE LETRA CORRESPONDE A CADA NÚMERO. ESTUDIA EL PUZLE PARA LLEGAR A TUS CONCLUSIONES."
const TUTORIAL_GIFTS := "QUECIFRL"

var _step := 1
var _hole := Rect2()
var _click_through := Rect2()
var _target_cell: Celda
var _target_key: Letra
var _target_letter := ""
var _anim_token := 0
var _reveal_blink: Tween
var _play_blink: Tween
var _next_blink: Tween
var _blinks: Array[Tween] = []
var _ghosted := false
var _board_cover_alpha := 1.0
var _keyboard_cover_alpha := 0.0
var _reveal_sequence_running := false
var _letter_placed := false
var _keyboard_revealed := false
var _footer_tween: Tween
var _play_ref_width := 0.0
var _play_step1_width := 0.0
var _next_step1_width := 0.0
var _opening_full_tutorial := false
var _italic_font: FontVariation

var _header: PanelContainer
var _title: Label
var _step_label: Label
var _above_card: PanelContainer
var _above_body: RichTextLabel
var _card: PanelContainer
var _card_lead: Label
var _letter_gap_top: Control
var _card_letter: Label
var _letter_gap_bottom: Control
var _example_row: HBoxContainer
var _example_num: Label
var _example_letter: Label
var _body_gap: Control
var _card_body: RichTextLabel
var _card_sub: RichTextLabel
var _card_star: TextureRect
var _star_host: Control
var _star_slash: Control
var _star_gap: Control
var _card_fin: Label
var _menu_tutorial_demo: Control
var _footer: VBoxContainer
var _play: Button
var _next: Button
var _prompt: RichTextLabel
var _skip_row: Button
var _skip_icon: TextureRect
var _skip_tex_off: Texture2D
var _skip_tex_on: Texture2D
var _skip_on := false
var _skip_label: Label
var _bar: ProgressBar
var _hand: TextureRect
var _actions: HBoxContainer
var _actions_spacer: Control


func _ready() -> void:
	add_to_group("BasicStartTutorial")
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp := get_viewport()
	if vp:
		size = vp.get_visible_rect().size
	_build()
	if not SignalManager.puzzle_input.is_connected(_on_puzzle_input):
		SignalManager.puzzle_input.connect(_on_puzzle_input)
	await get_tree().process_frame
	await get_tree().process_frame
	var tries := 0
	while get_tree().get_nodes_in_group("Celda").is_empty() and tries < 40:
		await get_tree().process_frame
		tries += 1
	await _load_tutorial_puzzle()
	_pick_targets()
	if _target_cell == null or _target_letter.is_empty():
		_finish()
		return
	_show_step(1)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_header()
		_fit_card()
		queue_redraw()


func _draw() -> void:
	_draw_filter_with_holes(_visual_holes())


func _visual_holes() -> Array[Rect2]:
	var holes: Array[Rect2] = []
	match _step:
		2:
			if _hole.size.x > 8.0:
				holes.append(_hole)
		3:
			if _letter_placed:
				if _keyboard_cover_alpha < 0.99:
					var kb := _local_rect(_keyboard_node())
					if kb.size.x > 8.0:
						holes.append(kb)
				else:
					var board3 := _local_rect(_board_node())
					if board3.size.x > 8.0:
						holes.append(board3)
			elif _hole.size.x > 8.0:
				holes.append(_hole)
		4:
			var board := _local_rect(_board_node())
			if board.size.x > 8.0:
				holes.append(board)
			var reveal := _local_rect(_reveal_button()).grow(18.0)
			if reveal.size.x > 8.0:
				holes.append(reveal)
		5:
			var board5 := _local_rect(_board_node())
			if board5.size.x > 8.0:
				holes.append(board5)
	return holes


func _draw_filter_with_holes(holes: Array[Rect2]) -> void:
	var full := Rect2(Vector2.ZERO, size)
	var valid: Array[Rect2] = []
	for hole in holes:
		var clipped := hole.intersection(full)
		if clipped.size.x > 2.0 and clipped.size.y > 2.0:
			valid.append(clipped)
	if valid.is_empty():
		draw_rect(full, FILTER)
		return
	var ys: Array[float] = [0.0, size.y]
	for hole in valid:
		ys.append(hole.position.y)
		ys.append(hole.end.y)
	ys.sort()
	var bands: Array[float] = []
	for y in ys:
		if bands.is_empty() or absf(y - bands[bands.size() - 1]) > 0.5:
			bands.append(y)
	for i in range(bands.size() - 1):
		var y0 := bands[i]
		var y1 := bands[i + 1]
		if y1 - y0 < 0.5:
			continue
		var xs: Array[float] = [0.0, size.x]
		for hole in valid:
			if hole.position.y < y1 - 0.5 and hole.end.y > y0 + 0.5:
				xs.append(hole.position.x)
				xs.append(hole.end.x)
		xs.sort()
		var xbands: Array[float] = []
		for x in xs:
			if xbands.is_empty() or absf(x - xbands[xbands.size() - 1]) > 0.5:
				xbands.append(x)
		for j in range(xbands.size() - 1):
			var x0 := xbands[j]
			var x1 := xbands[j + 1]
			if x1 - x0 < 0.5:
				continue
			var mid := Vector2((x0 + x1) * 0.5, (y0 + y1) * 0.5)
			var inside := false
			for hole in valid:
				if hole.has_point(mid):
					inside = true
					break
			if not inside:
				draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), FILTER)
	var board := _local_rect(_board_node()) if _covers_board() or _step == 5 else Rect2()
	var covering := _covers_board()
	var kb_rect := _local_rect(_keyboard_node())
	for hole in valid:
		if covering and board.size.x > 8.0 and hole.intersects(board) and _board_cover_alpha > 0.4:
			continue
		if _keyboard_cover_alpha > 0.01 and kb_rect.size.x > 8.0 and hole.intersects(kb_rect):
			continue
		draw_rect(hole.grow(6.0), Color(0.96, 0.51, 0.01, 0.9), false, 6.0)
	if covering and board.size.x > 8.0 and _board_cover_alpha > 0.01:
		var cover := FILTER
		cover.a = FILTER.a * _board_cover_alpha
		draw_rect(board, cover)
	if covering and board.size.x > 8.0 and _board_cover_alpha < 0.45:
		var stroke_a := 0.9 * (1.0 - _board_cover_alpha)
		draw_rect(board.grow(6.0), Color(0.96, 0.51, 0.01, stroke_a), false, 6.0)
	if _keyboard_cover_alpha > 0.01 and kb_rect.size.x > 8.0:
		var kb_cover := FILTER
		kb_cover.a = FILTER.a * _keyboard_cover_alpha
		draw_rect(kb_rect, kb_cover)


func _covers_board() -> bool:
	return _step == 4 or _step == 5 or (_step == 3 and _letter_placed and _keyboard_cover_alpha >= 0.99)


func _has_point(point: Vector2) -> bool:
	if _step == 2 and _target_tap_rect().has_point(point):
		return true
	if _click_through.size.x > 4.0 and _click_through.grow(36.0).has_point(point):
		return false
	return Rect2(Vector2.ZERO, size).has_point(point)


func _gui_input(event: InputEvent) -> void:
	if _reveal_sequence_running:
		accept_event()
		return
	if not _is_press_event(event):
		return
	var pos := _event_local_pos(event)
	if _step == 6 and _menu_tutorial_demo and _menu_tutorial_demo.visible:
		var demo := _local_rect(_menu_tutorial_demo).grow(16.0)
		if demo.size.x > 8.0 and demo.has_point(pos):
			_open_full_tutorial()
			accept_event()
			return
	if _step == 2 and _target_tap_rect().has_point(pos):
		_activate_target_cell()
		accept_event()
		return
	if _step == 3 and _keyboard_revealed and not _letter_placed and _target_key and _local_rect(_target_key).grow(48.0).has_point(pos):
		_target_key.apply_from_keyboard()
		accept_event()


func on_reveal_clicked() -> bool:
	if _step != 4:
		return false
	if _reveal_sequence_running:
		return true
	_run_reveal_sequence()
	return true


func _on_puzzle_input(kind: String, data: Dictionary) -> void:
	if _step == 2 and kind == "cell" and _target_cell:
		if int(data.get("orden", -1)) == _target_cell.orden:
			_show_step(3)
	elif _step == 3 and _keyboard_revealed and not _letter_placed and kind == "letter":
		if str(data.get("letter", "")).to_upper() == _target_letter:
			_on_letter_assigned()


func _pick_targets() -> void:
	var counts: Dictionary = {}
	var candidates: Array[Celda] = []
	var board := _board_global()
	for node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		var cell: Celda = node
		if cell.bloqueada or cell.es_regalo_inicial or cell.revelada_verde:
			continue
		if cell.letra.strip_edges() == "" or cell.letra == " " or cell.numero >= 100:
			continue
		var key := GameManager._hint_letter_key(cell.letra)
		if key.is_empty():
			continue
		candidates.append(cell)
		counts[cell.numero] = int(counts.get(cell.numero, 0)) + 1
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: Celda, b: Celda) -> bool:
		var a_vis := 1 if board.intersects(a.get_global_rect()) else 0
		var b_vis := 1 if board.intersects(b.get_global_rect()) else 0
		if a_vis != b_vis:
			return a_vis > b_vis
		var a_key := GameManager._hint_letter_key(a.letra)
		var b_key := GameManager._hint_letter_key(b.letra)
		var a_target := 1 if a_key == "A" else 0
		var b_target := 1 if b_key == "A" else 0
		if a_target != b_target:
			return a_target > b_target
		var a_vowel := 1 if VOWELS.has(a_key) else 0
		var b_vowel := 1 if VOWELS.has(b_key) else 0
		if a_vowel != b_vowel:
			return a_vowel > b_vowel
		var a_n := int(counts.get(a.numero, 0))
		var b_n := int(counts.get(b.numero, 0))
		if a_n != b_n:
			return a_n > b_n
		return a.orden < b.orden
	)
	_target_cell = candidates[0]
	_target_letter = GameManager._hint_letter_key(_target_cell.letra)
	_target_key = _find_key(_target_letter)


func _find_key(letter: String) -> Letra:
	var wanted := letter.to_upper()
	for panel in get_tree().get_nodes_in_group("KeyboardPanel"):
		var grid := panel.get_node_or_null("GridContainer")
		if grid == null:
			continue
		for child in grid.get_children():
			if child is Letra and (child as Letra).letra.to_upper() == wanted:
				return child
	for node in get_tree().get_nodes_in_group("Letra"):
		if node is Letra and (node as Letra).letra.to_upper() == wanted:
			return node
	return null


func _show_step(step: int, fade_in := false) -> void:
	_anim_token += 1
	_step = step
	_step_label.text = "%d/%d" % [_step, STEP_COUNT]
	_stop_reveal_blink()
	_stop_play_blink()
	_stop_next_blink()
	_stop_blinks()
	_reveal_sequence_running = false
	_letter_placed = false
	_keyboard_revealed = step != 3
	_keyboard_cover_alpha = 0.0
	_kill_footer_tween()
	_restore_letter_alphas()
	_board_cover_alpha = 0.0 if step == 5 else 1.0
	if _card:
		_card.modulate.a = 0.0 if fade_in else 1.0
	if _above_card:
		_above_card.modulate.a = 0.0 if fade_in else 1.0
	if _prompt:
		_prompt.modulate.a = 0.0 if fade_in else 1.0
	if _next:
		_next.modulate.a = 1.0
	if _bar:
		_bar.modulate.a = 0.0 if fade_in else 1.0
	_hand.visible = false
	_apply_hand_size()
	_bar.visible = step == 2 or step == 3 or step == 4
	_next.visible = step == 1 or step == 5
	_prompt.visible = step == 2 or step == 3 or step == 4
	_play.visible = true
	_card.visible = step != 5
	_above_card.visible = false
	if step != 4 and step != 5 and step != 6:
		_fit_play_button(false)
	match step:
		1:
			_set_hole(Rect2(), Rect2())
			_set_step1_card()
			_place_card_below_header()
			_place_footer(false)
			_layout_step1_buttons()
			_start_text_blink(_example_letter)
			call_deferred("_start_play_blink")
			call_deferred("_start_next_blink")
			call_deferred("_capture_play_step1_width")
		2:
			_refresh_holes()
			_hide_card_extras()
			_set_card_plain(_break_after_colon(_t("TutBasicSelectCell", "Cuando tengas una hipótesis: 1- Primero tendrás que seleccionar la casilla de la hipótesis en el tablero.")))
			_set_select_cell_prompt()
			_place_card_below_header()
			_place_footer(false)
			_start_text_blink(_prompt)
			_run_cell_anim(_anim_token)
			call_deferred("_capture_play_ref_width")
		3:
			if _target_letter != "":
				_target_key = _find_key(_target_letter)
			if _target_cell:
				GameManager.set_celda_seleccionada(_target_cell.orden, _target_cell.numero)
				_target_cell.celda_selected.visible = true
			_set_card_letter_step()
			_set_press_letter_texts()
			_place_card_below_header()
			_set_hole(Rect2(), Rect2())
			call_deferred("_capture_play_ref_width")
			_run_step3_intro(_anim_token)
		4:
			_refresh_holes()
			_set_step4_card()
			_set_press_reveal_prompt()
			_place_card_in_hand_gap()
			_fit_play_button(false)
			_run_step4_intro(_anim_token, fade_in)
		5:
			_paint_tutorial_as_green()
			_refresh_holes()
			_hide_card_extras()
			_place_footer(false)
			_layout_play_with_next_right(true)
			_run_green_hold(_anim_token)
			call_deferred("_start_next_blink")
		6:
			_paint_tutorial_as_hypothesis()
			_set_hole(Rect2(), Rect2())
			_set_step6_card()
			_place_card_below_header()
			_place_footer(false)
			_layout_play_centered()
			call_deferred("_start_play_blink")
	call_deferred("_fit_card")
	if fade_in and step != 4:
		call_deferred("_fade_in_step_ui")
	queue_redraw()


func _refresh_holes() -> void:
	match _step:
		2:
			_set_hole(_local_rect(_board_node()), Rect2())
		3:
			if _letter_placed:
				_set_hole(_local_rect(_board_node()), Rect2())
			else:
				var key_rect := _local_rect(_target_key)
				if _target_key and _target_key.has_node("PanelLetra/Button"):
					key_rect = _local_rect(_target_key.get_node("PanelLetra/Button"))
				_set_hole(_local_rect(_keyboard_node()), key_rect)
		4:
			var reveal := _reveal_button()
			_set_hole(_local_rect(reveal).grow(18.0), _local_rect(reveal))
		5:
			_set_hole(_local_rect(_board_node()), Rect2())
		_:
			_set_hole(Rect2(), Rect2())


func _set_hole(visual: Rect2, click: Rect2) -> void:
	_hole = visual
	_click_through = click
	queue_redraw()


func _local_rect(node: CanvasItem) -> Rect2:
	if node == null or not is_instance_valid(node):
		return Rect2()
	var rect := (node as Control).get_global_rect() if node is Control else Rect2(node.get_global_transform_with_canvas().origin, Vector2(80, 80))
	var top_left := get_global_transform_with_canvas().affine_inverse() * rect.position
	return Rect2(top_left, rect.size)


func _target_tap_rect() -> Rect2:
	var rect := _local_rect(_target_cell)
	if rect.size.x < 4.0:
		return Rect2()
	rect = rect.grow(52.0)
	var min_side := 132.0
	if rect.size.x < min_side:
		var extra := (min_side - rect.size.x) * 0.5
		rect.position.x -= extra
		rect.size.x = min_side
	if rect.size.y < min_side:
		var extra := (min_side - rect.size.y) * 0.5
		rect.position.y -= extra
		rect.size.y = min_side
	return rect


func _is_press_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false


func _event_local_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouse:
		return (event as InputEventMouse).position
	if event is InputEventScreenTouch:
		var screen := (event as InputEventScreenTouch).position
		return get_global_transform_with_canvas().affine_inverse() * screen
	return Vector2.ZERO


func _activate_target_cell() -> void:
	if _step != 2 or _target_cell == null or not is_instance_valid(_target_cell):
		return
	_target_cell._on_button_pressed()
	if _step == 2:
		_show_step(3)


func _board_node() -> Control:
	return get_tree().get_first_node_in_group("PuzzleCanvas") as Control


func _board_global() -> Rect2:
	var board := _board_node()
	var frame := board.get_parent() as Control if board else null
	if frame:
		return frame.get_global_rect()
	return board.get_global_rect() if board else Rect2()


func _keyboard_node() -> Control:
	return get_tree().get_first_node_in_group("KeyboardPanel") as Control


func _reveal_button() -> Button:
	var hud := get_tree().get_first_node_in_group("GameHUD")
	if hud and hud.get("reveal_button"):
		return hud.reveal_button
	return null


func _place_card_below_header() -> void:
	_layout_header()
	_card.offset_left = CARD_SIDE
	_card.offset_right = -CARD_SIDE
	_card.offset_top = _header.offset_bottom + 24.0
	_fit_card()


func _place_above_card() -> void:
	_layout_header()
	if _above_card == null:
		return
	_above_card.offset_left = CARD_SIDE
	_above_card.offset_right = -CARD_SIDE
	_above_card.offset_top = _header.offset_bottom + 24.0
	_fit_above_card()


func _place_card_in_hand_gap() -> void:
	_layout_header()
	var reveal := _local_rect(_reveal_button())
	var gap_top := maxf(_header.offset_bottom + 24.0, reveal.end.y + 36.0)
	var gap_bottom := size.y + FOOTER_REST_TOP
	_card.offset_left = CARD_SIDE
	_card.offset_right = -CARD_SIDE
	_card.offset_top = gap_top
	_fit_card()
	var card_h := maxf(_card.size.y, 80.0)
	var max_top := gap_bottom - card_h
	var top := gap_top + 72.0
	if top > max_top:
		top = maxf(gap_top, max_top)
	_card.offset_top = top
	_fit_card()


func _place_card_lower() -> void:
	_layout_header()
	_place_footer(false)
	var gap_top := _header.offset_bottom + 48.0
	var gap_bottom := size.y + _footer.offset_top
	_card.offset_left = CARD_SIDE
	_card.offset_right = -CARD_SIDE
	_card.offset_top = gap_top
	_fit_card()
	var card_h := maxf(_card.size.y, 80.0)
	var top := lerpf(gap_top, gap_bottom - card_h, 0.42)
	_card.offset_top = top
	_fit_card()


func _layout_header() -> void:
	if _header == null:
		return
	_header.offset_left = CARD_SIDE
	_header.offset_right = -CARD_SIDE
	_header.offset_top = 24.0
	var h := maxf(_header.get_combined_minimum_size().y, 160.0)
	_header.offset_bottom = 24.0 + h


func _fit_card() -> void:
	if _card == null:
		return
	_card.grow_vertical = Control.GROW_DIRECTION_END
	_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_card.anchor_bottom = 0.0
	_card.offset_left = CARD_SIDE
	_card.offset_right = -CARD_SIDE
	var width := maxf(size.x - CARD_SIDE * 2.0, 200.0)
	_card.size.x = width
	var inner_w := width - 80.0
	if _card_body:
		_card_body.custom_minimum_size.x = inner_w
		_card_body.size.x = inner_w
	if _card_sub:
		_card_sub.custom_minimum_size.x = inner_w
		_card_sub.size.x = inner_w
	if _card_lead:
		_card_lead.size.x = inner_w
	var h := _measured_card_height(width)
	var reserve := 160.0 if _example_row and _example_row.visible else 260.0
	var max_h := maxf(size.y - _card.offset_top - reserve, 80.0)
	h = clampf(h, 80.0, max_h)
	if _example_row and _example_row.visible:
		h = maxf(h, _measured_card_height(width))
	_card.clip_contents = not (_example_row and _example_row.visible)
	_card.offset_bottom = _card.offset_top + h
	_card.size.y = h


func _measured_card_height(width: float) -> float:
	var inner_w := maxf(width - 80.0, 120.0)
	var h := 28.0 + 28.0
	if _card_lead and _card_lead.visible:
		h += FONT.get_multiline_string_size(_card_lead.text, HORIZONTAL_ALIGNMENT_CENTER, inner_w, BODY_FONT).y + 16.0
	if _card_letter and _card_letter.visible:
		if _letter_gap_top and _letter_gap_top.visible:
			h += LETTER_GAP
		h += float(HERO_FONT) + 16.0
		if _letter_gap_bottom and _letter_gap_bottom.visible:
			h += LETTER_GAP
	if _card_body and _card_body.visible:
		var body_txt := _card_body.get_parsed_text() if _card_body.bbcode_enabled else _card_body.text
		h += FONT.get_multiline_string_size(body_txt, HORIZONTAL_ALIGNMENT_CENTER, inner_w, BODY_FONT).y + 16.0
	if _body_gap and _body_gap.visible:
		h += EXAMPLE_GAP
	if _example_row and _example_row.visible:
		h += EXAMPLE_ROW_H + 16.0
	if _card_star and _card_star.visible:
		h += STAR_SLASH_SIZE.y + 16.0
	if _star_gap and _star_gap.visible:
		h += 28.0
	if _card_fin and _card_fin.visible:
		h += 52.0 + 24.0
	if _card_sub and _card_sub.visible:
		var sub_txt := _card_sub.get_parsed_text() if _card_sub.bbcode_enabled else _card_sub.text
		var sub_size := NOTE_FONT if _card_sub.bbcode_enabled else BODY_FONT
		h += FONT.get_multiline_string_size(sub_txt, HORIZONTAL_ALIGNMENT_CENTER, inner_w, sub_size).y + 16.0
	if _menu_tutorial_demo and _menu_tutorial_demo.visible:
		h += _menu_tutorial_demo.custom_minimum_size.y + 16.0
	return h


func _fit_above_card() -> void:
	if _above_card == null or not _above_card.visible:
		return
	_above_card.offset_left = CARD_SIDE
	_above_card.offset_right = -CARD_SIDE
	var width := maxf(size.x - CARD_SIDE * 2.0, 200.0)
	_above_card.size.x = width
	if _above_body:
		_above_body.size.x = width - 80.0
	var h := maxf(_above_card.get_combined_minimum_size().y, 80.0)
	_above_card.offset_bottom = _above_card.offset_top + h
	_above_card.size.y = h


func _place_footer(above_keyboard: bool) -> void:
	_kill_footer_tween()
	if above_keyboard:
		var lift := _keyboard_lift()
		_footer.offset_bottom = -lift
		_footer.offset_top = -(lift + 380.0)
	else:
		_footer.offset_bottom = FOOTER_REST_BOTTOM
		_footer.offset_top = FOOTER_REST_TOP


func _keyboard_lift() -> float:
	var kb := _local_rect(_keyboard_node())
	if kb.size.y > 8.0:
		return size.y - kb.position.y + 24.0
	return 640.0


func _kill_footer_tween() -> void:
	if is_instance_valid(_footer_tween):
		_footer_tween.kill()
	_footer_tween = null


func _run_step3_intro(token: int) -> void:
	await get_tree().process_frame
	if token != _anim_token or not is_inside_tree() or _footer == null:
		return
	await _lower_footer_to_rest(token, true)
	if token != _anim_token or not is_inside_tree():
		return
	var lift := _keyboard_lift()
	_kill_footer_tween()
	_footer_tween = create_tween()
	_footer_tween.set_trans(Tween.TRANS_QUAD)
	_footer_tween.set_ease(Tween.EASE_OUT)
	_footer_tween.set_parallel(true)
	_footer_tween.tween_property(_footer, "offset_bottom", -lift, FOOTER_LIFT_SEC)
	_footer_tween.tween_property(_footer, "offset_top", -(lift + 380.0), FOOTER_LIFT_SEC)
	await get_tree().create_timer(FOOTER_LIFT_SEC).timeout
	if token != _anim_token or not is_inside_tree():
		return
	_footer_tween = null
	_keyboard_revealed = true
	_refresh_holes()
	queue_redraw()
	_start_text_blink(_card_letter)
	_start_text_blink(_prompt)
	_run_letter_anim(token)


func _run_step4_intro(token: int, fade_in: bool) -> void:
	await get_tree().process_frame
	if token != _anim_token or not is_inside_tree():
		return
	_fit_play_button(false)
	if _next:
		_next.visible = false
	if _prompt:
		_prompt.visible = true
	await _lower_footer_to_rest(token)
	if token != _anim_token or not is_inside_tree():
		return
	if fade_in:
		await _fade_in_step_ui()
		return
	_start_text_blink(_prompt)
	_start_reveal_blink()
	_run_reveal_anim(token)


func _lower_footer_to_rest(token: int, force := false) -> void:
	if _footer == null:
		return
	if not force and is_equal_approx(_footer.offset_bottom, FOOTER_REST_BOTTOM):
		return
	_kill_footer_tween()
	_footer_tween = create_tween()
	_footer_tween.set_trans(Tween.TRANS_QUAD)
	_footer_tween.set_ease(Tween.EASE_OUT)
	_footer_tween.set_parallel(true)
	_footer_tween.tween_property(_footer, "offset_bottom", FOOTER_REST_BOTTOM, FOOTER_LIFT_SEC)
	_footer_tween.tween_property(_footer, "offset_top", FOOTER_REST_TOP, FOOTER_LIFT_SEC)
	await get_tree().create_timer(FOOTER_LIFT_SEC).timeout
	if token != _anim_token:
		return
	_footer_tween = null


func _run_cell_anim(token: int) -> void:
	while token == _anim_token and is_inside_tree() and _step == 2:
		_refresh_holes()
		var start := Vector2(size.x - 80.0, size.y - 90.0)
		var target := _hand_pos(_target_cell)
		await _move_hand(start, target, 1.45, token)
		if token != _anim_token:
			return
		_flash_cell()
		await _wait(0.5)
		if token != _anim_token:
			return
		_clear_cell_flash()
		_hand.visible = false
		await _wait(0.25)


func _run_letter_anim(token: int) -> void:
	var start := _hand_pos(_target_cell)
	while token == _anim_token and is_inside_tree() and _step == 3:
		_refresh_holes()
		var target := _hand_pos(_target_key)
		await _move_hand(start, target, 0.85, token)
		if token != _anim_token:
			return
		if _target_key:
			_target_key.letra_selected.visible = true
		await _wait(0.45)
		if token != _anim_token:
			return
		if _target_key:
			_target_key.letra_selected.visible = false
		start = target
		_hand.visible = false
		await _wait(0.2)


func _run_reveal_anim(token: int) -> void:
	var start := _hand_pos(_target_key)
	var reveal := _reveal_button()
	while token == _anim_token and is_inside_tree() and _step == 4 and not _reveal_sequence_running:
		_refresh_holes()
		var target := _hand_pos(reveal)
		await _move_hand(start, target, STEP4_HAND_SEC, token)
		if token != _anim_token or _reveal_sequence_running:
			return
		await _wait(0.5)
		if token != _anim_token or _reveal_sequence_running:
			return
		_hand.visible = false
		await _wait(0.2)
		start = target


func _set_board_cover_alpha(value: float) -> void:
	_board_cover_alpha = clampf(value, 0.0, 1.0)
	queue_redraw()


func _set_keyboard_cover_alpha(value: float) -> void:
	_keyboard_cover_alpha = clampf(value, 0.0, 1.0)
	queue_redraw()


func _run_reveal_sequence() -> void:
	_reveal_sequence_running = true
	var token := _anim_token + 1
	_anim_token = token
	_hand.visible = false
	_stop_reveal_blink()
	_stop_blinks()
	var fade_out := create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(_card, "modulate:a", 0.0, 0.35)
	if _prompt:
		fade_out.tween_property(_prompt, "modulate:a", 0.0, 0.35)
	if _bar:
		fade_out.tween_property(_bar, "modulate:a", 0.0, 0.35)
	await fade_out.finished
	if token != _anim_token:
		return
	_apply_play_ref_width()
	if _prompt:
		_prompt.visible = false
	if _bar:
		_bar.visible = false
	_layout_play_with_next_right(false)
	_set_board_cover_alpha(1.0)
	var fade_in := create_tween()
	fade_in.tween_method(_set_board_cover_alpha, 1.0, 0.0, 0.5)
	await fade_in.finished
	if token != _anim_token:
		return
	var elapsed := 0.0
	var green := false
	while elapsed < 1.0 and token == _anim_token and is_inside_tree():
		green = not green
		if green:
			_paint_tutorial_as_green()
		else:
			_paint_tutorial_as_hypothesis()
		await _wait(0.16)
		elapsed += 0.16
	if token != _anim_token:
		return
	_paint_tutorial_as_green()
	if _card:
		_card.modulate.a = 1.0
	_reveal_sequence_running = false
	_show_step(5)


func _move_hand(from: Vector2, to: Vector2, duration: float, token: int) -> void:
	_hand.visible = true
	_hand.position = from
	_bar.value = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_hand, "position", to, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_bar, "value", 1.0, duration)
	await tween.finished
	if token != _anim_token:
		return
	var tap := create_tween()
	var rest := _hand.scale
	tap.tween_property(_hand, "scale", rest * 0.88, 0.08)
	tap.tween_property(_hand, "scale", rest, 0.1)
	await tap.finished


func _hand_pos(node: CanvasItem) -> Vector2:
	if node == null or not is_instance_valid(node):
		return Vector2(size.x * 0.5, size.y * 0.5)
	var rect := _local_rect(node)
	var tip := rect.get_center()
	var hand_size := _hand.custom_minimum_size if _hand.custom_minimum_size.x > 1.0 else _hand.size
	return tip - Vector2(hand_size.x * 0.22, hand_size.y * 0.04)


func _flash_cell() -> void:
	if _target_cell == null:
		return
	_target_cell.celda_selected.visible = true
	_target_cell.modulate = Color(1.0, 1.0, 0.35, 0.72)


func _clear_cell_flash() -> void:
	if _target_cell == null or _step != 2:
		return
	_target_cell.modulate = Color.WHITE
	_target_cell.celda_selected.visible = false


func _ghost_letter() -> void:
	pass


func _tutorial_a_cells() -> Array[Celda]:
	var cells: Array[Celda] = []
	for node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		var cell: Celda = node
		if cell.es_regalo_inicial or cell.numero >= 100:
			continue
		var key := GameManager._hint_letter_key(cell.letra)
		if key == _target_letter or (_target_letter.is_empty() and key == "A"):
			cells.append(cell)
	return cells


func _paint_tutorial_as_green() -> void:
	for cell in _tutorial_a_cells():
		if cell.letter_user.strip_edges() == "":
			cell.set_letter_user(_target_letter if _target_letter != "" else "A")
		cell.mostrar_letra()


func _paint_tutorial_as_hypothesis() -> void:
	for cell in _tutorial_a_cells():
		if cell.letter_user.strip_edges() == "":
			continue
		cell.mostrar_letra_jugador()


func _restore_letter_alphas() -> void:
	for cell in _tutorial_a_cells():
		if is_instance_valid(cell) and cell.label_letra:
			cell.label_letra.modulate.a = 1.0


func _run_letter_hold(token: int) -> void:
	var on := true
	_paint_tutorial_as_hypothesis()
	while token == _anim_token and is_inside_tree() and _step == 3 and _letter_placed:
		on = not on
		for cell in _tutorial_a_cells():
			if is_instance_valid(cell) and cell.label_letra:
				cell.label_letra.modulate.a = 1.0 if on else 0.18
		await _wait(0.16)


func _run_green_hold(token: int) -> void:
	var green := true
	_paint_tutorial_as_green()
	while token == _anim_token and is_inside_tree() and _step == 5:
		green = not green
		if green:
			_paint_tutorial_as_green()
		else:
			_paint_tutorial_as_hypothesis()
		await _wait(0.16)


func _load_tutorial_puzzle() -> void:
	var phrase := GameManager.normalizar_frase_idioma(
		_tutorial_phrase_text(),
		GameManager.locale_code()
	)
	GameManager.begin_basic_tutorial_board(phrase, _tutorial_gifts_for(phrase))
	var canvas := get_tree().get_first_node_in_group("PuzzleCanvas")
	if canvas != null and canvas.has_method("rebuild_puzzle_board"):
		await canvas.rebuild_puzzle_board()
		await get_tree().process_frame
		await get_tree().process_frame


func _restore_real_puzzle() -> void:
	if not GameManager.tutorial_board_active:
		return
	GameManager.end_basic_tutorial_board()
	var canvas := get_tree().get_first_node_in_group("PuzzleCanvas")
	if canvas != null and canvas.has_method("rebuild_puzzle_board"):
		await canvas.rebuild_puzzle_board()
		await get_tree().process_frame
	await PuzzleSaveManager.restore_current_puzzle()
	SignalManager.añade_las_letras_iniciales.emit()
	GameManager.update_numero_letras_reveladas()
	SignalManager.update_puzzle_stars.emit(GameManager.puzzle_stars)


func _apply_hand_size() -> void:
	var hand_size := HAND_SIZE_SMALL if _step == 2 or _step == 3 or _step == 4 else HAND_SIZE
	_hand.scale = Vector2.ONE
	_hand.custom_minimum_size = hand_size
	_hand.size = hand_size


func _start_text_blink(node: CanvasItem) -> void:
	if node == null:
		return
	node.modulate.a = 1.0
	var tw := create_tween()
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate:a", 0.28, 0.45)
	tw.tween_property(node, "modulate:a", 1.0, 0.45)
	_blinks.append(tw)


func _stop_blinks() -> void:
	for tw in _blinks:
		if is_instance_valid(tw):
			tw.kill()
	_blinks.clear()
	if _prompt:
		_prompt.modulate.a = 1.0
	if _card_sub:
		_card_sub.modulate.a = 1.0
	if _card_letter:
		_card_letter.modulate.a = 1.0
	if _example_letter:
		_example_letter.modulate.a = 1.0
	if _star_slash:
		_star_slash.modulate.a = 1.0
	if _card_star:
		_card_star.modulate = STAR_YELLOW


func _start_reveal_blink() -> void:
	var button := _reveal_button()
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	_reveal_blink = create_tween()
	_reveal_blink.set_loops()
	_reveal_blink.set_trans(Tween.TRANS_SINE)
	_reveal_blink.tween_property(button, "scale", Vector2(1.08, 1.08), 0.45)
	_reveal_blink.tween_property(button, "scale", Vector2.ONE, 0.45)


func _stop_reveal_blink() -> void:
	if is_instance_valid(_reveal_blink):
		_reveal_blink.kill()
	var button := _reveal_button()
	if button:
		button.scale = Vector2.ONE


func _start_play_blink() -> void:
	await get_tree().process_frame
	if _play == null or not is_instance_valid(_play) or not (_step == 1 or _step == 6):
		return
	_play.pivot_offset = _play.size * 0.5
	_play_blink = create_tween()
	_play_blink.set_loops()
	_play_blink.set_trans(Tween.TRANS_SINE)
	_play_blink.tween_property(_play, "scale", Vector2(1.06, 1.06), 0.45)
	_play_blink.tween_property(_play, "scale", Vector2.ONE, 0.45)


func _stop_play_blink() -> void:
	if is_instance_valid(_play_blink):
		_play_blink.kill()
	if _play:
		_play.scale = Vector2.ONE


func _start_next_blink() -> void:
	await get_tree().process_frame
	if _next == null or not is_instance_valid(_next):
		return
	if not (_step == 1 or _step == 5 or (_step == 3 and _letter_placed)):
		return
	_next.pivot_offset = _next.size * 0.5
	_next_blink = create_tween()
	_next_blink.set_loops()
	_next_blink.set_trans(Tween.TRANS_SINE)
	_next_blink.tween_property(_next, "scale", Vector2(1.08, 1.08), 0.45)
	_next_blink.tween_property(_next, "scale", Vector2.ONE, 0.45)


func _stop_next_blink() -> void:
	if is_instance_valid(_next_blink):
		_next_blink.kill()
	if _next:
		_next.scale = Vector2.ONE


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _finish() -> void:
	_anim_token += 1
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_footer_tween()
	_stop_reveal_blink()
	_stop_play_blink()
	_stop_next_blink()
	_stop_blinks()
	var host := get_parent() as Control
	var cover := ColorRect.new()
	cover.color = Color.BLACK
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.modulate.a = 0.0
	if host:
		host.add_child(cover)
	else:
		add_child(cover)
	var fade_out := cover.create_tween()
	fade_out.tween_property(cover, "modulate:a", 1.0, PLAY_FADE_SEC)
	await fade_out.finished
	if not is_inside_tree():
		if is_instance_valid(cover):
			cover.queue_free()
		return
	_paint_tutorial_as_hypothesis()
	_restore_letter_alphas()
	if _target_cell and is_instance_valid(_target_cell):
		_target_cell.modulate = Color.WHITE
		_target_cell.label_letra.modulate.a = 1.0
	await _restore_real_puzzle()
	visible = false
	var fade_in := cover.create_tween()
	fade_in.tween_property(cover, "modulate:a", 0.0, PLAY_FADE_SEC)
	await fade_in.finished
	if is_instance_valid(cover):
		cover.queue_free()
	queue_free()


func _t(key: String, fallback: String) -> String:
	var value := tr(key)
	if value == key or value.is_empty():
		value = fallback
	return value.replace("\\n", "\n")


func _white_card_style() -> StyleBoxFlat:
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 1, 1, 1)
	card_style.set_corner_radius_all(36)
	card_style.set_border_width_all(4)
	card_style.border_color = Color(0.82, 0.82, 0.82, 1)
	return card_style


func _set_card_plain(text: String) -> void:
	_hide_card_extras()
	_card_lead.visible = false
	_card_letter.visible = false
	_card_body.visible = true
	_card_body.bbcode_enabled = false
	_card_body.text = text
	_card_sub.visible = false


func _hide_card_extras() -> void:
	if _example_row:
		_example_row.visible = false
	if _example_letter:
		_example_letter.modulate.a = 1.0
	if _star_host:
		_star_host.visible = false
	if _card_star:
		_card_star.visible = false
	if _star_slash:
		_star_slash.visible = false
		_star_slash.modulate.a = 1.0
	if _star_gap:
		_star_gap.visible = false
	if _card_fin:
		_card_fin.visible = false
	if _menu_tutorial_demo:
		_menu_tutorial_demo.visible = false
	if _card_sub:
		_card_sub.visible = false
	if _letter_gap_top:
		_letter_gap_top.visible = false
	if _letter_gap_bottom:
		_letter_gap_bottom.visible = false
	if _body_gap:
		_body_gap.visible = false


func _bb_orange(text: String, font_size := 0) -> String:
	if font_size > 0:
		return "[color=#f58203][b][font_size=%d]%s[/font_size][/b][/color]" % [font_size, text]
	return "[color=#f58203][b]%s[/b][/color]" % text


func _bb_red(text: String) -> String:
	return "[color=#db1a1a][b]%s[/b][/color]" % text


func _set_step1_card() -> void:
	_hide_card_extras()
	_card_lead.visible = false
	_card_letter.visible = false
	_card_body.visible = true
	_card_body.bbcode_enabled = false
	_card_body.text = _t("TutBasicIntro", "En CifraLetra tendrás que descubrir qué letra corresponde a cada número.")
	_example_row.visible = true
	if _example_num:
		_example_num.text = str(_target_cell.numero) if _target_cell else ""
		_example_num.add_theme_color_override("font_color", INK)
	if _example_letter:
		_example_letter.text = _target_letter
	_card_sub.visible = false
	if _body_gap:
		_body_gap.visible = true


func _set_step4_card() -> void:
	_hide_card_extras()
	var reveal := _bb_orange(_t("TutReveal", "REVELAR"), 66)
	var body := _break_after_first_sentence(_t("TutBasicHypothesis", "Has puesto tu primera letra.\nDe momento es solo una hipótesis: todavía no está comprobada.\n\nPara saber si has acertado, pulsa %s.\n\nSi es correcta, esa letra se pondrá verde en todo el tablero."))
	_card_lead.visible = false
	_card_letter.visible = false
	_card_body.visible = true
	_card_body.bbcode_enabled = true
	_card_body.text = body % reveal
	_card_sub.visible = false


func _set_step6_card() -> void:
	_hide_card_extras()
	var reveal := _bb_orange(_t("TutReveal", "REVELAR"))
	var red := _bb_red(_t("TutBasicRed", "rojo").to_upper())
	var star_word := _bb_orange(_t("TutBasicStar", "estrella"))
	var hit := _t("TutBasicHitHypothesis", "¡Has acertado tu hipótesis!")
	var anytime := _t("TutBasicRevealAnytime", "Puedes pulsar %s cuando quieras, todas las hipótesis que tengas acumuladas serán comprobadas.") % reveal
	var wrong := _t("TutBasicWrongReveal", "Pero si pulsas %s y te equivocas, esas letras se ponen en %s y pierdes una %s.") % [reveal, red, star_word]
	var fail := _t("TutBasicByFail", "por fallo")
	if not wrong.to_lower().contains(fail.to_lower()):
		wrong = wrong.trim_suffix(".") + " " + fail + "."
	var body := "\n%s\n\n%s\n\n%s" % [hit, anytime, wrong]
	var more := _t("TutBasicRevealMore", "Más info en el tutorial del menú.")
	if not more.begins_with("("):
		more = "(%s)" % more.trim_suffix(".").strip_edges()
	_card_lead.visible = false
	_card_letter.visible = false
	if _letter_gap_top:
		_letter_gap_top.visible = true
	_card_body.visible = true
	_card_body.bbcode_enabled = true
	_card_body.text = body
	if _star_host:
		_star_host.visible = true
	_card_star.visible = true
	_card_star.modulate = STAR_YELLOW
	if _star_slash:
		_star_slash.visible = true
		_star_slash.modulate.a = 1.0
		_star_slash.queue_redraw()
		call_deferred("_redraw_star_slash")
		_start_slash_blink()
	if _star_gap:
		_star_gap.visible = true
	_card_fin.visible = true
	_card_fin.text = _t("TutBasicEnd", "FIN DEL TUTORIAL BÁSICO")
	_card_sub.visible = true
	_card_sub.bbcode_enabled = true
	_card_sub.text = "[i][font_size=%d]%s[/font_size][/i]" % [NOTE_FONT, more]
	_menu_tutorial_demo.visible = true


func _set_card_letter_step() -> void:
	_hide_card_extras()
	var lead := _t("TutBasicLetterLead", "Para esta casilla la letra que le corresponde es la")
	lead = lead.replace("%s", "").strip_edges()
	if lead.ends_with("."):
		lead = lead.substr(0, lead.length() - 1).strip_edges()
	var note := _t("TutBasicLetterNote", "(No te preocupes, por ahora no tienes por qué saber qué letra corresponde. Lo irás deduciendo según estudies el puzle y saques tus conclusiones...)")
	if not note.begins_with("("):
		note = "(%s)" % note
	_card_lead.visible = not lead.is_empty()
	_card_lead.text = lead
	_card_letter.visible = true
	_card_letter.text = _target_letter
	if _letter_gap_top:
		_letter_gap_top.visible = true
	if _letter_gap_bottom:
		_letter_gap_bottom.visible = true
	_card_body.visible = true
	_card_body.bbcode_enabled = true
	_card_body.add_theme_font_size_override("italics_font_size", BODY_FONT)
	_card_body.text = "[i]%s[/i]" % note
	_card_sub.visible = false


func _hero_letter_bbcode() -> String:
	return _hero_bbcode(_target_letter)


func _hero_bbcode(text: String) -> String:
	return "[color=#%s][font_size=%d][b]%s[/b][/font_size][/color]" % [ORANGE.to_html(false), HERO_FONT, text]


func _apply_action_prompt_style(alignment: HorizontalAlignment, shrink_end := false) -> void:
	_prompt.visible = true
	_prompt.bbcode_enabled = true
	_prompt.fit_content = true
	_prompt.scroll_active = false
	_prompt.horizontal_alignment = alignment
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.size_flags_horizontal = Control.SIZE_SHRINK_END if shrink_end else Control.SIZE_EXPAND_FILL
	_prompt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_prompt.custom_minimum_size = Vector2(0, PROMPT_MIN_H)
	_prompt.add_theme_font_size_override("normal_font_size", PROMPT_FONT)
	_prompt.add_theme_font_size_override("bold_font_size", PROMPT_FONT)
	_prompt.add_theme_constant_override("line_separation", 4)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_OFF


func _tutorial_phrase_text() -> String:
	var translated := tr("TutBasicPuzzle")
	if translated != "TutBasicPuzzle" and not translated.is_empty():
		return translated
	match GameManager.locale_code():
		"en":
			return "CIFRALETRA IS A CRYPTOGRAM GAME WHERE YOU HAVE TO FIND WHICH LETTER MATCHES EACH NUMBER. STUDY THE PUZZLE TO REACH YOUR CONCLUSIONS."
		"de":
			return "CIFRALETRA IST EIN KRYPTOGRAMM SPIEL IN DEM DU HERAUSFINDEN MUSST WELCHER BUCHSTABE ZU JEDER ZAHL GEHORT. STUDIERE DAS RATSEL UM ZU DEINEN SCHLUSSEN ZU KOMMEN."
		"fr":
			return "CIFRALETRA EST UN JEU DE CRYPTOGRAMMES OU TU DOIS DECOUVRIR QUELLE LETTRE CORRESPOND A CHAQUE NUMERO. ETUDIE LE PUZZLE POUR ARRIVER A TES CONCLUSIONS."
		"eu":
			return "CIFRALETRA KRIPTOGRAMA JOKO BAT DA. ZENBAKI BAKOITZARI DAGOKION LETRA AURKITU BEHAR DUZU. AZTERTU PUZZLEA ONDORIOETARA IRISTEKO."
		"it":
			return "CIFRALETRA E UN GIOCO DI CRITTOGRAMMI IN CUI DEVI SCOPRIRE QUALE LETTERA CORRISPONDE A OGNI NUMERO. STUDIA IL PUZZLE PER ARRIVARE ALLE TUE CONCLUSIONI."
		"pt":
			return "CIFRALETRA E UM JOGO DE CRIPTOGRAMAS EM QUE TENS DE DESCOBRIR QUE LETRA CORRESPONDE A CADA NUMERO. ESTUDA O PUZZLE PARA CHEGARES AS TUAS CONCLUSOES."
		_:
			return TUTORIAL_PHRASE


func _tutorial_gifts_for(phrase: String) -> String:
	var alphabet: Array = GameManager.get_letters_for_lang(GameManager.locale_code())
	var gifts := ""
	var source := TUTORIAL_GIFTS + phrase.to_upper()
	for i in source.length():
		var ch := source.substr(i, 1)
		if ch == "A" or gifts.contains(ch):
			continue
		if not alphabet.has(ch):
			continue
		if not phrase.to_upper().contains(ch):
			continue
		gifts += ch
		if gifts.length() >= 8:
			break
	return gifts if not gifts.is_empty() else TUTORIAL_GIFTS


func _set_press_letter_texts() -> void:
	_apply_action_prompt_style(HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.text = _t("TutBasicPressLetter", "Pulsa la %s") % _hero_letter_bbcode()


func _set_select_cell_prompt() -> void:
	var lead := _t("TutBasicSelectCellPrompt", "Selecciona la casilla")
	var num := str(_target_cell.numero) if _target_cell else ""
	_apply_action_prompt_style(HORIZONTAL_ALIGNMENT_CENTER, true)
	_prompt.text = "%s\n%s" % [lead, _hero_bbcode(num)]


func _set_press_reveal_prompt() -> void:
	_apply_action_prompt_style(HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.text = "%s\n%s" % [_t("TutBasicPress", "Pulsa"), _hero_bbcode(_t("TutReveal", "REVELAR"))]


func _set_prompt_plain(text: String) -> void:
	_prompt.bbcode_enabled = false
	_prompt.fit_content = false
	_prompt.scroll_active = false
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prompt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_prompt.custom_minimum_size = Vector2(0, 110)
	_prompt.add_theme_font_size_override("normal_font_size", 40)
	_prompt.add_theme_font_size_override("bold_font_size", 40)
	_prompt.add_theme_constant_override("line_separation", 6)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_OFF
	_prompt.text = text


func _make_italic_font() -> FontVariation:
	var italic := FontVariation.new()
	italic.base_font = FONT_FILE
	italic.variation_transform = Transform2D(Vector2(1, 0.22), Vector2(0, 1), Vector2.ZERO)
	return italic


func _make_rich(font_size: int, color: Color) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = false
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("normal_font", FONT)
	label.add_theme_font_override("bold_font", FONT)
	label.add_theme_font_override("italics_font", _italic_font)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_font_size_override("bold_font_size", font_size)
	label.add_theme_font_size_override("italics_font_size", NOTE_FONT)
	label.add_theme_color_override("default_color", color)
	label.add_theme_constant_override("line_separation", 16)
	return label


func _center_example_label(label: Label) -> void:
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


func _build() -> void:
	_italic_font = _make_italic_font()
	_header = PanelContainer.new()
	_header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_header.anchor_bottom = 0.0
	_header.offset_left = CARD_SIDE
	_header.offset_right = -CARD_SIDE
	_header.offset_top = 24.0
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_theme_stylebox_override("panel", _white_card_style())
	add_child(_header)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 28)
	header_margin.add_theme_constant_override("margin_right", 28)
	header_margin.add_theme_constant_override("margin_top", 22)
	header_margin.add_theme_constant_override("margin_bottom", 22)
	_header.add_child(header_margin)
	var header_col := VBoxContainer.new()
	header_col.add_theme_constant_override("separation", 2)
	header_margin.add_child(header_col)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", FONT)
	_title.add_theme_font_size_override("font_size", 64)
	_title.add_theme_color_override("font_color", INK)
	_title.text = _t("TutBasicTitle", "TUTORIAL BÁSICO")
	header_col.add_child(_title)

	_step_label = Label.new()
	_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_step_label.add_theme_font_override("font", FONT)
	_step_label.add_theme_font_size_override("font_size", 60)
	_step_label.add_theme_color_override("font_color", INK_SOFT)
	_step_label.text = "1/%d" % STEP_COUNT
	header_col.add_child(_step_label)

	_above_card = PanelContainer.new()
	_above_card.visible = false
	_above_card.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_above_card.anchor_bottom = 0.0
	_above_card.offset_left = CARD_SIDE
	_above_card.offset_right = -CARD_SIDE
	_above_card.offset_top = 240.0
	_above_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_above_card.add_theme_stylebox_override("panel", _white_card_style())
	add_child(_above_card)
	var above_margin := MarginContainer.new()
	above_margin.add_theme_constant_override("margin_left", 40)
	above_margin.add_theme_constant_override("margin_right", 40)
	above_margin.add_theme_constant_override("margin_top", 28)
	above_margin.add_theme_constant_override("margin_bottom", 28)
	_above_card.add_child(above_margin)
	_above_body = _make_rich(BODY_FONT, INK)
	above_margin.add_child(_above_body)

	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_card.anchor_bottom = 0.0
	_card.grow_vertical = Control.GROW_DIRECTION_END
	_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_card.offset_left = CARD_SIDE
	_card.offset_right = -CARD_SIDE
	_card.offset_top = 240.0
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.clip_contents = true
	_card.add_theme_stylebox_override("panel", _white_card_style())
	add_child(_card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	_card.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	margin.add_child(col)

	_card_lead = Label.new()
	_card_lead.visible = false
	_card_lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_lead.add_theme_font_override("font", FONT)
	_card_lead.add_theme_font_size_override("font_size", BODY_FONT)
	_card_lead.add_theme_constant_override("line_spacing", 16)
	_card_lead.add_theme_color_override("font_color", INK)
	col.add_child(_card_lead)

	_letter_gap_top = _make_gap(LETTER_GAP)
	col.add_child(_letter_gap_top)

	_card_letter = Label.new()
	_card_letter.visible = false
	_card_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_letter.add_theme_font_override("font", FONT)
	_card_letter.add_theme_font_size_override("font_size", HERO_FONT)
	_card_letter.add_theme_color_override("font_color", ORANGE)
	col.add_child(_card_letter)

	_letter_gap_bottom = _make_gap(LETTER_GAP)
	col.add_child(_letter_gap_bottom)

	_card_body = _make_rich(BODY_FONT, INK)
	col.add_child(_card_body)

	_body_gap = _make_gap(EXAMPLE_GAP)
	col.add_child(_body_gap)

	_example_row = HBoxContainer.new()
	_example_row.visible = false
	_example_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_example_row.add_theme_constant_override("separation", 22)
	_example_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_example_row.custom_minimum_size = Vector2(0, EXAMPLE_ROW_H)
	col.add_child(_example_row)
	var example_lead := Label.new()
	example_lead.text = _t("TutBasicExample", "Ej:")
	example_lead.add_theme_font_override("font", FONT)
	example_lead.add_theme_font_size_override("font_size", EXAMPLE_LEAD_FONT)
	example_lead.add_theme_color_override("font_color", INK)
	_center_example_label(example_lead)
	_example_row.add_child(example_lead)
	_example_num = Label.new()
	_example_num.text = ""
	_example_num.add_theme_font_override("font", FONT)
	_example_num.add_theme_font_size_override("font_size", EXAMPLE_LEAD_FONT)
	_example_num.add_theme_color_override("font_color", INK)
	_center_example_label(_example_num)
	_example_row.add_child(_example_num)
	var example_arrow := Label.new()
	example_arrow.text = "→"
	example_arrow.add_theme_font_override("font", FONT)
	example_arrow.add_theme_font_size_override("font_size", EXAMPLE_ARROW_FONT)
	example_arrow.add_theme_color_override("font_color", INK)
	_center_example_label(example_arrow)
	_example_row.add_child(example_arrow)
	_example_letter = Label.new()
	_example_letter.text = "A"
	_example_letter.add_theme_font_override("font", FONT)
	_example_letter.add_theme_font_size_override("font_size", EXAMPLE_LETTER_FONT)
	_example_letter.add_theme_color_override("font_color", ORANGE)
	_center_example_label(_example_letter)
	_example_row.add_child(_example_letter)

	_star_host = Control.new()
	_star_host.visible = false
	_star_host.custom_minimum_size = STAR_SLASH_SIZE
	_star_host.size = STAR_SLASH_SIZE
	_star_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_star_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_star_host)

	_card_star = TextureRect.new()
	_card_star.visible = false
	_card_star.texture = STAR_TEX
	_card_star.anchor_left = 0.5
	_card_star.anchor_right = 0.5
	_card_star.anchor_top = 0.5
	_card_star.anchor_bottom = 0.5
	_card_star.offset_left = -STAR_SIZE.x * 0.5
	_card_star.offset_top = -STAR_SIZE.y * 0.5
	_card_star.offset_right = STAR_SIZE.x * 0.5
	_card_star.offset_bottom = STAR_SIZE.y * 0.5
	_card_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card_star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_card_star.modulate = STAR_YELLOW
	_card_star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star_host.add_child(_card_star)

	_star_slash = Control.new()
	_star_slash.visible = false
	_star_slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star_slash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_star_slash.draw.connect(_draw_star_slash)
	_star_host.add_child(_star_slash)

	_star_gap = _make_gap(28.0)
	col.add_child(_star_gap)

	_card_fin = Label.new()
	_card_fin.visible = false
	_card_fin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_fin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_fin.add_theme_font_override("font", FONT)
	_card_fin.add_theme_font_size_override("font_size", 42)
	_card_fin.add_theme_color_override("font_color", INK)
	_card_fin.text = _t("TutBasicEnd", "FIN DEL TUTORIAL BÁSICO")
	col.add_child(_card_fin)

	_card_sub = _make_rich(BODY_FONT, INK)
	_card_sub.visible = false
	col.add_child(_card_sub)

	_menu_tutorial_demo = _make_tutorial_menu_demo()
	_menu_tutorial_demo.visible = false
	col.add_child(_menu_tutorial_demo)

	_hand = TextureRect.new()
	_hand.texture = HAND
	_hand.custom_minimum_size = HAND_SIZE
	_hand.size = HAND_SIZE
	_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hand.visible = false
	_hand.z_index = 20
	add_child(_hand)

	_footer = VBoxContainer.new()
	_footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_footer.offset_left = 36.0
	_footer.offset_right = -36.0
	_footer.offset_top = -520.0
	_footer.offset_bottom = -36.0
	_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_footer.add_theme_constant_override("separation", 18)
	add_child(_footer)

	_bar = ProgressBar.new()
	_bar.min_value = 0
	_bar.max_value = 1
	_bar.value = 0
	_bar.show_percentage = false
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(1, 1, 1, 0.35)
	bar_bg.set_corner_radius_all(12)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = ORANGE
	bar_fill.set_corner_radius_all(12)
	_bar.add_theme_stylebox_override("background", bar_bg)
	_bar.add_theme_stylebox_override("fill", bar_fill)
	_bar.custom_minimum_size = Vector2(0, BAR_H)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bar_slot := PanelContainer.new()
	bar_slot.custom_minimum_size = Vector2(0, BAR_H)
	bar_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_slot.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	bar_slot.add_child(_bar)
	_footer.add_child(bar_slot)

	_skip_tex_off = _make_skip_texture(false)
	_skip_tex_on = _make_skip_texture(true)
	_skip_row = Button.new()
	_skip_row.toggle_mode = true
	_skip_row.focus_mode = Control.FOCUS_NONE
	_skip_row.mouse_filter = Control.MOUSE_FILTER_STOP
	_skip_row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_skip_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skip_row.custom_minimum_size = Vector2(0, 120)
	_skip_row.clip_contents = true
	_skip_row.flat = true
	var skip_empty := StyleBoxEmpty.new()
	_skip_row.add_theme_stylebox_override("normal", skip_empty)
	_skip_row.add_theme_stylebox_override("hover", skip_empty)
	_skip_row.add_theme_stylebox_override("pressed", skip_empty)
	_skip_row.add_theme_stylebox_override("hover_pressed", skip_empty)
	_skip_row.add_theme_stylebox_override("focus", skip_empty)
	_skip_row.add_theme_stylebox_override("disabled", skip_empty)
	_skip_row.toggled.connect(_on_skip_row_toggled)
	_footer.add_child(_skip_row)
	var skip_inner := HBoxContainer.new()
	skip_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skip_inner.offset_left = 0
	skip_inner.offset_top = 0
	skip_inner.offset_right = 0
	skip_inner.offset_bottom = 0
	skip_inner.add_theme_constant_override("separation", 18)
	skip_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	_skip_row.add_child(skip_inner)
	_skip_icon = TextureRect.new()
	_skip_icon.custom_minimum_size = Vector2(SKIP_CHECK_SIZE, SKIP_CHECK_SIZE)
	_skip_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_skip_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_skip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_skip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_skip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_icon.texture = _skip_tex_off
	skip_inner.add_child(_skip_icon)
	_skip_label = Label.new()
	_skip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skip_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_skip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_skip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_skip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_label.add_theme_font_override("font", FONT)
	_skip_label.add_theme_font_size_override("font_size", 40)
	_skip_label.add_theme_color_override("font_color", INK)
	_skip_label.text = _t("TutBasicSkip", "No mostrar más veces el tutorial al inicio del juego")
	skip_inner.add_child(_skip_label)
	_sync_skip_from_prefs()

	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override("separation", 24)
	_actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_footer.add_child(_actions)
	_play = _make_action_button(_t("Play", "Jugar"), true)
	_play.pressed.connect(_on_play)
	_actions.add_child(_play)
	_actions_spacer = Control.new()
	_actions_spacer.visible = false
	_actions_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actions_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_actions.add_child(_actions_spacer)
	_next = _make_action_button(_t("Next", "Siguiente"), false)
	_next.pressed.connect(_on_next)
	_actions.add_child(_next)
	_prompt = _make_rich(PROMPT_FONT, INK)
	_prompt.visible = false
	_prompt.custom_minimum_size = Vector2(0, 80)
	_actions.add_child(_prompt)
	_layout_header()


func _fit_play_button(compact: bool) -> void:
	if _play == null or _actions == null:
		return
	_actions.add_theme_constant_override("separation", 24)
	if compact:
		var font_size := 40
		var text_w := FONT.get_string_size(_play.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_play.custom_minimum_size = Vector2(text_w + 88.0, 110.0)
		_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_play.custom_minimum_size = Vector2(0, 110)
		_play.scale = Vector2.ONE
		_actions.alignment = BoxContainer.ALIGNMENT_BEGIN
		_restore_action_order()
		if _next:
			_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			_next.custom_minimum_size = Vector2(0, 110)
			_next.scale = Vector2.ONE


func _capture_play_ref_width() -> void:
	if _play == null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if (_step == 2 or _step == 3) and _play.size.x > 20.0:
		_play_ref_width = _play.size.x


func _keep_play_width() -> void:
	if _play == null:
		return
	var play_w := _play.size.x
	if play_w > 20.0:
		_play_ref_width = play_w
	_apply_play_ref_width()


func _apply_play_ref_width() -> void:
	if _play == null or _play_ref_width < 20.0:
		return
	_play.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_play.custom_minimum_size = Vector2(_play_ref_width, 110.0)
	_play.size = Vector2(_play_ref_width, 110.0)
	_play.scale = Vector2.ONE


func _make_action_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size = Vector2(0, 110)
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 40)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(28)
	style.set_border_width_all(3)
	style.border_width_bottom = 8
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 18
	style.content_margin_bottom = 22
	if primary:
		style.bg_color = ORANGE
		style.border_color = Color(0.83, 0.41, 0.02, 1)
		button.add_theme_color_override("font_color", Color.WHITE)
	else:
		style.bg_color = Color(1, 0.982, 0.92, 1)
		style.border_color = Color(0.66, 0.44, 0.2, 0.7)
		button.add_theme_color_override("font_color", INK)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	return button


func _restore_action_order() -> void:
	if _actions == null or _play == null or _next == null:
		return
	if _play.get_parent() == _actions:
		_actions.move_child(_play, 0)
	if _actions_spacer and _actions_spacer.get_parent() == _actions:
		_actions_spacer.visible = false
		_actions.move_child(_actions_spacer, 1)
	if _next.get_parent() == _actions:
		_actions.move_child(_next, 2)
	if _prompt and _prompt.get_parent() == _actions:
		_actions.move_child(_prompt, 3)


func _layout_step1_buttons() -> void:
	if _play == null or _next == null or _actions == null:
		return
	_restore_action_order()
	_actions.add_theme_constant_override("separation", int(STEP1_BUTTON_GAP))
	_actions.alignment = BoxContainer.ALIGNMENT_BEGIN
	_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play.custom_minimum_size = Vector2(0, 110)
	_play.scale = Vector2.ONE
	_next.visible = true
	_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next.custom_minimum_size = Vector2(0, 110)
	_next.scale = Vector2.ONE


func _layout_play_centered() -> void:
	if _play == null or _actions == null:
		return
	_restore_action_order()
	_actions.add_theme_constant_override("separation", 24)
	_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	var play_w := _play_step1_width
	if play_w < 20.0:
		var font_size := 40
		play_w = FONT.get_string_size(_play.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 120.0
	_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_play.custom_minimum_size = Vector2(play_w, 110.0)
	_play.size = Vector2(play_w, 110.0)
	_play.scale = Vector2.ONE
	if _next:
		_next.visible = false
	if _actions_spacer:
		_actions_spacer.visible = false


func _capture_play_step1_width() -> void:
	if _play == null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if _step != 1:
		return
	if _play.size.x > 20.0:
		_play_step1_width = _play.size.x
	if _next and _next.size.x > 20.0:
		_next_step1_width = _next.size.x


func _break_after_colon(text: String) -> String:
	if text.contains("\n"):
		return text
	var idx := text.find(":")
	if idx < 0:
		return text
	return text.substr(0, idx + 1) + "\n" + text.substr(idx + 1).strip_edges()


func _break_after_first_sentence(text: String) -> String:
	var dot := text.find(". ")
	if dot < 0:
		return text
	return text.substr(0, dot + 1) + "\n" + text.substr(dot + 2).strip_edges()


func _start_slash_blink() -> void:
	if _star_slash == null:
		return
	if _card_star:
		_card_star.modulate = STAR_YELLOW
	_star_slash.modulate.a = 1.0
	var tw := create_tween()
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(_star_slash, "modulate:a", 0.12, 0.45)
	tw.tween_property(_star_slash, "modulate:a", 1.0, 0.45)
	_blinks.append(tw)


func _draw_star_slash() -> void:
	if _star_slash == null:
		return
	var r := Rect2(Vector2.ZERO, _star_slash.size)
	if r.size.x < 4.0 or r.size.y < 4.0:
		return
	var pad := r.size * 0.08
	var from := r.position + pad
	var to := r.end - pad
	var other_from := Vector2(r.end.x - pad.x, r.position.y + pad.y)
	var other_to := Vector2(r.position.x + pad.x, r.end.y - pad.y)
	var color := Color(0.86, 0.1, 0.1, 1)
	_star_slash.draw_line(from, to, color, 14.0, true)
	_star_slash.draw_line(other_from, other_to, color, 14.0, true)


func _redraw_star_slash() -> void:
	if _star_slash:
		_star_slash.queue_redraw()


func _layout_play_with_next_right(show_next: bool) -> void:
	if _play == null or _next == null or _actions == null:
		return
	_restore_action_order()
	_actions.add_theme_constant_override("separation", 24)
	_actions.alignment = BoxContainer.ALIGNMENT_BEGIN
	var font_size := 40
	var next_w := _next_step1_width
	if next_w < 20.0:
		next_w = _play_step1_width
	if next_w < 20.0:
		next_w = FONT.get_string_size(_next.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 80.0
	var play_w := _play_ref_width
	if play_w < 20.0:
		play_w = maxf(_actions.size.x - next_w - 24.0, 280.0)
	_play.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_play.custom_minimum_size = Vector2(play_w, 110.0)
	_play.size = Vector2(play_w, 110.0)
	_play.scale = Vector2.ONE
	if _actions_spacer:
		_actions_spacer.visible = true
		_actions_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_actions.move_child(_actions_spacer, 1)
	_next.visible = show_next
	_next.size_flags_horizontal = Control.SIZE_SHRINK_END
	_next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_next.custom_minimum_size = Vector2(next_w, 110.0)
	_next.size = Vector2(next_w, 110.0)
	_next.scale = Vector2.ONE
	if _next.get_parent() == _actions:
		_actions.move_child(_next, 2)


func _make_tutorial_menu_demo() -> Control:
	var host := Button.new()
	host.custom_minimum_size = Vector2(240, 290)
	host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	host.focus_mode = Control.FOCUS_NONE
	host.pressed.connect(_open_full_tutorial)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.819608, 0.909804, 0.866667, 1)
	style.border_width_left = 5
	style.border_width_top = 5
	style.border_width_right = 5
	style.border_width_bottom = 12
	style.border_color = Color(0.368627, 0.643137, 0.498039, 1)
	style.set_corner_radius_all(40)
	host.add_theme_stylebox_override("normal", style)
	host.add_theme_stylebox_override("hover", style)
	host.add_theme_stylebox_override("pressed", style)
	host.add_theme_stylebox_override("focus", style)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(margin)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	var circle_host := Control.new()
	circle_host.custom_minimum_size = Vector2(148, 148)
	circle_host.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	circle_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(circle_host)

	var circle := Panel.new()
	circle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var circle_style := StyleBoxFlat.new()
	circle_style.bg_color = Color(0.5803922, 0.8, 0.7058824, 1)
	circle_style.set_corner_radius_all(200)
	circle.add_theme_stylebox_override("panel", circle_style)
	circle_host.add_child(circle)

	var shadow := TextureRect.new()
	shadow.texture = TUTORIAL_SHADOW
	shadow.modulate = Color(0.286275, 0.184314, 0.129412, 0.28)
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.offset_left = 10.0
	shadow.offset_top = 12.0
	shadow.offset_right = -2.0
	shadow.offset_bottom = -2.0
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle_host.add_child(shadow)

	var icon := TextureRect.new()
	icon.texture = TUTORIAL_ICON
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 18.0
	icon.offset_top = 14.0
	icon.offset_right = -18.0
	icon.offset_bottom = -18.0
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle_host.add_child(icon)

	var label := Label.new()
	label.text = _t("HowToPlay", "Tutorial")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(0.376471, 0.27451, 0.231373, 1))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(label)
	return host


func _make_gap(height: float) -> Control:
	var gap := Control.new()
	gap.visible = false
	gap.custom_minimum_size = Vector2(0, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


func _on_letter_assigned() -> void:
	if _letter_placed:
		return
	_letter_placed = true
	_anim_token += 1
	var token := _anim_token
	_hand.visible = false
	_stop_blinks()
	_keep_play_width()
	if _prompt:
		_prompt.visible = false
		_prompt.modulate.a = 1.0
	if _bar:
		_bar.visible = false
	_click_through = Rect2()
	var fade_card := create_tween()
	fade_card.set_trans(Tween.TRANS_SINE)
	fade_card.tween_property(_card, "modulate:a", 0.0, 0.5)
	await fade_card.finished
	if token != _anim_token:
		return
	_card.visible = false
	_refresh_holes()
	queue_redraw()
	var fade_keyboard := create_tween()
	fade_keyboard.set_trans(Tween.TRANS_SINE)
	fade_keyboard.tween_method(_set_keyboard_cover_alpha, 0.0, 1.0, 0.5)
	await fade_keyboard.finished
	if token != _anim_token:
		return
	_keyboard_cover_alpha = 1.0
	_refresh_holes()
	queue_redraw()
	await _lower_footer_to_rest(token, true)
	if token != _anim_token:
		return
	_board_cover_alpha = 1.0
	_refresh_holes()
	queue_redraw()
	var fade_board := create_tween()
	fade_board.set_trans(Tween.TRANS_SINE)
	fade_board.tween_method(_set_board_cover_alpha, 1.0, 0.0, 0.5)
	await fade_board.finished
	if token != _anim_token:
		return
	_paint_tutorial_as_hypothesis()
	_run_letter_hold(token)
	_layout_play_with_next_right(true)
	call_deferred("_start_next_blink")


func _transition_to_step(step: int) -> void:
	_anim_token += 1
	var token := _anim_token
	_hand.visible = false
	_stop_blinks()
	_stop_reveal_blink()
	var fade := create_tween()
	fade.set_parallel(true)
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_IN)
	if _card:
		fade.tween_property(_card, "modulate:a", 0.0, 1.15)
	if _above_card and _above_card.visible:
		fade.tween_property(_above_card, "modulate:a", 0.0, 1.15)
	if _prompt:
		fade.tween_property(_prompt, "modulate:a", 0.0, 1.15)
	if _bar:
		fade.tween_property(_bar, "modulate:a", 0.0, 1.15)
	await fade.finished
	if token != _anim_token:
		return
	if _bar:
		_bar.modulate.a = 1.0
	_show_step(step, true)


func _fade_in_step_ui() -> void:
	if _card and _card.visible:
		_card.modulate.a = 0.0
	if _above_card and _above_card.visible:
		_above_card.modulate.a = 0.0
	if _prompt and _prompt.visible:
		_prompt.modulate.a = 0.0
	if _bar and _bar.visible:
		_bar.modulate.a = 0.0
	var duration := STEP4_FADE_SEC if _step == 4 else (0.5 if _step == 6 else 1.4)
	var fade := create_tween()
	fade.set_parallel(true)
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_OUT)
	if _card and _card.visible:
		fade.tween_property(_card, "modulate:a", 1.0, duration)
	if _above_card and _above_card.visible:
		fade.tween_property(_above_card, "modulate:a", 1.0, duration)
	if _prompt and _prompt.visible:
		fade.tween_property(_prompt, "modulate:a", 1.0, duration)
	if _bar and _bar.visible:
		fade.tween_property(_bar, "modulate:a", 1.0, duration)
	await fade.finished
	if not is_inside_tree() or _step != 4:
		return
	_start_text_blink(_prompt)
	_start_reveal_blink()
	_run_reveal_anim(_anim_token)


func _on_next() -> void:
	SoundManager.play("ButtonClick")
	if _step == 1:
		_show_step(2)
	elif _step == 3 and _letter_placed:
		_show_step(4, true)
	elif _step == 5:
		_transition_from_5_to_6()


func _transition_from_5_to_6() -> void:
	_anim_token += 1
	var token := _anim_token
	_stop_next_blink()
	_hand.visible = false
	var fade := create_tween()
	fade.set_parallel(true)
	fade.set_trans(Tween.TRANS_SINE)
	fade.set_ease(Tween.EASE_IN)
	fade.tween_method(_set_board_cover_alpha, _board_cover_alpha, 1.0, 0.5)
	if _next:
		fade.tween_property(_next, "modulate:a", 0.0, 0.5)
	await fade.finished
	if token != _anim_token:
		return
	if _next:
		_next.modulate.a = 1.0
	_show_step(6, true)


func _on_play() -> void:
	SoundManager.play("ButtonClick")
	_finish()


func _open_full_tutorial() -> void:
	if _opening_full_tutorial:
		return
	_opening_full_tutorial = true
	SoundManager.play("ButtonClick")
	_anim_token += 1
	GameManager.set_go_to_game_disable()
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file("res://scenes/MenuTutorial.tscn")


func _sync_skip_from_prefs() -> void:
	_skip_on = not PlayerPrefs.mostrar_tuto_antes_partida
	if _skip_row:
		_skip_row.set_pressed_no_signal(_skip_on)
	_apply_skip_visual()


func _on_skip_row_toggled(pressed: bool) -> void:
	_skip_on = pressed
	_apply_skip_visual()
	SoundManager.play("ButtonClick")
	PlayerPrefs.set_mostrar_tutorial(not pressed)


func _apply_skip_visual() -> void:
	if _skip_icon:
		_skip_icon.texture = _skip_tex_on if _skip_on else _skip_tex_off


func _make_skip_texture(checked: bool) -> Texture2D:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var bg := Color(0.93, 0.84, 0.68, 1) if checked else Color(1, 0.98, 0.93, 1)
	var border := Color(0.78, 0.38, 0.05, 1) if checked else Color(0.72, 0.52, 0.28, 0.92)
	var m := 6
	var t := 12
	img.fill_rect(Rect2i(m, m, s - m * 2, s - m * 2), border)
	img.fill_rect(Rect2i(m + t, m + t, s - (m + t) * 2, s - (m + t) * 2), bg)
	if checked:
		_stamp_skip_check(img, INK)
	return ImageTexture.create_from_image(img)


func _stamp_skip_check(img: Image, color: Color) -> void:
	var s := float(img.get_width())
	_stamp_skip_line(img, Vector2(s * 0.26, s * 0.50), Vector2(s * 0.44, s * 0.70), color, 12)
	_stamp_skip_line(img, Vector2(s * 0.44, s * 0.70), Vector2(s * 0.76, s * 0.28), color, 12)


func _stamp_skip_line(img: Image, a: Vector2, b: Vector2, color: Color, width: int) -> void:
	var steps := maxi(int(a.distance_to(b)), 1)
	for i in range(steps + 1):
		var p := a.lerp(b, float(i) / float(steps))
		var r := int(width / 2.0)
		var x0 := clampi(int(p.x) - r, 0, img.get_width() - 1)
		var y0 := clampi(int(p.y) - r, 0, img.get_height() - 1)
		var x1 := clampi(int(p.x) + r, 0, img.get_width() - 1)
		var y1 := clampi(int(p.y) + r, 0, img.get_height() - 1)
		img.fill_rect(Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1), color)
