extends ColorRect

signal finished

const FONT_TITLE: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_BODY: Font = preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const ICON_PENCIL: Texture2D = preload("res://GUI/Library/Demo/Demo_Icon/Icon_WhiteIcon_Pencil.png")
const NAME_MAX_LENGTH := 10

const COLOR_INK := Color(0.32, 0.20, 0.12, 1)
const COLOR_MUTED := Color(0.39, 0.33, 0.25, 1)

var _card: Panel
var _nombre: LineEdit
var _name_slots: HBoxContainer
var _name_slot_style: StyleBoxFlat
var _name_slot_style_active: StyleBoxFlat
var _updating_name := false
var _closed := false
var _card_rest_y := 0.0
var _applied_keyboard_h := -1.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.10, 0.06, 0.03, 0.62)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 50
	_build()
	set_process(true)
	await get_tree().process_frame
	if is_instance_valid(_nombre):
		_nombre.grab_focus()
		_nombre.caret_column = _nombre.text.length()
		_refresh_name_slots()


func _process(_delta: float) -> void:
	_apply_keyboard_inset()
	if is_instance_valid(_nombre) and _nombre.has_focus():
		_refresh_name_slots()


func _build() -> void:
	_card = Panel.new()
	_card.size = Vector2(1062, 1180)
	_card.position = Vector2((size.x - _card.size.x) * 0.5, (size.y - _card.size.y) * 0.42)
	if size.x < 10.0:
		_card.position = Vector2(72, 420)
	_card_rest_y = _card.position.y
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.add_theme_stylebox_override("panel", _card_style())
	add_child(_card)

	var title := Label.new()
	title.position = Vector2(48, 36)
	title.size = Vector2(966, 100)
	title.text = _t("OnlineName", "NOMBRE ONLINE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", COLOR_INK)
	_card.add_child(title)

	var ask := Label.new()
	ask.position = Vector2(56, 130)
	ask.size = Vector2(950, 110)
	ask.text = _t("OnlineNamePromptAsk", "Elige el nombre que se mostrará en las clasificaciones online.")
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ask.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ask.add_theme_font_override("font", FONT_BODY)
	ask.add_theme_font_size_override("font_size", 36)
	ask.add_theme_color_override("font_color", COLOR_INK)
	_card.add_child(ask)

	_name_slots = HBoxContainer.new()
	_name_slots.position = Vector2(48, 268)
	_name_slots.size = Vector2(780, 137)
	_name_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_slots.add_theme_constant_override("separation", 8)
	_name_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(_name_slots)

	_nombre = LineEdit.new()
	_nombre.position = Vector2(48, 268)
	_nombre.size = Vector2(780, 137)
	_nombre.max_length = NAME_MAX_LENGTH
	_nombre.placeholder_text = ""
	_nombre.caret_blink = false
	_nombre.caret_mid_grapheme = true
	_nombre.add_theme_font_override("font", FONT_UI)
	_nombre.add_theme_font_size_override("font_size", 48)
	_nombre.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	_nombre.add_theme_color_override("font_placeholder_color", Color(0, 0, 0, 0))
	_nombre.add_theme_color_override("caret_color", Color(0.04, 0.65, 0.64, 0))
	_nombre.add_theme_color_override("selection_color", Color(0.04, 0.65, 0.64, 0))
	_nombre.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_nombre.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_nombre.text_changed.connect(_on_nombre_text_changed)
	_nombre.text_submitted.connect(_on_nombre_submitted)
	_card.add_child(_nombre)

	var edit_btn := Button.new()
	edit_btn.position = Vector2(848, 286)
	edit_btn.size = Vector2(108, 100)
	edit_btn.focus_mode = Control.FOCUS_NONE
	edit_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	edit_btn.add_theme_stylebox_override("normal", _edit_style(false))
	edit_btn.add_theme_stylebox_override("hover", _edit_style(false))
	edit_btn.add_theme_stylebox_override("pressed", _edit_style(true))
	edit_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	edit_btn.pressed.connect(_on_edit_pressed)
	_card.add_child(edit_btn)

	var pencil := TextureRect.new()
	pencil.position = Vector2(25, 21)
	pencil.size = Vector2(58, 58)
	pencil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pencil.texture = ICON_PENCIL
	pencil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pencil.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	edit_btn.add_child(pencil)

	_build_name_slots()

	var help := Label.new()
	help.position = Vector2(56, 430)
	help.size = Vector2(950, 90)
	help.text = _t("OnlineNameHelp", "Este nombre se mostrará en las clasificaciones y retos online.")
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_font_override("font", FONT_BODY)
	help.add_theme_font_size_override("font_size", 32)
	help.add_theme_color_override("font_color", COLOR_MUTED)
	_card.add_child(help)

	var hint := Label.new()
	hint.position = Vector2(56, 530)
	hint.size = Vector2(950, 180)
	hint.text = _t(
		"OnlineNameChangeHint",
		"Puedes modificar este nombre desde el menú de opciones, en la sección de nombre online."
	)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_override("font", FONT_BODY)
	hint.add_theme_font_size_override("font_size", 34)
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	_card.add_child(hint)

	var continue_btn := Button.new()
	continue_btn.position = Vector2(196, 900)
	continue_btn.size = Vector2(670, 168)
	continue_btn.text = _t("ContinueAction", "CONTINUAR")
	continue_btn.focus_mode = Control.FOCUS_NONE
	continue_btn.add_theme_font_override("font", FONT_UI)
	continue_btn.add_theme_font_size_override("font_size", 58)
	continue_btn.add_theme_color_override("font_color", Color(1, 0.996, 0.94, 1))
	continue_btn.add_theme_stylebox_override("normal", _ok_style(false))
	continue_btn.add_theme_stylebox_override("hover", _ok_style(false))
	continue_btn.add_theme_stylebox_override("pressed", _ok_style(true))
	continue_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	continue_btn.pressed.connect(_on_continue_pressed)
	_card.add_child(continue_btn)


func _on_edit_pressed() -> void:
	_nombre.grab_focus()
	_nombre.caret_column = _nombre.text.length()
	_refresh_name_slots()


func _on_nombre_text_changed(new_text: String) -> void:
	if _updating_name:
		return
	var caret := _nombre.caret_column
	var sanitized := _sanitize_player_name(new_text)
	if sanitized != new_text:
		var removed := new_text.length() - sanitized.length()
		_set_nombre_text(sanitized)
		_nombre.caret_column = clampi(caret - removed, 0, sanitized.length())
	else:
		_refresh_name_slots()


func _on_nombre_submitted(new_text: String) -> void:
	_set_nombre_text(_sanitize_player_name(new_text))
	_nombre.release_focus()
	_refresh_name_slots()


func _on_continue_pressed() -> void:
	if _closed:
		return
	_closed = true
	SoundManager.play("ButtonClick")
	_save_online_name()
	finished.emit()
	queue_free()


func _save_online_name() -> void:
	var cleaned := _sanitize_player_name(_nombre.text)
	if cleaned == "":
		return
	GameManager.set_player_name(cleaned)
	PlayerPrefs.save_prefs()
	if GameManager.has_chosen_online_name() and typeof(PlayFabTools) != TYPE_NIL:
		PlayFabTools.sync_player_display_name(GameManager.player_name)


func _sanitize_player_name(text: String) -> String:
	var out := ""
	for i in text.length():
		var ch := text.substr(i, 1)
		if not _is_alphanumeric_char(ch):
			continue
		out += ch
		if out.length() >= NAME_MAX_LENGTH:
			break
	return out


func _is_alphanumeric_char(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code := ch.unicode_at(0)
	return (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or (code >= 48 and code <= 57)


func _set_nombre_text(value: String) -> void:
	_updating_name = true
	_nombre.text = value
	_updating_name = false
	_refresh_name_slots()


func _build_name_slots() -> void:
	_name_slot_style = StyleBoxFlat.new()
	_name_slot_style.bg_color = Color(1.0, 0.984, 0.925, 0.92)
	_name_slot_style.border_color = Color(0.77, 0.62, 0.40, 0.55)
	_name_slot_style.set_border_width_all(2)
	_name_slot_style.border_width_bottom = 6
	_name_slot_style.set_corner_radius_all(14)
	_name_slot_style_active = _name_slot_style.duplicate()
	_name_slot_style_active.border_color = Color(0.04, 0.65, 0.64, 0.95)
	_name_slot_style_active.set_border_width_all(3)
	_name_slot_style_active.border_width_bottom = 7
	for _i in NAME_MAX_LENGTH:
		var slot := Panel.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("panel", _name_slot_style)
		var letter := Label.new()
		letter.name = "Letter"
		letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter.set_anchors_preset(Control.PRESET_FULL_RECT)
		letter.add_theme_font_override("font", FONT_UI)
		letter.add_theme_font_size_override("font_size", 46)
		letter.add_theme_color_override("font_color", Color(0.34, 0.22, 0.15, 1))
		slot.add_child(letter)
		_name_slots.add_child(slot)
	_refresh_name_slots()


func _refresh_name_slots() -> void:
	if _name_slots == null or _nombre == null:
		return
	var value := _nombre.text
	var caret := _nombre.caret_column if _nombre.has_focus() else -1
	for i in _name_slots.get_child_count():
		var slot := _name_slots.get_child(i) as Panel
		if slot == null:
			continue
		var letter := slot.get_node_or_null("Letter") as Label
		if letter:
			if i < value.length():
				letter.text = value.substr(i, 1)
				letter.modulate.a = 1.0
			else:
				letter.text = "_"
				letter.modulate.a = 0.28
		var is_active := _nombre.has_focus() and i == mini(caret, NAME_MAX_LENGTH - 1)
		slot.add_theme_stylebox_override(
			"panel",
			_name_slot_style_active if is_active else _name_slot_style
		)


func _apply_keyboard_inset() -> void:
	if _card == null:
		return
	var kb := _virtual_keyboard_height()
	if is_equal_approx(kb, _applied_keyboard_h):
		return
	_applied_keyboard_h = kb
	var target := _card_rest_y
	if kb > 1.0:
		target = maxf(40.0, size.y - kb - _card.size.y - 24.0)
	_card.position.y = target


func _virtual_keyboard_height() -> float:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return 0.0
	var kb := float(DisplayServer.virtual_keyboard_get_height())
	if kb <= 0.0:
		return 0.0
	var win_h := float(DisplayServer.window_get_size().y)
	if win_h <= 1.0:
		return kb
	return kb * get_viewport_rect().size.y / win_h


func _t(key: String, fallback: String) -> String:
	var translated := tr(key)
	return fallback if translated.is_empty() or translated == key else translated


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.973, 0.882, 1)
	style.border_color = Color(0.79, 0.60, 0.31, 0.62)
	style.set_border_width_all(3)
	style.border_width_bottom = 8
	style.set_corner_radius_all(48)
	style.shadow_color = Color(0.35, 0.21, 0.11, 0.22)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 14)
	return style


func _edit_style(pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.027, 0.53, 0.53, 1) if pressed else Color(0.039, 0.647, 0.643, 1)
	style.border_color = Color(0.02, 0.43, 0.43, 1) if pressed else Color(0.024, 0.50, 0.51, 1)
	style.set_border_width_all(3)
	if pressed:
		style.border_width_top = 6
		style.border_width_bottom = 2
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.24, 0.16, 0.10, 0.18)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 6)
	return style


func _ok_style(pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.51, 0.13, 1) if pressed else Color(0.96, 0.55, 0.13, 1)
	style.border_color = Color(0.62, 0.28, 0.04, 1)
	style.set_border_width_all(4)
	style.border_width_bottom = 10 if not pressed else 4
	style.border_width_top = 8 if pressed else 4
	style.set_corner_radius_all(28)
	return style
