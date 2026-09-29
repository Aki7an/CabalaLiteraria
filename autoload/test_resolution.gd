extends Node

# Tope de F5: la ventana cabe en Full HD y deja ver la barra de título para poder moverla.
var WINDOW_SCALE := 0.5
const SCREEN_USAGE := 0.82
const TITLE_BAR := 48
const DESKTOP_PLATFORMS := ["Windows", "Linux", "macOS"]
const PLAYBACK_MAX := Vector2i(1920, 1080)
const GAME_SIZE := Vector2i(1206, 2622)

var _placed := false


func _ready() -> void:
	if OS.has_feature("movie"):
		return
	if not OS.is_debug_build():
		return
	if not DESKTOP_PLATFORMS.has(OS.get_name()):
		return
	_apply_for_current_scene()
	call_deferred("_apply_for_current_scene")
	if get_tree() != null:
		get_tree().process_frame.connect(_apply_for_current_scene, CONNECT_ONE_SHOT)


func _apply_for_current_scene() -> void:
	if _is_trailer_scene():
		return
	_apply_game_window()


func _is_trailer_scene() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var path := str(scene.scene_file_path)
	return (
		path.begins_with("res://scenes/trailer/")
		or path.begins_with("res://scenes/trailer_reboot/")
		or path.contains("trailer_cinematic")
		or path.contains("trailer_resumen")
		or path.contains("fondo_fullhd")
	)


func _apply_game_window() -> void:
	var win := get_window()
	if win == null:
		return
	var design := _game_design_size()
	var target := _fit_window(design.x, design.y, WINDOW_SCALE)

	win.mode = Window.MODE_WINDOWED
	win.borderless = false
	win.unresizable = false
	win.min_size = Vector2i(0, 0)
	win.max_size = PLAYBACK_MAX
	win.size = target
	win.content_scale_size = design
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	DisplayServer.window_set_size(target)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

	if _placed:
		return
	_placed = true
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var pos := usable.position + (usable.size - target) / 2
	pos.y = maxi(usable.position.y + TITLE_BAR, pos.y)
	win.position = pos
	DisplayServer.window_set_position(pos)


func _game_design_size() -> Vector2i:
	var vw: int = int(ProjectSettings.get_setting("display/window/size/viewport_width", GAME_SIZE.x))
	var vh: int = int(ProjectSettings.get_setting("display/window/size/viewport_height", GAME_SIZE.y))
	if vw > vh:
		return GAME_SIZE
	return Vector2i(vw, vh)


func _fit_window(vw: int, vh: int, requested_scale: float) -> Vector2i:
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var box := Vector2(
		minf(float(usable.size.x) * SCREEN_USAGE, float(PLAYBACK_MAX.x)),
		minf(float(usable.size.y) * SCREEN_USAGE - float(TITLE_BAR), float(PLAYBACK_MAX.y) - float(TITLE_BAR))
	)
	var fit_scale := minf(box.x / float(vw), box.y / float(vh))
	var final_scale := clampf(minf(requested_scale, fit_scale), 0.1, 1.0)
	return Vector2i(
		maxi(1, roundi(float(vw) * final_scale)),
		maxi(1, roundi(float(vh) * final_scale))
	)
