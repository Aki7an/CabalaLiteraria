extends ColorRect

const PUZZLE_SELECTION := "res://scenes/MenuSelectLevelByID.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	$Card/Title.text = tr("PauseTitle")
	$Card/Subtitle.text = tr("PauseSavedWhilePlaying")
	$Card/Actions/ButtonContinue.text = tr("KeepPlaying")
	$Card/Actions/ButtonRestart.text = tr("RestartPuzzle")
	$Card/Actions/ButtonExit.text = tr("ExitToMenu")
	$Card/SaveNote.text = tr("ProgressAutoSaved")


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _on_button_seguir_pressed() -> void:
	SoundManager.play("ButtonClick")
	get_tree().paused = false
	queue_free()


func _on_button_reiniciar_pressed() -> void:
	SoundManager.play("ButtonClick")
	PuzzleSaveManager.reset_resolution_keep_attempt()
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()


func _on_button_salir_pressed() -> void:
	SoundManager.play("ButtonClick")
	PuzzleSaveManager.save_current_now()
	get_tree().paused = false
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file(PUZZLE_SELECTION)
