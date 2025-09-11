extends Node2D
@onready var button_español = $ButtonEspañol
@onready var button_euskera = $ButtonEuskera
@onready var button_ingles = $ButtonIngles
@onready var button_frances = $ButtonFrances
@onready var button_aleman = $ButtonAleman
@onready var button_portugues = $ButtonPortugues
@onready var button_italiano = $ButtonItaliano

@onready var check_button_music = $ButtonRefranesPopulares2/CheckButtonMusic
@onready var check_button_fx = $ButtonFx/CheckButtonFx

@onready var h_slider_sound = $ButtonRefranesPopulares2/HSliderSound
@onready var h_slider_fx = $ButtonFx/HSliderFx

func _on_button_back_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")
	SoundManager.play("ButtonClick")

func _on_button_español_pressed():
	TranslationServer.set_locale("es")
	GameManager.button_blink(button_español)
	PlayerPrefs.idioma = "es"
	PlayerPrefs.save_prefs()
	SoundManager.play("ButtonClick")
	SignalManager.fit_text.emit()
	GameManager.change_letters_aphabet_array()
	GameManager.cargar_frases_desde_json()
	
func _on_button_ingles_pressed():
	TranslationServer.set_locale("en")
	GameManager.button_blink(button_ingles)
	PlayerPrefs.idioma = "en"
	PlayerPrefs.save_prefs()
	SoundManager.play("ButtonClick")
	SignalManager.fit_text.emit()
	GameManager.change_letters_aphabet_array()
	GameManager.cargar_frases_desde_json()

func _on_button_euskera_pressed():
	TranslationServer.set_locale("eu")
	GameManager.button_blink(button_euskera)
	PlayerPrefs.idioma = "eu"
	PlayerPrefs.save_prefs()
	SoundManager.play("ButtonClick")
	SignalManager.fit_text.emit()
	GameManager.change_letters_aphabet_array()
	GameManager.cargar_frases_desde_json()

func _on_button_aleman_pressed():
	TranslationServer.set_locale("de")
	GameManager.button_blink(button_aleman)
	PlayerPrefs.idioma = "de"
	PlayerPrefs.save_prefs()
	SoundManager.play("ButtonClick")
	SignalManager.fit_text.emit()
	GameManager.change_letters_aphabet_array()
	GameManager.cargar_frases_desde_json()

func _on_button_portugues_pressed():
	TranslationServer.set_locale("pt")
	GameManager.button_blink(button_portugues)
	PlayerPrefs.idioma = "pt"
	PlayerPrefs.save_prefs()
	SoundManager.play("ButtonClick")
	SignalManager.fit_text.emit()
	GameManager.change_letters_aphabet_array()
	GameManager.cargar_frases_desde_json()

func _on_button_italiano_pressed():
	TranslationServer.set_locale("it")
	GameManager.button_blink(button_italiano)
	PlayerPrefs.idioma = "it"
	PlayerPrefs.save_prefs()
	SoundManager.play("ButtonClick")
	SignalManager.fit_text.emit()
	GameManager.change_letters_aphabet_array()
	GameManager.cargar_frases_desde_json()

func _on_button_frances_pressed():
	TranslationServer.set_locale("fr")
	GameManager.button_blink(button_frances)
	PlayerPrefs.idioma = "fr"
	PlayerPrefs.save_prefs()
	SoundManager.play("ButtonClick")
	SignalManager.fit_text.emit()
	GameManager.change_letters_aphabet_array()
	GameManager.cargar_frases_desde_json()

func _on_check_button_2_pressed():
	SoundManager.play("ButtonClick")
	if check_button_fx.button_pressed:
		PlayerPrefs.mute_fx = true
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SoundFx"), false)
		PlayerPrefs.save_prefs()
	else:
		PlayerPrefs.mute_fx = false
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SoundFx"), true)
		
	

func _ready():
	#print("FX Volume:" , PlayerPrefs.volumen_fx)
	#print("Music Volume:" , PlayerPrefs.volumen_musica)
	
	h_slider_fx.value = PlayerPrefs.volumen_fx
	h_slider_sound.value = PlayerPrefs.volumen_musica
	
	if PlayerPrefs.mute_fx:
		check_button_fx.button_pressed = true
	else:
		check_button_fx.button_pressed = false

	if PlayerPrefs.mute_musica:
		check_button_music.button_pressed = true
	else:
		check_button_music.button_pressed = false


func _on_check_button_music_pressed():
	SoundManager.play("ButtonClick")
	if check_button_music.button_pressed:
		PlayerPrefs.mute_musica = true
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), false)
	else:
		PlayerPrefs.mute_musica = false
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), true)
		
	PlayerPrefs.save_prefs()


func _on_h_slider_fx_value_changed(value):
	PlayerPrefs.volumen_fx = h_slider_fx.value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SoundFx"), linear_to_db(h_slider_fx.value))
	PlayerPrefs.save_prefs()
	#print("Changed" , h_slider_fx.value)


func _on_h_slider_sound_value_changed(value):
	PlayerPrefs.volumen_musica = h_slider_sound.value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(h_slider_sound.value))
	PlayerPrefs.save_prefs()
