extends Panel

const OVERLAY_EXIT := preload("res://scenes/fondo_salir.tscn")
const OVERLAY_RESULTS := preload("res://scenes/menu_game_over.tscn")
const OVERLAY_GAME_OVER := preload("res://scenes/menu_game_over_fail.tscn")
const OVERLAY_ERASE := preload("res://scenes/fondo_aviso_borrado.tscn")
const OVERLAY_HINTS := preload("res://scenes/Cuadro_Hints.tscn")
const THEME_PREVIEW := preload("res://scenes/game/PuzzleThemePreview.tscn")
const CATEGORY_ICONS := {
	"efemeride": preload("res://images/Efemerides.png"),
	"cita": preload("res://images/Citas.png"),
	"curiosidades": preload("res://images/Adivinanza.png"),
	"fragmento": preload("res://images/FragmentosLiterarios.png")
}

@onready var category_button: Button = $ButtonCategory
@onready var category_label: Label = $ButtonCategory/Category
@onready var category_icon: TextureRect = $ButtonCategory/Icon
@onready var progress_bar: ProgressBar = $PuzzleInfo/ProgressBar
@onready var uses_label: Label = $PuzzleInfo/Uses
@onready var stars: Array[TextureRect] = [
	$PuzzleInfo/Stars/Star1,
	$PuzzleInfo/Stars/Star2,
	$PuzzleInfo/Stars/Star3,
	$PuzzleInfo/Stars/Star4,
	$PuzzleInfo/Stars/Star5
]

var _start_ms: int


func _ready() -> void:
	_start_ms = Time.get_ticks_msec()
	category_label.text = GameManager.category_display_name()
	var category_id: String = GameManager.normalize_category(GameManager.categoria_actual)
	category_icon.texture = CATEGORY_ICONS.get(category_id, CATEGORY_ICONS["efemeride"])
	_apply_category_color()
	_update_stars()
	_update_progress()

	SignalManager.update_resting_characters.connect(_update_progress)
	SignalManager.update_puzzle_stars.connect(_update_stars)
	SignalManager.game_finished.connect(_on_game_finished)
	SignalManager.game_finished_lost.connect(_on_game_lost)
	SignalManager.erase_letter.connect(_erase_selected_letter)
	SignalManager.erase_letter_open_dialog.connect(_open_erase_dialog)


func _process(_delta: float) -> void:
	var elapsed_seconds := float(Time.get_ticks_msec() - _start_ms) / 1000.0
	GameManager.set_tiempo_partida(elapsed_seconds)


func _update_stars(_value: int = -1) -> void:
	var filled: int = clampi(GameManager.puzzle_stars, 0, stars.size())
	for index in range(stars.size()):
		stars[index].self_modulate = (
			Color(1.0, 0.62, 0.08, 1.0)
			if index < filled
			else Color(0.73, 0.62, 0.42, 0.28)
		)


func _update_progress() -> void:
	var total: int = max(GameManager.numero_letras_a_revelar_originales, 0)
	var revealed: int = clampi(GameManager.numero_letras_reveladas, 0, total)
	progress_bar.max_value = max(total, 1)
	progress_bar.value = revealed
	uses_label.text = "Progreso: %d de %d" % [revealed, total]


func _on_hint_pressed() -> void:
	SoundManager.play("ButtonClick")
	GameManager.register_hint_used("hint_1")
	_add_overlay(OVERLAY_HINTS)


func _on_theme_pressed() -> void:
	if not get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
		return
	SoundManager.play("ButtonClick")
	var preview := THEME_PREVIEW.instantiate()
	preview.set("launch_game_on_start", false)
	get_parent().add_child(preview)


func _on_reveal_pressed() -> void:
	SoundManager.play("ButtonClick")
	GameManager.reveal_assignment_errors()


func _on_pause_pressed() -> void:
	SoundManager.play("ButtonClick")
	_add_overlay(OVERLAY_EXIT)


func _on_game_finished() -> void:
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
		hover.bg_color = category_color.lightened(0.1)
		hover.border_color = category_color.darkened(0.24)
		category_button.add_theme_stylebox_override("hover", hover)
	if pressed != null:
		pressed.bg_color = category_color.darkened(0.12)
		pressed.border_color = category_color.darkened(0.35)
		category_button.add_theme_stylebox_override("pressed", pressed)
