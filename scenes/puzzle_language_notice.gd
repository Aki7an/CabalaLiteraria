extends ColorRect

const FONT := preload("res://fonts/Fonts/Rubik-SemiBold.ttf")

const LOCK_BODY := {
	"es": "Una vez empezado un puzle en un idioma, no se puede cambiar el idioma del puzle. Para cambiar el idioma, sal al menú principal.",
	"en": "Once a puzzle has started in one language, its language cannot be changed. To change the language, go back to the main menu.",
	"eu": "Puzzle bat hizkuntza batean hasitakoan, ezin da puzzlearen hizkuntza aldatu. Hizkuntza aldatzeko, irten menu nagusira.",
	"de": "Wenn ein Rätsel in einer Sprache begonnen wurde, lässt sich die Sprache des Rätsels nicht mehr ändern. Um die Sprache zu wechseln, geh zurück ins Hauptmenü.",
	"fr": "Une fois un puzzle commencé dans une langue, on ne peut plus changer la langue du puzzle. Pour changer de langue, retourne au menu principal.",
	"it": "Una volta iniziato un puzzle in una lingua, non si può cambiare la lingua del puzzle. Per cambiare lingua, torna al menu principale.",
	"pt": "Depois de começar um puzzle num idioma, não se pode mudar o idioma do puzzle. Para mudar o idioma, volta ao menu principal.",
}

const RESUME_BODY := {
	"es": "Este puzle se empezó en %s y no se puede cambiar de idioma.",
	"en": "This puzzle was started in %s and its language cannot be changed.",
	"eu": "Puzzle hau %s hasi zen eta ezin da hizkuntza aldatu.",
	"de": "Dieses Rätsel wurde auf %s begonnen und die Sprache kann nicht geändert werden.",
	"fr": "Ce puzzle a été commencé en %s et sa langue ne peut pas être changée.",
	"it": "Questo puzzle è stato iniziato in %s e la lingua non si può cambiare.",
	"pt": "Este puzzle começou em %s e o idioma não se pode mudar.",
}

const LANGUAGE_NAME := {
	"es": {
		"es": "español", "en": "inglés", "eu": "euskera", "de": "alemán",
		"fr": "francés", "it": "italiano", "pt": "portugués",
	},
	"en": {
		"es": "Spanish", "en": "English", "eu": "Basque", "de": "German",
		"fr": "French", "it": "Italian", "pt": "Portuguese",
	},
	"eu": {
		"es": "gaztelaniaz", "en": "ingelesez", "eu": "euskaraz", "de": "alemanez",
		"fr": "frantsesez", "it": "italieraz", "pt": "portugesez",
	},
	"de": {
		"es": "Spanisch", "en": "Englisch", "eu": "Baskisch", "de": "Deutsch",
		"fr": "Französisch", "it": "Italienisch", "pt": "Portugiesisch",
	},
	"fr": {
		"es": "espagnol", "en": "anglais", "eu": "basque", "de": "allemand",
		"fr": "français", "it": "italien", "pt": "portugais",
	},
	"it": {
		"es": "spagnolo", "en": "inglese", "eu": "basco", "de": "tedesco",
		"fr": "francese", "it": "italiano", "pt": "portoghese",
	},
	"pt": {
		"es": "espanhol", "en": "inglês", "eu": "basco", "de": "alemão",
		"fr": "francês", "it": "italiano", "pt": "português",
	},
}

const NATIVE_NAME := {
	"es": "Español",
	"en": "English",
	"eu": "Euskara",
	"de": "Deutsch",
	"fr": "Français",
	"it": "Italiano",
	"pt": "Português",
}

const OK_TEXT := {
	"es": "Entendido",
	"en": "OK",
	"eu": "Ados",
	"de": "Verstanden",
	"fr": "Compris",
	"it": "Capito",
	"pt": "Percebi",
}

var _card: Control


func open(puzzle_lang: String, other_lang: String, resume: bool) -> void:
	name = "PuzzleLanguageNotice"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.08, 0.04, 0.02, 0.58)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 80
	gui_input.connect(_on_overlay_input)

	var center := CenterContainer.new()
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var card := PanelContainer.new()
	card.process_mode = Node.PROCESS_MODE_ALWAYS
	card.custom_minimum_size = Vector2(980, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 0.965, 0.86, 1)
	card_style.border_color = Color(0.62, 0.4, 0.16, 0.46)
	card_style.set_border_width_all(4)
	card_style.border_width_bottom = 9
	card_style.set_corner_radius_all(48)
	card_style.shadow_color = Color(0.14, 0.08, 0.03, 0.34)
	card_style.shadow_size = 24
	card_style.shadow_offset = Vector2(0, 17)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	_card = card

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 36)
	card.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 18)
	margin.add_child(inner)

	var puzzle_code := _code(puzzle_lang)
	var other_code := _code(other_lang)
	var show_other := other_code != puzzle_code
	_add_block(inner, puzzle_code, puzzle_code, resume, show_other)
	if show_other:
		var rule := ColorRect.new()
		rule.custom_minimum_size = Vector2(0, 3)
		rule.color = Color(0.62, 0.4, 0.16, 0.28)
		inner.add_child(rule)
		_add_block(inner, other_code, puzzle_code, resume, true)

	var button := Button.new()
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 110)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 40)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.text = _ok_label(puzzle_code, other_code if show_other else puzzle_code)
	var normal := _button_style(Color(0.96, 0.51, 0.01, 1), Color(0.83, 0.41, 0.02, 1), 12)
	var pressed := _button_style(Color(0.91, 0.43, 0, 1), Color(1, 0.63, 0.04, 1), 5)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.pressed.connect(_close)
	inner.add_child(button)


func _close() -> void:
	SoundManager.play("ButtonClick")
	queue_free()


func _on_overlay_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var mouse := event as InputEventMouseButton
	if _card != null and _card.get_global_rect().has_point(mouse.global_position):
		return
	_close()


func _add_block(parent: VBoxContainer, text_lang: String, puzzle_lang: String, resume: bool, with_caption: bool) -> void:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 8)
	parent.add_child(block)
	if with_caption:
		var caption := _label(str(NATIVE_NAME.get(text_lang, text_lang)), 28, Color(0.04, 0.45, 0.45, 1))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		block.add_child(caption)
	var body := _label(_paragraph(text_lang, puzzle_lang, resume), 36, Color(0.24, 0.14, 0.08, 1))
	block.add_child(body)


func _paragraph(text_lang: String, puzzle_lang: String, resume: bool) -> String:
	var code := _code(text_lang)
	if resume:
		var template := str(RESUME_BODY.get(code, RESUME_BODY["es"]))
		var names: Dictionary = LANGUAGE_NAME.get(code, LANGUAGE_NAME["es"])
		return template % str(names.get(puzzle_lang, puzzle_lang))
	return str(LOCK_BODY.get(code, LOCK_BODY["es"]))


func _ok_label(first: String, second: String) -> String:
	var a := str(OK_TEXT.get(_code(first), "OK"))
	var b := str(OK_TEXT.get(_code(second), "OK"))
	if a == b:
		return a
	return "%s  ·  %s" % [a, b]


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _button_style(fill: Color, border: Color, bottom: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 8
	style.border_width_top = 8
	style.border_width_right = 8
	style.border_width_bottom = bottom
	style.set_corner_radius_all(42)
	return style


func _code(lang: String) -> String:
	var code := lang.strip_edges().to_lower().substr(0, 2)
	if LOCK_BODY.has(code):
		return code
	return "es"
