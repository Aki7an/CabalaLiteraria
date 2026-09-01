# App.gd — Godot 4.4
extends Node

const PORTRAIT_SCENE := preload("res://scenes/main/MainPortrait.tscn")

var _current_scene: Node


func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	_swap_scene(PORTRAIT_SCENE)


func _swap_scene(packed: PackedScene) -> void:
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = packed.instantiate()
	add_child(_current_scene)
