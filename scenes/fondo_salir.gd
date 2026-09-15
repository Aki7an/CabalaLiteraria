extends ColorRect

const PUZZLE_SELECTION := "res://scenes/MenuSelectLevelByID.tscn"
const SETTINGS_SCENE := preload("res://scenes/MenuSettings.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	SoundManager.fade_to_menu_music()
	$Card/Title.text = tr("PauseTitle")
	$Card/Subtitle.text = tr("PauseSavedWhilePlaying")
	$Card/Actions/ButtonContinue.text = tr("KeepPlaying")
	$Card/Actions/ButtonRestart.text = tr("RestartPuzzle")
	$Card/Actions/ButtonOptions/Row/Text.text = tr("Options").to_upper()
	$Card/Actions/ButtonExit.text = tr("ExitToMenu")
	$Card/SaveNote.text = tr("ProgressAutoSaved")


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _on_button_seguir_pressed() -> void:
	SoundManager.play("ButtonClick")
	SoundManager.fade_to_game_music()
	get_tree().paused = false
	queue_free()


func _on_button_reiniciar_pressed() -> void:
	SoundManager.play("ButtonClick")
	SoundManager.fade_to_game_music()
	PuzzleSaveManager.reset_resolution_keep_attempt()
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()


func _on_button_options_pressed() -> void:
	SoundManager.play("ButtonClick")
	if has_node("SettingsOverlay"):
		return
	var overlay := SETTINGS_SCENE.instantiate()
	overlay.name = "SettingsOverlay"
	overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(overlay)
	if overlay is Control:
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_button_salir_pressed() -> void:
	SoundManager.play("ButtonClick")
	PuzzleSaveManager.save_current_now()
	EventLoggerAutoload.discard_session()
	get_tree().paused = false
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file(PUZZLE_SELECTION)
