extends Control

@onready var button_español: Button = $Panel/LanguageCard/ButtonEspañol
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
@onready var nombre: LineEdit = $Panel/OnlineCard/Nombre
@onready var title_label: Label = $Panel/Header/Title
@onready var online_title_label: Label = $Panel/OnlineCard/Title
@onready var online_help_label: Label = $Panel/OnlineCard/Info/Text
@onready var reset_label: Label = $Panel/Footer/ButtonReset/Text

var _language_buttons: Dictionary = {}
var _normal_language_styles: Dictionary = {}

const LOCALIZED_COPY := {
	"es": {
		"title": "Opciones",
		"online_title": "NOMBRE ONLINE",
		"online_help": "Este nombre se mostrará en las clasificaciones y retos online.",
		"reset": "RESTABLECER VALORES",
	},
	"en": {
		"title": "Options",
		"online_title": "ONLINE NAME",
		"online_help": "This name will be shown in online leaderboards and challenges.",
		"reset": "RESET VALUES",
	},
	"eu": {
		"title": "Aukerak",
		"online_title": "LINEAKO IZENA",
		"online_help": "Izen hau lineako sailkapenetan eta erronketan agertuko da.",
		"reset": "BERREZARRI BALIOAK",
	},
	"de": {
		"title": "Optionen",
		"online_title": "ONLINE-NAME",
		"online_help": "Dieser Name wird in Online-Ranglisten und Herausforderungen angezeigt.",
		"reset": "WERTE ZURÜCKSETZEN",
	},
	"fr": {
		"title": "Options",
		"online_title": "NOM EN LIGNE",
		"online_help": "Ce nom apparaîtra dans les classements et défis en ligne.",
		"reset": "RÉINITIALISER",
	},
	"it": {
		"title": "Opzioni",
		"online_title": "NOME ONLINE",
		"online_help": "Questo nome apparirà nelle classifiche e nelle sfide online.",
		"reset": "RIPRISTINA VALORI",
	},
	"pt": {
		"title": "Opções",
		"online_title": "NOME ONLINE",
		"online_help": "Este nome aparecerá nas classificações e desafios online.",
		"reset": "REPOR VALORES",
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

	nombre.text = GameManager.player_name
	nombre.placeholder_text = tr("Enter Name")
	h_slider_fx.value = PlayerPrefs.volumen_fx
	h_slider_sound.value = PlayerPrefs.volumen_musica
	check_button_fx.button_pressed = PlayerPrefs.mute_fx
	check_button_music.button_pressed = PlayerPrefs.mute_musica
	_update_language_selection()


func _on_button_back_pressed() -> void:
	_save_online_name()
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")
	SoundManager.play("ButtonClick")


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


func _on_check_button_2_pressed() -> void:
	SoundManager.play("ButtonClick")
	PlayerPrefs.mute_fx = check_button_fx.button_pressed
	AudioServer.set_bus_mute(
		AudioServer.get_bus_index("SoundFx"),
		not check_button_fx.button_pressed
	)
	PlayerPrefs.save_prefs()


func _on_check_button_music_pressed() -> void:
	SoundManager.play("ButtonClick")
	PlayerPrefs.mute_musica = check_button_music.button_pressed
	AudioServer.set_bus_mute(
		AudioServer.get_bus_index("Music"),
		not check_button_music.button_pressed
	)
	PlayerPrefs.save_prefs()


func _on_h_slider_fx_value_changed(value: float) -> void:
	PlayerPrefs.volumen_fx = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SoundFx"), linear_to_db(value))
	PlayerPrefs.save_prefs()


func _on_h_slider_sound_value_changed(value: float) -> void:
	PlayerPrefs.volumen_musica = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	PlayerPrefs.save_prefs()


func _on_nombre_text_submitted(new_text: String) -> void:
	nombre.text = new_text.strip_edges()
	_save_online_name()
	nombre.release_focus()


func _on_button_edit_pressed() -> void:
	nombre.grab_focus()
	nombre.select_all()


func _on_button_reset_pressed() -> void:
	SoundManager.play("ButtonClick")
	h_slider_sound.value = 0.8
	h_slider_fx.value = 0.8
	check_button_music.button_pressed = true
	check_button_fx.button_pressed = true
	PlayerPrefs.volumen_musica = 0.8
	PlayerPrefs.volumen_fx = 0.8
	PlayerPrefs.mute_musica = true
	PlayerPrefs.mute_fx = true
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SoundFx"), false)
	PlayerPrefs.save_prefs()
	GameManager.apply_language("es")
	_update_language_selection()


func _save_online_name() -> void:
	GameManager.player_name = nombre.text.strip_edges()
	PlayerPrefs.save_prefs()


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


func _update_localized_copy(locale: String) -> void:
	var copy: Dictionary = LOCALIZED_COPY.get(locale, LOCALIZED_COPY["en"])
	title_label.text = copy["title"]
	online_title_label.text = copy["online_title"]
	online_help_label.text = copy["online_help"]
	reset_label.text = copy["reset"]


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
