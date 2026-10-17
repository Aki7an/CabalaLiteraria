extends Node


func _ready() -> void:
	Distribution.apply_display()
	get_tree().call_deferred("change_scene_to_file", Distribution.home_scene())
