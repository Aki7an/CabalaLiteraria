extends ColorRect

const scene_to_load_MainMenu = preload("res://scenes/MenuMain.tscn")

func _on_button_seguir_pressed():
	queue_free()


func _on_button_salir_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(scene_to_load_MainMenu)
	SoundManager.play("ButtonClick")
