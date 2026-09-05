extends Control

const CREDITS_SCENE := preload("res://scenes/MenuCredits.tscn")
const CREDITS_BLINK_EVERY := 3.0

@onready var button_español: Button = $Panel/LanguageCard/ButtonEspañol
@onready var button_credits: Button = $Panel/Header/ButtonCredits
@onready var button_euskera: Button = $Panel/LanguageCard/ButtonEuskera
@onready var button_ingles: Button = $Panel/LanguageCard/ButtonIngles
@onready var button_frances: Button = $Panel/LanguageCard/ButtonFrances
@onready var button_aleman: Button = $Panel/LanguageCard/ButtonAleman
@onready var button_portugues: Button = $Panel/LanguageCard/ButtonPortugues
@onready var button_italiano: Button = $Panel/LanguageCard/ButtonItaliano

@onready var check_button_music: Button = $Panel/SoundCard/SoundRows/CheckButtonMusic
@onready var check_button_fx: Button = $Panel/SoundCard/SoundRows/CheckButtonFx
@onready var h_slider_sound: HSlider = $Panel/SoundCard/SoundRows/HSliderSound
@onready var h_slider_fx: HSlider = $Panel/SoundCard/SoundRows/HSliderFx
@onready var music_icon_texture: TextureRect = $Panel/SoundCard/SoundRows/MusicIcon/Texture
@onready var music_icon_slash: TextureRect = $Panel/SoundCard/SoundRows/MusicIcon/Slash
@onready var fx_icon_texture: TextureRect = $Panel/SoundCard/SoundRows/FxIcon/Texture
@onready var fx_icon_slash: TextureRect = $Panel/SoundCard/SoundRows/FxIcon/Slash
@onready var nombre: LineEdit = $Panel/OnlineCard/Nombre
@onready var name_slots: HBoxContainer = $Panel/OnlineCard/NameSlots
@onready var title_label: Label = $Panel/Header/Title
@onready var online_title_label: Label = $Panel/OnlineCard/Title
@onready var online_help_label: Label = $Panel/OnlineCard/Info/Text
@onready var reset_label: Label = $Panel/Footer/ButtonReset/Text
@onready var game_title_label: Label = $Panel/GameCard/Title
@onready var tutorial_label: Label = $Panel/GameCard/GameRows/TutorialLabel
@onready var reveal_label: Label = $Panel/GameCard/GameRows/RevealLabel
@onready var check_button_tutorial: Button = $Panel/GameCard/GameRows/CheckButtonTutorial
@onready var check_button_reveal: Button = $Panel/GameCard/GameRows/CheckButtonReveal

var _language_buttons: Dictionary = {}
var _normal_language_styles: Dictionary = {}
var _name_slot_style: StyleBoxFlat
var _name_slot_style_active: StyleBoxFlat
var _updating_name := false
var _updating_audio := false

const NAME_MAX_LENGTH := 10

const LOCALIZED_COPY := {
	"es": {
		"title": "Opciones",
		"online_title": "NOMBRE ONLINE",
		"online_help": "Este nombre se mostrará en las clasificaciones y retos online.",
		"reset": "RESTABLECER VALORES",
		"game_title": "JUEGO",
		"tutorial": "Mostrar tutorial antes de jugar.",
		"reveal": "Mostrar explicación botón REVELAR.",
	},
	"en": {
		"title": "Options",
		"online_title": "ONLINE NAME",
		"online_help": "This name will be shown in online leaderboards and challenges.",
		"reset": "RESET VALUES",
		"game_title": "GAME",
		"tutorial": "Show tutorial before playing.",
		"reveal": "Show REVEAL button explanation.",
	},
	"eu": {
		"title": "Aukerak",
		"online_title": "LINEAKO IZENA",
		"online_help": "Izen hau lineako sailkapenetan eta erronketan agertuko da.",
		"reset": "BERREZARRI BALIOAK",
		"game_title": "JOKOA",
		"tutorial": "Erakutsi tutoriala jokatu aurretik.",
		"reveal": "Erakutsi REVELAR botoiaren azalpena.",
	},
	"de": {
		"title": "Optionen",
		"online_title": "ONLINE-NAME",
		"online_help": "Dieser Name wird in Online-Ranglisten und Herausforderungen angezeigt.",
		"reset": "WERTE ZURÜCKSETZEN",
		"game_title": "SPIEL",
		"tutorial": "Tutorial vor dem Spielen anzeigen.",
		"reveal": "Erklärung der REVELAR-Taste anzeigen.",
	},
	"fr": {
		"title": "Options",
		"online_title": "NOM EN LIGNE",
		"online_help": "Ce nom apparaîtra dans les classements et défis en ligne.",
		"reset": "RÉINITIALISER",
		"game_title": "JEU",
		"tutorial": "Afficher le tutoriel avant de jouer.",
		"reveal": "Afficher l'explication du bouton REVELAR.",
	},
	"it": {
		"title": "Opzioni",
		"online_title": "NOME ONLINE",
		"online_help": "Questo nome apparirà nelle classifiche e nelle sfide online.",
		"reset": "RIPRISTINA VALORI",
		"game_title": "GIOCO",
		"tutorial": "Mostra il tutorial prima di giocare.",
		"reveal": "Mostra la spiegazione del pulsante REVELAR.",
	},
	"pt": {
		"title": "Opções",
		"online_title": "NOME ONLINE",
		"online_help": "Este nome aparecerá nas classificações e desafios online.",
		"reset": "REPOR VALORES",
		"game_title": "JOGO",
		"tutorial": "Mostrar tutorial antes de jogar.",
		"reveal": "Mostrar explicação do botão REVELAR.",
	},
}


func _ready() -> void:
	_language_buttons = {
		"es": button_español,
		"eu": button_euskera,
		"en": button_ingles,
		"fr": button_frances,
		"de": button_aleman,
		"pt": button_portugues,
		"it": button_italiano,
	}
	for code in _language_buttons:
		var button: Button = _language_buttons[code]
		_normal_language_styles[code] = button.get_theme_stylebox("normal").duplicate()

	nombre.max_length = NAME_MAX_LENGTH
	nombre.focus_entered.connect(_refresh_name_slots)
	nombre.focus_exited.connect(_on_nombre_focus_exited)
	_build_name_slots()
	_set_nombre_text(_sanitize_player_name(GameManager.chosen_online_name_or_empty()))
	nombre.placeholder_text = ""
	h_slider_fx.set_value_no_signal(PlayerPrefs.volumen_fx)
	h_slider_sound.set_value_no_signal(PlayerPrefs.volumen_musica)
	_refresh_audio_controls()
	if not SignalManager.audio_prefs_changed.is_connected(_refresh_audio_controls):
		SignalManager.audio_prefs_changed.connect(_refresh_audio_controls)
	check_button_tutorial.button_pressed = PlayerPrefs.mostrar_tuto_antes_partida
	check_button_reveal.button_pressed = not PlayerPrefs.skip_reveal_dialog
	_update_language_selection()
	_start_credits_blink()


func _on_button_back_pressed() -> void:
	_save_online_name(true)
	SoundManager.play("ButtonClick")
	if _is_overlay():
		queue_free()
		return
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")


func _on_button_credits_pressed() -> void:
	_save_online_name(true)
	SoundManager.play("ButtonClick")
	if _is_overlay():
		var credits := CREDITS_SCENE.instantiate()
		if credits.has_method("present_as_overlay"):
			credits.call("present_as_overlay")
		get_parent().add_child(credits)
		if credits is Control:
			var overlay := credits as Control
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overlay.mouse_filter = Control.MOUSE_FILTER_STOP
			overlay.z_index = 20
		return
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuCredits.tscn")


func _start_credits_blink() -> void:
	if button_credits == null:
		return
	await get_tree().process_frame
	if not is_instance_valid(button_credits):
		return
	button_credits.pivot_offset = button_credits.size * 0.5
	await get_tree().create_timer(0.7).timeout
	while is_instance_valid(button_credits):
		await _pulse_credits_button()
		if not is_instance_valid(button_credits):
			return
		await get_tree().create_timer(CREDITS_BLINK_EVERY).timeout


func _pulse_credits_button() -> void:
	if not is_instance_valid(button_credits):
		return
	button_credits.pivot_offset = button_credits.size * 0.5
	var blink := create_tween()
	blink.tween_property(button_credits, "scale", Vector2(1.16, 1.16), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	blink.parallel().tween_property(button_credits, "modulate", Color(1.12, 0.9, 0.45, 1), 0.16)
	blink.tween_property(button_credits, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	blink.parallel().tween_property(button_credits, "modulate", Color.WHITE, 0.22)
	blink.tween_property(button_credits, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_SINE)
	blink.tween_property(button_credits, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE)
	await blink.finished


func _is_overlay() -> bool:
	return get_tree() != null and get_tree().current_scene != self


func _select_language(code: String, button: Button) -> void:
	GameManager.button_blink(button)
	SoundManager.play("ButtonClick")
	GameManager.apply_language(code)
	_update_language_selection()


func _on_button_español_pressed() -> void:
	_select_language("es", button_español)


func _on_button_ingles_pressed() -> void:
	_select_language("en", button_ingles)


func _on_button_euskera_pressed() -> void:
	_select_language("eu", button_euskera)


func _on_button_aleman_pressed() -> void:
	_select_language("de", button_aleman)


func _on_button_portugues_pressed() -> void:
	_select_language("pt", button_portugues)


func _on_button_italiano_pressed() -> void:
	_select_language("it", button_italiano)


func _on_button_frances_pressed() -> void:
	_select_language("fr", button_frances)


func _on_check_button_fx_toggled(enabled: bool) -> void:
	if _updating_audio:
		return
	var enabling := enabled and not SoundManager.is_fx_enabled()
	if not enabling:
		SoundManager.play("ButtonClick")
	SoundManager.set_fx_enabled(enabled)
	if enabling:
		SoundManager.play("ButtonClick")


func _on_check_button_music_toggled(enabled: bool) -> void:
	if _updating_audio:
		return
	SoundManager.play("ButtonClick")
	SoundManager.set_music_enabled(enabled)


func _on_h_slider_fx_value_changed(value: float) -> void:
	PlayerPrefs.volumen_fx = value
	SoundManager.apply_audio_prefs()
	PlayerPrefs.save_prefs()


func _on_h_slider_sound_value_changed(value: float) -> void:
	PlayerPrefs.volumen_musica = value
	SoundManager.apply_audio_prefs()
	PlayerPrefs.save_prefs()


func _refresh_audio_controls(_unused: Variant = null) -> void:
	_updating_audio = true
	check_button_music.set_pressed_no_signal(SoundManager.is_music_enabled())
	check_button_fx.set_pressed_no_signal(SoundManager.is_fx_enabled())
	check_button_music.queue_redraw()
	check_button_fx.queue_redraw()
	_updating_audio = false
	_set_audio_icon_state(music_icon_texture, music_icon_slash, SoundManager.is_music_enabled())
	_set_audio_icon_state(fx_icon_texture, fx_icon_slash, SoundManager.is_fx_enabled())


func _set_audio_icon_state(icon: TextureRect, slash: TextureRect, enabled: bool) -> void:
	if icon:
		var color := icon.modulate
		color.a = 1.0 if enabled else 0.38
		icon.modulate = color
	if slash:
		slash.visible = not enabled


func _on_nombre_text_changed(new_text: String) -> void:
	if _updating_name:
		return
	var caret := nombre.caret_column
	var sanitized := _sanitize_player_name(new_text)
	if sanitized != new_text:
		var removed := new_text.length() - sanitized.length()
		_set_nombre_text(sanitized)
		nombre.caret_column = clampi(caret - removed, 0, sanitized.length())
	else:
		_refresh_name_slots()
	_save_online_name()


func _on_nombre_text_submitted(new_text: String) -> void:
	_set_nombre_text(_sanitize_player_name(new_text))
	_save_online_name(true)
	nombre.release_focus()
	_refresh_name_slots()


func _on_nombre_focus_exited() -> void:
	_save_online_name(true)
	_refresh_name_slots()


func _on_button_edit_pressed() -> void:
	nombre.grab_focus()
	nombre.caret_column = nombre.text.length()
	_refresh_name_slots()


func _on_button_reset_pressed() -> void:
	SoundManager.play("ButtonClick")
	h_slider_sound.set_value_no_signal(0.8)
	h_slider_fx.set_value_no_signal(0.8)
	PlayerPrefs.volumen_musica = 0.8
	PlayerPrefs.volumen_fx = 0.8
	SoundManager.set_music_enabled(true)
	SoundManager.set_fx_enabled(true)
	SoundManager.apply_audio_prefs()
	PlayerPrefs.save_prefs()
	GameManager.apply_language("es")
	check_button_tutorial.button_pressed = true
	check_button_reveal.button_pressed = true
	PlayerPrefs.set_mostrar_tutorial(true)
	PlayerPrefs.set_show_reveal_explanation(true)
	_refresh_audio_controls()
	_update_language_selection()


func _on_check_button_tutorial_pressed() -> void:
	SoundManager.play("ButtonClick")
	PlayerPrefs.set_mostrar_tutorial(check_button_tutorial.button_pressed)


func _on_check_button_reveal_pressed() -> void:
	SoundManager.play("ButtonClick")
	PlayerPrefs.set_show_reveal_explanation(check_button_reveal.button_pressed)


func _save_online_name(sync_online: bool = false) -> void:
	GameManager.set_player_name(_sanitize_player_name(nombre.text))
	PlayerPrefs.save_prefs()
	if sync_online and typeof(PlayFabTools) != TYPE_NIL:
		PlayFabTools.sync_player_display_name(GameManager.player_name)


func _sanitize_player_name(text: String) -> String:
	var out := ""
	for i in text.length():
		var ch := text.substr(i, 1)
		if not _is_alphanumeric_char(ch):
			continue
		out += ch
		if out.length() >= NAME_MAX_LENGTH:
			break
	return out


func _is_alphanumeric_char(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code := ch.unicode_at(0)
	var is_upper := code >= 65 and code <= 90
	var is_lower := code >= 97 and code <= 122
	var is_digit := code >= 48 and code <= 57
	return is_upper or is_lower or is_digit


func _set_nombre_text(value: String) -> void:
	_updating_name = true
	nombre.text = value
	_updating_name = false
	_refresh_name_slots()


func _build_name_slots() -> void:
	_name_slot_style = StyleBoxFlat.new()
	_name_slot_style.bg_color = Color(1.0, 0.984, 0.925, 0.92)
	_name_slot_style.border_color = Color(0.77, 0.62, 0.40, 0.55)
	_name_slot_style.set_border_width_all(2)
	_name_slot_style.border_width_bottom = 6
	_name_slot_style.set_corner_radius_all(14)
	_name_slot_style_active = _name_slot_style.duplicate()
	_name_slot_style_active.border_color = Color(0.04, 0.65, 0.64, 0.95)
	_name_slot_style_active.set_border_width_all(3)
	_name_slot_style_active.border_width_bottom = 7
	while name_slots.get_child_count() > 0:
		name_slots.get_child(0).free()
	for _i in NAME_MAX_LENGTH:
		var slot := Panel.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("panel", _name_slot_style)
		var letter := Label.new()
		letter.name = "Letter"
		letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter.set_anchors_preset(Control.PRESET_FULL_RECT)
		letter.add_theme_font_override("font", nombre.get_theme_font("font"))
		letter.add_theme_font_size_override("font_size", 46)
		letter.add_theme_color_override("font_color", Color(0.34, 0.22, 0.15, 1))
		slot.add_child(letter)
		name_slots.add_child(slot)
	_refresh_name_slots()


func _refresh_name_slots() -> void:
	if name_slots == null:
		return
	var value := nombre.text
	var caret := nombre.caret_column if nombre.has_focus() else -1
	for i in name_slots.get_child_count():
		var slot := name_slots.get_child(i) as Panel
		if slot == null:
			continue
		var letter := slot.get_node_or_null("Letter") as Label
		if letter:
			if i < value.length():
				letter.text = value.substr(i, 1)
				letter.modulate.a = 1.0
			else:
				letter.text = "_"
				letter.modulate.a = 0.28
		var is_active := nombre.has_focus() and i == mini(caret, NAME_MAX_LENGTH - 1)
		slot.add_theme_stylebox_override(
			"panel",
			_name_slot_style_active if is_active else _name_slot_style
		)


func _process(_delta: float) -> void:
	if is_instance_valid(nombre) and nombre.has_focus():
		_refresh_name_slots()


func _update_language_selection() -> void:
	var current_locale := TranslationServer.get_locale().left(2).to_lower()
	for code in _language_buttons:
		var button: Button = _language_buttons[code]
		var is_selected: bool = code == current_locale
		button.get_node("Selected").visible = is_selected
		button.add_theme_stylebox_override(
			"normal",
			_make_selected_language_style() if is_selected else _normal_language_styles[code]
		)
	_update_localized_copy(current_locale)


func _update_localized_copy(_locale: String = "") -> void:
	title_label.text = tr("Options")
	online_title_label.text = tr("OnlineName")
	online_help_label.text = tr("OnlineNameHelp")
	reset_label.text = tr("ResetValues")
	game_title_label.text = tr("GameSection")
	tutorial_label.text = tr("ShowTutorialBefore")
	reveal_label.text = tr("ShowRevealExplain")
	nombre.placeholder_text = ""
	$Panel/SoundCard/Title.text = tr("SOUND")
	$Panel/SoundCard/SoundRows/MusicLabel.text = tr("Music")
	$Panel/SoundCard/SoundRows/FxLabel.text = tr("Fx")
	$Panel/LanguageCard/Title.text = tr("LANGUAGE")


func _make_selected_language_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#FFFBEF")
	style.border_color = Color("#0AA5A4")
	style.set_border_width_all(7)
	style.set_corner_radius_all(30)
	style.shadow_color = Color(0.04, 0.50, 0.50, 0.16)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 7)
	return style
