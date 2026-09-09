extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const PATH_SHOP := "res://scenes/MenuShop.tscn"
const PATH_APP := "res://scenes/App.tscn"
const PATH_LIBRARY := "res://scenes/MenuLibrary.tscn"
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const ICON_CITA: Texture2D = preload("res://images/Citas.png")
const ICON_EFEM: Texture2D = preload("res://images/Efemerides.png")
const ICON_CURIO: Texture2D = preload("res://images/Adivinanza.png")
const ICON_FRAG: Texture2D = preload("res://images/FragmentosLiterarios.png")
const ICON_QUICK: Texture2D = preload("res://images/mode_quick.svg")
const ICON_LUPA: Texture2D = preload("res://images/ui_icon_lupa.svg")
const ICON_DAILY: Texture2D = preload("res://images/ui_icon_daily.svg")
const ICON_LIBRARY: Texture2D = preload("res://images/ui_icon_library.svg")
const ICON_CLOCK: Texture2D = preload("res://images/stats_icon_clock.svg")
const ICON_PLAY: Texture2D = preload("res://GUI/BotonPlaySimboloTextura.png")
const ICON_BULB: Texture2D = preload("res://images/ui_icon_bulb_white.svg")
const ICON_SIGNAL: Texture2D = preload("res://images/ui_icon_signal.svg")
const ICON_PEOPLE: Texture2D = preload("res://images/ui_icon_people.svg")
const STAR_ON: Texture2D = preload("res://images/estrella_plano.png")
const STAR_OFF: Texture2D = preload("res://images/contorno_estrella.png")
const INK := Color(0.22, 0.16, 0.1, 1)
const INK_SOFT := Color(0.48, 0.36, 0.26, 0.82)
const TEAL := Color(0.31, 0.74, 0.76, 1)
const ORANGE := Color(0.96, 0.51, 0.01, 1)
const CARD_WHITE := Color(1, 0.997, 0.992, 1)
const ICON_TEAL := Color(0.22, 0.62, 0.66, 1)
const ICON_BROWN := Color(0.55, 0.38, 0.24, 1)

var _item: Dictionary = {}
var _play_button: Button
var _completed_box: VBoxContainer

@onready var brand_cifra: Label = $Header/Brand/Cifra
@onready var brand_letra: Label = $Header/Brand/Letra
@onready var title_label: Label = $Header/Title
@onready var tagline_label: Label = $Header/TaglineRow/Tagline
@onready var body: VBoxContainer = $Scroll/Body
@onready var footer: VBoxContainer = $Footer
@onready var version_label: Label = $Version
@onready var lock_overlay: Control = $LockOverlay


func _ready() -> void:
	brand_cifra.text = tr("Cipher")
	brand_letra.text = tr("Letter")
	title_label.text = tr("DailyChallenge")
	tagline_label.text = tr("DailyTagline")
	version_label.text = "%s %s" % [tr("Version"), PlayerPrefs.version_display()]
	version_label.visible = false
	_style_back_button()
	_apply_lock_texts()
	if not SignalManager.full_game_changed.is_connected(_refresh_purchase_lock):
		SignalManager.full_game_changed.connect(_refresh_purchase_lock)
	_refresh_purchase_lock()


func _refresh_purchase_lock() -> void:
	_apply_lock_texts()
	if not GameManager.has_full_game():
		$Scroll.visible = false
		footer.visible = false
		lock_overlay.visible = true
		return
	lock_overlay.visible = false
	$Scroll.visible = true
	footer.visible = true
	_item = GameManager.todays_daily_item()
	_build_content()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
		_item = GameManager.advance_daily_to_next()
		_build_content()
		get_viewport().set_input_as_handled()


func _build_content() -> void:
	for child in body.get_children():
		child.queue_free()
	for child in footer.get_children():
		child.queue_free()
	var done := PlayerPrefs.is_daily_completed_today()
	body.add_child(_date_card(done))
	body.add_child(_how_card())
	body.add_child(_image_block(done))
	body.add_child(_details_card())
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	body.add_child(spacer)
	_play_button = _make_play_button()
	_completed_box = _make_completed_box()
	footer.add_child(_play_button)
	footer.add_child(_completed_box)
	_play_button.visible = not done
	_completed_box.visible = done
	if _item.is_empty():
		_play_button.disabled = true


func _date_card(done: bool) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(0, 196)
	card.add_theme_stylebox_override("panel", _white_card_style())
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 28
	row.offset_right = -28
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(row)
	var icon := _circle_icon(ICON_DAILY, 128, Color(0.9, 0.97, 0.97, 1), Color.WHITE, 0.14)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	row.add_child(col)
	var date := Label.new()
	date.text = GameManager.format_long_date()
	date.add_theme_font_override("font", FONT_UI)
	date.add_theme_font_size_override("font_size", 38)
	date.add_theme_color_override("font_color", INK)
	col.add_child(date)
	var status := Label.new()
	status.text = tr("DailyCompletedShort") if done else tr("DailyAvailable")
	status.add_theme_font_override("font", FONT_UI)
	status.add_theme_font_size_override("font_size", 36)
	status.add_theme_color_override("font_color", Color(0.18, 0.55, 0.32, 1) if done else INK_SOFT)
	col.add_child(status)
	var sparkles := Label.new()
	sparkles.text = "✦"
	sparkles.add_theme_font_size_override("font_size", 40)
	sparkles.add_theme_color_override("font_color", Color(0.98, 0.78, 0.28, 1))
	sparkles.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sparkles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sparkles)
	return card


func _image_block(done: bool) -> CenterContainer:
	return _square_image(str(_item.get("category", "")), done)


func _details_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _white_card_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	card.add_child(margin)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 16)
	margin.add_child(col)
	var cat_id := str(_item.get("category", ""))
	var mode := GameManager.level_game_mode(_item)
	var is_crypto := mode == GameManager.MODE_CRYPTOGRAM
	var diff_name := tr("Medium") if int(_item.get("difficulty", 1)) == 2 else GameManager.difficulty_display_name(int(_item.get("difficulty", 1)))
	col.add_child(_centered_meta(ICON_LUPA if is_crypto else ICON_QUICK, tr("DailyType") % (
		tr("Cryptogram") if is_crypto else tr("Quick")
	), INK_SOFT))
	col.add_child(_centered_meta(ICON_SIGNAL, "%s %s" % [
		tr("DailyDifficulty").replace("%s", "").strip_edges(),
		diff_name
	], ORANGE))
	col.add_child(_centered_meta(ICON_CLOCK, tr("DailyEstimated") % (
		tr("TimeCryptoRange") if is_crypto else tr("TimeQuickRange")
	), ICON_TEAL))
	col.add_child(_centered_text(_teaser_for(cat_id), 32, INK_SOFT))
	return card


func _square_image(cat_id: String, done: bool) -> CenterContainer:
	var wrap := CenterContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var frame := Panel.new()
	frame.clip_contents = true
	frame.custom_minimum_size = Vector2(760, 760)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.93, 0.9, 0.86, 1)
	frame_style.set_corner_radius_all(28)
	frame.add_theme_stylebox_override("panel", frame_style)
	var image := TextureRect.new()
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := GameManager.find_level_image_path(int(_item.get("image_number", -1)))
	if path != "":
		var tex := load(path) as Texture2D
		image.texture = tex if tex else _category_icon_for(cat_id)
	else:
		image.texture = _category_icon_for(cat_id)
	frame.add_child(image)
	if done:
		frame.clip_contents = false
		frame.add_child(_completed_stamp(Vector2(280, 88), 30))
	wrap.add_child(frame)
	wrap.resized.connect(func() -> void:
		var side := mini(int(wrap.size.x), 820)
		if side > 1:
			frame.custom_minimum_size = Vector2(side, side)
	)
	return wrap


func _how_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _white_card_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)
	col.add_child(_ruled_title(tr("DailyHowTitle")))
	var how4 := tr("DailyHow4")
	if how4 == "DailyHow4":
		how4 = "El mismo puzle para todos los jugadores."
	var lines := [tr("DailyHow1"), tr("DailyHow2"), tr("DailyHow3"), how4]
	for i in lines.size():
		if i > 0:
			var sep := ColorRect.new()
			sep.custom_minimum_size = Vector2(0, 2)
			sep.color = Color(0.9, 0.84, 0.74, 0.35)
			col.add_child(sep)
		col.add_child(_centered_text(lines[i], 36, INK))
	return card


func _make_play_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 132)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_play_pressed)
	var style := StyleBoxFlat.new()
	style.bg_color = ORANGE
	style.set_border_width_all(0)
	style.set_corner_radius_all(66)
	style.shadow_color = Color(0.96, 0.51, 0.01, 0.28)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.texture = ICON_PLAY
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color.WHITE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := Label.new()
	label.text = tr("DailyPlay")
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 46)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return button


func _make_completed_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	var title := Label.new()
	title.visible = false
	box.add_child(title)
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 8)
	box.add_child(stars)
	var mode := GameManager.level_game_mode(_item)
	var is_crypto := mode == GameManager.MODE_CRYPTOGRAM
	var total := clampi(int(_item.get("difficulty", 1)), 1, 5)
	var got := clampi(int(PlayerPrefs.daily_stars), 0, total)
	for i in range(total):
		var star := TextureRect.new()
		star.custom_minimum_size = Vector2(58, 58)
		star.texture = STAR_ON if i < got else STAR_OFF
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if i < got:
			star.modulate = Color(1, 0.55, 0.14, 1) if is_crypto else Color(1, 0.84, 0.18, 1)
		else:
			star.modulate = Color(0.62, 0.52, 0.46, 0.38)
		stars.add_child(star)
	var view := Button.new()
	view.custom_minimum_size = Vector2(0, 104)
	view.focus_mode = Control.FOCUS_NONE
	view.text = tr("DailyViewSheet")
	view.add_theme_font_override("font", FONT_UI)
	view.add_theme_font_size_override("font_size", 38)
	view.add_theme_color_override("font_color", INK)
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_WHITE
	style.border_color = Color(0.9, 0.84, 0.76, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.32, 0.2, 0.12, 0.08)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	view.add_theme_stylebox_override("normal", style)
	view.add_theme_stylebox_override("hover", style)
	view.add_theme_stylebox_override("pressed", style)
	view.pressed.connect(_on_view_sheet_pressed)
	box.add_child(view)
	return box


func _completed_stamp(stamp_size: Vector2, font_size: int) -> Panel:
	var stamp := Panel.new()
	stamp.name = "CompletedStamp"
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.custom_minimum_size = stamp_size
	stamp.size = stamp_size
	stamp.position = Vector2(16, 96)
	stamp.pivot_offset = stamp_size * 0.5
	stamp.rotation = deg_to_rad(-22.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.5, 0.3, 0.16)
	style.border_color = Color(0.16, 0.5, 0.3, 0.92)
	style.set_border_width_all(6)
	style.set_corner_radius_all(8)
	stamp.add_theme_stylebox_override("panel", style)
	var inner := Panel.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 7
	inner.offset_top = 6
	inner.offset_right = -7
	inner.offset_bottom = -6
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color(0, 0, 0, 0)
	inner_style.border_color = Color(0.16, 0.5, 0.3, 0.88)
	inner_style.set_border_width_all(3)
	inner_style.set_corner_radius_all(4)
	inner.add_theme_stylebox_override("panel", inner_style)
	stamp.add_child(inner)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = tr("DailyCompletedShort").to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.14, 0.46, 0.28, 0.95))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.add_child(label)
	return stamp


func _hoy_badge(done: bool) -> Panel:
	var badge := Panel.new()
	badge.custom_minimum_size = Vector2(184, 84)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.55, 0.32, 1) if done else TEAL
	style.set_corner_radius_all(42)
	badge.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = "✓" if done else tr("Today")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(label)
	return badge


func _meta_row(icon_tex: Texture2D, text: String, icon_color: Color = INK_SOFT) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.texture = icon_tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = icon_color
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", INK_SOFT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row


func _difficulty_row(difficulty: int) -> HBoxContainer:
	var name := tr("Medium") if difficulty == 2 else GameManager.difficulty_display_name(difficulty)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.texture = ICON_SIGNAL
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("normal_font", FONT_UI)
	label.add_theme_font_size_override("normal_font_size", 36)
	label.add_theme_color_override("default_color", INK_SOFT)
	label.text = "%s [color=#F58220]%s[/color]" % [tr("DailyDifficulty").replace("%s", "").strip_edges(), name]
	row.add_child(label)
	return row


func _centered_text(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(0, 56)
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _centered_meta(icon_tex: Texture2D, text: String, icon_color: Color = INK_SOFT) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.texture = icon_tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = icon_color
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", INK)
	row.add_child(label)
	return row


func _ruled_title(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.add_child(_rule())
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", INK)
	row.add_child(label)
	row.add_child(_rule())
	return row


func _rule() -> ColorRect:
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(80, 3)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.color = Color(0.78, 0.62, 0.42, 0.5)
	return line


func _teaser_for(cat_id: String) -> String:
	match GameManager.normalize_category(cat_id):
		GameManager.CAT_CITA:
			return tr("DailyTeaserQuotes")
		GameManager.CAT_EFEMERIDE:
			return tr("DailyTeaserEphemerides")
		GameManager.CAT_FRAGMENTO:
			return tr("DailyTeaserFragments")
		_:
			return tr("DailyTeaserCuriosities")


func _category_icon_for(cat_id: String) -> Texture2D:
	match GameManager.normalize_category(cat_id):
		GameManager.CAT_CITA:
			return ICON_CITA
		GameManager.CAT_EFEMERIDE:
			return ICON_EFEM
		GameManager.CAT_CURIOSIDADES:
			return ICON_CURIO
		GameManager.CAT_FRAGMENTO:
			return ICON_FRAG
		_:
			return ICON_CITA


func _white_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_WHITE
	style.border_color = Color(0.9, 0.84, 0.76, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.32, 0.2, 0.12, 0.08)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 5)
	return style


func _circle_icon(tex: Texture2D, size: float, bg: Color, icon_mod: Color, pad: float = 0.2) -> Panel:
	var wrap := Panel.new()
	wrap.custom_minimum_size = Vector2(size, size)
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(int(size * 0.5))
	wrap.add_theme_stylebox_override("panel", style)
	var icon := TextureRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := size * pad
	icon.offset_left = margin
	icon.offset_top = margin
	icon.offset_right = -margin
	icon.offset_bottom = -margin
	icon.texture = tex
	icon.modulate = icon_mod
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(icon)
	return wrap


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


func _apply_lock_texts() -> void:
	var lock_title := lock_overlay.get_node_or_null("Card/Title") as Label
	var lock_body := lock_overlay.get_node_or_null("Card/Body") as Label
	var unlock_btn := lock_overlay.get_node_or_null("Card/Unlock") as Button
	var shop_btn := lock_overlay.get_node_or_null("Card/Shop") as Button
	var back_btn := lock_overlay.get_node_or_null("Card/Back") as Button
	if lock_title:
		lock_title.text = tr("DailyChallenge")
	if lock_body:
		lock_body.text = tr("DailyLockedBody")
	if unlock_btn:
		unlock_btn.text = tr("DailyUnlock")
	if shop_btn:
		shop_btn.text = tr("Shop")
	if back_btn:
		back_btn.text = tr("Back")


func _go_to(path: String) -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file(path)


func _on_button_back_pressed() -> void:
	_go_to(PATH_MAIN)


func _on_shop_pressed() -> void:
	_go_to(PATH_SHOP)


func _on_unlock_pressed() -> void:
	_go_to(PATH_SHOP)


func _on_lock_back_pressed() -> void:
	_go_to(PATH_MAIN)


func _on_view_sheet_pressed() -> void:
	var puzzle_id := int(_item.get("index", -1))
	if puzzle_id < 0:
		return
	GameManager.pending_library_puzzle_id = puzzle_id
	_go_to(PATH_LIBRARY)


func _on_play_pressed() -> void:
	if _item.is_empty() or PlayerPrefs.is_daily_completed_today():
		return
	SoundManager.play("ButtonClick")
	var puzzle_id := int(_item.get("index", -1))
	if puzzle_id < 0:
		return
	GameManager.session_source = GameManager.SOURCE_DAILY
	GameManager.allow_completed_replay = true
	GameManager.id_frase = puzzle_id
	GameManager.set_game_mode_actual(GameManager.level_game_mode(_item))
	GameManager.set_dificultad_actual(int(_item.get("difficulty", 1)))
	GameManager.seleccionar_por_index(puzzle_id)
	PuzzleSaveManager.prepare_current_puzzle_cipher()
	GameManager.set_go_to_game_disable()
	if _play_button:
		_play_button.disabled = true
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SignalManager.partida_iniciada.emit()
	get_tree().change_scene_to_file(PATH_APP)
