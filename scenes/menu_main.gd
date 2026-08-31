extends Control

@onready var button_settings: Button = %ButtonSettings
@onready var button_play: Button = %ButtonPlay
@onready var button_ranking: Button = %ButtonRanking
@onready var button_stats: Button = %ButtonStats
@onready var button_tutorial: Button = %ButtonTutorial
@onready var version_label: Label = %VersionLabel

func _ready() -> void:
	_apply_audio()
	_apply_labels()
	_update_version_label()
	SignalManager.app_version_changed.connect(_on_app_version_changed)
	SignalManager.fit_text.emit()
	GameManager.reset_game_paremeters()
	GameManager.resetear_partida_terminada()

func _apply_labels() -> void:
	var tagline := get_node_or_null("Panel/TaglineRow/Tagline") as Label
	if tagline:
		tagline.text = tr("Tagline")

func _update_version_label() -> void:
	if version_label == null:
		return
	version_label.text = "VERSION\n%s" % PlayerPrefs.version_display()

func _on_app_version_changed(_version_text: String) -> void:
	_update_version_label()

func _apply_audio() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),
		linear_to_db(PlayerPrefs.volumen_musica))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SoundFx"),
		linear_to_db(PlayerPrefs.volumen_fx))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not PlayerPrefs.mute_musica)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SoundFx"), not PlayerPrefs.mute_fx)

func _go_to(path: String, blink_node: Control = null) -> void:
	TransitionScreen.transition_to_black()
	if blink_node is Button:
		GameManager.button_blink(blink_node)
	elif blink_node is TextureButton:
		GameManager.button_blink_texture(blink_node)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file(path)

func _on_button_settings_pressed() -> void:
	_go_to("res://scenes/MenuSettings.tscn", button_settings)

func _on_button_play_pressed() -> void:
	_go_to("res://scenes/MenuSelectCategory.tscn", button_play)

func _on_button_ranking_pressed() -> void:
	HistoryManager.get_results_filtered("Todas", -1)
	_go_to("res://scenes/LeaderboardFINAL.tscn", button_ranking)

func _on_button_stats_pressed() -> void:
	_go_to("res://scenes/MenuStats.tscn", button_stats)

func _on_button_tutorial_pressed() -> void:
	_go_to("res://scenes/MenuTutorial.tscn", button_tutorial)
