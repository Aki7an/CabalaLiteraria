extends Node

func _ready() -> void:
	Distribution.apply_display()
	if Distribution.is_horizontal():
		call_deferred("_open_start_puzzle")
		return
	get_tree().call_deferred("change_scene_to_file", Distribution.home_scene())


func _open_start_puzzle() -> void:
	await PlayerProgress.ensure_loaded()
	PlayerProgress.open_current_puzzle()
