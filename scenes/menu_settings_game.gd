extends Node2D

@onready var check_button_music = $Panel/ButtonRefranesPopulares2/CheckButtonMusic
@onready var check_button_fx = $Panel/ButtonFx/CheckButtonFx

@onready var h_slider_sound = $Panel/ButtonRefranesPopulares2/HSliderSound
@onready var h_slider_fx = $Panel/ButtonFx/HSliderFx

@onready var labe_columns = $Panel/LabeColumns

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
		PlayerPrefs.save_prefs()
	else:
		PlayerPrefs.mute_fx = false
		AudioServer.set_bus_mute(AudioServer.get_bus_index("SoundFx"), true)
		
	

func _ready():
	#print("FX Volume:" , PlayerPrefs.volumen_fx)
	#print("Music Volume:" , PlayerPrefs.volumen_musica)
	_set_image(GameManager.NUM_COLUMNAS)
	
	labe_columns.text = str(GameManager.NUM_COLUMNAS)
	
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
