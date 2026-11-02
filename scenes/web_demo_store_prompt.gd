extends ColorRect

signal finished

const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const ShareConfig := preload("res://store/share_config.gd")


static func present(host: Node) -> void:
	if Distribution.current() != Distribution.WEB_DEMO:
		return
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return
	var dialog := (load("res://scenes/web_demo_store_prompt.gd") as GDScript).new() as ColorRect
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog.z_index = 200
	host.add_child(dialog)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await dialog.finished
	if is_instance_valid(dialog):
		dialog.queue_free()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.08, 0.04, 0.02, 0.62)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(980, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _card_style())
	center.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 22)
	card.add_child(inner)
	inner.add_child(_label(_text("WebDemoStoreTitle", "Más de 100 puzles"), 48))
	inner.add_child(_label(_text("WebDemoStoreBody", "En la app de iOS y Android puedes jugar gratis a más de 100 puzles."), 34))
	inner.add_child(_link_button("App Store", ShareConfig.STORE_URL_IOS))
	inner.add_child(_link_button("Google Play", ShareConfig.STORE_URL_ANDROID))
	var close := _link_button(_text("ContinueAction", "CONTINUAR"), "")
	close.pressed.connect(_close)
	inner.add_child(close)


func _close() -> void:
	SoundManager.play("ButtonClick")
	finished.emit()


func _open_store(url: String) -> void:
	SoundManager.play("ButtonClick")
	if url.is_empty():
		return
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.open(%s, '_blank', 'noopener')" % JSON.stringify(url), true)
		return
	OS.shell_open(url)


func _text(key: String, fallback: String) -> String:
	var translated := tr(key)
	if translated.is_empty() or translated == key:
		return fallback
	return translated


func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08, 1))
	return label


func _link_button(text: String, url: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 108)
	button.add_theme_font_override("font", FONT_UI)
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	if url.is_empty():
		style.bg_color = Color(0.45, 0.32, 0.18, 1)
		style.border_color = Color(0.28, 0.18, 0.08, 1)
	else:
		style.bg_color = Color(0.12, 0.38, 0.62, 1)
		style.border_color = Color(0.08, 0.24, 0.42, 1)
	style.set_border_width_all(3)
	style.border_width_bottom = 8
	style.set_corner_radius_all(30)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	if not url.is_empty():
		button.pressed.connect(_open_store.bind(url))
	return button


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.965, 0.86, 1)
	style.border_color = Color(0.62, 0.4, 0.16, 0.46)
	style.set_border_width_all(4)
	style.border_width_bottom = 9
	style.set_corner_radius_all(48)
	style.shadow_color = Color(0.14, 0.08, 0.03, 0.34)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 17)
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 40
	style.content_margin_bottom = 36
	return style
