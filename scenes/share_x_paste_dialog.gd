extends ColorRect

signal finished(confirmed: bool)

const FONT_TITLE: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_BODY: Font = preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const EXAMPLE_PATH := "res://images/x_paste_example.png"
const COLOR_INK := Color(0.24, 0.17, 0.12, 1)

var kind := "x"
var _closed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	var view := get_viewport_rect().size
	if view.x > 0.0 and view.y > 0.0:
		size = view
	color = Color(0.08, 0.04, 0.02, 0.58)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	_build()


func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(980, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _card_style())
	center.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_bottom", 40)
	card.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(col)

	var title := Label.new()
	title.text = _title_text()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", COLOR_INK)
	col.add_child(title)

	var body := Label.new()
	body.text = _body_text()
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", FONT_BODY)
	body.add_theme_font_size_override("font_size", 40)
	body.add_theme_color_override("font_color", COLOR_INK)
	col.add_child(body)

	if _shows_example():
		var picture := TextureRect.new()
		picture.texture = _example_texture()
		picture.custom_minimum_size = Vector2(0, 620)
		picture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(picture)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 24)
	col.add_child(actions)

	var cancel := _make_button(_t("ShareXPasteCancel", "CANCELAR"), false)
	cancel.pressed.connect(_close.bind(false))
	actions.add_child(cancel)

	var ok := _make_button(_t("ShareXPasteContinue", "CONTINUAR"), true)
	ok.pressed.connect(_close.bind(true))
	actions.add_child(ok)


func _make_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 120)
	button.add_theme_font_override("font", FONT_UI)
	button.add_theme_font_size_override("font_size", 40)
	button.add_theme_color_override("font_color", Color.WHITE if primary else COLOR_INK)
	button.add_theme_stylebox_override("normal", _btn_style(primary, false))
	button.add_theme_stylebox_override("hover", _btn_style(primary, false))
	button.add_theme_stylebox_override("pressed", _btn_style(primary, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _close(confirmed: bool) -> void:
	if _closed:
		return
	_closed = true
	SoundManager.play("ButtonClick")
	finished.emit(confirmed)
	queue_free()


func _title_text() -> String:
	match kind:
		"facebook":
			return _t("ShareFacebookPasteTitle", "Compartir en Facebook")
		"more":
			return _t("ShareMorePasteTitle", "Compartir")
		_:
			return _t("ShareXPasteTitle", "Compartir en X")


func _body_text() -> String:
	match kind:
		"facebook":
			return _t(
				"ShareFacebookPasteBody",
				"La tarjeta y el texto están en el portapapeles.\n\nEn Facebook, pégalos en el mensaje a publicar."
			)
		"more":
			return _t(
				"ShareMorePasteBody",
				"El mensaje está en el portapapeles.\n\nPégalo al compartir en la red que elijas."
			)
		_:
			return _t(
				"ShareXPasteBody",
				"La tarjeta y el texto están en el portapapeles.\n\nEn X, pégalos en el mensaje a publicar."
			)


func _shows_example() -> bool:
	return kind == "x"


func _example_texture() -> Texture2D:
	var imported: Resource = load(EXAMPLE_PATH)
	if imported is Texture2D:
		return imported
	var bytes := FileAccess.get_file_as_bytes(EXAMPLE_PATH)
	if bytes.is_empty():
		return null
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK and image.load_jpg_from_buffer(bytes) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _t(key: String, fallback: String) -> String:
	var value := tr(key)
	return fallback if value == key or value.is_empty() else value


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.996, 0.973, 0.906, 1)
	style.border_color = Color(0.62, 0.42, 0.2, 0.5)
	style.set_border_width_all(3)
	style.border_width_bottom = 8
	style.set_corner_radius_all(36)
	style.shadow_color = Color(0.14, 0.08, 0.03, 0.34)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 17)
	return style


func _btn_style(primary: bool, pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(28)
	style.set_border_width_all(3)
	style.border_width_bottom = 8 if not pressed else 4
	style.border_width_top = 8 if pressed else 3
	if primary:
		style.bg_color = Color(0.9, 0.4, 0.045, 1) if pressed else Color(1, 0.53, 0.08, 1)
		style.border_color = Color(0.74, 0.3, 0.025, 1)
	else:
		style.bg_color = Color(1, 0.982, 0.92, 1)
		style.border_color = Color(0.66, 0.44, 0.2, 0.48)
	return style
