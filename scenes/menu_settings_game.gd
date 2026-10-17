extends Node2D

@onready var check_button_music = $Panel/ButtonRefranesPopulares2/CheckButtonMusic
@onready var check_button_fx = $Panel/ButtonFx/CheckButtonFx

@onready var h_slider_sound = $Panel/ButtonRefranesPopulares2/HSliderSound
@onready var h_slider_fx = $Panel/ButtonFx/HSliderFx

@onready var labe_columns = $Panel/LabeColumns
@onready var nombre = $Panel/Nombre

@onready var cols_08 = $Panel/Cols08
@onready var cols_09 = $Panel/Cols09
@onready var cols_10 = $Panel/Cols10
@onready var cols_11 = $Panel/Cols11
@onready var cols_12 = $Panel/Cols12
@onready var cols_13 = $Panel/Cols13

func _on_button_back_pressed():
	queue_free()


func _on_check_button_2_pressed():
	SoundManager.play("ButtonClick")
	if check_button_fx.button_pressed:
		PlayerPrefs.mute_fx = true
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SoundFx"), false)
	else:
		PlayerPrefs.mute_fx = false
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SoundFx"), true)
	PlayerPrefs.save_prefs()
		
	

func _ready():
	#print("FX Volume:" , PlayerPrefs.volumen_fx)
	#print("Music Volume:" , PlayerPrefs.volumen_musica)
	_set_image(GameManager.NUM_COLUMNAS)
	
	labe_columns.text = str(GameManager.NUM_COLUMNAS)
	$Panel/LabelSound2.text = tr("GAME SETTINGS")
	$Panel/TextureRect3/LabeLanguage.text = tr("COLUMNS")
	$Panel/TextureRect4/LabeLanguage.text = tr("OnlineName")
	$Panel/TextureRect2/LabelSound.text = tr("SOUND")
	$Panel/ButtonRefranesPopulares2/Label2.text = tr("Music")
	$Panel/ButtonBack.text = tr("Back")
	
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
	
	if GameManager.has_chosen_online_name():
		nombre.placeholder_text = GameManager.player_name
	else:
		nombre.placeholder_text = tr("Enter Name")

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
	SoundManager.apply_audio_prefs()
	PlayerPrefs.save_prefs()


func _on_h_slider_sound_value_changed(value):
	PlayerPrefs.volumen_musica = h_slider_sound.value
	SoundManager.apply_audio_prefs()
	PlayerPrefs.save_prefs()


func _on_button_col_pressed():
	pass # Replace with function body.


func _on_button_col_plus_pressed():
	if GameManager.NUM_COLUMNAS < 13:
		SignalManager.update_canvas_grid.emit(+1)
		labe_columns.text = str(GameManager.NUM_COLUMNAS)
		_set_image(GameManager.NUM_COLUMNAS)


func _on_button_col_less_pressed():
	if GameManager.NUM_COLUMNAS > 8:
		SignalManager.update_canvas_grid.emit(-1)
		labe_columns.text = str(GameManager.NUM_COLUMNAS)
		_set_image(GameManager.NUM_COLUMNAS)
		
func _set_image(cols: int) -> void:
	
	cols_08.visible = false
	cols_09.visible = false
	cols_10.visible = false
	cols_11.visible = false
	cols_12.visible = false
	cols_13.visible = false

	if cols == 8:
		cols_08.visible = true
	elif cols == 9:
		cols_09.visible = true
	elif cols == 10:
		cols_10.visible = true
	elif cols == 11:
		cols_11.visible = true
	elif cols == 12:
		cols_12.visible = true
	else: 
		cols_13.visible = true


func _on_nombre_text_submitted(new_text):
	GameManager.set_player_name(nombre.text)
	PlayerPrefs.save_prefs()
