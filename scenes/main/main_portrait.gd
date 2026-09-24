extends Node2D

const scene_to_load = preload("res://scenes/MenuResults.tscn")
const ONBOARDING_GUIDE := preload("res://scenes/onboarding_guide.tscn")
const LEVEL_INTRO := preload("res://scenes/level_start_intro.gd")
const ENTER_ANIM := preload("res://scenes/game/puzzle_enter_animation.gd")

func _ready():
	SignalManager.game_finished_to_results.connect(_game_finished_to_results)
	var play_enter: bool = ENTER_ANIM.should_play()
	GameManager.puzzle_enter_pending = play_enter
	if play_enter:
		_prepare_enter_chrome()
	var show_intro := _should_show_level_intro()
	await get_tree().process_frame
	await get_tree().process_frame
	PuzzleSaveManager.begin_current_puzzle()
	await PuzzleSaveManager.restore_current_puzzle()
	if play_enter:
		var layer := get_node_or_null("CanvasLayer") as CanvasLayer
		var anim: Node = ENTER_ANIM.new()
		if layer:
			layer.add_child(anim)
			await anim.play(layer)
			anim.queue_free()
		else:
			GameManager.puzzle_enter_pending = false
			SignalManager.añade_las_letras_iniciales.emit()
	else:
		GameManager.puzzle_enter_pending = false
		SignalManager.añade_las_letras_iniciales.emit()
	GameManager.update_numero_letras_reveladas()
	SignalManager.update_puzzle_stars.emit(GameManager.puzzle_stars)
	var panel_up := get_node_or_null("CanvasLayer/PanelUP")
	if panel_up != null and panel_up.has_method("resume_saved_time"):
		panel_up.call("resume_saved_time")
	if panel_up != null and panel_up.has_method("refresh_hud"):
		panel_up.call("refresh_hud")
	if GameManager.is_onboarding_session():
		call_deferred("_show_onboarding_guide")
	elif show_intro:
		call_deferred("_show_level_intro")


func _prepare_enter_chrome() -> void:
	var layer := get_node_or_null("CanvasLayer")
	if layer == null:
		return
	for path in ["PanelUP/GameHeader", "PanelUP/ButtonReveal", "PanelUP/ButtonHint", "PanelUP/ButtonTheme", "BoardFrame", "PanelColors", "PanelLetras"]:
		var node := layer.get_node_or_null(path) as CanvasItem
		if node:
			node.visible = false
			node.modulate.a = 0.0


func _should_show_level_intro() -> bool:
	if Engine.has_meta("store_screenshot") and bool(Engine.get_meta("store_screenshot")):
		return false
	if GameManager.is_onboarding_session():
		return false
	if get_tree().get_first_node_in_group("LevelStartIntro"):
		return false
	if typeof(HistoryManager) != TYPE_NIL and HistoryManager.count_finished_puzzles_excluding_onboarding() < 2:
		return false
	var status := str(PuzzleSaveManager.get_puzzle_summary(GameManager.id_frase).get("status", "new"))
	return status != "in_progress"


func _show_level_intro() -> void:
	var host := _overlay_host()
	if host == null:
		return
	var intro := LEVEL_INTRO.new()
	host.add_child(intro)
	if intro is Control:
		intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		intro.size = host.size


func _show_onboarding_guide() -> void:
	if get_tree().get_first_node_in_group("OnboardingGuide"):
		return
	var host := _overlay_host()
	if host == null:
		return
	host.add_child(ONBOARDING_GUIDE.instantiate())


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
