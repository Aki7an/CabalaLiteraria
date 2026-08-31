extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const PATH_GAME := "res://scenes/App.tscn"
const PATH_SELECTION := "res://scenes/MenuSelectCategory.tscn"

const STANDARD_BACK_BUTTON := preload("res://scenes/StandardBackButton.tscn")
const BACKGROUND_SCENE := preload("res://scenes/fondo.tscn")
const FONT_TITLE := preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_BODY := preload("res://fonts/Fonts/Montserrat/static/Montserrat-SemiBold.ttf")
const FONT_REGULAR := preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")
const TEX_STAR := preload("res://images/estrella_plano.png")
const TEX_STAR_OFF := preload("res://images/contorno_estrella.png")
const TEX_QUICK := preload("res://images/mode_quick.svg")
const TEX_CRYPTO := preload("res://images/mode_scroll.svg")
const TEX_HINT := preload("res://images/ui_icon_bulb_white.svg")
const TEX_REVEAL := preload("res://GUI/Library/Demo/Demo_ItemIcon_(OriginalSize)/itemicon_eye.png")
const TEX_CLOUD := preload("res://images/tutorial_cloud.svg")

const COLOR_BACKGROUND := Color(0.984, 0.949, 0.865, 1.0)
const COLOR_CARD := Color(0.996, 0.973, 0.906, 1.0)
const COLOR_INK := Color(0.24, 0.15, 0.09, 1.0)
const COLOR_MUTED := Color(0.36, 0.26, 0.18, 0.92)
const COLOR_ORANGE := Color(0.90, 0.50, 0.13, 1.0)
const COLOR_ORANGE_DARK := Color(0.78, 0.38, 0.05, 1.0)
const COLOR_TEAL := Color(0.10, 0.58, 0.50, 1.0)
const COLOR_PURPLE := Color(0.40, 0.28, 0.68, 1.0)
const COLOR_GREEN_CELL := Color(0.75, 0.88, 0.64, 1.0)
const COLOR_TILE := Color(1.0, 0.98, 0.92, 1.0)
const COLOR_TILE_BORDER := Color(0.55, 0.42, 0.28, 0.78)
const PAGE_COUNT := 4

var _page_index := 0
var _pages: Array[Control] = []
var _dots: Array[Button] = []
var _step_badge: Label
var _next_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_show_page(0, false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		_on_next_pressed()
	elif event.is_action_pressed("ui_left") and _page_index > 0:
		_show_page(_page_index - 1)


func _build_ui() -> void:
	var background := Panel.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_theme_stylebox_override("panel", _flat(COLOR_BACKGROUND, 0))
	add_child(background)

	var pattern := BACKGROUND_SCENE.instantiate()
	pattern.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pattern.modulate = Color(1, 1, 1, 0.16)
	pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(pattern)

	var card := Panel.new()
	card.name = "TutorialCard"
	card.clip_contents = false
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 42
	card.offset_top = 96
	card.offset_right = -42
	card.offset_bottom = -56
	card.add_theme_stylebox_override("panel", _card_style())
	add_child(card)

	_step_badge = _label("1 / 4", 28, Color.WHITE)
	_step_badge.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_step_badge.offset_left = -78
	_step_badge.offset_top = -22
	_step_badge.offset_right = 78
	_step_badge.offset_bottom = 46
	var badge_style := _flat(COLOR_ORANGE, 8, COLOR_ORANGE_DARK, 2)
	badge_style.corner_radius_top_left = 6
	badge_style.corner_radius_top_right = 6
	badge_style.corner_radius_bottom_left = 14
	badge_style.corner_radius_bottom_right = 14
	badge_style.content_margin_left = 18
	badge_style.content_margin_right = 18
	_step_badge.add_theme_stylebox_override("normal", badge_style)
	card.add_child(_step_badge)

	var page_holder := Control.new()
	page_holder.name = "Pages"
	page_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_holder.offset_left = 40
	page_holder.offset_top = 74
	page_holder.offset_right = -40
	page_holder.offset_bottom = -292
	card.add_child(page_holder)

	for page in [
		_build_page_decipher(),
		_build_page_patterns(),
		_build_page_stars(),
		_build_page_modes(),
	]:
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		page_holder.add_child(page)
		_pages.append(page)

	_next_button = Button.new()
	_next_button.name = "ButtonNext"
	_next_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_next_button.offset_left = -240
	_next_button.offset_top = -236
	_next_button.offset_right = 240
	_next_button.offset_bottom = -108
	_next_button.focus_mode = Control.FOCUS_NONE
	_next_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_next_button.add_theme_font_override("font", FONT_TITLE)
	_next_button.add_theme_font_size_override("font_size", 36)
	_next_button.add_theme_color_override("font_color", Color.WHITE)
	_next_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_next_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	_next_button.add_theme_stylebox_override("normal", _action_style(COLOR_ORANGE))
	_next_button.add_theme_stylebox_override(
		"hover",
		_action_style(COLOR_ORANGE.lightened(0.07))
	)
	_next_button.add_theme_stylebox_override(
		"pressed",
		_action_style(COLOR_ORANGE_DARK, true)
	)
	_next_button.pressed.connect(_on_next_pressed)
	card.add_child(_next_button)

	var dots := HBoxContainer.new()
	dots.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dots.offset_left = -110
	dots.offset_top = -84
	dots.offset_right = 110
	dots.offset_bottom = -36
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 22)
	card.add_child(dots)
	for index in range(PAGE_COUNT):
		var dot := Button.new()
		dot.custom_minimum_size = Vector2(24, 24)
		dot.focus_mode = Control.FOCUS_NONE
		dot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		dot.pressed.connect(_show_page.bind(index))
		dots.add_child(dot)
		_dots.append(dot)

	var back := STANDARD_BACK_BUTTON.instantiate() as Button
	back.name = "ButtonBack"
	back.position = Vector2(28, 28)
	back.pressed.connect(_on_button_back_pressed)
	add_child(back)


func _show_page(index: int, animate := true) -> void:
	_page_index = clampi(index, 0, PAGE_COUNT - 1)
	for page_index in range(_pages.size()):
		var page := _pages[page_index]
		page.visible = page_index == _page_index
		if page.visible and animate:
			page.modulate.a = 0.0
			page.position.x = 24
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(page, "modulate:a", 1.0, 0.24)
			tween.tween_property(page, "position:x", 0.0, 0.28).set_trans(
				Tween.TRANS_CUBIC
			).set_ease(Tween.EASE_OUT)
	_step_badge.text = "%d / %d" % [_page_index + 1, PAGE_COUNT]
	_next_button.text = "¡A JUGAR!" if _page_index == PAGE_COUNT - 1 else "SIGUIENTE"
	var action_color := COLOR_TEAL if _page_index == PAGE_COUNT - 1 else COLOR_ORANGE
	_next_button.add_theme_stylebox_override("normal", _action_style(action_color))
	_next_button.add_theme_stylebox_override(
		"hover",
		_action_style(action_color.lightened(0.07))
	)
	_next_button.add_theme_stylebox_override(
		"pressed",
		_action_style(action_color.darkened(0.08), true)
	)
	for dot_index in range(_dots.size()):
		var selected := dot_index == _page_index
		var dot_color := COLOR_ORANGE if selected else Color(1, 0.98, 0.92, 1)
		var border := COLOR_ORANGE if selected else Color(0.72, 0.52, 0.28, 0.85)
		var style := _flat(dot_color, 12, border, 3)
		_dots[dot_index].add_theme_stylebox_override("normal", style)
		_dots[dot_index].add_theme_stylebox_override("hover", style)
		_dots[dot_index].add_theme_stylebox_override("pressed", style)
	if animate:
		SoundManager.play("ButtonClick")


func _on_next_pressed() -> void:
	if _page_index < PAGE_COUNT - 1:
		_show_page(_page_index + 1)
	else:
		_finish_tutorial()


func _finish_tutorial() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if GameManager.go_to_game:
		SignalManager.partida_iniciada.emit()
		get_tree().change_scene_to_file(PATH_GAME)
	else:
		get_tree().change_scene_to_file(PATH_SELECTION)


func _on_button_back_pressed() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if GameManager.go_to_game:
		SignalManager.partida_iniciada.emit()
		get_tree().change_scene_to_file(PATH_GAME)
	else:
		get_tree().change_scene_to_file(PATH_MAIN)


func _build_page_decipher() -> VBoxContainer:
	var page := _page_box(26)
	page.add_child(_page_title("DESCIFRA LA FRASE"))
	page.add_child(_body("Cada número representa siempre la misma letra.", 28))
	page.add_child(
		_body("Descubre las correspondencias para completar la frase.", 28)
	)
	page.add_child(_cipher_example(false))
	page.add_child(_example_section())
	return page


func _build_page_patterns() -> VBoxContainer:
	var page := _page_box(24)
	page.add_child(_page_title("BUSCA PATRONES"))
	page.add_child(
		_body(
			"Marca números iguales con colores para localizar patrones y probar tus hipótesis.",
			26
		)
	)
	page.add_child(_number_pattern_block())
	page.add_child(
		_body("Selecciona una casilla y escribe la letra que crees que corresponde.", 26)
	)
	page.add_child(_color_swatches())
	page.add_child(_label("↓", 40, COLOR_TEAL))
	page.add_child(_keyboard_example())
	return page


func _build_page_stars() -> VBoxContainer:
	var page := _page_box(28)
	page.add_child(_page_title("CONSIGUE 5 ESTRELLAS"))
	page.add_child(_star_row(5, 78))
	page.add_child(_body("Puedes pedir ayuda, pero perderás estrellas.", 28))

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 48)
	actions.add_child(
		_help_card(
			"PISTA",
			"Te da una ayuda contextual.",
			TEX_HINT,
			COLOR_ORANGE,
			false
		)
	)
	actions.add_child(
		_help_card(
			"REVELAR",
			"Comprueba o revela las letras marcadas.",
			TEX_REVEAL,
			COLOR_PURPLE,
			true
		)
	)
	page.add_child(actions)

	var divider := DashedLine.new()
	divider.custom_minimum_size = Vector2(0, 18)
	page.add_child(divider)
	page.add_child(_body("Cada ayuda que uses te costará estrellas.", 26))

	var penalty := PanelContainer.new()
	penalty.custom_minimum_size = Vector2(0, 118)
	penalty.add_theme_stylebox_override(
		"panel",
		_padded(_flat(Color(0.99, 0.94, 0.82, 0.95), 22, Color(0.84, 0.68, 0.40, 0.45), 2), 18)
	)
	var penalty_row := HBoxContainer.new()
	penalty_row.alignment = BoxContainer.ALIGNMENT_CENTER
	penalty_row.add_theme_constant_override("separation", 22)
	penalty.add_child(penalty_row)
	penalty_row.add_child(_star_row(5, 36))
	penalty_row.add_child(_label("→", 40, COLOR_MUTED))
	penalty_row.add_child(_star_row(4, 36))
	page.add_child(penalty)
	return page


func _build_page_modes() -> VBoxContainer:
	var page := _page_box(26)
	page.add_child(_page_title("JUEGA A TU RITMO"))
	page.add_child(
		_body("Elige una temática y juega en modo Rápido o Criptograma.", 28)
	)

	var modes := HBoxContainer.new()
	modes.alignment = BoxContainer.ALIGNMENT_CENTER
	modes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modes.add_theme_constant_override("separation", 24)
	modes.add_child(
		_mode_card(
			"RÁPIDO",
			"Puzles más cortos para partidas rápidas.",
			TEX_QUICK,
			Color(0.86, 0.94, 0.86, 1),
			COLOR_TEAL
		)
	)
	modes.add_child(
		_mode_card(
			"CRIPTOGRAMA",
			"Puzles más largos para los amantes del desafío.",
			TEX_CRYPTO,
			Color(1.0, 0.94, 0.82, 1),
			COLOR_ORANGE_DARK
		)
	)
	page.add_child(modes)
	page.add_child(
		_info_card(
			TEX_CLOUD,
			"Tu progreso se guarda automáticamente",
			"Puedes continuar un puzle más adelante.",
			Color(0.86, 0.94, 0.86, 1),
			COLOR_TEAL,
			true
		)
	)
	page.add_child(
		_info_card(
			TEX_STAR,
			"",
			"Intenta completar cada puzle conservando el mayor número de estrellas posible.",
			Color(1.0, 0.95, 0.84, 1),
			COLOR_ORANGE,
			false
		)
	)
	return page


func _example_section() -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 470)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_top = 22
	frame.add_theme_stylebox_override(
		"panel",
		_padded(
			_flat(Color(1, 0.98, 0.93, 0.35), 22, Color(0.78, 0.62, 0.38, 0.42), 2),
			22
		)
	)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	frame.add_child(box)
	box.add_child(
		_rich("Si descubres que [color=#1F7366][b]12 = A[/b][/color]...", 26)
	)
	box.add_child(_label("↓", 42, COLOR_TEAL))
	box.add_child(_cipher_example(true))
	box.add_child(
		_rich(
			"...todas las casillas con el número [color=#1F7366][b]12[/b][/color] mostrarán la letra [color=#1F7366][b]A[/b][/color].",
			24
		)
	)
	wrap.add_child(frame)

	var badge := _label("EJEMPLO", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	badge.position = Vector2(28, 0)
	badge.size = Vector2(168, 46)
	badge.add_theme_stylebox_override(
		"normal",
		_padded(_flat(COLOR_TEAL, 12, COLOR_TEAL.darkened(0.12), 1), 10, 18)
	)
	wrap.add_child(badge)
	return wrap


func _cipher_example(resolved: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 168)
	panel.add_theme_stylebox_override(
		"panel",
		_padded(
			_flat(Color(0.99, 0.93, 0.74, 0.92), 20, Color(0.78, 0.60, 0.32, 0.55), 2),
			16
		)
	)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var words := [[12, 7, 12], [4, 19]]
	for word_index in range(words.size()):
		if word_index > 0:
			var gap := Control.new()
			gap.custom_minimum_size.x = 26
			row.add_child(gap)
		for number in words[word_index]:
			var column := VBoxContainer.new()
			column.add_theme_constant_override("separation", 6)
			row.add_child(column)
			column.add_child(_label(str(number), 20, COLOR_INK))
			var tile := PanelContainer.new()
			tile.custom_minimum_size = Vector2(92, 76)
			tile.add_theme_stylebox_override(
				"panel",
				_flat(COLOR_TILE, 6, COLOR_TILE_BORDER, 2)
			)
			var letter := "A" if resolved and int(number) == 12 else ""
			tile.add_child(_label(letter, 40, COLOR_INK))
			column.add_child(tile)
	return panel


func _number_pattern_block() -> HBoxContainer:
	var wrap := HBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_theme_constant_override("separation", 14)
	wrap.add_child(_spark_marks())
	wrap.add_child(_number_pattern_grid())
	wrap.add_child(_spark_marks())
	return wrap


func _spark_marks() -> VBoxContainer:
	var marks := VBoxContainer.new()
	marks.alignment = BoxContainer.ALIGNMENT_CENTER
	marks.add_theme_constant_override("separation", 10)
	for text in ["/", "—", "\\"]:
		marks.add_child(_label(text, 18, COLOR_TEAL))
	return marks


func _number_pattern_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var values := [8, 17, 5, 8, 21, 14, 8, 6, 3, 8, 19, 2, 8, 11, 7]
	for value in values:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(118, 68)
		var repeated: bool = int(value) == 8
		cell.add_theme_stylebox_override(
			"panel",
			_flat(
				COLOR_GREEN_CELL if repeated else Color(0.99, 0.95, 0.84, 1),
				8,
				Color(0.42, 0.62, 0.34, 0.85) if repeated else Color(0.70, 0.56, 0.36, 0.45),
				2
			)
		)
		cell.add_child(_label(str(value), 24, COLOR_INK))
		grid.add_child(cell)
	return grid


func _color_swatches() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	var colors := [
		Color(0.93, 0.42, 0.56, 1),
		Color(0.27, 0.68, 0.86, 1),
		Color(0.52, 0.78, 0.48, 1),
		Color(0.98, 0.62, 0.20, 1),
		Color(0.58, 0.44, 0.76, 1),
	]
	for index in range(colors.size()):
		var color: Color = colors[index]
		var swatch := Panel.new()
		swatch.custom_minimum_size = Vector2(72, 72)
		swatch.add_theme_stylebox_override(
			"panel",
			_flat(color, 12, color.darkened(0.22), 3 if index == 2 else 2)
		)
		if index == 2:
			var check := Label.new()
			check.text = "✓"
			check.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			check.add_theme_font_override("font", FONT_TITLE)
			check.add_theme_font_size_override("font_size", 34)
			check.add_theme_color_override("font_color", Color.WHITE)
			check.add_theme_color_override("font_outline_color", Color(0.18, 0.42, 0.20, 1))
			check.add_theme_constant_override("outline_size", 10)
			swatch.add_child(check)
		row.add_child(swatch)
	return row


func _keyboard_example() -> GridContainer:
	var keyboard := GridContainer.new()
	keyboard.columns = 9
	keyboard.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	keyboard.add_theme_constant_override("h_separation", 6)
	keyboard.add_theme_constant_override("v_separation", 6)
	var letters := "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ"
	for index in range(letters.length()):
		var key := PanelContainer.new()
		key.custom_minimum_size = Vector2(92, 64)
		var selected := index == 0
		key.add_theme_stylebox_override(
			"panel",
			_flat(
				COLOR_GREEN_CELL if selected else Color(0.99, 0.96, 0.86, 1),
				8,
				Color(0.42, 0.62, 0.34, 0.85) if selected else Color(0.68, 0.54, 0.34, 0.42),
				2
			)
		)
		key.add_child(_label(letters[index], 22, COLOR_INK))
		keyboard.add_child(key)
	return keyboard


func _help_card(
	title: String,
	description: String,
	texture: Texture2D,
	color: Color,
	keep_icon_colors: bool
) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 360
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 268)
	card.add_theme_stylebox_override("panel", _action_style(color))
	var card_box := VBoxContainer.new()
	card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card_box.add_theme_constant_override("separation", 12)
	card.add_child(card_box)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(108, 108)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not keep_icon_colors:
		icon.modulate = Color.WHITE
	card_box.add_child(icon)
	card_box.add_child(_label(title, 32, Color.WHITE))
	box.add_child(card)
	box.add_child(_body(description, 22))
	return box


func _mode_card(
	title: String,
	description: String,
	texture: Texture2D,
	background: Color,
	accent: Color
) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 360)
	card.add_theme_stylebox_override(
		"panel",
		_padded(_flat(background, 24, accent.lightened(0.12), 3, true), 22)
	)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(112, 112)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)
	box.add_child(_label(title, 28, accent))
	box.add_child(_body(description, 22))
	return card


func _info_card(
	texture: Texture2D,
	title: String,
	description: String,
	background: Color,
	accent: Color,
	tint_icon: bool
) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 150)
	card.add_theme_stylebox_override(
		"panel",
		_padded(_flat(background, 22, accent.lightened(0.18), 2), 18, 22)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(78, 78)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if tint_icon:
		icon.modulate = accent
	elif texture == TEX_STAR:
		icon.modulate = Color(1.0, 0.64, 0.10, 1)
	row.add_child(icon)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 6)
	row.add_child(texts)
	if title != "":
		var title_label := _label(title, 24, accent, HORIZONTAL_ALIGNMENT_LEFT)
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(title_label)
	var description_label := _label(
		description,
		21,
		COLOR_MUTED,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(description_label)
	return card


func _star_row(filled: int, size: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for index in range(5):
		var star := TextureRect.new()
		star.texture = TEX_STAR if index < filled else TEX_STAR_OFF
		star.custom_minimum_size = Vector2(size, size)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.modulate = (
			Color(1.0, 0.64, 0.10, 1)
			if index < filled
			else Color(0.50, 0.38, 0.26, 0.55)
		)
		row.add_child(star)
	return row


func _page_box(separation := 22) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_theme_constant_override("separation", separation)
	return box


func _page_title(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.add_child(_ornament())
	var title := _label(text, 48, COLOR_INK)
	title.add_theme_font_override("font", FONT_TITLE)
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(title)
	row.add_child(_ornament())
	return row


func _ornament() -> Label:
	var mark := _label("✦", 28, Color(0.92, 0.58, 0.16, 0.82))
	mark.add_theme_font_override("font", FONT_TITLE)
	return mark


func _body(text: String, size: int) -> Label:
	var label := _label(text, size, COLOR_MUTED)
	label.add_theme_font_override("font", FONT_REGULAR)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _rich(text: String, size: int) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "[center]%s[/center]" % text
	label.add_theme_font_override("normal_font", FONT_REGULAR)
	label.add_theme_font_override("bold_font", FONT_BODY)
	label.add_theme_font_size_override("normal_font_size", size)
	label.add_theme_font_size_override("bold_font_size", size)
	label.add_theme_color_override("default_color", COLOR_MUTED)
	return label


func _label(
	text: String,
	size: int,
	color: Color,
	alignment := HORIZONTAL_ALIGNMENT_CENTER
) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_BODY)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _card_style() -> StyleBoxFlat:
	var style := _flat(COLOR_CARD, 36, Color(0.78, 0.61, 0.36, 0.48), 3, true)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style


func _action_style(color: Color, pressed := false) -> StyleBoxFlat:
	var style := _flat(
		color.darkened(0.08) if pressed else color,
		24,
		color.darkened(0.28),
		3,
		true
	)
	style.border_width_bottom = 4 if pressed else 10
	style.shadow_offset = Vector2(0, 3 if pressed else 8)
	return style


func _padded(
	style: StyleBoxFlat,
	vertical: int,
	horizontal := -1
) -> StyleBoxFlat:
	var side := vertical if horizontal < 0 else horizontal
	style.content_margin_left = side
	style.content_margin_right = side
	style.content_margin_top = vertical
	style.content_margin_bottom = vertical
	return style


func _flat(
	color: Color,
	radius: int,
	border_color := Color.TRANSPARENT,
	border_width := 0,
	with_shadow := false
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.border_color = border_color
	style.anti_aliasing_size = 0.7
	if with_shadow:
		style.shadow_color = Color(0.25, 0.14, 0.06, 0.16)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 7)
	return style


class DashedLine extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var y := size.y * 0.5
		var x := 0.0
		var dash := 16.0
		var gap := 12.0
		var color := Color(0.72, 0.58, 0.38, 0.62)
		while x < size.x:
			draw_line(Vector2(x, y), Vector2(minf(x + dash, size.x), y), color, 3.0, true)
			x += dash + gap
