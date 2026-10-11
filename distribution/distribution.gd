extends Node

const MOBILE := "mobile_store"
const CRAZYGAMES := "crazygames"
const WEB_DEMO := "web_demo"
const PREVIEW_SETTING := "cifraletra/distribution/editor_preview"

const SCENE_MOBILE := "res://scenes/mobile/MobileMain.tscn"
const SCENE_CRAZY := "res://scenes/crazygames/CrazyGamesMain.tscn"

const DESIGN_MOBILE := Vector2i(1206, 2622)
const DESIGN_WEB := Vector2i(1280, 720)
const PREVIEW_WEB_WINDOW := Vector2i(821, 462)

var _preview_hold := 0

func current() -> String:
	if OS.has_feature(CRAZYGAMES):
		return CRAZYGAMES
	if OS.has_feature(WEB_DEMO):
		return WEB_DEMO
	if OS.has_feature(MOBILE):
		return MOBILE
	if running_from_editor():
		return editor_preview()
	if OS.has_feature("android") or OS.has_feature("ios"):
		return MOBILE
	if OS.has_feature("web"):
		return CRAZYGAMES
	return MOBILE


func editor_preview() -> String:
	var value := str(ProjectSettings.get_setting(PREVIEW_SETTING, MOBILE))
	if value == CRAZYGAMES or value == WEB_DEMO or value == MOBILE:
		return value
	return MOBILE


func is_horizontal() -> bool:
	return current() == CRAZYGAMES


func home_scene() -> String:
	if is_horizontal():
		return SCENE_CRAZY
	return SCENE_MOBILE


func _ready() -> void:
	call_deferred("apply_display")


func running_from_editor() -> bool:
	if Engine.is_editor_hint():
		return false
	if OS.has_feature("template"):
		return false
	return OS.is_debug_build() or Engine.is_embedded_in_editor()


func apply_display() -> void:
	if Engine.has_meta("store_screenshot") or not is_horizontal() or _skip_display():
		return
	var win := get_window()
	if win == null:
		return
	win.content_scale_factor = 1.0
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	if running_from_editor():
		_apply_preview_window(win)
		if _preview_hold <= 0:
			_preview_hold = 20
			if get_tree() != null and not get_tree().process_frame.is_connected(_keep_preview_window):
				get_tree().process_frame.connect(_keep_preview_window)
		return
	win.content_scale_size = DESIGN_WEB
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND


func _apply_preview_window(win: Window) -> void:
	win.content_scale_factor = 1.0
	win.content_scale_size = PREVIEW_WEB_WINDOW
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	if Engine.is_embedded_in_editor():
		return
	win.mode = Window.MODE_WINDOWED
	win.borderless = false
	win.unresizable = false
	win.min_size = Vector2i(0, 0)
	win.size = PREVIEW_WEB_WINDOW
	DisplayServer.window_set_size(PREVIEW_WEB_WINDOW)
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var pos := usable.position + (usable.size - PREVIEW_WEB_WINDOW) / 2
	pos.y = maxi(usable.position.y + 48, pos.y)
	win.position = pos
	DisplayServer.window_set_position(pos)


func _keep_preview_window() -> void:
	var stop := true
	if _preview_hold > 0 and is_horizontal() and running_from_editor():
		var win := get_window()
		if win != null and win.size != PREVIEW_WEB_WINDOW:
			_apply_preview_window(win)
		_preview_hold -= 1
		stop = _preview_hold <= 0
	if stop:
		_preview_hold = 0
		var tree := get_tree()
		if tree != null and tree.process_frame.is_connected(_keep_preview_window):
			tree.process_frame.disconnect(_keep_preview_window)


func _skip_display() -> bool:
	if OS.has_feature("movie"):
		return true
	var scene := get_tree().current_scene if get_tree() != null else null
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
