extends Control

const PATH_SETTINGS := "res://scenes/MenuSettings.tscn"
const DRAG_THRESHOLD := 14.0

const ICON_GODOT := preload("res://images/credit_icon_godot.svg")
const ICON_CURSOR := preload("res://images/credit_icon_cursor.svg")
const ICON_CHATGPT := preload("res://images/credit_icon_chatgpt.svg")
const ICON_SUNO := preload("res://images/credit_icon_suno.svg")
const ICON_HEART := preload("res://images/credit_icon_heart.svg")
const FONT_TITLE := preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_BODY := preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")
const FONT_STRONG := preload("res://fonts/Fonts/Montserrat/static/Montserrat-SemiBold.ttf")
const COPY := {
	"Cipher": {
		"es": "Cifra", "en": "Cipher", "de": "Zahl",
		"fr": "Chiffrer", "eu": "Zifratzea", "it": "Cifra", "pt": "Cifra",
	},
	"Letter": {
		"es": "Letra", "en": "Letter", "de": "Buchstabe",
		"fr": "Lettre", "eu": "Gutuna", "it": "Lettera", "pt": "Carta",
	},
	"Credits": {
		"es": "Créditos", "en": "Credits", "de": "Mitwirkende",
		"fr": "Crédits", "eu": "Kredituak", "it": "Crediti", "pt": "Créditos",
	},
}

@onready var title_label: Label = $Panel/Header/Title
@onready var scroll: ScrollContainer = $Panel/Scroll
@onready var rows: VBoxContainer = $Panel/Scroll/Rows

var _overlay := false
var _drag_held := false
var _drag_active := false
var _drag_origin := Vector2.ZERO
var _drag_scroll_origin := 0


func present_as_overlay() -> void:
	_overlay = true
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _ready() -> void:
	title_label.text = _t("Credits", "CRÉDITOS")
	scroll.scroll_deadzone = 16
	_build_content()


func _t(key: String, fallback: String) -> String:
	var text := tr(key)
	if not text.is_empty() and text != key:
		return text
	var locale := TranslationServer.get_locale().left(2).to_lower()
	var by_locale: Dictionary = COPY.get(key, {})
	if by_locale.has(locale):
		return str(by_locale[locale])
	if not text.is_empty() and locale == "en":
		return text
	return fallback


func _brand_name() -> String:
	return "%s %s" % [_t("Cipher", "Cifra"), _t("Letter", "Letra")]


func _brand_title() -> String:
	return _brand_name().to_upper()


func _with_brand(text: String) -> String:
	return text.replace("Cifra Letra", _brand_name())


func _build_content() -> void:
	_clear_rows()
	_add_intro_card()
	_add_tools_row()
	_add_text_card(
		_t("CreditsDesignTitle", "Diseño"),
		_t(
			"CreditsDesign",
			"El diseño del juego es mío. Para llevarlo a cabo me apoyo en la IA y en colaboradores que me echan una mano cuando el tablero se llena de números."
		),
		ICON_HEART
	)
	_add_text_card(
		_t("CreditsCodeTitle", "Programación"),
		_t(
			"CreditsCode",
			"La programación está hecha en Godot 4.7. La mayor parte la ha implementado la IA desde Cursor: yo pongo el rumbo, la máquina escribe gran parte del código."
		),
		ICON_GODOT
	)
	_add_text_card(
		_t("CreditsArtTitle", "Imágenes"),
		_t(
			"CreditsArt",
			"Las imágenes del juego están generadas por IA. El estilo de papel, las estrellas y los menús salieron de ir afinando esa mirada hasta que el juego se sintió cálido."
		),
		ICON_CHATGPT
	)
	_add_text_card(
		_t("CreditsMusicTitle", "Música"),
		_t(
			"CreditsMusic",
			"La música está compuesta en gran parte con Suno. Buscaba algo que sonara a papel, a calma y a pequeño descubrimiento."
		),
		ICON_SUNO
	)
	_add_text_card(
		_t("CreditsPhrasesTitle", "Frases y citas"),
		_t(
			"CreditsPhrases",
			"Las frases, citas y fragmentos están documentadas en fuentes fiables consultadas en internet o con ayuda de la IA. Cada texto quiere respetar a quien lo escribió."
		)
	)
	_add_text_card(
		_t("CreditsHobbyTitle", "Un hobby, ahora posible"),
		_with_brand(_t(
			"CreditsHobby",
			"Cifra Letra responde a un hobby por el diseño, la creación y la programación de videojuegos. Ahora lo he potenciado con Cursor, ChatGPT y Suno. Todo esto habría llevado un tiempo del que, por desgracia, no dispongo. Sin estas herramientas habría sido imposible."
		)),
		ICON_CURSOR
	)
	_add_future_card()
	_add_signoff()


func _clear_rows() -> void:
	for child in rows.get_children():
		child.queue_free()


func _add_intro_card() -> void:
	var card := _make_card()
	var box := _make_vbox(18)
	var kicker := _make_label(
		_t("CreditsKicker", "Un criptograma con alma de cuaderno"),
		FONT_STRONG,
		32,
		Color(0.45, 0.32, 0.2, 0.82)
	)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var name_label := _make_label(
		_brand_title(),
		FONT_TITLE,
		64,
		Color(0.325, 0.2, 0.125, 1)
	)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body := _make_label(
		_with_brand(_t(
			"CreditsLead",
			"Cifra Letra es un juego creado por Aki (Aki7an, AkiDev…) con la ayuda de la IA, de amigos y de la familia. Un pasatiempo hecho con cariño, entre frases, números y mucho café."
		)),
		FONT_BODY,
		40,
		Color(0.34, 0.22, 0.14, 0.92)
	)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kicker)
	box.add_child(name_label)
	box.add_child(body)
	card.add_child(box)
	rows.add_child(card)


func _add_tools_row() -> void:
	var card := _make_card()
	var box := _make_vbox(18)
	var title := _make_label(
		_t("CreditsToolsTitle", "Hecho con"),
		FONT_STRONG,
		36,
		Color(0.325, 0.2, 0.125, 1)
	)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var grid := HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 18)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for item in [
		{"icon": ICON_GODOT, "name": "Godot 4.7"},
		{"icon": ICON_CURSOR, "name": "Cursor"},
		{"icon": ICON_CHATGPT, "name": "ChatGPT"},
		{"icon": ICON_SUNO, "name": "Suno"},
	]:
		grid.add_child(_make_tool_chip(item.icon, item.name))
	box.add_child(grid)
	card.add_child(box)
	rows.add_child(card)


func _add_text_card(title: String, body: String, icon: Texture2D = null) -> void:
	var card := _make_card()
	var box := _make_vbox(12)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	if icon != null:
		header.add_child(_make_icon(icon, Vector2(72, 72)))
	var title_label_card := _make_label(title, FONT_STRONG, 40, Color(0.325, 0.2, 0.125, 1))
	title_label_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_label_card)
	box.add_child(header)
	box.add_child(_make_label(body, FONT_BODY, 38, Color(0.34, 0.22, 0.14, 0.92)))
	card.add_child(box)
	rows.add_child(card)


func _add_future_card() -> void:
	var card := _make_card()
	var style := card.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style = style.duplicate() as StyleBoxFlat
		style.bg_color = Color(0.93, 0.97, 0.95, 0.96)
		style.border_color = Color(0.04, 0.65, 0.64, 0.42)
		card.add_theme_stylebox_override("panel", style)
	var box := _make_vbox(14)
	var title := _make_label(
		_t("CreditsFutureTitle", "Seguiré haciendo juegos pequeños"),
		FONT_STRONG,
		40,
		Color(0.05, 0.42, 0.42, 1)
	)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var body := _make_label(
		_with_brand(_t(
			"CreditsFuture",
			"Si te ha gustado Cifra Letra, este es el rincón para seguir en contacto. Iré publicando más juegos pequeños desde aquí. Gracias por descifrar conmigo."
		)),
		FONT_BODY,
		38,
		Color(0.18, 0.32, 0.3, 0.95)
	)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(body)
	card.add_child(box)
	rows.add_child(card)


func _add_signoff() -> void:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 90)
	var sign := _make_label(
		_t("CreditsSignoff", "— Aki"),
		FONT_TITLE,
		42,
		Color(0.45, 0.32, 0.2, 0.78)
	)
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sign.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(sign)
	rows.add_child(wrap)


func _make_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.984, 0.953, 0.96)
	style.set_border_width_all(2)
	style.border_width_bottom = 5
	style.border_color = Color(0.77, 0.62, 0.4, 0.38)
	style.set_corner_radius_all(28)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


func _make_vbox(separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return box


func _make_label(text: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_icon(texture: Texture2D, size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _make_tool_chip(texture: Texture2D, caption: String) -> VBoxContainer:
	var chip := VBoxContainer.new()
	chip.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_theme_constant_override("separation", 8)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_child(_make_icon(texture, Vector2(96, 96)))
	var name_label := _make_label(caption, FONT_STRONG, 26, Color(0.34, 0.22, 0.14, 0.88))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(name_label)
	return chip


func _input(event: InputEvent) -> void:
	if not is_instance_valid(scroll):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_drag_press(event.pressed, event.position)
	elif event is InputEventMouseMotion and _drag_held:
		_handle_drag_motion(event.position)
	elif event is InputEventScreenTouch:
		_handle_drag_press(event.pressed, event.position)
	elif event is InputEventScreenDrag and _drag_held:
		_handle_drag_motion(event.position)


func _handle_drag_press(pressed: bool, position: Vector2) -> void:
	if pressed:
		if not scroll.get_global_rect().has_point(position):
			return
		_drag_held = true
		_drag_active = false
		_drag_origin = position
		_drag_scroll_origin = scroll.scroll_vertical
		return
	if _drag_active:
		get_viewport().set_input_as_handled()
	_drag_held = false
	_drag_active = false


func _handle_drag_motion(position: Vector2) -> void:
	var delta := position.y - _drag_origin.y
	if not _drag_active and absf(delta) >= DRAG_THRESHOLD:
		_drag_active = true
	if not _drag_active:
		return
	scroll.scroll_vertical = _drag_scroll_origin - int(delta)
	get_viewport().set_input_as_handled()


func _on_button_back_pressed() -> void:
	SoundManager.play("ButtonClick")
	if _overlay:
		queue_free()
		return
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file(PATH_SETTINGS)
