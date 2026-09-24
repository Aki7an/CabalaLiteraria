extends Control

const FONT: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const HAND: Texture2D = preload("res://images/tutorial/hand_pointer.png")
const FILTER := Color(1, 1, 1, 0.84)
const ORANGE := Color(0.96, 0.51, 0.01, 1)
const INK := Color(0.24, 0.14, 0.08, 1)
const HAND_SIZE := Vector2(188, 240)
const INTRO_PAPER := Color(0.894, 0.753, 0.565, 1)
const FADE_SEC := 0.45
const HOLD_SEC := 5.0
const CELL_HOLD_SEC := 7.0
const REVEAL_HOLD_SEC := 4.0
const STATE_INTRO := "intro"
const STATE_CELL := "cell"
const STATE_CLEAR_CELL := "clear_cell"
const STATE_LETTER := "letter"
const STATE_CLEAR_LETTER := "clear_letter"
const STATE_REVEAL := "reveal"
const STATE_REVEAL_READ := "reveal_read"
const STATE_REVEAL_CONFIRM := "reveal_confirm"
const STATE_WAIT := "wait"
const STATE_DONE := "done"
const STATE_THEME := "theme"
const STATE_THEME_WAIT := "theme_wait"
const STATE_THEME_CONTINUE := "theme_continue"
const THEME_HOLD_SEC := 4.0
const LATER_TOOLS_COPY := {
	"es": "Estos botones los aprenderás más adelante, cuando ya domines la mecánica básica del juego.",
	"en": "You'll learn what these buttons do later, once you've mastered the basic game mechanics.",
	"de": "Diese Tasten lernst du später kennen, wenn du die Grundmechanik des Spiels beherrschst.",
	"fr": "Tu apprendras ce que font ces boutons plus tard, une fois la mécanique de base maîtrisée.",
	"eu": "Botoi hauek geroago ikasiko dituzu, jokoaren oinarrizko mekanika menderatu ondoren.",
	"it": "Imparerai a usare questi pulsanti più avanti, quando avrai padroneggiato la meccanica di base.",
	"pt": "Vais aprender o que estes botões fazem mais tarde, quando já dominares a mecânica básica do jogo.",
}

var _state := STATE_CELL
var _hole := Rect2()
var _click_through := Rect2()
var _target_cell: Celda
var _target_key: Letra
var _target_letter := ""
var _letters_solved := 0
var _reveal_shown := false
var _filter_alpha := 0.0
var _flow_token := 0
var _filter_tween: Tween
var _hand: TextureRect
var _hand_tween: Tween
var _intro: Control
var _intro_card: Panel
var _intro_card_style: StyleBoxFlat
var _intro_image: TextureRect
var _intro_body: Label
var _intro_button: Button
var _later: Control
var _later_card: Control
var _later_body: Label
var _later_button: Button
var _filter_hidden_for_overlay := false
var _locked_letters: Dictionary = {}
var _recovering := false
var _pan_snap_token := 0

func _ready() -> void:
	add_to_group("BasicStartTutorial")
	add_to_group("OnboardingGuide")
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp := get_viewport()
	if vp:
		size = vp.get_visible_rect().size
	_build()
	if not SignalManager.puzzle_input.is_connected(_on_puzzle_input):
		SignalManager.puzzle_input.connect(_on_puzzle_input)
	if not SignalManager.game_finished.is_connected(_dismiss):
		SignalManager.game_finished.connect(_dismiss)
	await get_tree().process_frame
	await get_tree().process_frame
	var tries := 0
	while get_tree().get_nodes_in_group("Celda").is_empty() and tries < 50:
		await get_tree().process_frame
		tries += 1
	var gift_wait := 0
	while gift_wait < 40:
		var gifted := 0
		for node in get_tree().get_nodes_in_group("Celda"):
			if node is Celda and (node as Celda).es_regalo_inicial:
				gifted += 1
		if gifted > 0:
			break
		await get_tree().process_frame
		gift_wait += 1
	if GameManager.onboarding_stage == 2:
		_hide_intro()
		_show_theme_prompt()
	else:
		_hide_intro()
		_pick_and_show_cell()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_intro()
		_layout_later_tools()
		_refresh_hole()
		queue_redraw()


func _draw() -> void:
	if _state == STATE_INTRO or _state == STATE_DONE or _state == STATE_REVEAL_READ or _filter_alpha <= 0.01:
		return
	var tint := Color(FILTER.r, FILTER.g, FILTER.b, FILTER.a * _filter_alpha)
	var hole := _hole
	if hole.size.x > 4.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, maxf(hole.position.y, 0.0))), tint)
		draw_rect(Rect2(0.0, hole.position.y, maxf(hole.position.x, 0.0), hole.size.y), tint)
		draw_rect(Rect2(hole.end.x, hole.position.y, maxf(size.x - hole.end.x, 0.0), hole.size.y), tint)
		draw_rect(Rect2(0.0, hole.end.y, size.x, maxf(size.y - hole.end.y, 0.0)), tint)
		var stroke := ORANGE
		stroke.a = 0.95 * _filter_alpha
		draw_rect(hole.grow(6.0), stroke, false, 6.0)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), tint)


func _draw_confirm_stroke() -> void:
	if _hole.size.x <= 4.0:
		return
	var stroke := ORANGE
	stroke.a = 0.95
	draw_rect(_hole.grow(6.0), stroke, false, 6.0)


func _has_point(point: Vector2) -> bool:
	if _game_menu_open():
		return false
	if _later_tools_visible():
		return true
	if _is_options_hit(point):
		return false
	if _state == STATE_INTRO:
		return Rect2(Vector2.ZERO, size).has_point(point)
	if _state == STATE_REVEAL_READ:
		return false
	if _state == STATE_REVEAL_CONFIRM or _state == STATE_THEME_CONTINUE:
		if _click_through.size.x > 4.0 and _click_through.grow(28.0).has_point(point):
			return false
		return Rect2(Vector2.ZERO, size).has_point(point)
	if _is_clear_state():
		return false
	if _click_through.size.x > 4.0 and _click_through.grow(28.0).has_point(point):
		return false
	return Rect2(Vector2.ZERO, size).has_point(point)


func _process(_delta: float) -> void:
	if _state != STATE_DONE:
		_sync_overlay_vs_filter()
	if _later_tools_visible():
		return
	if _state == STATE_CELL or _state == STATE_LETTER:
		_follow_board_motion()
	if _state == STATE_THEME_CONTINUE:
		if get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
			_begin_cells_after_theme()
		else:
			_refresh_hole()
		return
	if _state != STATE_REVEAL_READ and _state != STATE_REVEAL_CONFIRM:
		return
	if _reveal_already_confirmed():
		_begin_reveal_wait()
		return
	if get_tree().get_nodes_in_group("RevealOverlay").is_empty():
		_retry_hud_reveal()
		return
	_refresh_hole()


func _gui_input(event: InputEvent) -> void:
	if _game_menu_open():
		return
	if _later_tools_visible():
		if _later_button and _is_press_event(event):
			var global := get_global_transform_with_canvas() * _event_local_pos(event)
			if _later_button.get_global_rect().grow(8.0).has_point(global):
				return
		accept_event()
		return
	if GameManager.onboarding_stage == 1 and _is_press_event(event) and _pressed_later_tool(_event_local_pos(event)):
		show_later_tools_message()
		accept_event()
		return
	if _state == STATE_INTRO or _state == STATE_WAIT or _state == STATE_DONE:
		accept_event()
		return
	if _state == STATE_REVEAL_READ:
		return
	if _is_clear_state() or _state == STATE_THEME_WAIT:
		return
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		return
	if not _is_press_event(event):
		return
	var pos := _event_local_pos(event)
	if _state == STATE_CELL and _target_cell and _click_through.grow(36.0).has_point(pos):
		_activate_target_cell()
		accept_event()
	elif _state == STATE_LETTER and _target_key and _click_through.grow(36.0).has_point(pos):
		_target_key.apply_from_keyboard()
		accept_event()
	elif _state == STATE_THEME and _click_through.grow(24.0).has_point(pos):
		_press_theme()
		accept_event()
	elif _state == STATE_REVEAL and _click_through.grow(24.0).has_point(pos):
		_press_reveal()
		accept_event()
	elif _state == STATE_THEME_CONTINUE and _click_through.grow(24.0).has_point(pos):
		_press_theme_continue()
		accept_event()
	elif _state == STATE_REVEAL_CONFIRM and _click_through.grow(24.0).has_point(pos):
		_press_dialog_reveal()
		accept_event()
	elif _state == STATE_REVEAL_CONFIRM or _state == STATE_THEME_CONTINUE:
		accept_event()


func on_reveal_clicked() -> bool:
	if GameManager.onboarding_stage == 1:
		show_later_tools_message()
		return true
	if _state == STATE_REVEAL:
		_start_reveal_read()
		return false
	if _is_reveal_flow():
		return true
	_recover_from_offpath()
	return true


func _reveal_already_confirmed() -> bool:
	if not get_tree().get_nodes_in_group("RevealSequence").is_empty():
		return true
	var overlay := get_tree().get_first_node_in_group("RevealOverlay")
	if overlay != null and bool(overlay.get("confirmed")):
		return true
	return false


func _is_reveal_flow() -> bool:
	return (
		_state == STATE_REVEAL
		or _state == STATE_REVEAL_READ
		or _state == STATE_REVEAL_CONFIRM
		or _state == STATE_WAIT
	)


func _is_theme_flow() -> bool:
	return (
		_state == STATE_THEME
		or _state == STATE_THEME_WAIT
		or _state == STATE_THEME_CONTINUE
	)


func _allows_theme_preview() -> bool:
	return _state == STATE_THEME_WAIT or _state == STATE_THEME_CONTINUE


func _is_clear_state() -> bool:
	return _state == STATE_CLEAR_CELL or _state == STATE_CLEAR_LETTER


func _sync_mouse() -> void:
	if _is_clear_state() or _state == STATE_THEME_WAIT or _state == STATE_REVEAL_READ:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP


func _set_filter_alpha(value: float) -> void:
	_filter_alpha = clampf(value, 0.0, 1.0)
	queue_redraw()


func _fade_filter(target: float) -> void:
	if is_instance_valid(_filter_tween):
		_filter_tween.kill()
		_filter_tween = null
	var token := _flow_token
	var start := _filter_alpha
	if is_equal_approx(start, target):
		_set_filter_alpha(target)
		return
	var elapsed := 0.0
	while elapsed < FADE_SEC:
		if _flow_token != token or _state == STATE_DONE:
			return
		elapsed += get_process_delta_time()
		_set_filter_alpha(lerpf(start, target, clampf(elapsed / FADE_SEC, 0.0, 1.0)))
		await get_tree().process_frame
	if _flow_token != token:
		return
	_set_filter_alpha(target)


func _on_puzzle_input(kind: String, data: Dictionary) -> void:
	if kind == "theme" and (_state == STATE_THEME or _state == STATE_THEME_WAIT):
		_start_theme_wait()
		return
	if _recovering or _state == STATE_INTRO or _state == STATE_DONE or _is_reveal_flow() or _is_theme_flow():
		if kind == "reveal" and _state == STATE_REVEAL:
			_start_reveal_read()
		return
	if kind == "cell" and _target_cell:
		if int(data.get("orden", -1)) == _target_cell.orden:
			if _state == STATE_CELL or _state == STATE_CLEAR_LETTER:
				_on_cell_picked()
			return
		if _state == STATE_CLEAR_CELL or _state == STATE_LETTER or _state == STATE_CLEAR_LETTER:
			_recover_from_offpath()
		return
	if kind == "letter":
		var placed := GameManager._hint_letter_key(str(data.get("letter", "")))
		var numero := int(data.get("numero", -1))
		var right_letter := placed == _target_letter and not _target_letter.is_empty()
		var right_cell := _target_cell != null and is_instance_valid(_target_cell) and numero == _target_cell.numero
		if right_letter and right_cell and (_state == STATE_LETTER or _state == STATE_CLEAR_CELL):
			_on_letter_assigned()
			return
		if _state == STATE_CELL or _state == STATE_CLEAR_CELL or _state == STATE_LETTER:
			_recover_from_offpath()
		return
	if GameManager.onboarding_stage == 1 and (kind == "reveal" or kind == "hint" or kind == "hint_select" or kind == "theme" or kind.begins_with("color")):
		show_later_tools_message()
		return
	if kind == "options":
		return
	if kind == "reveal" or kind == "hint" or kind == "hint_select" or kind == "theme" or kind.begins_with("color") or kind == "erase":
		_recover_from_offpath()


func _pick_and_show_cell() -> void:
	_pick_targets()
	_snapshot_locked_letters()
	if _target_cell == null or _target_letter.is_empty():
		_finish_puzzle()
		return
	_show_cell_prompt()


func _show_cell_prompt() -> void:
	if _target_cell == null or not is_instance_valid(_target_cell) or _target_letter.is_empty():
		_pick_and_show_cell()
		return
	if _target_letter_on_cell():
		_pick_and_show_cell()
		return
	_ensure_cell_visible(_target_cell)
	_flow_token += 1
	var token := _flow_token
	await _ensure_board_visible()
	if _flow_token != token or not is_inside_tree():
		return
	_state = STATE_CELL
	_sync_mouse()
	_refresh_hole()
	_point_hand(_hole)
	await _fade_filter(1.0)
	if _flow_token != token:
		return


func _on_cell_picked() -> void:
	if _state != STATE_CELL and _state != STATE_CLEAR_LETTER:
		return
	_flow_token += 1
	var token := _flow_token
	_hide_hand()
	_state = STATE_CLEAR_CELL
	_sync_mouse()
	await _fade_filter(0.0)
	if _flow_token != token or _state != STATE_CLEAR_CELL:
		return
	_hole = Rect2()
	_click_through = Rect2()
	queue_redraw()
	var elapsed := 0.0
	while elapsed < CELL_HOLD_SEC:
		if _flow_token != token or _state != STATE_CLEAR_CELL:
			return
		if _later_tools_visible() or _has_stray_overlay():
			await get_tree().process_frame
			continue
		if not _target_cell_selected():
			_recover_from_offpath()
			return
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if _flow_token != token or _state != STATE_CLEAR_CELL:
		return
	await _ensure_board_visible()
	if _flow_token != token or _state != STATE_CLEAR_CELL:
		return
	if not _target_cell_selected():
		_recover_from_offpath()
		return
	_show_letter_prompt()


func _show_letter_prompt() -> void:
	if _target_key == null:
		_target_key = _find_key(_target_letter)
	if _target_key == null:
		_finish_puzzle()
		return
	_flow_token += 1
	var token := _flow_token
	await _ensure_board_visible()
	if _flow_token != token or not is_inside_tree():
		return
	_state = STATE_LETTER
	if not _target_cell_selected() and _target_cell and is_instance_valid(_target_cell):
		_target_cell._on_button_pressed()
	if not _target_cell_selected():
		_show_cell_prompt()
		return
	_sync_mouse()
	_refresh_hole()
	_point_hand(_hole)
	await _fade_filter(1.0)
	if _flow_token != token:
		return


func _on_letter_assigned() -> void:
	if _state != STATE_LETTER and _state != STATE_CLEAR_CELL:
		return
	_flow_token += 1
	var token := _flow_token
	_letters_solved += 1
	_hide_hand()
	_state = STATE_CLEAR_LETTER
	_sync_mouse()
	await _fade_filter(0.0)
	if not is_inside_tree() or _state == STATE_DONE or _flow_token != token:
		return
	_hole = Rect2()
	_click_through = Rect2()
	queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	if GameManager.onboarding_stage == 2 and not _reveal_shown and _letters_solved >= 2:
		_reveal_shown = true
		_show_reveal()
		return
	_pick_targets()
	_snapshot_locked_letters()
	if _target_cell == null or _target_letter.is_empty():
		_finish_puzzle()
		return
	var elapsed := 0.0
	while elapsed < HOLD_SEC:
		if _flow_token != token or _state != STATE_CLEAR_LETTER:
			return
		if _later_tools_visible() or _has_stray_overlay():
			await get_tree().process_frame
			continue
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if _flow_token != token or _state != STATE_CLEAR_LETTER:
		return
	await _ensure_board_visible()
	if _flow_token != token or _state != STATE_CLEAR_LETTER:
		return
	_state = STATE_CELL
	_sync_mouse()
	_refresh_hole()
	_point_hand(_hole)
	await _fade_filter(1.0)


func _show_theme_prompt() -> void:
	_flow_token += 1
	var token := _flow_token
	await _ensure_board_visible()
	if _flow_token != token or not is_inside_tree():
		return
	if _theme_button() == null:
		_pick_and_show_cell()
		return
	_state = STATE_THEME
	_target_cell = null
	_target_key = null
	_sync_mouse()
	_refresh_hole()
	_point_hand(_hole)
	_fade_filter(1.0)


func _press_theme() -> void:
	if _state != STATE_THEME:
		return
	var panel_up := get_tree().get_first_node_in_group("GameHUD")
	if panel_up and panel_up.has_method("_on_theme_pressed"):
		panel_up.call("_on_theme_pressed")
	_start_theme_wait()


func _start_theme_wait() -> void:
	if _state == STATE_THEME_WAIT or _state == STATE_THEME_CONTINUE or _state == STATE_DONE:
		return
	_flow_token += 1
	var token := _flow_token
	_state = STATE_THEME_WAIT
	_sync_mouse()
	_hide_hand()
	_hole = Rect2()
	_click_through = Rect2()
	queue_redraw()
	await _fade_filter(0.0)
	if _flow_token != token:
		return
	var guard := 0
	while get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty() and guard < 90:
		if _flow_token != token:
			return
		await get_tree().process_frame
		guard += 1
	if get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
		_begin_cells_after_theme()
		return
	var elapsed := 0.0
	while elapsed < THEME_HOLD_SEC:
		if _flow_token != token:
			return
		if get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
			_begin_cells_after_theme()
			return
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if _flow_token != token:
		return
	if get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
		_begin_cells_after_theme()
		return
	_show_theme_continue()


func _show_theme_continue() -> void:
	if get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
		_begin_cells_after_theme()
		return
	_flow_token += 1
	var token := _flow_token
	_state = STATE_THEME_CONTINUE
	_filter_hidden_for_overlay = false
	_sync_mouse()
	var tries := 0
	while tries < 45:
		if _flow_token != token or _state != STATE_THEME_CONTINUE:
			return
		if get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
			_begin_cells_after_theme()
			return
		_refresh_hole()
		if _hole.size.x > 4.0:
			break
		await get_tree().process_frame
		tries += 1
	if _flow_token != token or _state != STATE_THEME_CONTINUE:
		return
	if get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
		_begin_cells_after_theme()
		return
	_refresh_hole()
	_point_hand(_hole)
	queue_redraw()
	await _fade_filter(1.0)
	if _flow_token != token:
		return
	_wait_theme_closed()


func _press_theme_continue() -> void:
	var preview := get_tree().get_first_node_in_group("PuzzleThemePreview")
	if preview != null and preview.has_method("_on_start_pressed"):
		preview.call("_on_start_pressed")
	_begin_cells_after_theme()


func _wait_theme_closed() -> void:
	var token := _flow_token
	var guard := 0
	while not get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty() and guard < 800:
		if _flow_token != token:
			return
		await get_tree().process_frame
		guard += 1
	if _flow_token != token:
		return
	_begin_cells_after_theme()


func _begin_cells_after_theme() -> void:
	if _state == STATE_DONE or not _is_theme_flow():
		return
	_flow_token += 1
	var token := _flow_token
	_state = STATE_CELL
	_hide_hand()
	_hole = Rect2()
	_click_through = Rect2()
	queue_redraw()
	await _fade_filter(0.0)
	if _flow_token != token or not is_inside_tree() or _state == STATE_DONE:
		return
	_pick_and_show_cell()


func _show_reveal() -> void:
	_flow_token += 1
	var token := _flow_token
	await _ensure_board_visible()
	if _flow_token != token or not is_inside_tree():
		return
	_state = STATE_REVEAL
	_target_cell = null
	_target_key = null
	_sync_mouse()
	_refresh_hole()
	_point_hand(_hole)
	var panel_up := get_tree().get_first_node_in_group("GameHUD")
	if panel_up and panel_up.has_method("_blink_reveal_button"):
		panel_up.call("_blink_reveal_button")
	_fade_filter(1.0)


func _start_reveal_read() -> void:
	if _state != STATE_REVEAL and _state != STATE_REVEAL_READ:
		return
	_flow_token += 1
	var token := _flow_token
	_state = STATE_REVEAL_READ
	_sync_mouse()
	_hide_hand()
	_hole = Rect2()
	_click_through = Rect2()
	queue_redraw()
	await _fade_filter(0.0)
	if _flow_token != token:
		return
	var guard := 0
	while get_tree().get_nodes_in_group("RevealOverlay").is_empty() and guard < 90:
		await get_tree().process_frame
		if _flow_token != token:
			return
		guard += 1
	if get_tree().get_nodes_in_group("RevealOverlay").is_empty():
		_retry_hud_reveal()
		return
	var elapsed := 0.0
	while elapsed < REVEAL_HOLD_SEC:
		if _flow_token != token or _state != STATE_REVEAL_READ:
			return
		if _reveal_already_confirmed():
			_begin_reveal_wait()
			return
		if get_tree().get_nodes_in_group("RevealOverlay").is_empty():
			_retry_hud_reveal()
			return
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if _flow_token != token or _state != STATE_REVEAL_READ:
		return
	if _reveal_already_confirmed():
		_begin_reveal_wait()
		return
	if get_tree().get_nodes_in_group("RevealOverlay").is_empty():
		_retry_hud_reveal()
		return
	_show_reveal_dialog_button()


func _show_reveal_dialog_button() -> void:
	if _reveal_already_confirmed():
		_begin_reveal_wait()
		return
	if get_tree().get_nodes_in_group("RevealOverlay").is_empty():
		_retry_hud_reveal()
		return
	_flow_token += 1
	var token := _flow_token
	_state = STATE_REVEAL_CONFIRM
	_filter_hidden_for_overlay = false
	_sync_mouse()
	var tries := 0
	while tries < 45:
		if _flow_token != token or _state != STATE_REVEAL_CONFIRM:
			return
		if _reveal_already_confirmed():
			_begin_reveal_wait()
			return
		if get_tree().get_nodes_in_group("RevealOverlay").is_empty():
			_retry_hud_reveal()
			return
		_refresh_hole()
		if _hole.size.x > 4.0:
			break
		await get_tree().process_frame
		tries += 1
	if _flow_token != token or _state != STATE_REVEAL_CONFIRM:
		return
	if _reveal_already_confirmed():
		_begin_reveal_wait()
		return
	if get_tree().get_nodes_in_group("RevealOverlay").is_empty():
		_retry_hud_reveal()
		return
	_refresh_hole()
	_point_hand(_hole)
	queue_redraw()
	await _fade_filter(1.0)


func _press_dialog_reveal() -> void:
	if _reveal_already_confirmed():
		_begin_reveal_wait()
		return
	var overlay := get_tree().get_first_node_in_group("RevealOverlay")
	if overlay != null and overlay.has_method("_on_reveal_pressed"):
		overlay.call("_on_reveal_pressed")
	else:
		GameManager.reveal_assignment_errors(true)
	_begin_reveal_wait()


func _press_reveal() -> void:
	var panel_up := get_tree().get_first_node_in_group("GameHUD")
	if panel_up and panel_up.has_method("_on_reveal_pressed"):
		panel_up.call("_on_reveal_pressed")
	else:
		_start_reveal_read()
		GameManager.reveal_assignment_errors(true)


func _retry_hud_reveal() -> void:
	if _state != STATE_REVEAL_READ and _state != STATE_REVEAL_CONFIRM:
		return
	_flow_token += 1
	var token := _flow_token
	_state = STATE_REVEAL
	_hide_hand()
	_hole = Rect2()
	_click_through = Rect2()
	queue_redraw()
	await _ensure_board_visible()
	if _flow_token != token or not is_inside_tree() or _state == STATE_DONE:
		return
	_show_reveal()


func _begin_reveal_wait() -> void:
	if _state == STATE_DONE or _state == STATE_WAIT:
		return
	_flow_token += 1
	_state = STATE_WAIT
	_sync_mouse()
	_hole = Rect2()
	_click_through = Rect2()
	_hide_hand()
	queue_redraw()
	_fade_filter(0.0)
	_wait_reveal_closed()


func _wait_reveal_closed() -> void:
	var token := _flow_token
	await get_tree().process_frame
	var guard := 0
	while not get_tree().get_nodes_in_group("RevealOverlay").is_empty() and guard < 400:
		if _flow_token != token:
			return
		await get_tree().process_frame
		guard += 1
	for _i in 16:
		if _flow_token != token:
			return
		await get_tree().process_frame
		if not get_tree().get_nodes_in_group("RevealSequence").is_empty():
			break
	guard = 0
	while not get_tree().get_nodes_in_group("RevealSequence").is_empty() and guard < 400:
		if _flow_token != token:
			return
		await get_tree().process_frame
		guard += 1
	await get_tree().process_frame
	if _state == STATE_DONE or _flow_token != token:
		return
	_pick_and_show_cell()


func _finish_puzzle() -> void:
	if _state == STATE_DONE:
		return
	_flow_token += 1
	_state = STATE_DONE
	_hide_hand()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if get_tree().get_nodes_in_group("RevealSequence").is_empty():
		GameManager.reveal_assignment_errors()
	queue_free()


func _dismiss() -> void:
	if _state == STATE_DONE:
		return
	_flow_token += 1
	_state = STATE_DONE
	queue_free()


func _pick_targets() -> void:
	_target_cell = null
	_target_key = null
	_target_letter = ""
	var candidates: Array[Celda] = []
	for node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		var cell: Celda = node
		if cell.bloqueada or cell.es_regalo_inicial or cell.revelada_verde or cell.celda_mostrada:
			continue
		if str(cell.letter_user).strip_edges() != "":
			continue
		if cell.letra.strip_edges() == "" or cell.letra == " " or cell.numero >= 100:
			continue
		var key := GameManager._hint_letter_key(cell.letra)
		if key.is_empty() or _letter_already_used(key):
			continue
		candidates.append(cell)
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: Celda, b: Celda) -> bool:
		return a.orden < b.orden
	)
	var seen: Dictionary = {}
	for cell in candidates:
		if seen.has(cell.numero):
			continue
		seen[cell.numero] = true
		_target_cell = cell
		break
	if _target_cell == null:
		return
	_target_letter = GameManager._hint_letter_key(_target_cell.letra)
	_target_key = _find_key(_target_letter)
	_ensure_cell_visible(_target_cell)


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


func _letter_already_used(letter: String) -> bool:
	var key := _find_key(letter)
	return key != null and key.letra_mostrada


func _target_cell_selected() -> bool:
	if _target_cell == null or not is_instance_valid(_target_cell):
		return false
	return GameManager.selected_celda_number == _target_cell.orden \
		and GameManager.celda_seleccionada_numero == _target_cell.numero


func _target_letter_on_cell() -> bool:
	if _target_cell == null or not is_instance_valid(_target_cell):
		return false
	return GameManager._hint_letter_key(str(_target_cell.letter_user)) == _target_letter \
		and not _target_letter.is_empty()


func _snapshot_locked_letters() -> void:
	_locked_letters.clear()
	for node in get_tree().get_nodes_in_group("Letra"):
		if node is Letra and (node as Letra).letra_mostrada:
			_locked_letters[(node as Letra).letra.to_upper()] = true


func _has_stray_overlay() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	if tree.paused:
		return true
	for group_name in ["HintsOverlay", "PuzzleThemePreview", "GameMenu", "BoardFillPrompt", "FondoCompraLetra", "RevealOverlay", "ShareSolveDialog", "LevelStartIntro"]:
		if _is_reveal_flow() and group_name == "RevealOverlay":
			continue
		if _allows_theme_preview() and group_name == "PuzzleThemePreview":
			continue
		if not tree.get_nodes_in_group(group_name).is_empty():
			return true
	var parent := get_parent()
	if parent == null:
		return false
	for child in parent.get_children():
		if child == self or not is_instance_valid(child):
			continue
		if child.is_in_group("RevealSequence"):
			continue
		if _is_reveal_flow() and child.is_in_group("RevealOverlay"):
			continue
		if _allows_theme_preview() and child.is_in_group("PuzzleThemePreview"):
			continue
		if child is CanvasItem and (child as CanvasItem).visible:
			return true
	return false


func _close_blocking_overlays() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if tree.paused:
		tree.paused = false
		SoundManager.fade_to_game_music()
	var allow_reveal := _is_reveal_flow()
	var allow_theme := _allows_theme_preview()
	for group_name in ["HintsOverlay", "PuzzleThemePreview", "GameMenu", "BoardFillPrompt", "FondoCompraLetra", "ShareSolveDialog"]:
		if allow_theme and group_name == "PuzzleThemePreview":
			continue
		for node in tree.get_nodes_in_group(group_name):
			if is_instance_valid(node):
				node.queue_free()
	if not allow_reveal:
		for node in tree.get_nodes_in_group("RevealOverlay"):
			if is_instance_valid(node):
				node.queue_free()
	var parent := get_parent()
	if parent == null:
		return
	for child in parent.get_children():
		if child == self or not is_instance_valid(child):
			continue
		if child.is_in_group("RevealSequence"):
			continue
		if allow_reveal and child.is_in_group("RevealOverlay"):
			continue
		if allow_theme and child.is_in_group("PuzzleThemePreview"):
			continue
		child.queue_free()


func _ensure_board_visible() -> void:
	_filter_hidden_for_overlay = false
	_close_blocking_overlays()
	if get_tree():
		await get_tree().process_frame
		await get_tree().process_frame


func _sync_overlay_vs_filter() -> void:
	if _state == STATE_THEME_CONTINUE or _state == STATE_REVEAL_CONFIRM:
		return
	if _has_stray_overlay():
		if not _filter_hidden_for_overlay:
			_filter_hidden_for_overlay = true
			_set_filter_alpha(0.0)
			_hide_hand()
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	if not _filter_hidden_for_overlay:
		return
	_filter_hidden_for_overlay = false
	_sync_mouse()
	_refresh_hole()
	_point_hand(_hole)
	_fade_filter(1.0)


func _undo_stray_assignments() -> void:
	var keep_target := _target_letter_on_cell()
	for node in get_tree().get_nodes_in_group("Letra"):
		if not node is Letra:
			continue
		var key := node as Letra
		if not key.letra_mostrada or key.verificada_correcta:
			continue
		var letter := key.letra.to_upper()
		if _locked_letters.has(letter):
			continue
		if keep_target and letter == _target_letter:
			continue
		GameManager.borrar_letra_en_tablero(letter)
		GameManager.liberar_letra_teclado(letter)
	SignalManager.update_resting_characters.emit()
	SignalManager.update_rubber.emit()


func _recover_from_offpath() -> void:
	if _recovering or _state == STATE_DONE or _state == STATE_INTRO or _is_reveal_flow() or _is_theme_flow():
		return
	_recovering = true
	_flow_token += 1
	var token := _flow_token
	_hide_hand()
	_close_blocking_overlays()
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree() or _flow_token != token or _state == STATE_DONE:
		_recovering = false
		return
	_undo_stray_assignments()
	_recovering = false
	if _target_letter_on_cell():
		_pick_and_show_cell()
		return
	if _target_cell_selected():
		_show_letter_prompt()
		return
	_show_cell_prompt()


func _refresh_hole() -> void:
	var visual := Rect2()
	if _state == STATE_CELL and _target_cell:
		visual = _padded_rect(_local_rect(_target_cell), 132.0)
	elif _state == STATE_LETTER and _target_key:
		visual = _padded_rect(_local_rect(_target_key), 148.0)
	elif _state == STATE_REVEAL:
		visual = _padded_rect(_local_rect(_reveal_button()), 168.0)
	elif _state == STATE_THEME:
		visual = _padded_rect(_local_rect(_theme_button()), 168.0)
	elif _state == STATE_THEME_CONTINUE:
		visual = _padded_rect(_local_rect(_theme_continue_button()), 148.0)
	elif _state == STATE_REVEAL_READ or _state == STATE_REVEAL_CONFIRM:
		visual = _padded_rect(_local_rect(_dialog_reveal_button()), 148.0)
	_hole = visual
	_click_through = visual
	queue_redraw()


func _padded_rect(rect: Rect2, min_side: float) -> Rect2:
	if rect.size.x < 4.0:
		return Rect2()
	rect = rect.grow(36.0)
	if rect.size.x < min_side:
		var extra := (min_side - rect.size.x) * 0.5
		rect.position.x -= extra
		rect.size.x = min_side
	if rect.size.y < min_side:
		var extra := (min_side - rect.size.y) * 0.5
		rect.position.y -= extra
		rect.size.y = min_side
	return rect


func _reveal_button() -> Control:
	var hud := get_tree().get_first_node_in_group("GameHUD")
	if hud == null:
		return null
	return hud.get_node_or_null("ButtonReveal") as Control


func _theme_button() -> Control:
	var hud := get_tree().get_first_node_in_group("GameHUD")
	if hud == null:
		return null
	return hud.get_node_or_null("ButtonTheme") as Control


func _theme_continue_button() -> Control:
	var preview := get_tree().get_first_node_in_group("PuzzleThemePreview")
	if preview == null:
		return null
	var btn := preview.get_node_or_null("Card/ButtonStart") as Control
	if btn:
		return btn
	return preview.find_child("ButtonStart", true, false) as Control


func _dialog_reveal_button() -> Control:
	var overlay := get_tree().get_first_node_in_group("RevealOverlay") as Node
	if overlay == null:
		return null
	var btn := overlay.find_child("ButtonReveal", true, false) as Control
	if btn:
		return btn
	return overlay.get_node_or_null("Center/Card/Margin/Content/Buttons/ButtonReveal") as Control


func _local_rect(node: CanvasItem) -> Rect2:
	if node == null or not is_instance_valid(node):
		return Rect2()
	var rect := (node as Control).get_global_rect() if node is Control else Rect2(node.get_global_transform_with_canvas().origin, Vector2(80, 80))
	var top_left := get_global_transform_with_canvas().affine_inverse() * rect.position
	return Rect2(top_left, rect.size)


func on_board_pan_ended() -> void:
	if _state == STATE_INTRO or _state == STATE_DONE or _later_tools_visible():
		return
	if _is_reveal_flow() or _is_theme_flow():
		return
	_pan_snap_token += 1
	var token := _pan_snap_token
	await get_tree().create_timer(0.28).timeout
	if not is_inside_tree() or token != _pan_snap_token:
		return
	_snap_sequence_into_view()


func _follow_board_motion() -> void:
	var before := _hole
	_refresh_hole()
	if _hand == null or not _hand.visible or _hole.size.x <= 4.0:
		return
	_hand.position += _hole.position - before.position


func _snap_sequence_into_view() -> void:
	if _target_cell == null or not is_instance_valid(_target_cell):
		return
	_ensure_cell_visible(_target_cell)
	_refresh_hole()
	if _state == STATE_CELL or _state == STATE_LETTER:
		_point_hand(_hole)


func _ensure_cell_visible(cell: Celda) -> void:
	var canvas := get_tree().get_first_node_in_group("PuzzleCanvas")
	if canvas == null or cell == null or not is_instance_valid(cell):
		return
	if canvas.has_method("pan_cell_into_view"):
		canvas.call("pan_cell_into_view", cell)
		return
	var parent_ctrl := (canvas as Control).get_parent() as Control
	var view := parent_ctrl.get_global_rect() if parent_ctrl else (canvas as Control).get_global_rect()
	var cell_rect := cell.get_global_rect()
	var pad := 56.0
	if cell_rect.position.y < view.position.y + pad:
		(canvas as Control).position.y += (view.position.y + pad) - cell_rect.position.y
	elif cell_rect.end.y > view.end.y - pad:
		(canvas as Control).position.y -= cell_rect.end.y - (view.end.y - pad)
	if canvas.has_method("_clamp_canvas_y"):
		canvas.call("_clamp_canvas_y")


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
	if (_state != STATE_CELL and _state != STATE_CLEAR_LETTER) or _target_cell == null or not is_instance_valid(_target_cell):
		return
	_target_cell._on_button_pressed()


func _point_hand(hole: Rect2) -> void:
	if _hand == null:
		return
	if hole.size.x < 4.0:
		_hide_hand()
		return
	_hand.visible = true
	_hand.size = HAND_SIZE
	var tip := hole.position + Vector2(hole.size.x * 0.55, hole.size.y * 0.72)
	_hand.position = tip
	if is_instance_valid(_hand_tween):
		_hand_tween.kill()
	_hand.scale = Vector2.ONE
	_hand.pivot_offset = Vector2(18, 12)
	_hand_tween = create_tween()
	_hand_tween.set_loops()
	_hand_tween.tween_property(_hand, "position:y", tip.y + 18.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hand_tween.tween_property(_hand, "position:y", tip.y, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _hide_hand() -> void:
	if is_instance_valid(_hand_tween):
		_hand_tween.kill()
	_hand_tween = null
	if _hand:
		_hand.visible = false


func _build() -> void:
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
	_intro = ColorRect.new()
	_intro.color = Color(0.12, 0.07, 0.04, 0.88)
	_intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro.mouse_filter = Control.MOUSE_FILTER_STOP
	_intro.visible = false
	_intro.z_index = 30
	add_child(_intro)
	_intro_card = Panel.new()
	_intro_card.name = "Card"
	_intro_card.set_anchors_preset(Control.PRESET_CENTER)
	_intro.add_child(_intro_card)
	_intro_card_style = StyleBoxFlat.new()
	_intro_card_style.bg_color = INTRO_PAPER
	_intro_card_style.set_corner_radius_all(36)
	_intro_card_style.set_border_width_all(4)
	_intro_card_style.border_color = Color(0.66, 0.44, 0.2, 0.7)
	_intro_card.add_theme_stylebox_override("panel", _intro_card_style)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 48)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro_card.add_child(margin)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 24)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)
	_intro_image = TextureRect.new()
	_intro_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_intro_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_intro_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_intro_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_intro_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_intro_image)
	_intro_body = Label.new()
	_intro_body.visible = false
	_intro_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro_button = Button.new()
	_intro_button.custom_minimum_size = Vector2(0, 108)
	_intro_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_intro_button.focus_mode = Control.FOCUS_NONE
	_intro_button.add_theme_font_override("font", FONT)
	_intro_button.add_theme_font_size_override("font_size", 36)
	_intro_button.add_theme_color_override("font_color", Color.WHITE)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = ORANGE
	btn_style.set_corner_radius_all(28)
	btn_style.set_border_width_all(3)
	btn_style.border_width_bottom = 8
	btn_style.border_color = Color(0.83, 0.41, 0.02, 1)
	_intro_button.add_theme_stylebox_override("normal", btn_style)
	_intro_button.add_theme_stylebox_override("hover", btn_style)
	_intro_button.add_theme_stylebox_override("pressed", btn_style)
	_intro_button.pressed.connect(_on_intro_continue)
	col.add_child(_intro_button)
	_build_later_tools()


func _show_intro() -> void:
	_state = STATE_INTRO
	_hide_hand()
	_hole = Rect2()
	_click_through = Rect2()
	queue_redraw()
	var path := GameManager.find_level_image_path(GameManager.id_image)
	if path != "" and ResourceLoader.exists(path):
		_intro_image.texture = load(path)
		_intro_image.visible = true
		_apply_intro_paper_color(_intro_image.texture)
	else:
		_intro_image.visible = false
		_apply_intro_paper_color(null)
	if _intro_body:
		_intro_body.visible = false
		_intro_body.text = ""
	_intro_button.text = tr("ContinueAction")
	_intro.visible = true
	_layout_intro()


func _hide_intro() -> void:
	if _intro:
		_intro.visible = false


func _apply_intro_paper_color(tex: Texture2D) -> void:
	if _intro_card_style == null:
		return
	var paper := INTRO_PAPER
	if tex:
		var img := tex.get_image()
		if img:
			paper = img.get_pixel(2, 2)
	_intro_card_style.bg_color = paper


func _layout_intro() -> void:
	if _intro == null:
		return
	var card := _intro.get_node_or_null("Card") as Control
	if card == null:
		return
	var width := minf(size.x * 0.92, 1000.0)
	var image_side := minf(width - 48.0, size.y * 0.58)
	var height := image_side + 108.0 + 148.0
	height = minf(height, size.y * 0.90)
	card.size = Vector2(width, height)
	card.position = (size - card.size) * 0.5
	if _intro_button:
		_intro_button.custom_minimum_size = Vector2(minf(width * 0.55, 420.0), 108.0)


func _on_intro_continue() -> void:
	SoundManager.play("ButtonClick")
	_hide_intro()
	_filter_alpha = 0.0
	_pick_and_show_cell()


func _build_later_tools() -> void:
	_later = ColorRect.new()
	_later.color = Color(0.12, 0.07, 0.04, 0.55)
	_later.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_later.mouse_filter = Control.MOUSE_FILTER_STOP
	_later.visible = false
	_later.z_index = 40
	add_child(_later)
	_later_card = Panel.new()
	_later_card.name = "Card"
	_later.add_child(_later_card)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.91, 1)
	style.set_corner_radius_all(32)
	style.set_border_width_all(4)
	style.border_color = Color(0.66, 0.44, 0.2, 0.7)
	(_later_card as Panel).add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 36)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_later_card.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 28)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(col)
	_later_body = Label.new()
	_later_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_later_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_later_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_later_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_later_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_later_body.add_theme_font_override("font", FONT)
	_later_body.add_theme_font_size_override("font_size", 34)
	_later_body.add_theme_color_override("font_color", INK)
	_later_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_later_body)
	_later_button = Button.new()
	_later_button.custom_minimum_size = Vector2(0, 100)
	_later_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_later_button.focus_mode = Control.FOCUS_NONE
	_later_button.add_theme_font_override("font", FONT)
	_later_button.add_theme_font_size_override("font_size", 36)
	_later_button.add_theme_color_override("font_color", Color.WHITE)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = ORANGE
	btn_style.set_corner_radius_all(28)
	btn_style.set_border_width_all(3)
	btn_style.border_width_bottom = 8
	btn_style.border_color = Color(0.83, 0.41, 0.02, 1)
	_later_button.add_theme_stylebox_override("normal", btn_style)
	_later_button.add_theme_stylebox_override("hover", btn_style)
	_later_button.add_theme_stylebox_override("pressed", btn_style)
	_later_button.pressed.connect(_hide_later_tools)
	col.add_child(_later_button)


func show_later_tools_message() -> void:
	if GameManager.onboarding_stage != 1:
		return
	if _later_tools_visible():
		return
	if _later == null:
		_build_later_tools()
	_later_body.text = _later_tools_text()
	_later_button.text = tr("ContinueAction")
	_later.visible = true
	_layout_later_tools()
	SoundManager.play("ButtonClick")


func _later_tools_text() -> String:
	var translated := tr("OnboardingLaterTools")
	if translated != "" and translated != "OnboardingLaterTools":
		return translated
	var locale := TranslationServer.get_locale().left(2).to_lower()
	return str(LATER_TOOLS_COPY.get(locale, LATER_TOOLS_COPY["es"]))


func _later_tools_visible() -> bool:
	return _later != null and _later.visible


func _hide_later_tools() -> void:
	SoundManager.play("ButtonClick")
	if _later:
		_later.visible = false
	if _state == STATE_CELL or _state == STATE_LETTER or _state == STATE_REVEAL:
		_point_hand(_hole)


func _layout_later_tools() -> void:
	if _later_card == null or not is_instance_valid(_later_card):
		return
	var width := minf(size.x * 0.88, 920.0)
	var height := minf(size.y * 0.42, 520.0)
	height = maxf(height, 360.0)
	_later_card.size = Vector2(width, height)
	_later_card.position = (size - _later_card.size) * 0.5
	if _later_button:
		_later_button.custom_minimum_size = Vector2(minf(width * 0.55, 420.0), 100.0)


func _pressed_later_tool(local_pos: Vector2) -> bool:
	var global := get_global_transform_with_canvas() * local_pos
	for btn in _later_tool_buttons():
		if btn.get_global_rect().grow(12.0).has_point(global):
			return true
	return false


func _later_tool_buttons() -> Array[Control]:
	var buttons: Array[Control] = []
	var hud := get_tree().get_first_node_in_group("GameHUD")
	if hud:
		for path in ["ButtonTheme", "ButtonHint", "ButtonReveal"]:
			var btn := hud.get_node_or_null(path) as Control
			if btn:
				buttons.append(btn)
	var colors := _panel_colors()
	if colors:
		var box := colors.get_node_or_null("HBoxContainer")
		if box:
			for i in range(1, 6):
				var color_btn := box.get_node_or_null("Button%d" % i) as Control
				if color_btn:
					buttons.append(color_btn)
	return buttons


func _panel_colors() -> Node:
	var host := get_parent()
	if host:
		var canvas := host.get_parent()
		if canvas:
			var found := canvas.get_node_or_null("PanelColors")
			if found:
				return found
	return get_tree().root.find_child("PanelColors", true, false)


func _options_button() -> Control:
	var hud := get_tree().get_first_node_in_group("GameHUD")
	if hud == null:
		return null
	var pause: Variant = hud.get("pause_button")
	if pause is Control:
		return pause
	return hud.find_child("ButtonPause", true, false) as Control


func _game_menu_open() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	if tree.paused:
		return true
	return not tree.get_nodes_in_group("GameMenu").is_empty()


func _is_options_hit(point: Vector2) -> bool:
	var btn := _options_button()
	if btn == null:
		return false
	var global := get_global_transform_with_canvas() * point
	return btn.get_global_rect().grow(12.0).has_point(global)
