extends Control

const SIZE := Vector2i(1920, 1080)
const PATTERN := preload("res://images/Fondo.png")
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const FONT_TITLE: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_CELL: Font = preload("res://fonts/Fonts/Montserrat/static/Montserrat-SemiBold.ttf")
const HAND_TEX: Texture2D = preload("res://images/tutorial/hand_pointer.png")
const THEME_ICON: Texture2D = preload("res://images/ui_icon_theme_white.svg")
const BULB_ICON: Texture2D = preload("res://images/ui_icon_bulb_white.svg")
const EYE_ICON: Texture2D = preload("res://GUI/Library/Demo/Demo_ItemIcon_(OriginalSize)/itemicon_eye.png")
const STAR_TEX: Texture2D = preload("res://images/estrella_plano.png")
const LOGO_TEX: Texture2D = preload("res://images/Icono.png")
const THEME_IMAGE: Texture2D = preload("res://data/images/image3049.png")
const ICON_CITA: Texture2D = preload("res://images/Ilustres.png")
const ICON_CURIO: Texture2D = preload("res://images/Adivinanza.png")
const ICON_EFEM: Texture2D = preload("res://images/Efemerides.png")
const ICON_FRAG: Texture2D = preload("res://images/FragmentosLiterarios.png")

const PAPER := Color(0.960784, 0.913725, 0.854902, 1)
const INK := Color(0.18, 0.12, 0.08, 1)
const CELL_BG := Color(0.975, 0.965, 0.945, 1)
const CELL_FILL := Color(0.78, 0.76, 0.74, 1)
const GREEN := Color(0.22, 0.62, 0.28, 1)
const RED := Color(0.81, 0.08, 0.08, 1)
const HINT_Y := Color(1.0, 0.86, 0.18, 1)
const SAME_Y := Color(1.0, 0.94, 0.68, 1)
const TITLE_A := Color(0.48, 0.24, 0.10, 1)
const TITLE_B := Color(0.92, 0.48, 0.08, 1)
const COLOR_VOWEL := Color(1.0, 0.8, 0.6, 1)
const COLOR_CONS := Color(0.6, 0.8, 1.0, 1)

const LINES: PackedStringArray = [
	"VOLVERAN LAS",
	"OSCURAS",
	"GOLONDRINAS",
	"EN TU BALCON",
	"SUS NIDOS A",
	"COLGAR",
]
const CIPHER := {
	"A": 4, "B": 19, "C": 11, "D": 23, "E": 7,
	"G": 15, "I": 2, "L": 18, "N": 9, "O": 12,
	"R": 6, "S": 21, "T": 14, "U": 3, "V": 16,
}
const CELL := Vector2(86, 108)
const GAP := 5.0
const HAND_SCALE := 0.155

var _board_rig: Control
var _board: Control
var _hud: Control
var _btn_tema: Panel
var _btn_pista: Panel
var _btn_revelar: Panel
var _theme_card: Control
var _hand: Sprite2D
var _dim: ColorRect
var _fx: Control
var _titles: Control
var _carousel: Control
var _features: Control
var _logo: Control
var _cells: Array[Dictionary] = []
var _start_scale := 1.85
var _end_scale := 0.94
var _hand_tween: Tween
var _end_pos := Vector2.ZERO
var _start_pos := Vector2.ZERO


func _enter_tree() -> void:
	_apply_fullhd()


func _ready() -> void:
	_apply_fullhd()
	_silence_music()
	_hide_overlays()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_stage()
	await _play()


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


func _silence_music() -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_mute(idx, true)


func _hide_overlays() -> void:
	for path in ["/root/TransitionScreen", "/root/StarCollectOverlay"]:
		var node := get_node_or_null(path)
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		if node is Node:
			node.process_mode = Node.PROCESS_MODE_DISABLED


func _build_stage() -> void:
	var paper := ColorRect.new()
	paper.color = PAPER
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	_add_pattern()

	_board = _build_board()
	var board_size := _board.size
	_board_rig = Control.new()
	_board_rig.name = "BoardRig"
	_board_rig.size = board_size
	_board_rig.pivot_offset = board_size * 0.5
	_end_pos = Vector2((SIZE.x - board_size.x) * 0.5, 268)
	_start_pos = Vector2((SIZE.x - board_size.x) * 0.5, (SIZE.y - board_size.y) * 0.42)
	_board_rig.position = _start_pos
	_board_rig.scale = Vector2(_start_scale, _start_scale)
	_board_rig.add_child(_board)
	add_child(_board_rig)

	_dim = ColorRect.new()
	_dim.color = Color(0.08, 0.05, 0.03, 0.0)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	_hud = _build_hud()
	_hud.modulate.a = 0.0
	_hud.position = Vector2(0, -40)
	add_child(_hud)

	_theme_card = _build_theme_card()
	_theme_card.position = Vector2(-720, 210)
	_theme_card.modulate.a = 0.0
	add_child(_theme_card)

	_titles = Control.new()
	_titles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_titles)

	_carousel = _build_carousel()
	_carousel.modulate.a = 0.0
	add_child(_carousel)

	_features = _build_features()
	_features.modulate.a = 0.0
	add_child(_features)

	_logo = _build_logo()
	_logo.modulate.a = 0.0
	add_child(_logo)

	_fx = Control.new()
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx)

	_hand = Sprite2D.new()
	_hand.texture = HAND_TEX
	_hand.centered = true
	_hand.scale = Vector2(HAND_SCALE, HAND_SCALE)
	_hand.visible = false
	_hand.z_index = 40
	add_child(_hand)


func _add_pattern() -> void:
	var field := Node2D.new()
	field.name = "Pattern"
	add_child(field)
	var sprite := Sprite2D.new()
	sprite.texture = PATTERN
	sprite.modulate = Color(0.59, 0.377, 0.313, 0.10)
	sprite.rotation = 0.523598
	sprite.scale = Vector2(3.81806, 3.81806)
	sprite.position = Vector2(960, 540)
	field.add_child(sprite)
	var tw := create_tween()
	tw.tween_property(field, "position", Vector2(80, -70), 52.0).set_trans(Tween.TRANS_LINEAR)


func _build_board() -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cols := 0
	for line in LINES:
		cols = maxi(cols, line.length())
	var rows := LINES.size()
	root.size = Vector2(
		cols * CELL.x + (cols - 1) * GAP,
		rows * CELL.y + (rows - 1) * GAP
	)
	for r in rows:
		var line: String = LINES[r]
		for c in line.length():
			var ch := line.substr(c, 1)
			var cell := _make_cell(ch)
			cell["node"].position = Vector2(c * (CELL.x + GAP), r * (CELL.y + GAP))
			root.add_child(cell["node"])
			_cells.append(cell)
	return root


func _make_cell(ch: String) -> Dictionary:
	var is_space := ch == " "
	var panel := Panel.new()
	panel.custom_minimum_size = CELL
	panel.size = CELL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.09, 0.08, 1) if is_space else CELL_BG
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.12, 0.10, 0.08, 0.88)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	panel.add_theme_stylebox_override("panel", style)
	var number := Label.new()
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	number.add_theme_font_override("font", FONT_CELL)
	number.add_theme_font_size_override("font_size", 22)
	number.add_theme_color_override("font_color", INK)
	number.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	number.offset_top = 4
	number.visible = not is_space
	if not is_space:
		number.text = str(int(CIPHER.get(ch, 1)))
	panel.add_child(number)
	var letter := Label.new()
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter.add_theme_font_override("font", FONT_CELL)
	letter.add_theme_font_size_override("font_size", 56)
	letter.add_theme_color_override("font_color", INK)
	letter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	letter.offset_top = 16
	letter.visible = false
	panel.add_child(letter)
	return {
		"ch": ch,
		"space": is_space,
		"node": panel,
		"style": style,
		"number": number,
		"letter": letter,
		"shown": false,
	}


func _build_hud() -> Control:
	var bar := Control.new()
	bar.size = Vector2(SIZE.x, 180)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_tema = _hud_button("TEMA", THEME_ICON, Color(0.12, 0.62, 0.58, 1), Color(0.05, 0.38, 0.36, 1))
	_btn_pista = _hud_button("PISTA", BULB_ICON, Color(1.0, 0.72, 0.08, 1), Color(0.82, 0.42, 0.02, 1))
	_btn_revelar = _hud_button("REVELAR", EYE_ICON, Color(0.38, 0.25, 0.72, 1), Color(0.22, 0.13, 0.49, 1))
	var total_w := 340.0 * 3.0 + 24.0 * 2.0
	var x0 := (SIZE.x - total_w) * 0.5
	_btn_tema.position = Vector2(x0, 28)
	_btn_pista.position = Vector2(x0 + 364, 28)
	_btn_revelar.position = Vector2(x0 + 728, 28)
	bar.add_child(_btn_tema)
	bar.add_child(_btn_pista)
	bar.add_child(_btn_revelar)
	return bar


func _hud_button(title: String, icon: Texture2D, fill: Color, border: Color) -> Panel:
	var btn := Panel.new()
	btn.custom_minimum_size = Vector2(340, 132)
	btn.size = Vector2(340, 132)
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.set_border_width_all(4)
	normal.border_width_bottom = 10
	normal.border_color = border
	normal.set_corner_radius_all(28)
	normal.shadow_color = Color(0, 0, 0, 0.24)
	normal.shadow_size = 10
	normal.shadow_offset = Vector2(0, 8)
	btn.add_theme_stylebox_override("panel", normal)
	var tex := TextureRect.new()
	tex.texture = icon
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.position = Vector2(20, 32)
	tex.size = Vector2(70, 70)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tex)
	var lab := Label.new()
	lab.text = title
	lab.position = Vector2(100, 30)
	lab.size = Vector2(220, 72)
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.add_theme_font_override("font", FONT_UI)
	lab.add_theme_font_size_override("font_size", 40)
	lab.add_theme_color_override("font_color", Color(1, 1, 0.96, 1))
	btn.add_child(lab)
	return btn


func _build_theme_card() -> Control:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(620, 620)
	card.size = Vector2(620, 620)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.949, 0.804, 1)
	style.set_border_width_all(5)
	style.border_width_bottom = 10
	style.border_color = Color(0.76, 0.56, 0.28, 0.78)
	style.set_corner_radius_all(36)
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 14)
	card.add_theme_stylebox_override("panel", style)
	var img := TextureRect.new()
	img.texture = THEME_IMAGE
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.position = Vector2(28, 28)
	img.size = Vector2(564, 564)
	card.add_child(img)
	return card


func _build_carousel() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var items := [
		{"title": "PERSONAJES", "icon": ICON_CITA, "img": "res://data/images/image3085.png", "color": Color(0.106, 0.541, 0.812)},
		{"title": "CURIOSIDADES", "icon": ICON_CURIO, "img": "res://data/images/image1060.png", "color": Color(0.812, 0.463, 0.176)},
		{"title": "EFEMÉRIDES", "icon": ICON_EFEM, "img": "res://data/images/image5.png", "color": Color(0.812, 0.408, 0.38)},
		{"title": "LITERATURA", "icon": ICON_FRAG, "img": "res://data/images/image3058.png", "color": Color(0.4, 0.824, 0.698)},
	]
	var x := 70.0
	for item in items:
		var card := _category_card(item)
		card.position = Vector2(x, 220)
		root.add_child(card)
		x += 460
	return root


func _category_card(item: Dictionary) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(430, 640)
	card.size = Vector2(430, 640)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.96, 0.90, 1)
	style.set_border_width_all(4)
	style.border_color = item["color"]
	style.set_corner_radius_all(28)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 10)
	style.shadow_color = Color(0, 0, 0, 0.18)
	card.add_theme_stylebox_override("panel", style)
	var icon := TextureRect.new()
	icon.texture = item["icon"]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(155, 28)
	icon.size = Vector2(120, 120)
	card.add_child(icon)
	var title := _plain_label(item["title"], 34, INK)
	title.position = Vector2(20, 150)
	title.size = Vector2(390, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)
	var img := TextureRect.new()
	var path := str(item["img"])
	if ResourceLoader.exists(path):
		img.texture = load(path)
	else:
		img.texture = THEME_IMAGE
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.position = Vector2(28, 214)
	img.size = Vector2(374, 390)
	card.add_child(img)
	return card


func _build_features() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var texts := [
		["6", "IDIOMAS"],
		["+100", "PUZLES"],
		["ONLINE", "CLASIFICACIÓN"],
		["2–5", "MINUTOS"],
	]
	var colors := [
		Color(0.12, 0.62, 0.58, 1),
		Color(0.92, 0.48, 0.08, 1),
		Color(0.38, 0.25, 0.72, 1),
		Color(0.22, 0.62, 0.28, 1),
	]
	var x := 80.0
	for i in texts.size():
		var card := Panel.new()
		card.size = Vector2(420, 360)
		card.position = Vector2(x, 360)
		var style := StyleBoxFlat.new()
		style.bg_color = colors[i]
		style.set_corner_radius_all(32)
		style.shadow_size = 18
		style.shadow_offset = Vector2(0, 12)
		style.shadow_color = Color(0, 0, 0, 0.2)
		card.add_theme_stylebox_override("panel", style)
		var a := _plain_label(texts[i][0], 72, Color(1, 1, 0.96, 1))
		a.position = Vector2(20, 80)
		a.size = Vector2(380, 100)
		a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var b := _plain_label(texts[i][1], 36, Color(1, 1, 0.96, 1))
		b.position = Vector2(20, 200)
		b.size = Vector2(380, 70)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(a)
		card.add_child(b)
		root.add_child(card)
		x += 460
	return root


func _build_logo() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var icon := TextureRect.new()
	icon.texture = LOGO_TEX
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon.position = Vector2(810, 200)
	icon.size = Vector2(300, 300)
	root.add_child(icon)
	var name := _plain_label("CifraLetra", 86, TITLE_A)
	name.position = Vector2(160, 600)
	name.size = Vector2(1600, 110)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(name)
	var tag := _plain_label("MIRA  ·  DESCIFRA  ·  DESCUBRE", 40, TITLE_B)
	tag.position = Vector2(160, 720)
	tag.size = Vector2(1600, 70)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(tag)
	return root


func _plain_label(text: String, size: int, color: Color) -> Label:
	var lab := Label.new()
	lab.text = text
	var font := FontVariation.new()
	font.base_font = FONT_TITLE
	font.spacing_space = 8
	font.spacing_glyph = 1
	lab.add_theme_font_override("font", font)
	lab.add_theme_font_size_override("font_size", size)
	lab.add_theme_color_override("font_color", color)
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lab


func _play() -> void:
	_zoom_board(6.4)
	_fly_question()
	await _wait(4.0)
	_show_espera()
	await _wait(3.0)
	await _act_mira()
	await _act_descifra()
	await _act_descubre()
	await _act_carousel()
	await _act_features()
	await _act_logo()
	await _wait(1.2)


func _zoom_board(duration: float) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_board_rig, "scale", Vector2(_end_scale, _end_scale), duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_board_rig, "position", _end_pos, duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _fly_question() -> void:
	var lab := _cinematic("¿PUEDES DESCIFRARLO?", 78)
	lab.position = Vector2(-1400, 460)
	lab.size = Vector2(1920, 140)
	_titles.add_child(lab)
	var tw := create_tween()
	tw.tween_property(lab, "position:x", 0.0, 1.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.85)
	tw.tween_property(lab, "position:x", 2100.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(lab.queue_free)


func _show_espera() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dim, "color:a", 0.28, 0.7)
	tw.tween_property(_hud, "modulate:a", 1.0, 0.55)
	tw.tween_property(_hud, "position:y", 0.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var lab := _cinematic("ESPERA…", 92)
	lab.position = Vector2(0, 820)
	lab.size = Vector2(1920, 130)
	lab.modulate.a = 0.0
	_titles.add_child(lab)
	var fade := create_tween()
	fade.tween_property(lab, "modulate:a", 1.0, 0.35)
	fade.tween_interval(1.6)
	fade.tween_property(lab, "modulate:a", 0.0, 0.35)
	fade.tween_callback(lab.queue_free)
	_pulse_button(_btn_tema)


func _act_mira() -> void:
	await _wait(0.15)
	await _hand_tap_control(_btn_tema)
	_sfx("ButtonClick")
	_press_flash(_btn_tema)
	var slide := create_tween()
	slide.set_parallel(true)
	slide.tween_property(_board_rig, "position:x", _end_pos.x + 620.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	slide.tween_property(_hud, "position:x", 520.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	slide.tween_property(_theme_card, "position:x", 80.0, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_property(_theme_card, "modulate:a", 1.0, 0.4)
	slide.tween_property(_dim, "color:a", 0.12, 0.4)
	await _wait(0.35)
	_title_hold("MIRA", 0.2, 3.6, 36.0, 80.0)
	_caption_hold("La imagen te da contexto y una primera pista.", 0.45, 3.2)
	_hide_hand()
	await _wait(4.15)


func _act_descifra() -> void:
	var back := create_tween()
	back.set_parallel(true)
	back.tween_property(_theme_card, "position:x", -760.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	back.tween_property(_theme_card, "modulate:a", 0.0, 0.45)
	back.tween_property(_board_rig, "position", _end_pos, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	back.tween_property(_hud, "position:x", 0.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	back.tween_property(_dim, "color:a", 0.08, 0.4)
	_title_hold("DESCIFRA", 0.15, 2.4, 172.0)
	await _wait(0.75)

	_caption_hold("HAZ HIPÓTESIS", 0.0, 2.8)
	await _hand_tap_cell("A")
	await _reveal_letter("A", GREEN)
	_hide_hand()
	await _wait(1.15)

	_caption_hold("RECONOCE PALABRAS", 0.0, 3.0)
	await _hand_tap_cell("O")
	await _reveal_letter("O", GREEN)
	await _wait(0.55)
	await _reveal_letter("S", INK)
	_hide_hand()
	await _wait(0.85)

	_caption_hold("PRUEBA  →  EQUIVÓCATE  →  CORRIGE", 0.0, 4.2)
	var wrong := _first_cell("V")
	await _hand_tap_node(wrong["node"])
	_write_cell(wrong, "E", RED, CELL_BG)
	_sfx_red()
	_show_cross(wrong["node"])
	await _wait(1.15)
	_write_cell(wrong, "", INK, CELL_BG)
	await _hand_tap_node(wrong["node"])
	await _reveal_letter("V", GREEN)
	_hide_hand()
	await _wait(0.7)

	await _reveal_letter("N", INK)
	await _wait(0.35)
	_paint_group("AEO", COLOR_VOWEL)
	_paint_group("NL", COLOR_CONS)
	_caption_hold("DEDUCE", 0.0, 3.2)
	await _wait(0.55)
	await _hand_tap_control(_btn_pista)
	_sfx("ButtonClick")
	_press_flash(_btn_pista)
	await _reveal_letter("G", HINT_Y)
	_pulse_letter("G")
	_hide_hand()
	await _wait(0.7)
	await _reveal_letter("L", INK)
	await _wait(0.45)
	await _reveal_letter("R", INK)
	await _wait(0.35)
	await _reveal_letter("U", INK)
	await _wait(0.2)
	await _reveal_letter("C", INK)
	await _wait(0.35)
	await _reveal_letter("D", INK)
	await _wait(0.2)
	await _reveal_letter("I", INK)
	await _wait(2.4)


func _act_descubre() -> void:
	_title_hold("DESCUBRE", 0.0, 5.4, 172.0)
	await _hand_tap_cell("T")
	await _reveal_letter("T", GREEN)
	await _wait(0.35)
	await _reveal_letter("B", GREEN)
	await _wait(0.2)
	await _reveal_letter("E", GREEN)
	_finish_all_green()
	_sfx("PlayAvailable")
	_burst_stars()
	_hide_hand()
	_caption_hold("Volverán las oscuras golondrinas…", 0.25, 4.4)
	await _wait(5.8)


func _act_carousel() -> void:
	var out := create_tween()
	out.set_parallel(true)
	out.tween_property(_board_rig, "position:x", 2100.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	out.tween_property(_hud, "position:x", 2100.0, 0.55)
	out.tween_property(_dim, "color:a", 0.0, 0.3)
	await _wait(0.25)
	_carousel.position.x = -300
	var inn := create_tween()
	inn.set_parallel(true)
	inn.tween_property(_carousel, "modulate:a", 1.0, 0.3)
	inn.tween_property(_carousel, "position:x", 0.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await _wait(5.1)
	var leave := create_tween()
	leave.set_parallel(true)
	leave.tween_property(_carousel, "position:x", 2200.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	leave.tween_property(_carousel, "modulate:a", 0.0, 0.4)


func _act_features() -> void:
	_features.position.y = 80
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_features, "modulate:a", 1.0, 0.35)
	tw.tween_property(_features, "position:y", 0.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _wait(5.0)
	var out := create_tween()
	out.tween_property(_features, "modulate:a", 0.0, 0.35)
	await out.finished


func _act_logo() -> void:
	_logo.scale = Vector2(0.86, 0.86)
	_logo.pivot_offset = Vector2(SIZE) * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_logo, "modulate:a", 1.0, 0.45)
	tw.tween_property(_logo, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _wait(4.8)


func _cinematic(text: String, size: int) -> Label:
	var lab := _plain_label(text, size, TITLE_A)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_color_override("font_outline_color", Color(0.96, 0.90, 0.82, 0.9))
	lab.add_theme_constant_override("outline_size", 10)
	return lab


func _title_hold(text: String, delay: float, hold: float, y: float, x: float = 0.0) -> void:
	var lab := _cinematic(text, 68)
	lab.position = Vector2(x, y)
	lab.size = Vector2(1920.0 - x, 72)
	if x > 0.0:
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lab.modulate.a = 0.0
	_titles.add_child(lab)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(lab, "modulate:a", 1.0, 0.22)
	tw.tween_interval(hold)
	tw.tween_property(lab, "modulate:a", 0.0, 0.28)
	tw.tween_callback(lab.queue_free)


func _caption_hold(text: String, delay: float, hold: float) -> void:
	var lab := _plain_label(text, 36, TITLE_A)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector2(80, 992)
	lab.size = Vector2(1760, 60)
	lab.modulate.a = 0.0
	_titles.add_child(lab)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(lab, "modulate:a", 1.0, 0.2)
	tw.tween_interval(hold)
	tw.tween_property(lab, "modulate:a", 0.0, 0.25)
	tw.tween_callback(lab.queue_free)


func _reveal_letter(ch: String, color: Color) -> void:
	var first := true
	for cell in _cells:
		if cell["space"] or cell["ch"] != ch:
			continue
		_write_cell(cell, ch, color, SAME_Y if first else CELL_FILL)
		var node: Control = cell["node"]
		node.pivot_offset = CELL * 0.5
		node.scale = Vector2(1.18, 1.18)
		var tw := create_tween()
		tw.tween_property(node, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if first:
			_sfx("ClickLetra")
			first = false
	await _wait(0.22)
	for cell in _cells:
		if cell["space"] or cell["ch"] != ch:
			continue
		cell["style"].bg_color = CELL_FILL


func _write_cell(cell: Dictionary, letter: String, color: Color, bg: Color) -> void:
	var lab: Label = cell["letter"]
	lab.text = letter
	lab.visible = letter != ""
	lab.add_theme_color_override("font_color", color)
	cell["style"].bg_color = bg
	cell["shown"] = letter != ""


func _finish_all_green() -> void:
	for cell in _cells:
		if cell["space"]:
			continue
		_write_cell(cell, cell["ch"], GREEN, Color(0.93, 0.97, 0.90, 1))


func _paint_group(letters: String, bg: Color) -> void:
	for cell in _cells:
		if cell["space"] or not cell["shown"]:
			continue
		if letters.find(cell["ch"]) >= 0:
			cell["style"].bg_color = bg


func _pulse_letter(ch: String) -> void:
	for cell in _cells:
		if cell["ch"] != ch or cell["space"]:
			continue
		var node: Control = cell["node"]
		node.pivot_offset = CELL * 0.5
		var tw := create_tween()
		tw.tween_property(node, "scale", Vector2(1.12, 1.12), 0.16)
		tw.tween_property(node, "scale", Vector2.ONE, 0.16)


func _first_cell(ch: String) -> Dictionary:
	for cell in _cells:
		if not cell["space"] and cell["ch"] == ch:
			return cell
	return _cells[0]


func _cell_screen_center(cell: Dictionary) -> Vector2:
	var node: Control = cell["node"]
	return node.global_position + CELL * 0.5 * _board_rig.scale.x


func _hand_tap_cell(ch: String) -> void:
	await _hand_tap_node(_first_cell(ch)["node"])


func _hand_tap_node(node: Control) -> void:
	var tip := node.get_global_rect().get_center()
	await _hand_tap(tip)


func _hand_tap_control(node: Control) -> void:
	await _hand_tap(node.get_global_rect().get_center())


func _hand_tap(target: Vector2) -> void:
	if is_instance_valid(_hand_tween):
		_hand_tween.kill()
	_hand.visible = true
	_hand.modulate.a = 1.0
	var dest := target + Vector2(46, 78)
	if _hand.position.length() < 2.0:
		_hand.position = dest + Vector2(280, 200)
	var tw := create_tween()
	tw.tween_property(_hand, "position", dest, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	var tap := create_tween()
	tap.tween_property(_hand, "scale", Vector2(HAND_SCALE * 0.86, HAND_SCALE * 0.86), 0.08)
	tap.tween_property(_hand, "scale", Vector2(HAND_SCALE, HAND_SCALE), 0.1)
	await tap.finished


func _hide_hand() -> void:
	if is_instance_valid(_hand_tween):
		_hand_tween.kill()
	if _hand == null or not _hand.visible:
		return
	_hand_tween = create_tween()
	_hand_tween.tween_property(_hand, "modulate:a", 0.0, 0.2)
	_hand_tween.tween_callback(func() -> void:
		_hand.visible = false
		_hand.position = Vector2.ZERO
	)


func _pulse_button(btn: Control) -> void:
	btn.pivot_offset = btn.size * 0.5
	var tw := create_tween()
	tw.set_loops(3)
	tw.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.28).set_trans(Tween.TRANS_SINE)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_SINE)


func _press_flash(btn: Control) -> void:
	btn.pivot_offset = btn.size * 0.5
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.07)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.12)


func _show_cross(node: Control) -> void:
	var mark := _plain_label("X", 72, RED)
	mark.position = node.get_global_rect().position + Vector2(8, -70)
	mark.size = Vector2(90, 80)
	_fx.add_child(mark)
	var tw := create_tween()
	tw.tween_property(mark, "position:y", mark.position.y - 30.0, 0.55)
	tw.parallel().tween_property(mark, "modulate:a", 0.0, 0.55)
	tw.tween_callback(mark.queue_free)


func _burst_stars() -> void:
	var origin := Vector2(SIZE) * 0.5 + Vector2(0, 40)
	for i in 18:
		var star := TextureRect.new()
		star.texture = STAR_TEX
		star.modulate = Color(1.0, 0.82, 0.12, 1)
		star.size = Vector2(56, 56)
		star.position = origin
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fx.add_child(star)
		var angle := TAU * float(i) / 18.0
		var dest := origin + Vector2(cos(angle), sin(angle)) * randf_range(220.0, 420.0)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(star, "position", dest, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(star, "modulate:a", 0.0, 0.85)
		tw.tween_property(star, "rotation", randf_range(-1.2, 1.2), 0.85)
		tw.chain().tween_callback(star.queue_free)


func _sfx(name: String) -> void:
	if typeof(SoundManager) == TYPE_NIL:
		return
	SoundManager.play(name)


func _sfx_red() -> void:
	if typeof(SoundManager) == TYPE_NIL:
		return
	if SoundManager.has_method("play_red_letter_click"):
		SoundManager.play_red_letter_click()
	else:
		SoundManager.play("LoseLive")


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, false).timeout
