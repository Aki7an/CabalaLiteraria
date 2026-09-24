extends ColorRect

const PUZZLE_SELECTION := "res://scenes/MenuSelectLevelByID.tscn"
const SETTINGS_SCENE := preload("res://scenes/MenuSettings.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	z_index = 120
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
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tree := get_tree()
	GameManager.puzzle_enter_pending = true
	if GameManager.is_onboarding_session():
		var stage := GameManager.onboarding_stage
		if stage < 1:
			stage = 1
		for node in tree.get_nodes_in_group("OnboardingGuide"):
			if is_instance_valid(node):
				node.process_mode = Node.PROCESS_MODE_DISABLED
				node.queue_free()
		GameManager.prepare_onboarding_puzzle(stage)
		GameManager.clear_resolution_runtime_state()
	else:
		PuzzleSaveManager.reset_resolution_keep_attempt()
	tree.paused = false
	tree.change_scene_to_file("res://scenes/App.tscn")


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
	process_mode = Node.PROCESS_MODE_ALWAYS
	PuzzleSaveManager.save_current_now()
	await EventLoggerAutoload.submit_if_consented(EventLoggerAutoload.OUTCOME_ABANDONED)
	var tree := get_tree()
	var leaving_onboarding := GameManager.is_onboarding_session()
	if leaving_onboarding:
		for node in tree.get_nodes_in_group("OnboardingGuide"):
			if is_instance_valid(node):
				node.process_mode = Node.PROCESS_MODE_DISABLED
				node.queue_free()
		GameManager.session_source = GameManager.SOURCE_NONE
		GameManager.onboarding_stage = 0
	tree.paused = false
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if not is_instance_valid(tree):
		return
	if leaving_onboarding:
		tree.change_scene_to_file("res://scenes/MenuMain.tscn")
		return
	tree.change_scene_to_file(PUZZLE_SELECTION)
