extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const ICON_PUZZLE: Texture2D = preload("res://images/ui_icon_puzzle.svg")
const ICON_BOLT: Texture2D = preload("res://images/ui_icon_bolt.svg")
const ICON_LIBRARY: Texture2D = preload("res://images/ui_icon_library.svg")
const ICON_DAILY: Texture2D = preload("res://images/ui_icon_daily.svg")
const INK := Color(0.22, 0.16, 0.1, 1)
const INK_SOFT := Color(0.48, 0.36, 0.26, 0.82)
const ORANGE := Color(0.96, 0.51, 0.01, 1)
const CARD_WHITE := Color(1, 0.997, 0.992, 1)
const PRICE := "1,99 €"

var _buy_button: Button
var _buy_blink: Tween

@onready var title_label: Label = $Header/Title
@onready var tagline_label: Label = $Header/TaglineRow/Tagline
@onready var body: VBoxContainer = $Scroll/Body


func _ready() -> void:
	title_label.text = _t("Shop", "Tienda")
	tagline_label.text = _t("ShopTagline", "Más contenido para CifraLetra")
	_style_back_button()
	_build_content()
	if not SignalManager.full_game_changed.is_connected(_build_content):
		SignalManager.full_game_changed.connect(_build_content)


func _exit_tree() -> void:
	if is_instance_valid(_buy_blink):
		_buy_blink.kill()


func _build_content() -> void:
	if is_instance_valid(_buy_blink):
		_buy_blink.kill()
	_buy_button = null
	for child in body.get_children():
		child.queue_free()
	var counts := _catalog_counts()
	body.add_child(_offer_card(counts))


func _catalog_counts() -> Dictionary:
	var total := 0
	var quick := 0
	var crypto := 0
	for item in GameManager.frases_db:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = item
		if GameManager.is_daily_puzzle(entry):
			continue
		total += 1
		if GameManager.level_game_mode(entry) == GameManager.MODE_CRYPTOGRAM:
			crypto += 1
		else:
			quick += 1
	if total <= 0:
		return {"total": 96, "quick": 72, "crypto": 24}
	return {"total": total, "quick": quick, "crypto": crypto}


func _offer_card(counts: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _white_card_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 36)
	card.add_child(margin)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 28)
	margin.add_child(col)

	var title := Label.new()
	title.text = _t("ShopFullTitle", "Compra el juego completo")
	title.add_theme_font_override("font", FONT_UI)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)

	var body_label := Label.new()
	var body_template := _t(
		"ShopFullBody",
		"Descubre las %s frases y disfruta de toda la experiencia de CifraLetra."
	)
	body_label.text = body_template % str(counts.total)
	body_label.add_theme_font_override("font", FONT_UI)
	body_label.add_theme_font_size_override("font_size", 34)
	body_label.add_theme_color_override("font_color", INK_SOFT)
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(body_label)

	var features := HBoxContainer.new()
	features.alignment = BoxContainer.ALIGNMENT_CENTER
	features.add_theme_constant_override("separation", 28)
	col.add_child(features)

	var pie := ShopPieChart.new()
	pie.custom_minimum_size = Vector2(380, 380)
	pie.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	features.add_child(pie)

	var stats := VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats.add_theme_constant_override("separation", 28)
	features.add_child(stats)
	stats.add_child(_stat_row(ICON_PUZZLE, _t("ShopPuzzles", "%s puzles") % str(counts.total)))
	stats.add_child(_stat_row(ICON_BOLT, _t("ShopQuick", "%s rápidos") % str(counts.quick)))
	stats.add_child(_stat_row(ICON_LIBRARY, _t("ShopCryptograms", "%s criptogramas") % str(counts.crypto)))
	stats.add_child(_stat_row(ICON_DAILY, _t("ShopDailyIncluded", "Reto diario incluido")))

	if GameManager.has_full_game():
		col.add_child(_owned_label())
	else:
		_buy_button = _make_buy_button()
		col.add_child(_buy_button)
		_start_buy_blink()
	return card


func _owned_label() -> Label:
	var owned := Label.new()
	owned.text = _t("ShopOwned", "Ya tienes el juego completo.")
	owned.add_theme_font_override("font", FONT_UI)
	owned.add_theme_font_size_override("font_size", 40)
	owned.add_theme_color_override("font_color", Color(0.18, 0.55, 0.32, 1))
	owned.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owned.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return owned


func _stat_row(tex: Texture2D, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(68, 68)
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", INK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	return row


func _make_buy_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 128)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var price := _t("ShopPrice", PRICE)
	button.text = _t("ShopBuy", "Comprar %s") % price
	button.add_theme_font_override("font", FONT_UI)
	button.add_theme_font_size_override("font_size", 48)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = ORANGE
	style.set_border_width_all(0)
	style.set_corner_radius_all(64)
	style.shadow_color = Color(0.96, 0.51, 0.01, 0.28)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.90, 0.46, 0.01, 1)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(_on_buy_pressed)
	return button


func _start_buy_blink() -> void:
	if _buy_button == null:
		return
	if is_instance_valid(_buy_blink):
		_buy_blink.kill()
	await get_tree().process_frame
	if not is_instance_valid(_buy_button):
		return
	_buy_button.pivot_offset = _buy_button.size * 0.5
	if not _buy_button.resized.is_connected(_on_buy_resized):
		_buy_button.resized.connect(_on_buy_resized)
	_buy_blink = create_tween()
	_buy_blink.set_loops()
	_buy_blink.set_trans(Tween.TRANS_SINE)
	_buy_blink.set_ease(Tween.EASE_IN_OUT)
	_buy_blink.tween_property(_buy_button, "scale", Vector2(1.03, 1.03), 0.55)
	_buy_blink.parallel().tween_property(_buy_button, "modulate", Color(1.06, 1.04, 1.02, 1), 0.55)
	_buy_blink.tween_property(_buy_button, "scale", Vector2.ONE, 0.55)
	_buy_blink.parallel().tween_property(_buy_button, "modulate", Color.WHITE, 0.55)
	_buy_blink.tween_interval(0.28)


func _on_buy_resized() -> void:
	if _buy_button:
		_buy_button.pivot_offset = _buy_button.size * 0.5


func _on_buy_pressed() -> void:
	SoundManager.play("ButtonClick")
	if _buy_button:
		GameManager.button_blink(_buy_button)
	GameManager.unlock_full_game()
	_build_content()


func _white_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_WHITE
	style.border_color = Color(0.9, 0.84, 0.76, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(36)
	style.shadow_color = Color(0.32, 0.2, 0.12, 0.08)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 6)
	return style


func _style_back_button() -> void:
	var back := $Header/ButtonBack as Button
	if back == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 1)
	style.set_border_width_all(0)
	style.set_corner_radius_all(80)
	style.shadow_color = Color(0.22, 0.16, 0.1, 0.1)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	back.add_theme_stylebox_override("normal", style)
	back.add_theme_stylebox_override("hover", style)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.97, 0.95, 0.92, 1)
	back.add_theme_stylebox_override("pressed", pressed)
	back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var arrow := back.get_node_or_null("ArrowIcon")
	if arrow:
		arrow.set("line_color", Color(0.55, 0.5, 0.46, 1))
		arrow.set("stroke_width", 11.0)


func _t(key: String, fallback: String) -> String:
	var value := tr(key)
	return fallback if value == key else value


func _go_to(path: String) -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file(path)


func _on_button_back_pressed() -> void:
	_go_to(PATH_MAIN)


class ShopPieChart extends Control:
	const ICON_SIZE := 88.0
	const TEX_CITA: Texture2D = preload("res://images/Citas.png")
	const TEX_CURIO: Texture2D = preload("res://images/Adivinanza.png")
	const TEX_FRAG: Texture2D = preload("res://images/FragmentosLiterarios.png")
	const TEX_EFEM: Texture2D = preload("res://images/Efemerides.png")

	var _icons: Array[TextureRect] = []
	var _slice_colors: Array[Color] = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slice_colors = [
			GameManager.category_color(GameManager.CAT_CITA),
			GameManager.category_color(GameManager.CAT_CURIOSIDADES),
			GameManager.category_color(GameManager.CAT_FRAGMENTO),
			GameManager.category_color(GameManager.CAT_EFEMERIDE),
		]
		_icons = [
			_make_icon(TEX_CITA),
			_make_icon(TEX_CURIO),
			_make_icon(TEX_FRAG),
			_make_icon(TEX_EFEM),
		]
		resized.connect(_place_icons)
		_place_icons()

	func _make_icon(tex: Texture2D) -> TextureRect:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.size = Vector2(ICON_SIZE, ICON_SIZE)
		add_child(icon)
		return icon

	func _place_icons() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5
		var offset := radius * 0.42
		var positions := [
			center + Vector2(-offset, -offset),
			center + Vector2(offset, -offset),
			center + Vector2(offset, offset),
			center + Vector2(-offset, offset),
		]
		for i in _icons.size():
			_icons[i].position = positions[i] - Vector2(ICON_SIZE, ICON_SIZE) * 0.5
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5
		if radius <= 2.0 or _slice_colors.size() < 4:
			return
		_draw_slice(center, radius, 180.0, 270.0, _slice_colors[0])
		_draw_slice(center, radius, 270.0, 360.0, _slice_colors[1])
		_draw_slice(center, radius, 0.0, 90.0, _slice_colors[2])
		_draw_slice(center, radius, 90.0, 180.0, _slice_colors[3])
		var line := Color(1, 1, 1, 0.92)
		draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), line, 6.0)
		draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), line, 6.0)

	func _draw_slice(center: Vector2, radius: float, start_deg: float, end_deg: float, color: Color) -> void:
		var points := PackedVector2Array()
		points.append(center)
		var steps := 28
		for i in range(steps + 1):
			var angle := deg_to_rad(lerpf(start_deg, end_deg, float(i) / float(steps)))
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		draw_colored_polygon(points, color)
