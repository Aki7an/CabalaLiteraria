extends Panel

const OVERLAY_EXIT := preload("res://scenes/fondo_salir.tscn")
const OVERLAY_RESULTS := preload("res://scenes/menu_game_over.tscn")
const OVERLAY_GAME_OVER := preload("res://scenes/menu_game_over_fail.tscn")
const OVERLAY_ERASE := preload("res://scenes/fondo_aviso_borrado.tscn")
const OVERLAY_HINTS := preload("res://scenes/CuadroPistas.tscn")
const OVERLAY_REVEAL := preload("res://scenes/CuadroRevelar.tscn")
const OVERLAY_BOARD_FILL := preload("res://scenes/fondo_tablero_completo.tscn")
const THEME_PREVIEW := preload("res://scenes/game/PuzzleThemePreview.tscn")

@onready var category_button: Button = $ButtonCategory
@onready var category_label: Label = $ButtonCategory/Category
@onready var category_icon: TextureRect = $ButtonCategory/Icon
@onready var letters_label: Label = $PuzzleInfo/LettersFilled
@onready var mode_icon: TextureRect = $PuzzleInfo/ModeRow/ModeIcon
@onready var mode_label: Label = $PuzzleInfo/ModeRow/ModeLabel
@onready var stars: Array[TextureRect] = [
	$PuzzleInfo/Stars/Star1,
	$PuzzleInfo/Stars/Star2,
	$PuzzleInfo/Stars/Star3,
	$PuzzleInfo/Stars/Star4,
	$PuzzleInfo/Stars/Star5
]

const MODE_ICON_QUICK := preload("res://images/mode_quick.svg")
const MODE_ICON_CRYPTO := preload("res://images/mode_scroll.svg")

var _start_ms: int
var _completion_recorded := false


func _ready() -> void:
	_start_ms = Time.get_ticks_msec()
	category_label.text = GameManager.category_display_name()
	_apply_category_color()
	_update_stars()
	_update_letters_filled()
	_update_game_mode()

	SignalManager.update_puzzle_stars.connect(_update_stars)
	SignalManager.update_resting_characters.connect(_update_letters_filled)
	SignalManager.board_filled.connect(_on_board_filled)
	SignalManager.game_finished.connect(_on_game_finished)
	SignalManager.game_finished_lost.connect(_on_game_lost)
	SignalManager.erase_letter.connect(_erase_selected_letter)
	SignalManager.erase_letter_open_dialog.connect(_open_erase_dialog)


func _process(_delta: float) -> void:
	var elapsed_seconds := float(Time.get_ticks_msec() - _start_ms) / 1000.0
	GameManager.set_tiempo_partida(elapsed_seconds)


func resume_saved_time() -> void:
	_start_ms = Time.get_ticks_msec() - GameManager.tiempo_partida * 1000


func _update_stars(_value: int = -1) -> void:
	var maximum := GameManager.get_puzzle_difficulty_stars()
	var filled: int = clampi(GameManager.puzzle_stars, 0, maximum)
	for index in range(stars.size()):
		stars[index].visible = index < maximum
		stars[index].self_modulate = (
			GameManager.star_fill_color()
			if index < filled
			else Color(0.72, 0.68, 0.6, 0.32)
		)


func _update_letters_filled() -> void:
	letters_label.text = "%d / %d" % [
		GameManager.numero_letras_reveladas,
		GameManager.numero_letras_a_revelar_originales
	]


func _update_game_mode() -> void:
	var is_crypto := GameManager.game_mode_actual == GameManager.MODE_CRYPTOGRAM
	mode_icon.texture = MODE_ICON_CRYPTO if is_crypto else MODE_ICON_QUICK
	mode_label.text = "Criptograma" if is_crypto else "Partida rápida"


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


func _on_reveal_pressed() -> void:
	if not get_tree().get_nodes_in_group("RevealOverlay").is_empty():
		return
	SoundManager.play("ButtonClick")
	if PlayerPrefs.skip_reveal_dialog:
		GameManager.reveal_assignment_errors()
		return
	_add_overlay(OVERLAY_REVEAL)


func _on_pause_pressed() -> void:
	if not get_tree().get_nodes_in_group("GameMenu").is_empty():
		return
	SoundManager.play("ButtonClick")
	_add_overlay(OVERLAY_EXIT)


func _on_game_finished() -> void:
	if _completion_recorded:
		return
	_completion_recorded = true
	if not GameManager.partida_terminada:
		GameManager._game_finished()
	HistoryManager.add_result(GameManager.player_name, GameManager.score)
	PlayFabTools.submit_competitive_rankings(GameManager.player_name)
	SoundManager.play("ButtonClick")
	_add_overlay(OVERLAY_RESULTS)


func _on_game_lost() -> void:
	GameManager._game_finished()
	GameManager.set_score_ultima_partida(0)
	GameManager.score = 0
	SoundManager.play("GameOver")
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
