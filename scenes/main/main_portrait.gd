extends Node2D

const scene_to_load = preload("res://scenes/MenuResults.tscn")

func _ready():
	SignalManager.game_finished_to_results.connect(_game_finished_to_results)

func _game_finished_to_results() -> void:
	#finished game
	# check if game has been completed OK or not.
	# go to result screen
	#print(GameManager.frase_original)
	
	# transition to results

	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(scene_to_load)
