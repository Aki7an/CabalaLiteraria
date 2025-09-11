extends Node2D

@onready var check_button_music = $ButtonRefranesPopulares2/CheckButtonMusic
@onready var check_button_fx = $ButtonFx/CheckButtonFx

@onready var h_slider_sound = $ButtonRefranesPopulares2/HSliderSound
@onready var h_slider_fx = $ButtonFx/HSliderFx

func _on_button_back_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")
	SoundManager.play("ButtonClick")


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
