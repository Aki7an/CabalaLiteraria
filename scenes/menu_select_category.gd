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
		"category": "Elige temática",
		"mode": "Tipo de partida",
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
	_update_category_progress()


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
	_update_category_progress()


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
		_set_check_blink(button, is_selected)
		button.add_theme_stylebox_override(
			"normal",
			_make_category_style(category_id, is_selected)
		)


func _update_mode_selection() -> void:
	for mode_id in _mode_buttons:
		var button: Button = _mode_buttons[mode_id]
		var is_selected: bool = mode_id == selected_mode
		_set_check_blink(button, is_selected)
		button.add_theme_stylebox_override(
			"normal",
			_make_mode_selected_style(mode_id) if is_selected else _mode_normal_styles[mode_id]
		)


func _set_check_blink(button: Button, is_selected: bool) -> void:
	var badge := button.get_node_or_null("Selected") as Control
	if badge == null:
		return
	if badge.has_meta("check_tween"):
		var previous: Variant = badge.get_meta("check_tween")
		if previous is Tween:
			(previous as Tween).kill()
	badge.visible = is_selected
	if badge.size == Vector2.ZERO:
		badge.pivot_offset = Vector2(30, 30)
	else:
		badge.pivot_offset = badge.size * 0.5
	badge.scale = Vector2.ONE
	if not is_selected:
		return
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(badge, "scale", Vector2(1.22, 1.22), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(badge, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	badge.set_meta("check_tween", tween)


func _update_category_progress() -> void:
	for category_id in _category_buttons:
		var record := HistoryManager.get_competitive_record(
			category_id,
			selected_mode
		)
		var stars_earned := int(record.get("stars_earned", 0))
		var stars_available := int(record.get("stars_available", 0))
		var button: Button = _category_buttons[category_id]
		var progress_bar := button.get_node_or_null("Progress") as ProgressBar
		if progress_bar != null:
			progress_bar.max_value = maxf(float(stars_available), 1.0)
			progress_bar.value = float(stars_earned)
			var value_label := button.get_node_or_null("ProgressValue") as Label
			if value_label != null:
				value_label.text = "%d / %d" % [
					stars_earned,
					stars_available,
				]


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


func _make_mode_selected_style(mode_id: String = MODE_QUICK) -> StyleBoxFlat:
	var style := _make_selected_style()
	if mode_id == MODE_CRYPTOGRAM:
		style.bg_color = Color(1.0, 0.96, 0.90, 1)
		style.border_color = Color(0.66, 0.34, 0.08, 1)
		style.shadow_color = Color(0.40, 0.18, 0.06, 0.14)
	else:
		style.bg_color = Color(0.86, 0.95, 0.96, 1)
		style.border_color = Color(0.04, 0.58, 0.61, 1)
		style.shadow_color = Color(0.04, 0.42, 0.48, 0.14)
	style.set_border_width_all(9)
	style.border_width_bottom = 12
	style.set_corner_radius_all(32)
	return style


func _set_mode_time_labels(button: Button, caption: String, value: String) -> void:
	var caption_label := button.get_node_or_null("TimeCaption") as Label
	var value_label := button.get_node_or_null("TimeValue") as Label
	if caption_label:
		caption_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		caption_label.clip_text = true
		caption_label.position.y = 277.0
		caption_label.size = Vector2(267.0, 48.0)
		caption_label.text = caption
	if value_label:
		value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		value_label.clip_text = true
		value_label.position.y = 328.0
		value_label.size = Vector2(267.0, 66.0)
		value_label.text = value


func _update_localized_copy() -> void:
	subtitle_label.visible = false
	subtitle_label.text = tr("ChooseGame")
	category_title_label.text = tr("ChooseTheme")
	mode_title_label.text = tr("GameType")
	quick_title_label.text = tr("Quick")
	quick_description_label.text = tr("QuickDescription")
	cryptogram_title_label.text = tr("Cryptogram")
	cryptogram_description_label.text = tr("CryptogramDescription")
	button_citas_celebres.get_node("Label").text = GameManager.category_display_name(GameManager.CAT_CITA)
	button_curiosidades.get_node("Label").text = GameManager.category_display_name(GameManager.CAT_CURIOSIDADES)
	button_efemerides.get_node("Label").text = GameManager.category_display_name(GameManager.CAT_EFEMERIDE)
	button_fragmentos_literarios.get_node("Label").text = GameManager.category_display_name(GameManager.CAT_FRAGMENTO)
	for button in [button_citas_celebres, button_curiosidades, button_efemerides, button_fragmentos_literarios]:
		var progress_title := button.get_node_or_null("ProgressTitle") as Label
		if progress_title:
			progress_title.text = tr("StarsEarnedLabel")
	_set_mode_time_labels(
		$Panel/ModeCard/ButtonQuick,
		tr("Estimated time"),
		"1 – 3 min"
	)
	_set_mode_time_labels(
		$Panel/ModeCard/ButtonCryptogram,
		tr("Estimated time"),
		"5 – 10 min"
	)
	$Panel/ButtonPlay/Content/Text.text = tr("ChoosePuzzle")
	$Panel/Header/Brand/Cipher.text = tr("Cipher")
	$Panel/Header/Brand/Letter.text = tr("Letter")
