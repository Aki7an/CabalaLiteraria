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
const STAR_ON: Texture2D = preload("res://images/estrella_plano.png")
const STAR_OFF: Texture2D = preload("res://images/contorno_estrella.png")
const INK := Color(0.29, 0.2, 0.13, 1)
const INK_SOFT := Color(0.45, 0.32, 0.22, 0.86)
const TEAL := Color(0.29, 0.69, 0.67, 1)
const ORANGE := Color(0.96, 0.51, 0.01, 1)

var _item: Dictionary = {}
var _play_button: Button
var _completed_box: VBoxContainer

@onready var brand_cifra: Label = $Header/Brand/Cifra
@onready var brand_letra: Label = $Header/Brand/Letra
@onready var title_label: Label = $Header/Title
@onready var tagline_label: Label = $Header/TaglineRow/Tagline
@onready var body: VBoxContainer = $Scroll/Body
@onready var version_label: Label = $Version
@onready var lock_overlay: Control = $LockOverlay


func _ready() -> void:
	brand_cifra.text = tr("Cipher")
	brand_letra.text = tr("Letter")
	title_label.text = tr("DailyChallenge")
	tagline_label.text = tr("DailyTagline")
	version_label.text = "%s %s" % [tr("Version"), PlayerPrefs.version_display()]
	_apply_lock_texts()
	if not GameManager.has_full_game():
		$Scroll.visible = false
		lock_overlay.visible = true
		return
	lock_overlay.visible = false
	_item = GameManager.todays_daily_item()
	_build_content()


func _build_content() -> void:
	for child in body.get_children():
		child.queue_free()
	var done := PlayerPrefs.is_daily_completed_today()
	body.add_child(_date_card(done))
	body.add_child(_challenge_card(done))
	body.add_child(_how_card())
	_play_button = _make_play_button()
	_completed_box = _make_completed_box()
	body.add_child(_play_button)
	body.add_child(_completed_box)
	body.add_child(_menu_link())
	_play_button.visible = not done
	_completed_box.visible = done
	if _item.is_empty():
		_play_button.disabled = true


func _date_card(done: bool) -> Panel:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(0, 132)
	card.add_theme_stylebox_override("panel", _stroke_card_style())
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 28
	row.offset_right = -28
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(72, 72)
	icon.texture = ICON_DAILY
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	var date := Label.new()
	date.text = GameManager.format_long_date()
	date.add_theme_font_override("font", FONT_UI)
	date.add_theme_font_size_override("font_size", 36)
	date.add_theme_color_override("font_color", INK)
	col.add_child(date)
	var status := Label.new()
	status.text = tr("DailyCompletedShort") if done else tr("DailyAvailable")
	status.add_theme_font_override("font", FONT_UI)
	status.add_theme_font_size_override("font_size", 28)
	status.add_theme_color_override("font_color", Color(0.18, 0.55, 0.32, 1) if done else INK_SOFT)
	col.add_child(status)
	var sparkles := Label.new()
	sparkles.text = "✦"
	sparkles.add_theme_font_size_override("font_size", 34)
	sparkles.add_theme_color_override("font_color", ORANGE)
	sparkles.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(sparkles)
	return card


func _challenge_card(done: bool) -> Panel:
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", _cream_card_style())
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 24
	col.offset_right = -24
	col.offset_top = 24
	col.offset_bottom = -20
	col.add_theme_constant_override("separation", 20)
	card.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 22)
	col.add_child(top)
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(280, 280)
	frame.clip_contents = true
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.91, 0.82, 0.64, 1)
	frame_style.set_corner_radius_all(24)
	frame.add_theme_stylebox_override("panel", frame_style)
	var image := TextureRect.new()
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.offset_left = 8
	image.offset_top = 8
	image.offset_right = -8
	image.offset_bottom = -8
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cat_id := str(_item.get("category", ""))
	var path := GameManager.find_level_image_path(int(_item.get("image_number", -1)))
	if path != "":
		var tex := load(path) as Texture2D
		image.texture = tex if tex else _category_icon_for(cat_id)
	else:
		image.texture = _category_icon_for(cat_id)
	frame.add_child(image)
	top.add_child(frame)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 10)
	top.add_child(info)
	var cat_row := HBoxContainer.new()
	cat_row.add_theme_constant_override("separation", 10)
	info.add_child(cat_row)
	var cat_icon := TextureRect.new()
	cat_icon.custom_minimum_size = Vector2(42, 42)
	cat_icon.texture = _category_icon_for(cat_id)
	cat_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cat_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cat_row.add_child(cat_icon)
	var cat_label := Label.new()
	cat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_label.text = GameManager.category_display_name(cat_id)
	cat_label.add_theme_font_override("font", FONT_UI)
	cat_label.add_theme_font_size_override("font_size", 36)
	cat_label.add_theme_color_override("font_color", INK)
	cat_row.add_child(cat_label)
	cat_row.add_child(_hoy_badge(done))
	var mode := GameManager.level_game_mode(_item)
	var is_crypto := mode == GameManager.MODE_CRYPTOGRAM
	info.add_child(_meta_row(ICON_QUICK if not is_crypto else ICON_LUPA, tr("DailyType") % (
		tr("Cryptogram") if is_crypto else tr("Quick")
	)))
	info.add_child(_difficulty_row(int(_item.get("difficulty", 1))))
	info.add_child(_meta_row(ICON_CLOCK, tr("DailyEstimated") % (
		tr("TimeCryptoRange") if is_crypto else tr("TimeQuickRange")
	)))
	var teaser := Panel.new()
	var teaser_style := StyleBoxFlat.new()
	teaser_style.bg_color = Color(0.97, 0.93, 0.86, 1)
	teaser_style.set_corner_radius_all(16)
	teaser.add_theme_stylebox_override("panel", teaser_style)
	var teaser_label := Label.new()
	teaser_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	teaser_label.offset_left = 16
	teaser_label.offset_right = -16
	teaser_label.offset_top = 12
	teaser_label.offset_bottom = -12
	teaser_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teaser_label.text = _teaser_for(cat_id)
	teaser_label.add_theme_font_override("font", FONT_UI)
	teaser_label.add_theme_font_size_override("font_size", 26)
	teaser_label.add_theme_color_override("font_color", INK_SOFT)
	teaser.add_child(teaser_label)
	teaser.custom_minimum_size = Vector2(0, 110)
	info.add_child(teaser)
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 2)
	line.color = Color(0.78, 0.62, 0.42, 0.28)
	col.add_child(line)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 10)
	var people := Label.new()
	people.text = "👤👤"
	people.add_theme_font_size_override("font_size", 22)
	footer.add_child(people)
	var same := Label.new()
	same.text = tr("DailySameForAll")
	same.add_theme_font_override("font", FONT_UI)
	same.add_theme_font_size_override("font_size", 26)
	same.add_theme_color_override("font_color", INK_SOFT)
	same.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	same.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(same)
	col.add_child(footer)
	card.custom_minimum_size = Vector2(0, 500)
	return card


func _how_card() -> Panel:
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", _cream_card_style())
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 28
	col.offset_right = -28
	col.offset_top = 18
	col.offset_bottom = -18
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	col.add_child(_ruled_title(tr("DailyHowTitle")))
	var rows := [
		[ICON_DAILY, tr("DailyHow1"), TEAL],
		[ICON_LIBRARY, tr("DailyHow2"), Color(0.48, 0.32, 0.2, 1)],
		[ICON_DAILY, tr("DailyHow3"), TEAL],
	]
	for i in rows.size():
		if i > 0:
			var sep := ColorRect.new()
			sep.custom_minimum_size = Vector2(0, 2)
			sep.color = Color(0.78, 0.62, 0.42, 0.22)
			col.add_child(sep)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		row.custom_minimum_size = Vector2(0, 64)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(42, 42)
		icon.texture = rows[i][0]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = rows[i][2]
		row.add_child(icon)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = rows[i][1]
		label.add_theme_font_override("font", FONT_UI)
		label.add_theme_font_size_override("font_size", 30)
		label.add_theme_color_override("font_color", INK)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		col.add_child(row)
	card.custom_minimum_size = Vector2(0, 320)
	return card


func _make_play_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 140)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_play_pressed)
	var style := StyleBoxFlat.new()
	style.bg_color = ORANGE
	style.border_color = Color(0.83, 0.41, 0.02, 1)
	style.set_border_width_all(4)
	style.border_width_bottom = 10
	style.set_corner_radius_all(40)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.texture = ICON_PLAY
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := Label.new()
	label.text = tr("DailyPlay")
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return button


func _make_completed_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	var title := Label.new()
	title.text = tr("DailyCompleted")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_UI)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.18, 0.55, 0.32, 1))
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
	view.custom_minimum_size = Vector2(0, 110)
	view.focus_mode = Control.FOCUS_NONE
	view.text = tr("DailyViewSheet")
	view.add_theme_font_override("font", FONT_UI)
	view.add_theme_font_size_override("font_size", 40)
	view.add_theme_color_override("font_color", INK)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.99, 0.96, 0.96)
	style.border_color = Color(0.78, 0.62, 0.42, 0.45)
	style.set_border_width_all(4)
	style.border_width_bottom = 8
	style.set_corner_radius_all(28)
	view.add_theme_stylebox_override("normal", style)
	view.add_theme_stylebox_override("hover", style)
	view.add_theme_stylebox_override("pressed", style)
	view.pressed.connect(_on_view_sheet_pressed)
	box.add_child(view)
	return box


func _menu_link() -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.text = tr("DailyBackToMenu")
	button.add_theme_font_override("font", FONT_UI)
	button.add_theme_font_size_override("font_size", 32)
	button.add_theme_color_override("font_color", INK_SOFT)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(_on_button_back_pressed)
	return button


func _hoy_badge(done: bool) -> Panel:
	var badge := Panel.new()
	badge.custom_minimum_size = Vector2(86, 40)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.55, 0.32, 1) if done else TEAL
	style.set_corner_radius_all(16)
	badge.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = "✓" if done else tr("Today")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color.WHITE)
	badge.add_child(label)
	return badge


func _meta_row(icon_tex: Texture2D, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.texture = icon_tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", INK_SOFT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row


func _difficulty_row(difficulty: int) -> HBoxContainer:
	var name := tr("Medium") if difficulty == 2 else GameManager.difficulty_display_name(difficulty)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var mark := Label.new()
	mark.text = "▮"
	mark.add_theme_font_size_override("font_size", 26)
	mark.add_theme_color_override("font_color", ORANGE)
	row.add_child(mark)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("normal_font", FONT_UI)
	label.add_theme_font_size_override("normal_font_size", 28)
	label.add_theme_color_override("default_color", INK_SOFT)
	label.text = "%s [color=#F58220]%s[/color]" % [tr("DailyDifficulty").replace("%s", "").strip_edges(), name]
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
	label.add_theme_font_size_override("font_size", 32)
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


func _cream_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.99, 0.97, 0.98)
	style.border_color = Color(0.82, 0.68, 0.46, 0.32)
	style.set_border_width_all(2)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.29, 0.18, 0.11, 0.12)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _stroke_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.99, 0.97, 0.72)
	style.border_color = Color(0.72, 0.55, 0.36, 0.55)
	style.set_border_width_all(3)
	style.set_corner_radius_all(28)
	return style


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
