extends Control

const SIZE := Vector2i(1920, 1080)
const PATTERN := preload("res://images/Fondo.png")
const FONT_TITLE: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const PAPER := Color(0.960784, 0.913725, 0.854902, 1)
const INK := Color(0.18, 0.12, 0.08, 1)
const ACCENT := Color(0.92, 0.48, 0.08, 1)
const CARD := Color(1.0, 0.97, 0.92, 1)
const BEATS := [
	{
		"time": "0–4 s",
		"title": "¿PUEDES DESCIFRARLO?",
		"body": "Tablero cifrado a pantalla completa y zoom al centro.",
		"file": "res://images/trailer_resumen/01_pregunta.png",
	},
	{
		"time": "4–7 s",
		"title": "ESPERA",
		"body": "Aparecen TEMA, PISTA y REVELAR. TEMA pulsa.",
		"file": "res://images/trailer_resumen/02_espera.png",
	},
	{
		"time": "7–12 s",
		"title": "MIRA",
		"body": "El dedo pulsa TEMA. Entra la imagen real del puzle.",
		"file": "res://images/trailer_resumen/03_mira.png",
	},
	{
		"time": "12–20 s",
		"title": "DESCIFRA",
		"body": "Letras y correspondencias. Hipótesis y palabras.",
		"file": "res://images/trailer_resumen/04_descifra.png",
	},
	{
		"time": "20–30 s",
		"title": "DEDUCE",
		"body": "Error, corrección, colores y una pista.",
		"file": "res://images/trailer_resumen/05_deduce.png",
	},
	{
		"time": "30–36 s",
		"title": "DESCUBRE",
		"body": "Última letra, frase resuelta y estrellas.",
		"file": "res://images/trailer_resumen/06_descubre.png",
	},
	{
		"time": "36–42 s",
		"title": "CATEGORÍAS",
		"body": "Personajes, curiosidades, efemérides, literatura.",
		"file": "res://images/trailer_resumen/07_categorias.png",
	},
	{
		"time": "42–47 s",
		"title": "FICHAS",
		"body": "6 idiomas, +100 puzles, online, 2–5 min.",
		"file": "res://images/trailer_resumen/08_fichas.png",
	},
	{
		"time": "47–52 s",
		"title": "CIFRALETRA",
		"body": "Logo. MIRA · DESCIFRA · DESCUBRE.",
		"file": "res://images/trailer_resumen/09_logo.png",
	},
]

var _cards: Array[Panel] = []
var _hero: TextureRect
var _hero_time: Label
var _hero_title: Label
var _hero_body: Label
var _index := 0


func _enter_tree() -> void:
	_apply_fullhd()


func _ready() -> void:
	_apply_fullhd()
	_hide_overlays()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_select(0)
	_cycle()


func _apply_fullhd() -> void:
	var win := get_window()
	if win == null:
		return
	win.mode = Window.MODE_WINDOWED
	win.min_size = SIZE
	win.size = SIZE
	win.content_scale_size = SIZE
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _hide_overlays() -> void:
	for path in ["/root/TransitionScreen", "/root/StarCollectOverlay"]:
		var node := get_node_or_null(path)
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		if node is Node:
			node.process_mode = Node.PROCESS_MODE_DISABLED


func _build() -> void:
	var paper := ColorRect.new()
	paper.color = PAPER
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	_add_pattern()

	add_child(_label("CIFRALETRA  ·  RESUMEN DEL TRÁILER", 42, INK, Vector2(64, 28), Vector2(1200, 56)))
	add_child(_label("52 s   ·   1920×1080   ·   videos/trailer_cifraletra.mp4", 22, ACCENT, Vector2(64, 82), Vector2(900, 36)))

	_hero = TextureRect.new()
	_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_hero.position = Vector2(64, 140)
	_hero.size = Vector2(980, 552)
	add_child(_wrap(_hero, Vector2(64, 140), Vector2(980, 552)))

	_hero_time = _label("", 24, ACCENT, Vector2(64, 712), Vector2(400, 36))
	_hero_title = _label("", 40, INK, Vector2(64, 748), Vector2(980, 52))
	_hero_body = _label("", 26, Color(0.32, 0.22, 0.14, 1), Vector2(64, 804), Vector2(980, 70))
	add_child(_hero_time)
	add_child(_hero_title)
	add_child(_hero_body)

	var cols := 3
	var card := Vector2(248, 248)
	var origin := Vector2(1088, 140)
	var gap := Vector2(18, 18)
	for i in BEATS.size():
		var col := i % cols
		var row := int(i / cols)
		var pos := origin + Vector2(col * (card.x + gap.x), row * (card.y + gap.y))
		var panel := _beat_card(i, pos, card)
		add_child(panel)
		_cards.append(panel)


func _add_pattern() -> void:
	var field := Node2D.new()
	add_child(field)
	var sprite := Sprite2D.new()
	sprite.texture = PATTERN
	sprite.modulate = Color(0.59, 0.377, 0.313, 0.08)
	sprite.rotation = 0.523598
	sprite.scale = Vector2(3.2, 3.2)
	sprite.position = Vector2(960, 540)
	field.add_child(sprite)


func _beat_card(index: int, pos: Vector2, size: Vector2) -> Panel:
	var beat: Dictionary = BEATS[index]
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	panel.add_theme_stylebox_override("panel", _card_style(false))
	var thumb := TextureRect.new()
	thumb.name = "Thumb"
	thumb.texture = _tex(str(beat["file"]))
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.position = Vector2(12, 12)
	thumb.size = Vector2(size.x - 24, 148)
	panel.add_child(thumb)
	var time := _label(str(beat["time"]), 16, ACCENT, Vector2(14, 166), Vector2(size.x - 28, 24))
	var title := _label(str(beat["title"]), 18, INK, Vector2(14, 190), Vector2(size.x - 28, 44))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(time)
	panel.add_child(title)
	return panel


func _wrap(child: TextureRect, pos: Vector2, size: Vector2) -> Panel:
	var frame := Panel.new()
	frame.position = pos
	frame.size = size
	frame.add_theme_stylebox_override("panel", _card_style(true))
	child.position = Vector2(10, 10)
	child.size = size - Vector2(20, 20)
	frame.add_child(child)
	return frame


func _card_style(featured: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD
	style.set_border_width_all(3 if featured else 2)
	style.border_color = ACCENT if featured else Color(0.76, 0.56, 0.28, 0.7)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.14)
	style.shadow_size = 10 if featured else 6
	style.shadow_offset = Vector2(0, 6)
	return style


func _select(index: int) -> void:
	_index = index
	var beat: Dictionary = BEATS[index]
	_hero.texture = _tex(str(beat["file"]))
	_hero_time.text = str(beat["time"])
	_hero_title.text = str(beat["title"])
	_hero_body.text = str(beat["body"])
	for i in _cards.size():
		_cards[i].add_theme_stylebox_override("panel", _card_style(i == index))


func _cycle() -> void:
	var tw := create_tween()
	tw.set_loops()
	tw.tween_interval(2.4)
	tw.tween_callback(func() -> void:
		_select((_index + 1) % BEATS.size())
	)


func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded := load(path)
		if loaded is Texture2D:
			return loaded
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	return null


func _label(text: String, size: int, color: Color, pos: Vector2, box: Vector2) -> Label:
	var lab := Label.new()
	lab.text = text
	lab.position = pos
	lab.size = box
	var font := FontVariation.new()
	font.base_font = FONT_TITLE if size >= 28 else FONT_UI
	font.spacing_space = 6
	lab.add_theme_font_override("font", font)
	lab.add_theme_font_size_override("font_size", size)
	lab.add_theme_color_override("font_color", color)
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lab
