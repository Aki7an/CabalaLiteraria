extends Control

const PATH_MENU_MAIN := "res://scenes/MenuMain.tscn"
const PATH_SETTINGS := "res://scenes/MenuSettings.tscn"
const PATH_SELECT_LEVEL := "res://scenes/MenuSelectLevelByID.tscn"
const MODE_QUICK := "quick"
const MODE_CRYPTOGRAM := "cryptogram"

@onready var button_citas_celebres: Button = $Panel/CategoryCard/ButtonCitasCelebres
@onready var button_curiosidades: Button = $Panel/CategoryCard/ButtonCuriosidades
@onready var button_efemerides: Button = $Panel/CategoryCard/ButtonEfemerides
@onready var button_fragmentos_literarios: Button = $Panel/CategoryCard/ButtonFragmentosLiterarios
@onready var button_quick: Button = $Panel/ModeCard/ButtonQuick
@onready var button_cryptogram: Button = $Panel/ModeCard/ButtonCryptogram
@onready var button_play: Button = $Panel/ButtonPlay

@onready var subtitle_label: Label = $Panel/Header/Subtitle
@onready var category_title_label: Label = $Panel/CategoryCard/Title
@onready var mode_title_label: Label = $Panel/ModeCard/Title
@onready var quick_title_label: Label = $Panel/ModeCard/ButtonQuick/Title
@onready var quick_description_label: Label = $Panel/ModeCard/ButtonQuick/Description
@onready var cryptogram_title_label: Label = $Panel/ModeCard/ButtonCryptogram/Title
@onready var cryptogram_description_label: Label = $Panel/ModeCard/ButtonCryptogram/Description

var categoria := GameManager.CAT_CITA
var selected_mode := MODE_QUICK
var scene_menu_main: PackedScene
var scene_settings: PackedScene
var scene_select_level: PackedScene
var _category_buttons: Dictionary = {}
var _category_normal_styles: Dictionary = {}
var _mode_buttons: Dictionary = {}
var _mode_normal_styles: Dictionary = {}

const LOCALIZED_COPY := {
	"es": {
		"subtitle": "Elige tu partida",
		"category": "Elige tu temática",
		"mode": "Elige cómo quieres jugar",
		"quick": "Rápido",
		"quick_description": "Descifra frases cortas y directas.",
		"cryptogram": "Criptograma",
		"cryptogram_description": "Resuelve textos más largos y completos.",
	},
	"en": {
		"subtitle": "Choose your game",
		"category": "Choose a theme",
		"mode": "Choose how you want to play",
		"quick": "Quick",
		"quick_description": "Decode short, direct phrases.",
		"cryptogram": "Cryptogram",
		"cryptogram_description": "Solve longer, complete texts.",
	},
	"eu": {
		"subtitle": "Aukeratu zure partida",
		"category": "Aukeratu gaia",
		"mode": "Aukeratu nola jokatu",
		"quick": "Azkarra",
		"quick_description": "Deszifratu esaldi labur eta zuzenak.",
		"cryptogram": "Kriptograma",
		"cryptogram_description": "Ebatzi testu luzeago eta osoak.",
	},
	"de": {
		"subtitle": "Wähle dein Spiel",
		"category": "Wähle ein Thema",
		"mode": "Wähle deine Spielart",
		"quick": "Schnell",
		"quick_description": "Entschlüssle kurze, direkte Sätze.",
		"cryptogram": "Kryptogramm",
		"cryptogram_description": "Löse längere und vollständige Texte.",
	},
	"fr": {
		"subtitle": "Choisissez votre partie",
		"category": "Choisissez un thème",
		"mode": "Choisissez comment jouer",
		"quick": "Rapide",
		"quick_description": "Déchiffrez des phrases courtes et directes.",
		"cryptogram": "Cryptogramme",
		"cryptogram_description": "Résolvez des textes plus longs et complets.",
	},
	"it": {
		"subtitle": "Scegli la tua partita",
		"category": "Scegli un tema",
		"mode": "Scegli come giocare",
		"quick": "Rapido",
		"quick_description": "Decifra frasi brevi e dirette.",
		"cryptogram": "Crittogramma",
		"cryptogram_description": "Risolvi testi più lunghi e completi.",
	},
	"pt": {
		"subtitle": "Escolha a sua partida",
		"category": "Escolha um tema",
		"mode": "Escolha como jogar",
		"quick": "Rápido",
		"quick_description": "Decifre frases curtas e diretas.",
		"cryptogram": "Criptograma",
		"cryptogram_description": "Resolva textos mais longos e completos.",
	},
}


func _ready() -> void:
	_category_buttons = {
		GameManager.CAT_CITA: button_citas_celebres,
		GameManager.CAT_CURIOSIDADES: button_curiosidades,
		GameManager.CAT_EFEMERIDE: button_efemerides,
		GameManager.CAT_FRAGMENTO: button_fragmentos_literarios,
	}
	_mode_buttons = {
		MODE_QUICK: button_quick,
		MODE_CRYPTOGRAM: button_cryptogram,
	}

	for category_id in _category_buttons:
		var button: Button = _category_buttons[category_id]
		_category_normal_styles[category_id] = button.get_theme_stylebox("normal").duplicate()
	for mode_id in _mode_buttons:
		var button: Button = _mode_buttons[mode_id]
		_mode_normal_styles[mode_id] = button.get_theme_stylebox("normal").duplicate()

	_update_category_selection()
	_update_mode_selection()
	_update_localized_copy()


func _on_button_citas_celebres_pressed() -> void:
	_select_category(GameManager.CAT_CITA, button_citas_celebres)


func _on_button_curiosidades_pressed() -> void:
	_select_category(GameManager.CAT_CURIOSIDADES, button_curiosidades)


func _on_button_efemerides_pressed() -> void:
	_select_category(GameManager.CAT_EFEMERIDE, button_efemerides)


func _on_button_fragmentos_literarios_pressed() -> void:
	_select_category(GameManager.CAT_FRAGMENTO, button_fragmentos_literarios)


func _select_category(category_id: String, button: Button) -> void:
	categoria = category_id
	GameManager.button_blink(button)
	SoundManager.play("ButtonClick")
	_update_category_selection()


func _on_button_quick_pressed() -> void:
	_select_mode(MODE_QUICK, button_quick)


func _on_button_cryptogram_pressed() -> void:
	_select_mode(MODE_CRYPTOGRAM, button_cryptogram)


func _select_mode(mode_id: String, button: Button) -> void:
	selected_mode = mode_id
	GameManager.button_blink(button)
	SoundManager.play("ButtonClick")
	_update_mode_selection()


func _on_button_play_pressed() -> void:
	GameManager.button_blink(button_play)
	SoundManager.play("ButtonClick")
	GameManager.set_categoria_actual(categoria)
	GameManager.set_game_mode_actual(selected_mode)
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if scene_select_level == null:
		scene_select_level = load(PATH_SELECT_LEVEL)
	get_tree().change_scene_to_packed(scene_select_level)


func _on_button_exit_pressed() -> void:
	TransitionScreen.transition_to_black()
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if scene_menu_main == null:
		scene_menu_main = load(PATH_MENU_MAIN)
	get_tree().change_scene_to_packed(scene_menu_main)


func _on_button_settings_pressed() -> void:
	TransitionScreen.transition_to_black()
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if scene_settings == null:
		scene_settings = load(PATH_SETTINGS)
	get_tree().change_scene_to_packed(scene_settings)


func _update_category_selection() -> void:
	for category_id in _category_buttons:
		var button: Button = _category_buttons[category_id]
		var is_selected: bool = category_id == categoria
		button.get_node("Selected").visible = is_selected
		button.add_theme_stylebox_override(
			"normal",
			_make_category_style(category_id, is_selected)
		)


func _update_mode_selection() -> void:
	for mode_id in _mode_buttons:
		var button: Button = _mode_buttons[mode_id]
		var is_selected: bool = mode_id == selected_mode
		button.get_node("Selected").visible = is_selected
		button.add_theme_stylebox_override(
			"normal",
			_make_mode_selected_style() if is_selected else _mode_normal_styles[mode_id]
		)


func _make_selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#FFFBEF")
	style.border_color = Color("#0AA5A4")
	style.set_border_width_all(7)
	style.border_width_bottom = 9
	style.set_corner_radius_all(31)
	style.shadow_color = Color(0.04, 0.50, 0.50, 0.16)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 7)
	return style


func _make_category_style(category_id: String, selected: bool) -> StyleBoxFlat:
	var category_color: Color = GameManager.category_color(category_id)
	var style := StyleBoxFlat.new()
	style.bg_color = category_color.lightened(0.68 if not selected else 0.5)
	style.border_color = category_color.lightened(0.12) if not selected else category_color.darkened(0.08)
	style.set_border_width_all(3 if not selected else 9)
	style.border_width_bottom = 8 if not selected else 12
	style.set_corner_radius_all(31)
	style.shadow_color = Color(category_color.r, category_color.g, category_color.b, 0.17)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 8)
	return style


func _make_mode_selected_style() -> StyleBoxFlat:
	var style := _make_selected_style()
	style.bg_color = Color("#DDF4D3")
	style.set_border_width_all(9)
	style.border_width_bottom = 12
	style.set_corner_radius_all(32)
	return style


func _update_localized_copy() -> void:
	var locale := TranslationServer.get_locale().left(2).to_lower()
	var copy: Dictionary = LOCALIZED_COPY.get(locale, LOCALIZED_COPY["en"])
	subtitle_label.visible = false
	subtitle_label.text = copy["subtitle"]
	category_title_label.text = copy["category"]
	mode_title_label.text = copy["mode"]
	quick_title_label.text = copy["quick"]
	quick_description_label.text = copy["quick_description"]
	cryptogram_title_label.text = copy["cryptogram"]
	cryptogram_description_label.text = copy["cryptogram_description"]
