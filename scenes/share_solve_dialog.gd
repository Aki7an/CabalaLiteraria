extends ColorRect

signal finished

const FONT_TITLE: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_BODY: Font = preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")

const COLOR_INK := Color(0.24, 0.17, 0.12, 1)
const COLOR_MUTED := Color(0.40, 0.28, 0.16, 0.90)
const COLOR_CHECK_ON := Color(0.93, 0.84, 0.68, 1)
const COLOR_CHECK_OFF := Color(1, 0.98, 0.93, 1)

var _share_btn: Button
var _share_box: Panel
var _share_mark: Label
var _hide_btn: Button
var _hide_box: Panel
var _hide_mark: Label
var _closed := false


func _ready() -> void:
	add_to_group("ShareSolveDialog")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.10, 0.06, 0.03, 0.62)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 40
	_build()


func _build() -> void:
	var card := Panel.new()
	card.position = Vector2(72, 560)
	card.size = Vector2(1062, 1360)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _card_style())
	add_child(card)

	var title := Label.new()
	title.position = Vector2(48, 48)
	title.size = Vector2(966, 120)
	title.text = _t("ShareSolveTitle", "Ayúdanos a mejorar")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 66)
	title.add_theme_color_override("font_color", COLOR_INK)
	card.add_child(title)

	var ask := Label.new()
	ask.position = Vector2(56, 186)
	ask.size = Vector2(950, 300)
	ask.text = _t(
		"ShareSolveAsk",
		"¿Quieres compartir los datos de la resolución del puzle con el desarrollador para mejorar los puzles?"
	)
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ask.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ask.add_theme_font_override("font", FONT_BODY)
	ask.add_theme_font_size_override("font_size", 42)
	ask.add_theme_color_override("font_color", COLOR_INK)
	card.add_child(ask)

	var share_row := _make_check_row(
		_t("ShareSolveCheck", "Compartir datos de resolución"),
		PlayerPrefs.share_solve_data
	)
	share_row["row"].position = Vector2(56, 500)
	share_row["row"].size = Vector2(950, 130)
	card.add_child(share_row["row"])
	_share_btn = share_row["button"]
	_share_box = share_row["box"]
	_share_mark = share_row["mark"]
	_share_btn.toggled.connect(_on_share_toggled)

	var hide_row := _make_check_row(
		_t("ShareSolveDontShow", "No volver a mostrar este diálogo"),
		false
	)
	hide_row["row"].position = Vector2(56, 680)
	hide_row["row"].size = Vector2(950, 130)
	card.add_child(hide_row["row"])
	_hide_btn = hide_row["button"]
	_hide_box = hide_row["box"]
	_hide_mark = hide_row["mark"]
	_hide_btn.toggled.connect(_on_hide_toggled)

	var hint := Label.new()
	hint.position = Vector2(56, 820)
	hint.size = Vector2(950, 110)
	hint.text = _t(
		"ShareSolveChangeHint",
		"(Esta selección se puede cambiar desde el menú de opciones)"
	)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_override("font", FONT_BODY)
	hint.add_theme_font_size_override("font_size", 34)
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	card.add_child(hint)

	var continue_btn := Button.new()
	continue_btn.position = Vector2(196, 1080)
	continue_btn.size = Vector2(670, 168)
	continue_btn.text = tr("CONTINUE")
	if continue_btn.text == "CONTINUE":
		continue_btn.text = "CONTINUAR"
	continue_btn.focus_mode = Control.FOCUS_NONE
	continue_btn.add_theme_font_override("font", FONT_UI)
	continue_btn.add_theme_font_size_override("font_size", 62)
	continue_btn.add_theme_color_override("font_color", Color(1, 0.996, 0.94, 1))
	continue_btn.add_theme_stylebox_override("normal", _ok_style(false))
	continue_btn.add_theme_stylebox_override("hover", _ok_style(false))
	continue_btn.add_theme_stylebox_override("pressed", _ok_style(true))
	continue_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	continue_btn.pressed.connect(_on_continue_pressed)
	card.add_child(continue_btn)


func _make_check_row(text: String, checked: bool) -> Dictionary:
	var button := Button.new()
	button.toggle_mode = true
	button.button_pressed = checked
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 22)
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8
	row.offset_right = -8

	var box := Panel.new()
	box.custom_minimum_size = Vector2(62, 62)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_theme_stylebox_override("panel", _check_style(checked))
	row.add_child(box)

	var mark := Label.new()
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.text = "✓" if checked else ""
	mark.add_theme_font_override("font", FONT_TITLE)
	mark.add_theme_font_size_override("font_size", 38)
	mark.add_theme_color_override("font_color", COLOR_INK)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(mark)

	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_BODY)
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", COLOR_INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	return {
		"row": button,
		"button": button,
		"box": box,
		"mark": mark,
	}


func _on_share_toggled(pressed: bool) -> void:
	SoundManager.play("ButtonClick")
	_apply_check(_share_box, _share_mark, pressed)


func _on_hide_toggled(pressed: bool) -> void:
	SoundManager.play("ButtonClick")
	_apply_check(_hide_box, _hide_mark, pressed)


func _apply_check(box: Panel, mark: Label, pressed: bool) -> void:
	mark.text = "✓" if pressed else ""
	box.add_theme_stylebox_override("panel", _check_style(pressed))


func _on_continue_pressed() -> void:
	if _closed:
		return
	_closed = true
	SoundManager.play("ButtonClick")
	PlayerPrefs.set_share_solve_data(_share_btn.button_pressed)
	PlayerPrefs.set_hide_share_solve_dialog(_hide_btn.button_pressed)
	finished.emit()
	queue_free()


func _t(key: String, fallback: String) -> String:
	var translated := tr(key)
	return fallback if translated == key else translated


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


func _check_style(on: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_CHECK_ON if on else COLOR_CHECK_OFF
	style.border_color = Color(0.42, 0.26, 0.12, 1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	return style


func _ok_style(pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.51, 0.13, 1) if pressed else Color(0.96, 0.55, 0.13, 1)
	style.border_color = Color(0.62, 0.28, 0.04, 1)
	style.set_border_width_all(4)
	style.border_width_bottom = 10
	style.set_corner_radius_all(28)
	return style
