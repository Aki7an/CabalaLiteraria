extends Node2D
@onready var button_settings = $Panel/ButtonSettings
#@onready var button_play = $Panel/ButtonPlay
@onready var play_button_fx = $Panel/PlayButtonFx

func _ready():
	# Aplicar preferencias PlayerPrefs
	TranslationServer.set_locale(PlayerPrefs.idioma)

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),
		linear_to_db(PlayerPrefs.volumen_musica))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SoundFx"),
		linear_to_db(PlayerPrefs.volumen_fx))

	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), !PlayerPrefs.mute_musica)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SoundFx"), !PlayerPrefs.mute_fx)
	SignalManager.fit_text.emit()
	GameManager.reset_game_paremeters()
	GameManager.resetear_partida_terminada()
	
#func _on_button_play_pressed():
	#TransitionScreen.transition_to_black()
	#GameManager.button_blink_texture(button_play)
	#SoundManager.play("ButtonClick")
	#await TransitionScreen._on_animation_finished("fade_to_black", 1)
	#get_tree().change_scene_to_file("res://scenes/MenuSelectGame.tscn")


func _on_button_settings_pressed():
	TransitionScreen.transition_to_black()
	GameManager.button_blink(button_settings)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuSettings.tscn")


func _on_play_button_fx_pressed():
	TransitionScreen.transition_to_black()
	#GameManager.button_blink_texture(play_button_fx)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuSelectCategory.tscn")


func _on_button_leaderboard_2_pressed() -> void:
	HistoryManager.get_results_filtered("Todas",-1)
	TransitionScreen.transition_to_black()
	GameManager.button_blink_texture(play_button_fx)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/Leaderboard.tscn")


func _on_button_settings_3_pressed():
	TransitionScreen.transition_to_black()
	GameManager.button_blink(button_settings)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuTutorial.tscn")


func _on_button_shop_2_pressed():
	TransitionScreen.transition_to_black()
	GameManager.button_blink(button_settings)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuStats.tscn")


func _on_button_shop_pressed():
	TransitionScreen.transition_to_black()
	GameManager.button_blink(button_settings)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuShop.tscn")


func _on_button_leaderboard_3_pressed():
	#HistoryManager.get_results_filtered("Todas",-1)
	TransitionScreen.transition_to_black()
	GameManager.button_blink_texture(play_button_fx)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/LeaderboardOnline.tscn")
