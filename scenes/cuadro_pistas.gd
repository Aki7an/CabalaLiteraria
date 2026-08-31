extends ColorRect

const FONT_TITLE: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_BODY: Font = preload("res://fonts/Fonts/Montserrat/static/Montserrat-SemiBold.ttf")
const FONT_REGULAR: Font = preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")
const STAR_TEXTURE: Texture2D = preload("res://images/estrella_plano.png")
const TEX_BULB: Texture2D = preload("res://images/ui_icon_bulb_white.svg")

const COLOR_INK := Color(0.22, 0.13, 0.07, 1)
const COLOR_BODY := Color(0.32, 0.2, 0.12, 1)
const COLOR_MUTED := Color(0.45, 0.32, 0.18, 0.82)
const COLOR_GREEN := Color(0.16, 0.55, 0.34, 1)
const COLOR_GREEN_DEEP := Color(0.12, 0.46, 0.3, 1)
const COLOR_ORANGE := Color(0.92, 0.48, 0.08, 1)
const COLOR_LOCKED := Color(0.62, 0.34, 0.22, 1)
const COLOR_TEAL := Color(0.12, 0.62, 0.62, 1)
const COLOR_GOLD := Color(0.62, 0.4, 0.16, 0.72)
const COLOR_COST := Color(0.55, 0.28, 0.08, 1)
const RIBBON_WIDTH := 72.0

var _card: Panel


func _ready() -> void:
	add_to_group("HintsOverlay")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.08, 0.04, 0.02, 0.58)
	mouse_filter = Control.MOUSE_FILTER_STOP
	GameManager.ensure_hint_word()
	_build()
	gui_input.connect(_on_background_input)


func _build() -> void:
	_card = Panel.new()
	_card.position = Vector2(48, 140)
	_card.size = Vector2(1110, 2180)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.clip_contents = false
	_card.add_theme_stylebox_override("panel", _card_style())
	add_child(_card)
	_add_corner_marks(_card)

	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 42
	inner.offset_top = 36
	inner.offset_right = -42
	inner.offset_bottom = -40
	inner.add_theme_constant_override("separation", 22)
	_card.add_child(inner)

	inner.add_child(_make_header())
	inner.add_child(_hint_card(1))
	inner.add_child(_hint_card(2))
	inner.add_child(_hint_card(3))
	inner.add_child(_star_divider())
	inner.add_child(_make_close_button())


func _make_header() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	var bulb := TextureRect.new()
	bulb.texture = TEX_BULB
	bulb.custom_minimum_size = Vector2(160, 160)
	bulb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bulb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bulb.modulate = Color(1, 0.72, 0.08, 1)
	bulb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(bulb)
	var title := _label("PISTAS", 64, COLOR_INK, FONT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	return col


func _hint_card(index: int) -> Panel:
	var unlocked := _is_unlocked(index)
	var state := "unlocked" if unlocked else "available"
	var palette := _palette_for(state)

	var card := Panel.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 470)
	card.clip_contents = false
	card.add_theme_stylebox_override("panel", _inner_style(palette.fill, palette.border))

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_top = 22
	box.offset_right = -RIBBON_WIDTH - 18
	box.offset_bottom = -18
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	header.custom_minimum_size = Vector2(0, 72)
	box.add_child(header)
	header.add_child(_number_badge(index, palette.accent))
	var name_label := _label("PISTA %d" % index, 40, COLOR_INK, FONT_TITLE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(name_label)

	box.add_child(_dotted_line(palette.border))
	box.add_child(_label(_prompt_text(index), 36, COLOR_BODY, FONT_REGULAR, true))

	var body := _label(
		_body_text(index),
		56 if unlocked else 40,
		_body_color(index),
		FONT_TITLE,
		true
	)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(body)

	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(footer)
	if not unlocked:
		var obtain := _make_obtain_button(index)
		obtain.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		footer.add_child(obtain)
		footer.add_child(_cost_row())

	card.add_child(_make_ribbon(unlocked, palette.ribbon))
	return card


func _number_badge(index: int, fill: Color) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(72, 72)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.draw.connect(func() -> void:
		wrap.draw_circle(wrap.size * 0.5, 32.0, fill)
	)
	wrap.resized.connect(func() -> void:
		wrap.queue_redraw()
	)
	var number := _label(str(index), 40, Color.WHITE, FONT_TITLE)
	number.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wrap.add_child(number)
	return wrap


func _make_ribbon(unlocked: bool, fill: Color) -> Panel:
	var ribbon := Panel.new()
	ribbon.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	ribbon.anchor_left = 1.0
	ribbon.anchor_right = 1.0
	ribbon.offset_left = -RIBBON_WIDTH
	ribbon.offset_right = 10
	ribbon.offset_top = -8
	ribbon.offset_bottom = -92
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.add_theme_stylebox_override("panel", _ribbon_style(fill))

	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.add_child(holder)
	holder.add_child(_lock_icon(unlocked))
	return ribbon


func _lock_icon(is_open: bool) -> Control:
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func() -> void:
		var center := icon.size * 0.5
		var white := Color.WHITE
		if is_open:
			icon.draw_arc(center + Vector2(10, -11), 12.0, PI * 0.15, PI * 1.15, 18, white, 4.0, true)
			icon.draw_rect(Rect2(center + Vector2(-15, -2), Vector2(30, 22)), white, true)
		else:
			icon.draw_arc(center + Vector2(0, -11), 11.0, PI, TAU, 18, white, 4.0, true)
			icon.draw_rect(Rect2(center + Vector2(-15, -2), Vector2(30, 22)), white, true)
	)
	icon.resized.connect(func() -> void:
		icon.queue_redraw()
	)
	return icon


func _make_obtain_button(index: int) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(420, 92)
	var fill := COLOR_TEAL
	var border := Color(0.06, 0.42, 0.44, 1)
	button.add_theme_stylebox_override("normal", _button_style(fill, border, 18))
	button.add_theme_stylebox_override("hover", _button_style(fill, border, 18))
	button.add_theme_stylebox_override("pressed", _button_style(fill.darkened(0.1), border, 18))
	button.add_theme_stylebox_override("disabled", _button_style(fill, border, 18))
	button.pressed.connect(func() -> void:
		_buy_hint(index)
	)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -16
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)

	var bulb := TextureRect.new()
	bulb.texture = TEX_BULB
	bulb.custom_minimum_size = Vector2(40, 40)
	bulb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bulb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bulb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bulb)
	var caption := _label("OBTENER", 46, Color.WHITE, FONT_TITLE)
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(caption)
	return button


func _cost_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var cost := _label("Coste: -1", 34, COLOR_COST, FONT_BODY)
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(cost)
	var star := TextureRect.new()
	star.custom_minimum_size = Vector2(34, 34)
	star.texture = STAR_TEXTURE
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.modulate = Color(1, 0.62, 0.12, 1)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(star)
	return row


func _make_close_button() -> Button:
	var close := Button.new()
	close.text = "CERRAR"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 118)
	close.add_theme_font_override("font", FONT_TITLE)
	close.add_theme_font_size_override("font_size", 46)
	close.add_theme_color_override("font_color", Color.WHITE)
	close.add_theme_stylebox_override("normal", _button_style(COLOR_TEAL, Color(0.06, 0.42, 0.44, 1), 22))
	close.add_theme_stylebox_override("hover", _button_style(COLOR_TEAL, Color(0.06, 0.42, 0.44, 1), 22))
	close.add_theme_stylebox_override("pressed", _button_style(Color(0.08, 0.52, 0.52, 1), Color(0.06, 0.42, 0.44, 1), 22))
	close.pressed.connect(func() -> void:
		SoundManager.play("ButtonClick")
		queue_free()
	)
	return close


func _star_divider() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(0, 36)
	row.add_theme_constant_override("separation", 16)
	row.add_child(_divider_line())
	var star := TextureRect.new()
	star.texture = STAR_TEXTURE
	star.custom_minimum_size = Vector2(28, 28)
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.modulate = Color(0.78, 0.52, 0.16, 1)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(star)
	row.add_child(_divider_line())
	return row


func _divider_line() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color(0.62, 0.42, 0.18, 0.35)
	line.custom_minimum_size = Vector2(0, 3)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _dotted_line(color: Color) -> Control:
	var line := Control.new()
	line.custom_minimum_size = Vector2(0, 12)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.draw.connect(func() -> void:
		var y := line.size.y * 0.5
		var x := 0.0
		while x < line.size.x:
			line.draw_line(Vector2(x, y), Vector2(minf(x + 7.0, line.size.x), y), color, 2.0, true)
			x += 14.0
	)
	line.resized.connect(func() -> void:
		line.queue_redraw()
	)
	return line


func _buy_hint(index: int) -> void:
	if _is_unlocked(index):
		return
	SoundManager.play("ButtonClick")
	match index:
		1:
			GameManager.register_hint_used("hint_1")
			GameManager.set_pista1()
			GameManager.ensure_hint_word()
		2:
			GameManager.register_hint_used("hint_2")
			GameManager.set_pista2()
			GameManager.refresh_hint_letter()
			SignalManager.compra_pista_2.emit(GameManager.tiempo_partida)
		3:
			GameManager.register_hint_used("hint_3")
			GameManager.set_pista3()
			GameManager.ensure_hint_vowel_numbers()
			SignalManager.compra_pista_3.emit(GameManager.tiempo_partida)
	GameManager.set_pistas_utilizadas(
		int(GameManager.pista_1) + int(GameManager.pista_2) + int(GameManager.pista_3)
	)
	PuzzleSaveManager.request_autosave()
	call_deferred("_rebuild")


func _rebuild() -> void:
	for child in get_children():
		child.free()
	_build()


func _on_background_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if _card != null and _card.get_global_rect().has_point((event as InputEventMouseButton).global_position):
		return
	SoundManager.play("ButtonClick")
	queue_free()


func _is_unlocked(index: int) -> bool:
	match index:
		1:
			return GameManager.pista_1
		2:
			return GameManager.pista_2
		3:
			return GameManager.pista_3
		_:
			return false


func _palette_for(state: String) -> Dictionary:
	match state:
		"unlocked":
			return {
				"fill": Color(0.9, 0.96, 0.88, 1),
				"border": Color(0.28, 0.55, 0.38, 0.78),
				"accent": COLOR_GREEN_DEEP,
				"ribbon": COLOR_GREEN_DEEP,
			}
		"available":
			return {
				"fill": Color(0.99, 0.96, 0.88, 1),
				"border": Color(0.78, 0.55, 0.22, 0.7),
				"accent": COLOR_ORANGE,
				"ribbon": COLOR_ORANGE,
			}
		_:
			return {
				"fill": Color(0.97, 0.93, 0.86, 1),
				"border": Color(0.62, 0.42, 0.28, 0.45),
				"accent": COLOR_LOCKED,
				"ribbon": COLOR_LOCKED,
			}


func _prompt_text(index: int) -> String:
	match index:
		1:
			return "Palabra que está en la frase:"
		2:
			return "Letra más repetida en la frase:"
		_:
			return "Los siguientes números son las 5 vocales:"


func _body_text(index: int) -> String:
	match index:
		1:
			var word := GameManager.ensure_hint_word()
			return word.to_upper() if _is_unlocked(1) else _asterisks(word)
		2:
			if _is_unlocked(2):
				var letter := GameManager.ensure_hint_letter()
				return letter.to_upper() if letter != "" else "—"
			return "*"
		_:
			var tokens := GameManager.ensure_hint_vowel_numbers()
			var values := "*, *, *, *, *"
			if _is_unlocked(3) and tokens.size() == 5:
				values = ", ".join(tokens)
			return "%s\n(No tienen por qué estar en este orden)." % values


func _asterisks(text: String) -> String:
	var count := 0
	for character in text:
		if character.strip_edges() == "":
			continue
		count += 1
	return "*".repeat(maxi(count, 1))


func _body_color(index: int) -> Color:
	if _is_unlocked(index):
		return COLOR_GREEN
	return Color(0.55, 0.42, 0.28, 0.7)


func _add_corner_marks(card: Panel) -> void:
	var marks := [
		{"pos": Vector2(18, 12), "text": "✦"},
		{"pos": Vector2(1042, 12), "text": "✦"},
		{"pos": Vector2(18, 2128), "text": "✦"},
		{"pos": Vector2(1042, 2128), "text": "✦"},
	]
	for data in marks:
		var mark := _label(str(data["text"]), 26, COLOR_GOLD, FONT_TITLE)
		mark.position = data["pos"]
		mark.size = Vector2(50, 40)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(mark)


func _label(
	text: String,
	size: int,
	color: Color,
	font: Font = FONT_BODY,
	wrap := false
) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.996, 0.973, 0.906, 1)
	style.border_color = Color(0.62, 0.4, 0.16, 0.46)
	style.set_border_width_all(4)
	style.border_width_bottom = 9
	style.set_corner_radius_all(40)
	style.shadow_color = Color(0.14, 0.08, 0.03, 0.34)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 17)
	return style


func _inner_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.18, 0.1, 0.04, 0.16)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	return style


func _ribbon_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = fill.darkened(0.18)
	style.set_border_width_all(0)
	style.corner_radius_top_left = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0.1, 0.05, 0.02, 0.28)
	style.shadow_size = 8
	style.shadow_offset = Vector2(4, 6)
	return style


func _button_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.border_width_bottom = 8
	style.set_corner_radius_all(radius)
	return style
