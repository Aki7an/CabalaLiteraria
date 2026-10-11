extends Node2D


func _on_button_back_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file(Distribution.home_scene())
	SoundManager.play("ButtonClick")
