@tool
extends Node2D

enum Orientation { PORTRAIT, LANDSCAPE }

@export var preview_enabled := true : set = _set_preview_enabled
@export_enum("PORTRAIT", "LANDSCAPE") var preview_orientation: int = Orientation.LANDSCAPE : set = _set_preview_orientation
@export var design_portrait := Vector2(800, 1280)
@export var design_landscape := Vector2(1280, 800)
@export var background_path: NodePath = ^"Background" # Sprite2D opcional

var _design_size := Vector2.ZERO

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_update_preview()

func _ready() -> void:
	if not Engine.is_editor_hint():
		if get_window():
			get_window().size_changed.connect(_on_resize)
	_on_resize()
	set_landscape()

func _set_preview_enabled(v: bool) -> void:
	preview_enabled = v
	_update_preview()

func _set_preview_orientation(o: int) -> void:
	preview_orientation = o
	_update_preview()

func _update_preview() -> void:
	if not Engine.is_editor_hint():
		return
	_design_size = design_landscape if preview_orientation == Orientation.LANDSCAPE else design_portrait
	queue_redraw()
	# Escala del fondo en el editor (si hay Sprite2D llamado en background_path)
	var bg := get_node_or_null(background_path)
	if bg and bg is Sprite2D and preview_enabled:
		var tex := (bg as Sprite2D).texture
		if tex:
			var s : float = max(_design_size.x / tex.get_size().x, _design_size.y / tex.get_size().y)
			(bg as Sprite2D).scale = Vector2(s, s)
			(bg as Sprite2D).position = _design_size * 0.5

func _draw() -> void:
	if Engine.is_editor_hint() and preview_enabled:
		# Marco de “lienzo” de diseño para colocar elementos con proporción real
		draw_rect(Rect2(Vector2.ZERO, _design_size), Color(0,0,0,0), false, 2.0)
		draw_rect(Rect2(Vector2.ZERO, _design_size), Color(0.1,0.1,0.1,0.05), true)

func _on_resize() -> void:
	# En juego real: cubrir viewport con el fondo
	var bg := get_node_or_null(background_path)
	if bg and bg is Sprite2D:
		var tex := (bg as Sprite2D).texture
		if tex:
			var vp := get_viewport().get_visible_rect().size
			var s : float = max(vp.x / tex.get_size().x, vp.y / tex.get_size().y)
			(bg as Sprite2D).scale = Vector2(s, s)
			(bg as Sprite2D).position = vp * 0.5

# En cualquier script (Godot 4.4)
func set_portrait() -> void:
	var win := get_window()
	if win:
		win.size = Vector2i(1024, 1920)  # portrait
		# opcional: recolocar
		var r := DisplayServer.screen_get_usable_rect()
		win.position = r.position + Vector2i(64, 64)

func set_landscape() -> void:
	var win := get_window()
	if win:
		win.size = Vector2i(1920, 1024)  # landscape
		var r := DisplayServer.screen_get_usable_rect()
		win.position = r.position + Vector2i(64, 64)
