# App.gd — Godot 4.4
extends Node

enum { PORTRAIT, LANDSCAPE }

const PORTRAIT_SCENE := preload("res://scenes/main/MainPortrait.tscn")
const LANDSCAPE_SCENE := preload("res://scenes/main/MainLandscape.tscn")

const P_SIZE := Vector2i(800, 1280)
const L_SIZE := Vector2i(1280, 800)

var _current_orientation: int = -1
var _current_scene: Node

func _ready() -> void:
	var win := get_window()
	if win:
		win.size_changed.connect(_on_size_changed)
	_apply_layout()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("dev_force_portrait"):
		_set_window_size(P_SIZE)
		_force_orientation(PORTRAIT)
	if Input.is_action_just_pressed("dev_force_landscape"):
		_set_window_size(L_SIZE)
		_force_orientation(LANDSCAPE)

func _set_window_size(sz: Vector2i) -> void:
	var win := get_window()
	if win:
		win.size = sz
		var rect := DisplayServer.screen_get_usable_rect()
		win.position = rect.position + Vector2i(64, 64)

func _on_size_changed() -> void:
	call_deferred("_apply_layout")

func _force_orientation(o: int) -> void:
	var packed: PackedScene = LANDSCAPE_SCENE if o == LANDSCAPE else PORTRAIT_SCENE
	_swap_scene(packed)
	_current_orientation = o
	print("Forced orientation -> ", "LANDSCAPE" if o == LANDSCAPE else "PORTRAIT")

func _apply_layout() -> void:
	var sz := _get_window_size()
	var o := LANDSCAPE if sz.x >= sz.y else PORTRAIT
	if o == _current_orientation:
		return
	var packed: PackedScene = LANDSCAPE_SCENE if o == LANDSCAPE else PORTRAIT_SCENE
	_swap_scene(packed)
	_current_orientation = o
	print("Auto layout -> ", "LANDSCAPE" if o == LANDSCAPE else "PORTRAIT", "  size=", sz)

func _swap_scene(packed: PackedScene) -> void:
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = packed.instantiate()
	add_child(_current_scene)

func _get_window_size() -> Vector2i:
	var win := get_window()
	return win.size if win else DisplayServer.window_get_size()
