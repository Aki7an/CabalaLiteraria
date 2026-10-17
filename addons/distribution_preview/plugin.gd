@tool
extends EditorPlugin

const SETTING := "cifraletra/distribution/editor_preview"
const OPTIONS := ["mobile_store", "crazygames", "web_demo"]
const LABELS := ["Móvil (Android / iOS)", "CrazyGames", "Web demo"]
const WINDOW_WIDTH := "display/window/size/window_width_override"
const WINDOW_HEIGHT := "display/window/size/window_height_override"
const MOBILE_WINDOW := Vector2i(430, 936)
const CRAZYGAMES_WINDOW := Vector2i(821, 462)

var _dock: Control
var _option: OptionButton


func _enter_tree() -> void:
	_register_setting()
	var margin := MarginContainer.new()
	margin.name = "Distribución"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title := Label.new()
	title.text = "Previsualización F5"
	box.add_child(title)
	_option = OptionButton.new()
	for label in LABELS:
		_option.add_item(label)
	_option.item_selected.connect(_on_selected)
	box.add_child(_option)
	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Las etiquetas del preset de exportación no se activan al pulsar F5. Esta elección decide qué interfaz abre el editor. CrazyGames abre la ventana a 821×462, densidad 1, sobre la base 1280×720."
	box.add_child(note)
	_dock = margin
	_select_current()
	_sync_window_override()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, _dock)


func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
	_option = null


func _register_setting() -> void:
	if not ProjectSettings.has_setting(SETTING):
		ProjectSettings.set_setting(SETTING, "crazygames")
	ProjectSettings.add_property_info({
		"name": SETTING,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "mobile_store,crazygames,web_demo",
	})
	ProjectSettings.set_initial_value(SETTING, "crazygames")
	ProjectSettings.set_as_basic(SETTING, true)


func _select_current() -> void:
	if _option == null:
		return
	var value := str(ProjectSettings.get_setting(SETTING, "crazygames"))
	var index := OPTIONS.find(value)
	if index < 0:
		index = 1
	_option.set_block_signals(true)
	_option.select(index)
	_option.set_block_signals(false)


func _on_selected(index: int) -> void:
	if index < 0 or index >= OPTIONS.size():
		return
	ProjectSettings.set_setting(SETTING, OPTIONS[index])
	_sync_window_override()


func _sync_window_override() -> void:
	var preview := str(ProjectSettings.get_setting(SETTING, "crazygames"))
	var target := CRAZYGAMES_WINDOW if preview == "crazygames" else MOBILE_WINDOW
	var width := int(ProjectSettings.get_setting(WINDOW_WIDTH, 0))
	var height := int(ProjectSettings.get_setting(WINDOW_HEIGHT, 0))
	if width == target.x and height == target.y:
		return
	ProjectSettings.set_setting(WINDOW_WIDTH, target.x)
	ProjectSettings.set_setting(WINDOW_HEIGHT, target.y)
	_patch_project_file(preview, target)


func _patch_project_file(preview: String, target: Vector2i) -> void:
	var path := ProjectSettings.globalize_path("res://project.godot")
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return
	text = _replace_setting_line(text, "window/size/window_width_override=", "window/size/window_width_override=%d" % target.x)
	text = _replace_setting_line(text, "window/size/window_height_override=", "window/size/window_height_override=%d" % target.y)
	var preview_line := "distribution/editor_preview=\"%s\"" % preview
	if text.contains("distribution/editor_preview="):
		text = _replace_setting_line(text, "distribution/editor_preview=", preview_line)
	else:
		text = text.rstrip("\n") + "\n\n[cifraletra]\n\n%s\n" % preview_line
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)
	file.close()


func _replace_setting_line(text: String, prefix: String, replacement: String) -> String:
	var lines := text.split("\n")
	for i in lines.size():
		if lines[i].begins_with(prefix):
			lines[i] = replacement
	return "\n".join(lines)
