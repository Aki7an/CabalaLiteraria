extends Control

const PATH_MENU_MAIN := "res://scenes/MenuMain.tscn"
const PATH_SETTINGS := "res://scenes/MenuSettings.tscn"
const PATH_SELECT_LEVEL := "res://scenes/MenuSelectLevelByID.tscn"
const MODE_QUICK := "quick"
const MODE_CRYPTOGRAM := "cryptogram"
const SELECTED_GREEN := Color(0.16, 0.72, 0.40, 1)
const FONT_TAG := preload("res://GUI/new_font_Rubik_semibold.tres")

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

var categoria := ""
var selected_mode := ""
var scene_menu_main: PackedScene
var scene_settings: PackedScene
var scene_select_level: PackedScene
var _category_buttons: Dictionary = {}
var _category_normal_styles: Dictionary = {}
var _mode_buttons: Dictionary = {}
var _mode_normal_styles: Dictionary = {}
var _play_was_enabled := false
var _play_style_normal: StyleBox
var _play_style_hover: StyleBox
var _play_style_pressed: StyleBox

const LOCALIZED_COPY := {
	"es": {
		"subtitle": "Elige tu partida",
		"category": "Elige temática",
		"mode": "Tipo de partida",
		"quick": "Rápido",
		"quick_description": "Descifra frases cortas y directas.",
		"cryptogram": "Desafío",
		"cryptogram_description": "Resuelve textos más largos y completos.",
	},
	"en": {
		"subtitle": "Choose your game",
		"category": "Choose a theme",
		"mode": "Choose how you want to play",
		"quick": "Quick",
		"quick_description": "Decode short, direct phrases.",
		"cryptogram": "Challenge",
		"cryptogram_description": "Solve longer, complete texts.",
	},
	"eu": {
		"subtitle": "Aukeratu zure partida",
		"category": "Aukeratu gaia",
		"mode": "Aukeratu nola jokatu",
		"quick": "Azkarra",
		"quick_description": "Deszifratu esaldi labur eta zuzenak.",
		"cryptogram": "Erronka",
		"cryptogram_description": "Ebatzi testu luzeago eta osoak.",
	},
	"de": {
		"subtitle": "Wähle dein Spiel",
		"category": "Wähle ein Thema",
		"mode": "Wähle deine Spielart",
		"quick": "Schnell",
		"quick_description": "Entschlüssle kurze, direkte Sätze.",
		"cryptogram": "Knifflig",
		"cryptogram_description": "Löse längere und vollständige Texte.",
	},
	"fr": {
		"subtitle": "Choisissez votre partie",
		"category": "Choisissez un thème",
		"mode": "Choisissez comment jouer",
		"quick": "Rapide",
		"quick_description": "Déchiffrez des phrases courtes et directes.",
		"cryptogram": "Défi",
		"cryptogram_description": "Résolvez des textes plus longs et complets.",
	},
	"it": {
		"subtitle": "Scegli la tua partita",
		"category": "Scegli un tema",
		"mode": "Scegli come giocare",
		"quick": "Rapido",
		"quick_description": "Decifra frasi brevi e dirette.",
		"cryptogram": "Sfida",
		"cryptogram_description": "Risolvi testi più lunghi e completi.",
	},
	"pt": {
		"subtitle": "Escolha a sua partida",
		"category": "Escolha um tema",
		"mode": "Escolha como jogar",
		"quick": "Rápido",
		"quick_description": "Decifre frases curtas e diretas.",
		"cryptogram": "Desafio",
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
		_category_normal_styles[category_id] = _make_category_style(category_id, false)
	for mode_id in _mode_buttons:
		var button: Button = _mode_buttons[mode_id]
		_mode_normal_styles[mode_id] = button.get_theme_stylebox("normal").duplicate()

	_play_style_normal = button_play.get_theme_stylebox("normal").duplicate()
	_play_style_hover = button_play.get_theme_stylebox("hover").duplicate()
	_play_style_pressed = button_play.get_theme_stylebox("pressed").duplicate()
	_update_category_selection()
	_update_mode_selection()
	_update_localized_copy()
	_update_category_progress()
	_update_play_button()


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
	_update_play_button()


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
	_update_play_button()


func _has_full_selection() -> bool:
	return not categoria.is_empty() and not selected_mode.is_empty()


func _on_button_play_pressed() -> void:
	if not _has_full_selection():
		_show_choose_first_dialog()
		return
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
		var is_selected: bool = category_id == categoria and not categoria.is_empty()
		_set_selected_look(button, is_selected)
		var style := _make_category_style(category_id, is_selected)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)


func _update_mode_selection() -> void:
	for mode_id in _mode_buttons:
		var button: Button = _mode_buttons[mode_id]
		var is_selected: bool = mode_id == selected_mode and not selected_mode.is_empty()
		_set_selected_look(button, is_selected)
		var style: StyleBox = _make_green_selected_style(mode_id) if is_selected else _mode_normal_styles[mode_id]
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)


func _set_selected_look(button: Button, is_selected: bool) -> void:
	var badge := button.get_node_or_null("Selected") as Control
	var tag := button.get_node_or_null("ChosenTag") as Label
	if tag:
		tag.visible = false
	if badge == null:
		return
	if badge.has_meta("check_tween"):
		var previous: Variant = badge.get_meta("check_tween")
		if previous is Tween:
			(previous as Tween).kill()
	badge.visible = is_selected
	if badge.size == Vector2.ZERO:
		badge.pivot_offset = Vector2(39, 39)
	else:
		badge.pivot_offset = badge.size * 0.5
	badge.scale = Vector2.ONE
	if not is_selected:
		return
	var tween := create_tween()
	tween.tween_property(badge, "scale", Vector2(1.18, 1.18), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	badge.set_meta("check_tween", tween)


func _update_play_button() -> void:
	var enabled := _has_full_selection()
	var just_enabled := enabled and not _play_was_enabled
	_play_was_enabled = enabled
	button_play.disabled = false
	button_play.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button_play.modulate = Color.WHITE
	if enabled:
		button_play.add_theme_stylebox_override("normal", _play_style_normal)
		button_play.add_theme_stylebox_override("hover", _play_style_hover)
		button_play.add_theme_stylebox_override("pressed", _play_style_pressed)
		button_play.remove_theme_stylebox_override("disabled")
	else:
		var faded := _make_play_disabled_style()
		button_play.add_theme_stylebox_override("normal", faded)
		button_play.add_theme_stylebox_override("hover", faded)
		button_play.add_theme_stylebox_override("pressed", faded)
		button_play.add_theme_stylebox_override("disabled", faded)
	var content := button_play.get_node_or_null("Content") as Control
	if content:
		content.modulate = Color.WHITE if enabled else Color(1, 0.90, 0.78, 1)
	var text := button_play.get_node_or_null("Content/Text") as Label
	if text:
		text.add_theme_color_override("font_color", Color(1, 1, 0.96, 1) if enabled else Color(1, 0.90, 0.76, 1))
	if just_enabled:
		GameManager.button_blink(button_play)


func _t(key: String, fallback: String) -> String:
	var text := tr(key)
	if text.is_empty() or text == key:
		return fallback
	return text


func _show_choose_first_dialog() -> void:
	if get_node_or_null("ChooseFirstDialog") != null:
		return
	SoundManager.play("ButtonClick")
	var overlay := ColorRect.new()
	overlay.name = "ChooseFirstDialog"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.08, 0.04, 0.02, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 80
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(980, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 0.965, 0.86, 1)
	card_style.border_color = Color(0.62, 0.4, 0.16, 0.46)
	card_style.set_border_width_all(4)
	card_style.border_width_bottom = 9
	card_style.set_corner_radius_all(40)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 36)
	card.add_child(margin)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 24)
	margin.add_child(inner)
	var title := Label.new()
	title.add_theme_font_override("font", FONT_TAG)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08, 1))
	title.text = _t("ChooseFirstTitle", "Elige primero")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(title)
	var body := Label.new()
	body.add_theme_font_override("font", FONT_TAG)
	body.add_theme_font_size_override("font_size", 36)
	body.add_theme_color_override("font_color", Color(0.28, 0.17, 0.1, 1))
	body.text = _t("ChooseFirstBody", "Primero elige el tipo de partida y la temática para poder jugar.")
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(body)
	var ok := Button.new()
	ok.text = _t("ChooseFirstOk", "ENTENDIDO")
	ok.focus_mode = Control.FOCUS_NONE
	ok.custom_minimum_size = Vector2(0, 110)
	ok.add_theme_font_override("font", FONT_TAG)
	ok.add_theme_font_size_override("font_size", 36)
	ok.add_theme_color_override("font_color", Color.WHITE)
	var ok_style := StyleBoxFlat.new()
	ok_style.bg_color = Color(0.96, 0.51, 0.01, 1)
	ok_style.border_color = Color(0.83, 0.41, 0.02, 1)
	ok_style.set_border_width_all(3)
	ok_style.border_width_bottom = 8
	ok_style.set_corner_radius_all(30)
	ok.add_theme_stylebox_override("normal", ok_style)
	ok.add_theme_stylebox_override("hover", ok_style)
	ok.add_theme_stylebox_override("pressed", ok_style)
	ok.pressed.connect(func() -> void:
		SoundManager.play("ButtonClick")
		overlay.queue_free()
	)
	inner.add_child(ok)
	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			SoundManager.play("ButtonClick")
			overlay.queue_free()
	)


func _make_play_disabled_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.74, 0.42, 1)
	style.border_color = Color(1, 0.82, 0.52, 1)
	style.border_width_left = 10
	style.border_width_top = 10
	style.border_width_right = 10
	style.border_width_bottom = 18
	style.set_corner_radius_all(95)
	style.corner_detail = 12
	style.shadow_color = Color(0.37, 0.20, 0.06, 0.10)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 8)
	return style


func _update_category_progress() -> void:
	var mode_for_progress := selected_mode if not selected_mode.is_empty() else MODE_QUICK
	for category_id in _category_buttons:
		var record := HistoryManager.get_competitive_record(
			category_id,
			mode_for_progress
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


func _make_green_selected_style(mode_id: String = MODE_QUICK) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if mode_id == MODE_CRYPTOGRAM:
		style.bg_color = Color(1.0, 0.96, 0.90, 1)
	else:
		style.bg_color = Color(0.86, 0.95, 0.96, 1)
	style.border_color = SELECTED_GREEN
	style.set_border_width_all(8)
	style.border_width_bottom = 11
	style.set_corner_radius_all(32)
	style.shadow_color = Color(0.08, 0.45, 0.22, 0.18)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 7)
	return style


func _make_category_style(category_id: String, selected: bool) -> StyleBoxFlat:
	var category_color: Color = GameManager.category_color(category_id)
	var style := StyleBoxFlat.new()
	style.bg_color = category_color.lightened(0.68 if not selected else 0.55)
	style.border_color = SELECTED_GREEN if selected else category_color.lightened(0.12)
	style.set_border_width_all(13 if selected else 3)
	style.border_width_bottom = 16 if selected else 8
	style.set_corner_radius_all(31)
	style.shadow_color = Color(0.08, 0.45, 0.22, 0.18) if selected else Color(category_color.r, category_color.g, category_color.b, 0.17)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 8)
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
