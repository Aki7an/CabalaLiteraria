extends Panel

const OVERLAY_EXIT := preload("res://scenes/fondo_salir.tscn")
const OVERLAY_RESULTS := preload("res://scenes/menu_game_over.tscn")
const OVERLAY_GAME_OVER := preload("res://scenes/menu_game_over_fail.tscn")
const OVERLAY_ERASE := preload("res://scenes/fondo_aviso_borrado.tscn")
const OVERLAY_HINTS := preload("res://scenes/CuadroPistas.tscn")
const OVERLAY_REVEAL := preload("res://scenes/CuadroRevelar.tscn")
const OVERLAY_BOARD_FILL := preload("res://scenes/fondo_tablero_completo.tscn")
const THEME_PREVIEW := preload("res://scenes/game/PuzzleThemePreview.tscn")

@onready var _header: Node = $GameHeader
@onready var category_button: Button = _header.get_node("%ButtonCategory")
@onready var category_label: Label = _header.get_node("%Category")
@onready var category_icon: TextureRect = _header.get_node("%CategoryIcon")
@onready var letters_label: Label = _header.get_node("%LettersFilled")
@onready var letters_progress: ProgressBar = _header.get_node("%LettersProgress")
@onready var stars_title: Label = _header.get_node("%StarsTitle")
@onready var time_value: Label = _header.get_node("%TimeValue")
@onready var time_unit: Label = _header.get_node("%TimeUnit")
@onready var hourglass: Control = _header.get_node("%TimeIcon")
@onready var mode_icon: TextureRect = _header.get_node("%ModeIcon")
@onready var mode_label: Label = _header.get_node("%ModeLabel")
@onready var stars: Array[TextureRect] = [
	_header.get_node("%Star1") as TextureRect,
	_header.get_node("%Star2") as TextureRect,
	_header.get_node("%Star3") as TextureRect,
	_header.get_node("%Star4") as TextureRect,
	_header.get_node("%Star5") as TextureRect
]
@onready var reveal_button: Button = $ButtonReveal
@onready var pause_button: Button = _header.get_node("%ButtonPause")

const REVEAL_BLINK_COUNT := 2
const REVEAL_BLINK_DIM := Color(1, 1, 1, 0.28)
const REVEAL_BLINK_FULL := Color(1, 1, 1, 1)
const REVEAL_BLINK_STEP := 0.11

const MODE_ICON_QUICK := preload("res://images/mode_quick.svg")
const MODE_ICON_CRYPTO := preload("res://images/mode_scroll.svg")
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
	_start_ms = Time.get_ticks_msec()
	if pause_button and not pause_button.pressed.is_connected(_on_pause_pressed):
		pause_button.pressed.connect(_on_pause_pressed)
	category_label.text = GameManager.category_display_name()
	if stars_title:
		stars_title.text = tr("TutStarsPuzzle")
	_apply_category_color()
	_apply_practice_lock()
	_update_stars()
	_update_letters_filled()
	_update_game_mode()
	_suppress_minute_fx = true
	_update_timer_label(0.0)
	_suppress_minute_fx = false

	SignalManager.update_puzzle_stars.connect(_update_stars)
	SignalManager.update_resting_characters.connect(_update_letters_filled)
	SignalManager.insert_letter_in_number.connect(_on_letter_placed)
	SignalManager.board_filled.connect(_on_board_filled)
	SignalManager.game_finished.connect(_on_game_finished)
	SignalManager.game_finished_lost.connect(_on_game_lost)
	SignalManager.erase_letter.connect(_erase_selected_letter)
	SignalManager.erase_letter_open_dialog.connect(_open_erase_dialog)


func _process(_delta: float) -> void:
	var elapsed_seconds := _elapsed_play_seconds()
	GameManager.set_tiempo_partida(elapsed_seconds)
	_update_timer_label(float(elapsed_seconds))


func resume_saved_time() -> void:
	_pause_ms = 0
	_start_ms = Time.get_ticks_msec() - GameManager.tiempo_partida * 1000
	_suppress_minute_fx = true
	_shown_minute = -1
	_update_timer_label(float(GameManager.tiempo_partida))
	_suppress_minute_fx = false


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


func _apply_practice_lock() -> void:
	if not GameManager.is_practice_session():
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


func _update_stars(_value: int = -1) -> void:
	var maximum := GameManager.get_puzzle_difficulty_stars()
	var filled: int = clampi(GameManager.puzzle_stars, 0, maximum)
	if GameManager.is_practice_session():
		var recorded := GameManager.locked_record_stars
		if recorded < 0:
			recorded = int(PuzzleSaveManager.get_puzzle_summary(int(GameManager.id_frase)).get("stars_remaining", filled))
		filled = clampi(recorded, 0, maximum)
	for index in range(stars.size()):
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
		letters_label.text = tr("LettersProgress") % [filled, total]
	if letters_progress:
		letters_progress.max_value = 1.0
		letters_progress.value = 0.0 if total <= 0 else float(filled) / float(total)


func _update_game_mode() -> void:
	var is_crypto := GameManager.game_mode_actual == GameManager.MODE_CRYPTOGRAM
	mode_icon.texture = MODE_ICON_CRYPTO if is_crypto else MODE_ICON_QUICK
	mode_label.text = tr("Cryptogram") if is_crypto else tr("TutQuickGame")


func _on_board_filled() -> void:
	if not get_tree().get_nodes_in_group("BoardFillPrompt").is_empty():
		return
	SoundManager.play("ButtonClick")
	_add_overlay(OVERLAY_BOARD_FILL)


func _on_hint_pressed() -> void:
	if not get_tree().get_nodes_in_group("HintsOverlay").is_empty():
		return
	SoundManager.play("ButtonClick")
	_add_overlay(OVERLAY_HINTS)


func _on_theme_pressed() -> void:
	if not get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
		return
	SoundManager.play("ButtonClick")
	var preview := THEME_PREVIEW.instantiate()
	preview.set("launch_game_on_start", false)
	get_parent().add_child(preview)


func _on_letter_placed(_letter: String, _number: int) -> void:
	_blink_reveal_button()


func _blink_reveal_button() -> void:
	if not is_instance_valid(reveal_button):
		return
	if GameManager.partida_terminada:
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
		reveal_button.modulate = REVEAL_BLINK_FULL


func _on_reveal_pressed() -> void:
	_stop_reveal_blink()
	if not get_tree().get_nodes_in_group("RevealOverlay").is_empty():
		return
	if not get_tree().get_nodes_in_group("RevealSequence").is_empty():
		return
	SoundManager.play("ButtonClick")
	if PlayerPrefs.skip_reveal_dialog:
		GameManager.reveal_assignment_errors()
		return
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
	_add_overlay(OVERLAY_EXIT)


func _on_game_finished() -> void:
	_stop_reveal_blink()
	if _completion_recorded:
		return
	_completion_recorded = true
	if not GameManager.partida_terminada:
		GameManager._game_finished()
	if not GameManager.is_practice_session():
		HistoryManager.add_result(GameManager.player_name, GameManager.score)
		PlayFabTools.submit_competitive_rankings(GameManager.player_name)
	SoundManager.play("ButtonClick")
	_add_overlay(OVERLAY_RESULTS)


func _on_game_lost() -> void:
	_stop_reveal_blink()
	GameManager._game_finished()
	GameManager.set_score_ultima_partida(0)
	GameManager.score = 0
	SoundManager.play("GameOver")
	if not GameManager.is_practice_session():
		HistoryManager.add_result(GameManager.player_name, 0)
	_add_overlay(OVERLAY_GAME_OVER)


func _erase_selected_letter(_letter: String) -> void:
	SignalManager.erase_selected_letter.emit()


func _open_erase_dialog() -> void:
	_add_overlay(OVERLAY_ERASE)


func _add_overlay(scene: PackedScene) -> void:
	var overlay := scene.instantiate()
	get_parent().add_child(overlay)
	if overlay is Control:
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP


func _apply_category_color() -> void:
	var category_color: Color = GameManager.category_color()
	var normal := category_button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	var hover := category_button.get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	var pressed := category_button.get_theme_stylebox("pressed").duplicate() as StyleBoxFlat
	if normal != null:
		normal.bg_color = category_color
		normal.border_color = category_color.darkened(0.28)
		category_button.add_theme_stylebox_override("normal", normal)
	if hover != null:
		hover.bg_color = category_color.lightened(0.08)
		hover.border_color = category_color.darkened(0.24)
		category_button.add_theme_stylebox_override("hover", hover)
	if pressed != null:
		pressed.bg_color = category_color.darkened(0.12)
		pressed.border_color = category_color.darkened(0.35)
		category_button.add_theme_stylebox_override("pressed", pressed)
	category_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
