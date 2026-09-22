extends Node2D

const scene_to_load = preload("res://scenes/MenuResults.tscn")
const BASIC_TUTORIAL := preload("res://scenes/basic_start_tutorial.tscn")
const LEVEL_INTRO := preload("res://scenes/level_start_intro.gd")

func _ready():
	SignalManager.game_finished_to_results.connect(_game_finished_to_results)
	var show_intro := _should_show_level_intro()
	await get_tree().process_frame
	await get_tree().process_frame
	PuzzleSaveManager.begin_current_puzzle()
	await PuzzleSaveManager.restore_current_puzzle()
	SignalManager.añade_las_letras_iniciales.emit()
	GameManager.update_numero_letras_reveladas()
	SignalManager.update_puzzle_stars.emit(GameManager.puzzle_stars)
	var panel_up := get_node_or_null("CanvasLayer/PanelUP")
	if panel_up != null and panel_up.has_method("resume_saved_time"):
		panel_up.call("resume_saved_time")
	if panel_up != null and panel_up.has_method("refresh_hud"):
		panel_up.call("refresh_hud")
	if show_intro:
		call_deferred("_show_level_intro")
	elif PlayerPrefs.mostrar_tuto_antes_partida:
		call_deferred("_show_basic_tutorial")


func _should_show_level_intro() -> bool:
	if Engine.has_meta("store_screenshot") and bool(Engine.get_meta("store_screenshot")):
		return false
	if get_tree().get_first_node_in_group("LevelStartIntro"):
		return false
	var status := str(PuzzleSaveManager.get_puzzle_summary(GameManager.id_frase).get("status", "new"))
	return status != "in_progress"


func _show_level_intro() -> void:
	var host := _overlay_host()
	if host == null:
		return
	var intro := LEVEL_INTRO.new()
	intro.finished.connect(_on_level_intro_closed)
	host.add_child(intro)
	if intro is Control:
		intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		intro.size = host.size


func _on_level_intro_closed() -> void:
	if not is_inside_tree():
		return
	if PlayerPrefs.mostrar_tuto_antes_partida:
		_show_basic_tutorial()


func _show_basic_tutorial() -> void:
	if get_tree().get_first_node_in_group("BasicStartTutorial"):
		return
	var host := _overlay_host()
	if host == null:
		return
	host.add_child(BASIC_TUTORIAL.instantiate())


func _overlay_host() -> Control:
	return get_node_or_null("CanvasLayer/OverlayHost") as Control

func _game_finished_to_results() -> void:
	#finished game
	# check if game has been completed OK or not.
	# go to result screen
	#print(GameManager.frase_original)
	
	# transition to results

	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(scene_to_load)
