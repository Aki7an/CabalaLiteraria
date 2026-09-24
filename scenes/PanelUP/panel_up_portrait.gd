extends Panel

const OVERLAY_EXIT := preload("res://scenes/fondo_salir.tscn")
const OVERLAY_RESULTS := preload("res://scenes/menu_game_over.tscn")
const OVERLAY_GAME_OVER := preload("res://scenes/menu_game_over_fail.tscn")
const OVERLAY_ERASE := preload("res://scenes/fondo_aviso_borrado.tscn")
const OVERLAY_HINTS := preload("res://scenes/CuadroPistas.tscn")
const OVERLAY_REVEAL := preload("res://scenes/CuadroRevelar.tscn")
const OVERLAY_BOARD_FILL := preload("res://scenes/fondo_tablero_completo.tscn")
const THEME_PREVIEW := preload("res://scenes/game/PuzzleThemePreview.tscn")
const ICON_CITA: Texture2D = preload("res://images/Ilustres.png")
const ICON_EFEM: Texture2D = preload("res://images/Efemerides.png")
const ICON_CURIO: Texture2D = preload("res://images/Adivinanza.png")
const ICON_FRAG: Texture2D = preload("res://images/FragmentosLiterarios.png")
const ICON_DAILY: Texture2D = preload("res://images/ui_icon_daily.svg")

@onready var _header: Node = $GameHeader
@onready var reveal_button: Button = $ButtonReveal
var category_button: Button
var category_label: Label
var category_icon: TextureRect
var letters_label: Label
var letters_progress: ProgressBar
var stars_title: Label
var time_value: Label
var time_unit: Label
var hourglass: Control
var mode_icon: TextureRect
var mode_label: Label
var stars: Array[TextureRect] = []
var pause_button: Button

const REVEAL_BLINK_COUNT := 2
const REVEAL_BLINK_DIM := Color(1, 1, 1, 0.28)
const REVEAL_BLINK_FULL := Color(1, 1, 1, 1)
const REVEAL_BLINK_STEP := 0.11

const MODE_ICON_QUICK := preload("res://images/mode_quick.svg")
const MODE_ICON_CRYPTO := preload("res://images/CriptogramaIcono.png")
const ICON_LOCK: Texture2D = preload("res://images/ui_icon_lock.svg")

var _start_ms: int
var _shown_minute := -1
var _suppress_minute_fx := false
var _completion_recorded := false
var _reveal_blink_tween: Tween
var _time_blink_tween: Tween
var _pause_ms := 0


func _ready() -> void:
	add_to_group("GameHUD")
	_bind_header_nodes()
	_bind_action_buttons()
	if not SignalManager.update_puzzle_stars.is_connected(_update_stars):
		SignalManager.update_puzzle_stars.connect(_update_stars)
	if not SignalManager.update_resting_characters.is_connected(_update_letters_filled):
		SignalManager.update_resting_characters.connect(_update_letters_filled)
	if not SignalManager.insert_letter_in_number.is_connected(_on_letter_placed):
		SignalManager.insert_letter_in_number.connect(_on_letter_placed)
	if not SignalManager.board_filled.is_connected(_on_board_filled):
		SignalManager.board_filled.connect(_on_board_filled)
	if not SignalManager.game_finished.is_connected(_on_game_finished):
		SignalManager.game_finished.connect(_on_game_finished)
	if not SignalManager.game_finished_lost.is_connected(_on_game_lost):
		SignalManager.game_finished_lost.connect(_on_game_lost)
	if not SignalManager.erase_letter.is_connected(_erase_selected_letter):
		SignalManager.erase_letter.connect(_erase_selected_letter)
	if not SignalManager.erase_letter_open_dialog.is_connected(_open_erase_dialog):
		SignalManager.erase_letter_open_dialog.connect(_open_erase_dialog)

	EventLoggerAutoload.start_session()
	_start_ms = Time.get_ticks_msec()
	if pause_button and not pause_button.pressed.is_connected(_on_pause_pressed):
		pause_button.pressed.connect(_on_pause_pressed)
	if category_label:
		category_label.text = GameManager.category_display_name()
	_apply_category_icon()
	if stars_title:
		stars_title.text = tr("TutStarsPuzzle")
	var theme_title := get_node_or_null("ButtonTheme/Title") as Label
	if theme_title:
		theme_title.text = tr("ThemeAction")
	var hint_title := get_node_or_null("ButtonHint/Title") as Label
	if hint_title:
		hint_title.text = tr("TutHint")
	var reveal_title := get_node_or_null("ButtonReveal/Title") as Label
	if reveal_title:
		reveal_title.text = tr("TutReveal")
	_apply_category_color()
	_apply_practice_lock()
	_apply_onboarding_tool_lock()
	refresh_hud()
	_suppress_minute_fx = true
	_update_timer_label(0.0)
	_suppress_minute_fx = false
	if get_tree() != null:
		await get_tree().process_frame
		refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.partida_terminada:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_0 or event.keycode == KEY_KP_0:
		if not OS.is_debug_build():
			return
		get_viewport().set_input_as_handled()
		_on_game_finished()
		return
	if _has_blocking_overlay():
		return
	var letter := _letter_from_key(event as InputEventKey)
	if letter == "":
		return
	if not _try_type_letter(letter):
		return
	get_viewport().set_input_as_handled()


func _has_blocking_overlay() -> bool:
	for group_name in ["HintsOverlay", "RevealOverlay", "RevealSequence", "BoardFillPrompt", "ShareSolveDialog", "GameMenu", "LevelStartIntro"]:
		if not get_tree().get_nodes_in_group(group_name).is_empty():
			return true
	return false


func _letter_from_key(event: InputEventKey) -> String:
	var raw := ""
	if event.unicode > 0:
		raw = String.chr(event.unicode)
	elif event.keycode >= KEY_A and event.keycode <= KEY_Z:
		raw = String.chr(event.keycode)
	if raw == "":
		return ""
	return GameManager._hint_letter_key(raw)


func _try_type_letter(letter: String) -> bool:
	if GameManager.celda_seleccionada_numero <= 0 or GameManager.celda_seleccionada_numero >= 100:
		return false
	for node in get_tree().get_nodes_in_group("Letra"):
		if not node is Letra:
			continue
		var key := node as Letra
		if key.letra.to_upper() != letter:
			continue
		key.apply_from_keyboard()
		return true
	return false


func _process(_delta: float) -> void:
	var elapsed_seconds := _elapsed_play_seconds()
	GameManager.set_tiempo_partida(elapsed_seconds)
	_update_timer_label(float(elapsed_seconds))


func refresh_hud() -> void:
	_update_stars()
	_update_letters_filled()
	_update_game_mode()


func _bind_header_nodes() -> void:
	if _header == null:
		_header = get_node_or_null("GameHeader")
	category_button = _header_node("ButtonCategory", "Margin/Main/Top/CategoryWrap/ButtonCategory") as Button
	category_label = _header_node("Category", "Margin/Main/Top/CategoryWrap/ButtonCategory/Category") as Label
	category_icon = _header_node("CategoryIcon", "Margin/Main/Top/CategoryWrap/ButtonCategory/CategoryIcon") as TextureRect
	letters_label = _header_node("LettersFilled", "Margin/Main/Bottom/LettersFilled") as Label
	letters_progress = _header_node("LettersProgress", "Margin/Main/Bottom/LettersProgress") as ProgressBar
	stars_title = _header_node("StarsTitle", "Margin/Main/Top/StarsBlock/StarsTitle") as Label
	time_value = _header_node("TimeValue", "Margin/Main/Top/TimerRow/TimeValue") as Label
	time_unit = _header_node("TimeUnit", "Margin/Main/Top/TimerRow/TimeUnit") as Label
	hourglass = _header_node("TimeIcon", "Margin/Main/Top/TimerRow/TimeIcon") as Control
	mode_icon = _header_node("ModeIcon", "Margin/Main/Top/StarsBlock/ModeRow/ModeIcon") as TextureRect
	mode_label = _header_node("ModeLabel", "Margin/Main/Top/StarsBlock/ModeRow/ModeLabel") as Label
	pause_button = _header_node("ButtonPause", "Margin/Main/Top/ButtonPause") as Button
	stars.clear()
	for index in range(1, 6):
		var star := _header_node(
			"Star%d" % index,
			"Margin/Main/Top/StarsBlock/Stars/Star%d" % index
		) as TextureRect
		if star != null:
			stars.append(star)


func _header_node(unique: String, path: String) -> Node:
	var found: Node = null
	if _header != null:
		found = _header.get_node_or_null("%" + unique)
		if found == null:
			found = _header.get_node_or_null(path)
	if found == null:
		found = get_node_or_null("%" + unique)
	return found


func _bind_action_buttons() -> void:
	_connect_action_button(get_node_or_null("ButtonTheme") as Button, _on_theme_pressed)
	_connect_action_button(get_node_or_null("ButtonHint") as Button, _on_hint_pressed)
	_connect_action_button(reveal_button, _on_reveal_pressed)


func _connect_action_button(button: Button, callback: Callable) -> void:
	if button == null:
		return
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func resume_saved_time() -> void:
	_pause_ms = 0
	_start_ms = Time.get_ticks_msec() - GameManager.tiempo_partida * 1000
	_suppress_minute_fx = true
	_shown_minute = -1
	_update_timer_label(float(GameManager.tiempo_partida))
	_suppress_minute_fx = false


func pause_play_clock() -> void:
	GameManager.set_tiempo_partida(_elapsed_play_seconds())
	_pause_ms = Time.get_ticks_msec()


func resume_play_clock() -> void:
	if _pause_ms > 0:
		_start_ms += Time.get_ticks_msec() - _pause_ms
		_pause_ms = 0


func sync_play_time() -> void:
	GameManager.set_tiempo_partida(_elapsed_play_seconds())


func _elapsed_play_seconds() -> int:
	var now := Time.get_ticks_msec()
	var start := _start_ms
	if _pause_ms > 0:
		now = _pause_ms
	return maxi(int((now - start) / 1000.0), 0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		GameManager.set_tiempo_partida(_elapsed_play_seconds())
		_pause_ms = Time.get_ticks_msec()
	elif what == NOTIFICATION_UNPAUSED:
		if _pause_ms > 0:
			_start_ms += Time.get_ticks_msec() - _pause_ms
			_pause_ms = 0


func _update_timer_label(elapsed_seconds: float) -> void:
	var elapsed := maxf(elapsed_seconds, 0.0)
	var minutes := int(elapsed) / 60
	var frac := fmod(elapsed, 60.0) / 60.0
	if time_unit:
		time_unit.text = "min"
	if time_value:
		time_value.text = str(minutes)
		if minutes != _shown_minute:
			if not _suppress_minute_fx and _shown_minute >= 0:
				_blink_time_label()
				if hourglass and hourglass.has_method("play_flip"):
					hourglass.play_flip()
			_shown_minute = minutes
	if hourglass and hourglass.has_method("set_sand_progress"):
		if hourglass.has_method("is_flipping") and hourglass.is_flipping():
			return
		hourglass.set_sand_progress(frac)


func _blink_time_label() -> void:
	if time_value == null:
		return
	time_value.pivot_offset = time_value.size * 0.5
	if _time_blink_tween != null and _time_blink_tween.is_valid():
		_time_blink_tween.kill()
	time_value.scale = Vector2.ONE
	_time_blink_tween = create_tween()
	_time_blink_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_time_blink_tween.tween_property(time_value, "scale", Vector2(1.34, 1.34), 0.12)
	_time_blink_tween.tween_property(time_value, "scale", Vector2(0.9, 0.9), 0.1)
	_time_blink_tween.tween_property(time_value, "scale", Vector2.ONE, 0.12)


func _apply_onboarding_tool_lock() -> void:
	if not GameManager.is_onboarding_session() or GameManager.onboarding_stage != 1:
		return
	for path in ["ButtonTheme", "ButtonHint", "ButtonReveal"]:
		var button := get_node_or_null(path) as CanvasItem
		if button:
			button.modulate = Color(1, 1, 1, 0.42)


func _block_onboarding_advanced() -> bool:
	if not GameManager.is_onboarding_session() or GameManager.onboarding_stage != 1:
		return false
	var guide := get_tree().get_first_node_in_group("OnboardingGuide")
	if guide and guide.has_method("show_later_tools_message"):
		guide.show_later_tools_message()
		return true
	return false


func _apply_practice_lock() -> void:
	if not GameManager.is_practice_session():
		return
	if stars.is_empty() or stars[0] == null:
		return
	var stars_row := stars[0].get_parent() as Control
	if stars_row == null or stars_row.get_parent() == null:
		return
	if stars_row.get_parent().name == "PracticeLockFrame":
		return
	var block := stars_row.get_parent()
	var frame := PanelContainer.new()
	frame.name = "PracticeLockFrame"
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var index := stars_row.get_index()
	block.add_child(frame)
	block.move_child(frame, index)
	stars_row.reparent(frame)
	var lock := TextureRect.new()
	lock.name = "Lock"
	lock.texture = ICON_LOCK
	lock.custom_minimum_size = Vector2(80, 80)
	lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.set_anchors_preset(Control.PRESET_CENTER)
	lock.anchor_left = 0.5
	lock.anchor_right = 0.5
	lock.anchor_top = 0.5
	lock.anchor_bottom = 0.5
	lock.offset_left = -40.0
	lock.offset_top = -40.0
	lock.offset_right = 40.0
	lock.offset_bottom = 40.0
	frame.add_child(lock)


func puzzle_star_slots() -> Array[TextureRect]:
	if stars.is_empty():
		_bind_header_nodes()
	var slots: Array[TextureRect] = []
	var maximum := GameManager.get_puzzle_difficulty_stars()
	for index in range(mini(stars.size(), maximum)):
		if stars[index]:
			slots.append(stars[index])
	return slots


func _update_stars(_value: int = -1) -> void:
	if stars.is_empty():
		_bind_header_nodes()
	var maximum := GameManager.get_puzzle_difficulty_stars()
	var filled: int = clampi(GameManager.puzzle_stars, 0, maximum)
	if GameManager.is_practice_session():
		var recorded := GameManager.locked_record_stars
		if recorded < 0:
			recorded = int(PuzzleSaveManager.get_puzzle_summary(int(GameManager.id_frase)).get("stars_remaining", filled))
		filled = clampi(recorded, 0, maximum)
	for index in range(stars.size()):
		if stars[index] == null:
			continue
		stars[index].visible = index < maximum
		stars[index].self_modulate = (
			GameManager.star_fill_color()
			if index < filled
			else Color(0.72, 0.68, 0.6, 0.32)
		)


func _update_letters_filled() -> void:
	var filled := GameManager.numero_letras_reveladas
	var total := GameManager.numero_letras_a_revelar_originales
	if letters_label:
		var template := tr("LettersProgress")
		if template.find("%d") < 0 and template.find("%s") < 0:
			template = "%d / %d"
		letters_label.text = template % [filled, total]
	if letters_progress:
		letters_progress.max_value = 1.0
		letters_progress.value = 0.0 if total <= 0 else float(filled) / float(total)


func _update_game_mode() -> void:
	var is_crypto := GameManager.game_mode_actual == GameManager.MODE_CRYPTOGRAM
	if mode_icon:
		mode_icon.texture = MODE_ICON_CRYPTO if is_crypto else MODE_ICON_QUICK
	if mode_label:
		mode_label.text = tr("Cryptogram") if is_crypto else tr("TutQuickGame")


func _on_board_filled() -> void:
	if GameManager.is_onboarding_session():
		GameManager.reveal_assignment_errors()
		return
	if not get_tree().get_nodes_in_group("BoardFillPrompt").is_empty():
		return
	SoundManager.play("ButtonClick")
	_add_overlay(OVERLAY_BOARD_FILL)


func _on_hint_pressed() -> void:
	if _block_onboarding_advanced():
		return
	if not get_tree().get_nodes_in_group("HintsOverlay").is_empty():
		return
	SoundManager.play("ButtonClick")
	SignalManager.puzzle_input.emit("hint", {"opened": true})
	_add_overlay(OVERLAY_HINTS)


func _on_theme_pressed() -> void:
	if _block_onboarding_advanced():
		return
	if not get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
		return
	SoundManager.play("ButtonClick")
	SignalManager.puzzle_input.emit("theme", {})
	var preview := THEME_PREVIEW.instantiate()
	preview.set("launch_game_on_start", false)
	var host := _overlay_host()
	host.add_child(preview)
	if preview is Control:
		var control := preview as Control
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		control.size = host.size
		control.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_letter_placed(_letter: String, _number: int) -> void:
	_blink_reveal_button()


func _blink_reveal_button() -> void:
	if not is_instance_valid(reveal_button):
		return
	if GameManager.partida_terminada:
		return
	if GameManager.is_onboarding_session() and GameManager.onboarding_stage == 1:
		return
	_stop_reveal_blink()
	reveal_button.modulate = REVEAL_BLINK_FULL
	_reveal_blink_tween = create_tween()
	_reveal_blink_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for _i in REVEAL_BLINK_COUNT:
		_reveal_blink_tween.tween_property(reveal_button, "modulate", REVEAL_BLINK_DIM, REVEAL_BLINK_STEP)
		_reveal_blink_tween.tween_property(reveal_button, "modulate", REVEAL_BLINK_FULL, REVEAL_BLINK_STEP)


func _stop_reveal_blink() -> void:
	if _reveal_blink_tween != null and _reveal_blink_tween.is_valid():
		_reveal_blink_tween.kill()
	_reveal_blink_tween = null
	if is_instance_valid(reveal_button):
		if GameManager.is_onboarding_session() and GameManager.onboarding_stage == 1:
			reveal_button.modulate = Color(1, 1, 1, 0.42)
		else:
			reveal_button.modulate = REVEAL_BLINK_FULL


func _on_reveal_pressed() -> void:
	if _block_onboarding_advanced():
		return
	var tutorial := get_tree().get_first_node_in_group("BasicStartTutorial")
	if tutorial and tutorial.has_method("on_reveal_clicked") and tutorial.on_reveal_clicked():
		SoundManager.play("ButtonClick")
		return
	_stop_reveal_blink()
	if not get_tree().get_nodes_in_group("RevealOverlay").is_empty():
		return
	if not get_tree().get_nodes_in_group("RevealSequence").is_empty():
		return
	SignalManager.puzzle_input.emit("reveal", {})
	if PlayerPrefs.skip_reveal_dialog and not GameManager.is_onboarding_session():
		GameManager.reveal_assignment_errors()
		return
	SoundManager.play("ButtonClick")
	_add_overlay(OVERLAY_REVEAL)


func animate_star_loss() -> void:
	if GameManager.puzzle_stars <= 0:
		return
	var index := GameManager.puzzle_stars - 1
	if index < 0 or index >= stars.size():
		return
	var star := stars[index]
	star.pivot_offset = star.size * 0.5
	var base := Vector2.ONE
	star.scale = base
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for _cycle in 2:
		tween.tween_property(star, "scale", base * 1.38, 0.12)
		tween.tween_property(star, "scale", base * 0.7, 0.12)
	tween.tween_property(star, "scale", base, 0.1)
	await tween.finished
	if is_instance_valid(star):
		star.scale = base


func _on_pause_pressed() -> void:
	if not get_tree().get_nodes_in_group("GameMenu").is_empty():
		return
	if not get_tree().get_nodes_in_group("RevealSequence").is_empty():
		return
	SoundManager.play("ButtonClick")
	SignalManager.puzzle_input.emit("options", {})
	_add_overlay(OVERLAY_EXIT)


func _on_game_finished() -> void:
	_stop_reveal_blink()
	if _completion_recorded:
		return
	_completion_recorded = true
	if not GameManager.partida_terminada:
		GameManager._game_finished()
	EventLoggerAutoload.finish_session(EventLoggerAutoload.OUTCOME_COMPLETED)
	var mode := GameManager.game_mode_actual
	var key := "stars_cryptogram" if mode == GameManager.MODE_CRYPTOGRAM else "stars_quick"
	var before := int(HistoryManager.get_stats_dashboard().get(key, 0))
	if not GameManager.skips_progress():
		HistoryManager.add_result(GameManager.player_name, GameManager.score)
		PlayFabTools.submit_competitive_rankings(GameManager.player_name)
	var after := int(HistoryManager.get_stats_dashboard().get(key, 0))
	StarCollectOverlay.remember_counter(mode, before, after)
	AdManager.note_puzzle_completed_for_ads()
	SoundManager.play("ButtonClick")
	_add_overlay(OVERLAY_RESULTS)


func _on_game_lost() -> void:
	_stop_reveal_blink()
	EventLoggerAutoload.discard_session()
	GameManager._game_finished()
	GameManager.set_score_ultima_partida(0)
	GameManager.score = 0
	SoundManager.play("GameOver")
	if not GameManager.skips_progress():
		HistoryManager.add_result(GameManager.player_name, 0)
	_add_overlay(OVERLAY_GAME_OVER)


func _erase_selected_letter(_letter: String) -> void:
	SignalManager.erase_selected_letter.emit()


func _open_erase_dialog() -> void:
	_add_overlay(OVERLAY_ERASE)


func _add_overlay(scene: PackedScene) -> void:
	if scene == null:
		return
	var overlay := scene.instantiate()
	var host := _overlay_host()
	host.add_child(overlay)
	if overlay is Control:
		var control := overlay as Control
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		control.size = host.size
		control.mouse_filter = Control.MOUSE_FILTER_STOP
		if overlay.is_in_group("GameMenu"):
			control.z_index = 120
		else:
			control.z_index = 80


func _overlay_host() -> Control:
	var parent := get_parent()
	if parent == null:
		return self
	var host := parent.get_node_or_null("OverlayHost") as Control
	if host == null:
		host = Control.new()
		host.name = "OverlayHost"
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.z_index = 40
		parent.add_child(host)
	_fit_to_viewport(host)
	return host


func _fit_to_viewport(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.position = Vector2.ZERO
	var vp := get_viewport()
	var size := vp.get_visible_rect().size if vp else Vector2.ZERO
	if size.x < 2.0 or size.y < 2.0:
		size = Vector2(
			float(ProjectSettings.get_setting("display/window/size/viewport_width", 1206)),
			float(ProjectSettings.get_setting("display/window/size/viewport_height", 2622))
		)
	control.size = size


func _apply_category_color() -> void:
	if category_button == null:
		return
	var category_color: Color = GameManager.category_color()
	var border := Color(1, 1, 1, 0.28)
	_paint_category_style("normal", category_color, border)
	_paint_category_style("hover", category_color, border)
	_paint_category_style("pressed", category_color, border)
	if category_label:
		category_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_apply_category_icon()


func _apply_category_icon() -> void:
	if category_icon == null:
		return
	category_icon.texture = _category_icon_for(GameManager.categoria_actual)


func _category_icon_for(cat_id: String) -> Texture2D:
	match GameManager.normalize_category(cat_id):
		GameManager.CAT_CITA:
			return ICON_CITA
		GameManager.CAT_EFEMERIDE:
			return ICON_EFEM
		GameManager.CAT_CURIOSIDADES:
			return ICON_CURIO
		GameManager.CAT_FRAGMENTO:
			return ICON_FRAG
		GameManager.CAT_DAILY:
			return ICON_DAILY
		_:
			return ICON_CITA


func _paint_category_style(style_name: String, fill: Color, border: Color) -> void:
	var current := category_button.get_theme_stylebox(style_name)
	if current == null:
		return
	var painted := current.duplicate() as StyleBoxFlat
	if painted == null:
		return
	painted.bg_color = fill
	painted.border_color = border
	painted.border_width_left = 3
	painted.border_width_top = 0
	painted.border_width_right = 3
	painted.border_width_bottom = 3
	painted.shadow_size = 0
	painted.shadow_offset = Vector2.ZERO
	category_button.add_theme_stylebox_override(style_name, painted)
