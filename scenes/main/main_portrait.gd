extends Node2D

const scene_to_load = preload("res://scenes/MenuResults.tscn")

func _ready():
	SignalManager.game_finished_to_results.connect(_game_finished_to_results)
	await get_tree().process_frame
	await get_tree().process_frame
	PuzzleSaveManager.begin_current_puzzle()
	await PuzzleSaveManager.restore_current_puzzle()
	var panel_up := get_node_or_null("CanvasLayer/PanelUP")
	if panel_up != null and panel_up.has_method("resume_saved_time"):
		panel_up.call("resume_saved_time")

func _game_finished_to_results() -> void:
	#finished game
	# check if game has been completed OK or not.
	# go to result screen
	#print(GameManager.frase_original)
	
	# transition to results

	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(scene_to_load)
