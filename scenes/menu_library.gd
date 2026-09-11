extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const ICON_CITA: Texture2D = preload("res://images/Citas.png")
const ICON_EFEM: Texture2D = preload("res://images/Efemerides.png")
const ICON_CURIO: Texture2D = preload("res://images/Adivinanza.png")
const ICON_FRAG: Texture2D = preload("res://images/FragmentosLiterarios.png")
const ICON_HEART: Texture2D = preload("res://images/ui_icon_heart.svg")
const ICON_QUICK: Texture2D = preload("res://images/mode_quick.svg")
const ICON_CRYPTO: Texture2D = preload("res://images/CriptogramaIcono.png")
const STAR_ON: Texture2D = preload("res://images/estrella_plano.png")
const STAR_OFF: Texture2D = preload("res://images/contorno_estrella.png")
const ICON_PLAY: Texture2D = preload("res://GUI/BotonPlaySimboloTextura.png")
const ICON_DAILY: Texture2D = preload("res://images/ui_icon_daily.svg")
const ICON_LOCK: Texture2D = preload("res://images/ui_icon_lock.svg")
const THEME_PREVIEW := preload("res://scenes/game/PuzzleThemePreview.tscn")
const PREVIEW_COUNT := 4
const THUMB_SIZE := 222
const THUMB_GAP := 12
const NAV_WIDTH := 78
const CAROUSEL_SEC := 0.28
const DRAG_THRESHOLD := 14.0
const INK := Color(0.267, 0.184, 0.102, 1)
const INK_SOFT := Color(0.42, 0.3, 0.2, 0.88)
const CREAM := Color(1, 0.984, 0.953, 0.98)

var _ficha_item: Dictionary = {}
var _collapsed: Dictionary = {}
var _mode_collapsed: Dictionary = {}
var _carousel_offset: Dictionary = {}
var _carousel_busy: Dictionary = {}
var _filter_favorites := false
var _drag_held := false
var _drag_active := false
var _drag_origin := Vector2.ZERO
var _drag_scroll_origin := 0

@onready var index_root: Control = $IndexRoot
@onready var ficha_root: Control = $FichaRoot
@onready var index_scroll: ScrollContainer = $IndexRoot/Scroll
@onready var ficha_scroll: ScrollContainer = $FichaRoot/Scroll
@onready var title_label: Label = $IndexRoot/Header/Title
@onready var subtitle_label: Label = $IndexRoot/Header/Subtitle
@onready var progress_label: Label = $IndexRoot/Header/ProgressCard/ProgressLabel
@onready var progress_bar: ProgressBar = $IndexRoot/Header/ProgressCard/ProgressBar
@onready var cards: VBoxContainer = $IndexRoot/Scroll/Cards
@onready var empty_state: Label = $IndexRoot/EmptyState
@onready var ficha_title: Label = $FichaRoot/Header/Title
@onready var ficha_subtitle: Label = $FichaRoot/Header/Subtitle
@onready var ficha_phrase: RichTextLabel = $FichaRoot/Scroll/Body/PhraseCard/Phrase
@onready var ficha_context: RichTextLabel = $FichaRoot/Scroll/Body/ContextCard/Context
@onready var ficha_image_frame: Panel = $FichaRoot/Scroll/Body/ImageFrame
@onready var ficha_image: TextureRect = $FichaRoot/Scroll/Body/ImageFrame/Image
@onready var ficha_sources_card: Panel = $FichaRoot/Scroll/Body/SourcesCard
@onready var ficha_sources_title: Label = $FichaRoot/Scroll/Body/SourcesCard/SourcesTitle
@onready var ficha_sources: RichTextLabel = $FichaRoot/Scroll/Body/SourcesCard/Sources
@onready var button_favorites: Button = %ButtonFavorites
@onready var button_ficha_favorite: Button = %ButtonFavorite
@onready var ficha_body: VBoxContainer = $FichaRoot/Scroll/Body


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	ficha_root.visible = false
	index_root.visible = true
	if GameManager.frases_db.is_empty():
		GameManager.cargar_frases_desde_json()
	title_label.text = tr("Library")
	ficha_sources_title.text = tr("Sources")
	index_scroll.scroll_deadzone = 16
	ficha_scroll.scroll_deadzone = 16
	_setup_ficha_layout()
	_rebuild_index()
	_open_pending_ficha()


func _input(event: InputEvent) -> void:
	var scroll := _active_scroll()
	if scroll == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_drag_press(event.pressed, event.position)
	elif event is InputEventMouseMotion and _drag_held:
		_handle_drag_motion(event.position)
	elif event is InputEventScreenTouch:
		_handle_drag_press(event.pressed, event.position)
	elif event is InputEventScreenDrag and _drag_held:
		_handle_drag_motion(event.position)


func _active_scroll() -> ScrollContainer:
	if ficha_root.visible:
		return ficha_scroll
	if index_root.visible:
		return index_scroll
	return null


func _handle_drag_press(pressed: bool, position: Vector2) -> void:
	var scroll := _active_scroll()
	if pressed:
		if scroll == null or not get_global_rect().has_point(position):
			return
		_drag_held = true
		_drag_active = false
		_drag_origin = position
		_drag_scroll_origin = scroll.scroll_vertical
		return
	if _drag_active:
		get_viewport().set_input_as_handled()
	call_deferred("_end_drag")


func _handle_drag_motion(position: Vector2) -> void:
	var scroll := _active_scroll()
	if scroll == null:
		return
	var delta := position.y - _drag_origin.y
	if not _drag_active and absf(delta) >= DRAG_THRESHOLD:
		_drag_active = true
	if not _drag_active:
		return
	scroll.scroll_vertical = _drag_scroll_origin - int(delta)
	get_viewport().set_input_as_handled()


func _end_drag() -> void:
	_drag_held = false
	_drag_active = false


func _category_defs() -> Array[Dictionary]:
	return [
		{
			"id": GameManager.CAT_DAILY,
			"icon": ICON_DAILY,
			"color": GameManager.category_color(GameManager.CAT_DAILY),
			"icon_bg": Color(1, 0.82, 0.35, 1),
		},
		{
			"id": GameManager.CAT_CITA,
			"icon": ICON_CITA,
			"color": GameManager.category_color(GameManager.CAT_CITA),
			"icon_bg": Color(0.447, 0.722, 0.918, 1),
		},
		{
			"id": GameManager.CAT_EFEMERIDE,
			"icon": ICON_EFEM,
			"color": GameManager.category_color(GameManager.CAT_EFEMERIDE),
			"icon_bg": Color(1, 0.467, 0.345, 1),
		},
		{
			"id": GameManager.CAT_CURIOSIDADES,
			"icon": ICON_CURIO,
			"color": GameManager.category_color(GameManager.CAT_CURIOSIDADES),
			"icon_bg": Color(1, 0.745, 0.251, 1),
		},
		{
			"id": GameManager.CAT_FRAGMENTO,
			"icon": ICON_FRAG,
			"color": GameManager.category_color(GameManager.CAT_FRAGMENTO),
			"icon_bg": Color(0.608, 0.835, 0.651, 1),
		},
	]


func _all_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for value in GameManager.frases_db:
		if value is Dictionary:
			items.append(value)
	return items


func _is_completed(puzzle_id: int) -> bool:
	if typeof(PuzzleSaveManager) != TYPE_NIL:
		if str(PuzzleSaveManager.get_puzzle_summary(puzzle_id).get("status", "")) == "completed":
			return true
	if typeof(HistoryManager) == TYPE_NIL:
		return false
	for entry in HistoryManager.get_history():
		if int(entry.get("id", -1)) == puzzle_id and bool(entry.get("partida_ganada", false)):
			return true
	return false


func _items_for(cat_id: String, mode: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var wanted := GameManager.normalize_category(cat_id)
	for item in _all_items():
		if GameManager.library_category(item) != wanted:
			continue
		if mode != "" and GameManager.level_game_mode(item) != mode:
			continue
		out.append(item)
	return out


func _completed_in(items: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in items:
		if _is_completed(int(item.get("index", -1))):
			out.append(item)
	return out


func _is_favorite(puzzle_id: int) -> bool:
	return PlayerPrefs.is_favorite(puzzle_id)


func _carousel_items(items: Array[Dictionary]) -> Array[Dictionary]:
	var done := _completed_in(items)
	if not _filter_favorites:
		return done
	var out: Array[Dictionary] = []
	for item in done:
		if _is_favorite(int(item.get("index", -1))):
			out.append(item)
	return out


func _rebuild_index() -> void:
	for child in cards.get_children():
		child.queue_free()
	var catalog: Array[Dictionary] = []
	for item in _all_items():
		if not GameManager.is_daily_puzzle(item):
			catalog.append(item)
	var completed_all := _completed_in(catalog)
	progress_bar.max_value = maxi(catalog.size(), 1)
	progress_bar.value = completed_all.size()
	progress_label.text = tr("LibraryProgress") % [completed_all.size(), catalog.size()]
	subtitle_label.text = tr("LibraryFavoritesSubtitle") if _filter_favorites else tr("LibrarySolvedSubtitle")
	empty_state.visible = false
	for def in _category_defs():
		cards.add_child(_create_category_card(def))


func _create_category_card(def: Dictionary) -> PanelContainer:
	var cat_id := str(def.get("id", ""))
	var cat_items := _items_for(cat_id)
	var cat_done := _completed_in(cat_items)
	var has_puzzles := not _carousel_items(cat_items).is_empty()
	var collapsed := _is_category_collapsed(cat_id, has_puzzles)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _category_card_style(def.get("color", CREAM), cat_id))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	margin.add_child(col)

	var header := Button.new()
	header.focus_mode = Control.FOCUS_NONE
	header.custom_minimum_size = Vector2(0, 108)
	header.flat = true
	header.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	header.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	header.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	header.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	header.pressed.connect(func() -> void:
		if _drag_active:
			return
		SoundManager.play("ButtonClick")
		_collapsed[cat_id] = not _is_category_collapsed(cat_id, has_puzzles)
		_rebuild_index()
	)
	col.add_child(header)

	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 18)
	head_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	head_row.anchor_right = 1.0
	head_row.anchor_bottom = 1.0
	head_row.offset_left = 0
	head_row.offset_top = 0
	head_row.offset_right = 0
	head_row.offset_bottom = 0
	header.add_child(head_row)

	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(96, 96)
	icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = def.get("icon_bg", def.get("color", Color(0.8, 0.6, 0.3)))
	icon_style.set_corner_radius_all(48)
	icon_style.content_margin_left = 12
	icon_style.content_margin_right = 12
	icon_style.content_margin_top = 12
	icon_style.content_margin_bottom = 12
	icon_wrap.add_theme_stylebox_override("panel", icon_style)
	head_row.add_child(icon_wrap)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(72, 72)
	icon.texture = def.get("icon")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_wrap.add_child(icon)

	var title := Label.new()
	title.text = GameManager.category_display_name(cat_id)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_UI)
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", INK)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head_row.add_child(title)

	var pill := _count_pill("%d / %d" % [cat_done.size(), cat_items.size()])
	head_row.add_child(pill)
	if cat_items.size() > 0 and cat_done.size() >= cat_items.size():
		head_row.add_child(_complete_check())

	head_row.add_child(_fold_chip(collapsed, 88.0))

	if not collapsed:
		var accent: Color = def.get("color", Color(0.8, 0.6, 0.3))
		if cat_id == GameManager.CAT_DAILY:
			col.add_child(_create_mode_row(cat_id, "", "", accent, false))
		else:
			col.add_child(_create_mode_row(cat_id, GameManager.MODE_QUICK, tr("Quick"), accent))
			col.add_child(_mode_separator())
			col.add_child(_create_mode_row(cat_id, GameManager.MODE_CRYPTOGRAM, tr("Cryptogram"), accent))
	return card


func _mode_separator() -> ColorRect:
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 3)
	line.color = Color(0.62, 0.46, 0.28, 0.38)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _carousel_width() -> float:
	return float(PREVIEW_COUNT * THUMB_SIZE + (PREVIEW_COUNT - 1) * THUMB_GAP)


func _carousel_height() -> float:
	return float(THUMB_SIZE)


func _clamped_offset(key: String, total: int) -> int:
	var maximum := maxi(0, total - PREVIEW_COUNT)
	var offset := int(_carousel_offset.get(key, 0))
	offset = clampi(offset, 0, maximum)
	_carousel_offset[key] = offset
	return offset


func _visible_slice(done: Array[Dictionary], offset: int) -> Array[Dictionary]:
	if done.is_empty():
		return []
	var end := mini(offset + PREVIEW_COUNT, done.size())
	return done.slice(offset, end)


func _is_category_collapsed(cat_id: String, has_puzzles: bool) -> bool:
	if _collapsed.has(cat_id):
		return bool(_collapsed[cat_id])
	if cat_id == GameManager.CAT_DAILY:
		return not has_puzzles
	return false


func _is_mode_collapsed(key: String, has_puzzles: bool) -> bool:
	if _mode_collapsed.has(key):
		return bool(_mode_collapsed[key])
	return not has_puzzles


func _toggle_mode_collapsed(key: String, has_puzzles: bool) -> void:
	_mode_collapsed[key] = not _is_mode_collapsed(key, has_puzzles)
	_rebuild_index()


func _fold_chip(collapsed: bool, diameter: float = 96.0) -> Control:
	var mark := Control.new()
	mark.custom_minimum_size = Vector2(diameter, diameter)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var color := Color(0.16, 0.1, 0.07, 0.86)
	mark.draw.connect(func() -> void:
		var side := minf(mark.size.x, mark.size.y)
		var center := mark.size * 0.5
		var half_w := side * 0.2
		var half_h := side * 0.16
		var pts := PackedVector2Array()
		if collapsed:
			pts.append(Vector2(center.x - half_h, center.y - half_w))
			pts.append(Vector2(center.x + half_w, center.y))
			pts.append(Vector2(center.x - half_h, center.y + half_w))
		else:
			pts.append(Vector2(center.x - half_w, center.y - half_h))
			pts.append(Vector2(center.x + half_w, center.y - half_h))
			pts.append(Vector2(center.x, center.y + half_w))
		mark.draw_colored_polygon(pts, color)
	)
	mark.resized.connect(mark.queue_redraw)
	return mark


func _create_mode_row(cat_id: String, mode: String, caption: String, accent: Color, show_mode_header: bool = true) -> VBoxContainer:
	var items := _items_for(cat_id, mode)
	var done := _carousel_items(items)
	var key := "%s|%s" % [cat_id, mode if mode != "" else "all"]
	var offset := _clamped_offset(key, done.size())
	var collapsed := show_mode_header and _is_mode_collapsed(key, not done.is_empty())

	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 12)
	block.set_meta("carousel_key", key)
	block.set_meta("carousel_items", done)

	if show_mode_header:
		var header := Button.new()
		header.focus_mode = Control.FOCUS_NONE
		header.custom_minimum_size = Vector2(0, 76)
		header.flat = true
		header.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		header.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		header.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		header.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		header.pressed.connect(func() -> void:
			if _drag_active:
				return
			SoundManager.play("ButtonClick")
			_toggle_mode_collapsed(key, not done.is_empty())
		)
		block.add_child(header)

		var info := HBoxContainer.new()
		info.add_theme_constant_override("separation", 14)
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		header.add_child(info)

		var mode_icon := TextureRect.new()
		mode_icon.custom_minimum_size = Vector2(44, 44)
		mode_icon.texture = ICON_QUICK if mode == GameManager.MODE_QUICK else ICON_CRYPTO
		mode_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mode_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mode_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_child(mode_icon)

		var name_label := Label.new()
		name_label.text = caption
		name_label.add_theme_font_override("font", FONT_UI)
		name_label.add_theme_font_size_override("font_size", 40)
		name_label.add_theme_color_override("font_color", INK)
		info.add_child(name_label)

		var count := Label.new()
		count.text = "%d / %d" % [_completed_in(items).size(), items.size()]
		count.add_theme_font_override("font", FONT_UI)
		count.add_theme_font_size_override("font_size", 26)
		count.add_theme_color_override("font_color", INK_SOFT)
		info.add_child(count)

		var mini := ProgressBar.new()
		mini.custom_minimum_size = Vector2(220, 16)
		mini.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mini.max_value = maxi(items.size(), 1)
		mini.value = _completed_in(items).size()
		mini.show_percentage = false
		mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mini_bg := StyleBoxFlat.new()
		mini_bg.bg_color = accent.lerp(Color(1, 0.98, 0.95, 1), 0.42)
		mini_bg.bg_color.a = 0.38
		mini_bg.set_corner_radius_all(8)
		var mini_fill := StyleBoxFlat.new()
		mini_fill.bg_color = accent.darkened(0.06)
		mini_fill.set_corner_radius_all(8)
		mini.add_theme_stylebox_override("background", mini_bg)
		mini.add_theme_stylebox_override("fill", mini_fill)
		info.add_child(mini)
		info.add_child(_fold_chip(collapsed, 80.0))

	if collapsed:
		return block

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	block.add_child(row)

	var left_nav := _create_nav_button(false)
	left_nav.pressed.connect(func() -> void:
		if _drag_active:
			return
		_shift_carousel(block, -1)
	)
	row.add_child(left_nav)

	var clip := Control.new()
	clip.name = "Clip"
	clip.clip_contents = true
	clip.custom_minimum_size = Vector2(_carousel_width(), _carousel_height())
	clip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(clip)

	var track := HBoxContainer.new()
	track.name = "Track"
	track.position = Vector2.ZERO
	track.add_theme_constant_override("separation", THUMB_GAP)
	clip.add_child(track)

	var right_nav := _create_nav_button(true)
	right_nav.pressed.connect(func() -> void:
		if _drag_active:
			return
		_shift_carousel(block, 1)
	)
	row.add_child(right_nav)

	block.set_meta("left_nav", left_nav)
	block.set_meta("right_nav", right_nav)
	block.set_meta("clip", clip)
	block.set_meta("track", track)
	_refresh_carousel(block, 0.0)
	return block


func _refresh_carousel(block: Control, slide_from: float) -> void:
	var key := str(block.get_meta("carousel_key", ""))
	var done: Array = block.get_meta("carousel_items", [])
	var offset := _clamped_offset(key, done.size())
	var left_nav := block.get_meta("left_nav") as Button
	var right_nav := block.get_meta("right_nav") as Button
	var track := block.get_meta("track") as HBoxContainer
	if track == null:
		return
	for child in track.get_children():
		child.queue_free()
	var slice := _visible_slice(done, offset)
	for item in slice:
		if item is Dictionary:
			track.add_child(_create_thumb(item))
	for _i in range(PREVIEW_COUNT - slice.size()):
		track.add_child(_create_empty_slot())
	if left_nav:
		var left_count := offset
		_set_nav_text(left_nav, false, left_count)
		_set_nav_enabled(left_nav, left_count > 0)
	if right_nav:
		var right_count := maxi(0, done.size() - offset - PREVIEW_COUNT)
		_set_nav_text(right_nav, true, right_count)
		_set_nav_enabled(right_nav, right_count > 0)
	if is_zero_approx(slide_from):
		track.position.x = 0.0
		return
	track.position.x = slide_from
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(track, "position:x", 0.0, CAROUSEL_SEC)


func _shift_carousel(block: Control, direction: int) -> void:
	var key := str(block.get_meta("carousel_key", ""))
	if bool(_carousel_busy.get(key, false)):
		return
	var done: Array = block.get_meta("carousel_items", [])
	var offset := _clamped_offset(key, done.size())
	var next := clampi(offset + direction * PREVIEW_COUNT, 0, maxi(0, done.size() - PREVIEW_COUNT))
	if next == offset:
		return
	SoundManager.play("ButtonClick")
	_carousel_busy[key] = true
	_carousel_offset[key] = next
	var track := block.get_meta("track") as HBoxContainer
	var clip := block.get_meta("clip") as Control
	var width := clip.size.x if clip and clip.size.x > 1.0 else _carousel_width()
	var outgoing := -width if direction > 0 else width
	if track:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(track, "position:x", outgoing, CAROUSEL_SEC)
		await tween.finished
	_refresh_carousel(block, -outgoing)
	await get_tree().create_timer(CAROUSEL_SEC).timeout
	_carousel_busy[key] = false


func _create_nav_button(going_right: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(NAV_WIDTH, _carousel_height())
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var col := VBoxContainer.new()
	col.name = "Col"
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(col)
	var plus := Label.new()
	plus.name = "Count"
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.add_theme_font_override("font", FONT_UI)
	plus.add_theme_font_size_override("font_size", 34)
	plus.add_theme_color_override("font_color", INK)
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var arrow := Label.new()
	arrow.name = "Arrow"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_override("font", FONT_UI)
	arrow.add_theme_font_size_override("font_size", 52)
	arrow.add_theme_color_override("font_color", INK_SOFT)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if going_right:
		col.add_child(plus)
		col.add_child(arrow)
	else:
		col.add_child(arrow)
		col.add_child(plus)
	_set_nav_text(button, going_right, 0)
	return button


func _set_nav_text(button: Button, going_right: bool, count: int) -> void:
	var plus := button.find_child("Count", true, false) as Label
	var arrow := button.find_child("Arrow", true, false) as Label
	if plus:
		plus.text = "+%d" % count
	if arrow:
		arrow.text = "›" if going_right else "‹"


func _set_nav_enabled(button: Button, enabled: bool) -> void:
	button.disabled = not enabled
	button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	button.modulate = Color.WHITE if enabled else Color(1, 1, 1, 0)


func _create_thumb(item: Dictionary) -> Button:
	var puzzle_id := int(item.get("index", -1))
	var button := Button.new()
	button.custom_minimum_size = Vector2(THUMB_SIZE, _carousel_height())
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func() -> void:
		if _drag_active:
			return
		_open_ficha(item)
	)

	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _image_frame_style())
	button.add_child(frame)
	button.add_child(_thumb_heart_button(puzzle_id))

	var image := TextureRect.new()
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.offset_left = 8
	image.offset_top = 8
	image.offset_right = -8
	image.offset_bottom = -8
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := GameManager.find_level_image_path(int(item.get("image_number", -1)))
	if path != "":
		var tex := load(path) as Texture2D
		if tex:
			image.texture = tex
	frame.add_child(image)
	return button


func _create_empty_slot() -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(THUMB_SIZE, THUMB_SIZE)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.draw.connect(func() -> void:
		_draw_empty_slot(slot)
	)
	slot.resized.connect(slot.queue_redraw)
	var plus := Label.new()
	plus.text = "+"
	plus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus.add_theme_font_override("font", FONT_UI)
	plus.add_theme_font_size_override("font_size", 72)
	plus.add_theme_color_override("font_color", Color(0.42, 0.3, 0.2, 0.28))
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(plus)
	return slot


func _draw_empty_slot(slot: Control) -> void:
	var size := slot.size
	if size.x < 8.0 or size.y < 8.0:
		return
	_draw_dashed_rounded_rect(
		slot,
		Rect2(Vector2(4, 4), size - Vector2(8, 8)),
		20.0,
		Color(0.48, 0.36, 0.22, 0.34),
		2.4,
		9.0,
		6.0
	)


func _draw_dashed_rounded_rect(
	ctrl: Control,
	rect: Rect2,
	radius: float,
	color: Color,
	width: float,
	dash: float,
	gap: float
) -> void:
	var pts := _rounded_rect_points(rect, radius)
	if pts.size() < 2:
		return
	var on := true
	var leftover := dash
	for i in range(pts.size() - 1):
		var start: Vector2 = pts[i]
		var stop: Vector2 = pts[i + 1]
		var remaining := start.distance_to(stop)
		if remaining <= 0.001:
			continue
		var dir := (stop - start) / remaining
		var pos := start
		while remaining > 0.001:
			var step := minf(remaining, leftover)
			var nxt := pos + dir * step
			if on:
				ctrl.draw_line(pos, nxt, color, width, true)
			remaining -= step
			leftover -= step
			pos = nxt
			if leftover <= 0.001:
				on = not on
				leftover = dash if on else gap


func _rounded_rect_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [
		[rect.position + Vector2(rect.size.x - r, r), -PI * 0.5, 0.0],
		[rect.position + Vector2(rect.size.x - r, rect.size.y - r), 0.0, PI * 0.5],
		[rect.position + Vector2(r, rect.size.y - r), PI * 0.5, PI],
		[rect.position + Vector2(r, r), PI, PI * 1.5],
	]
	for corner in corners:
		var center: Vector2 = corner[0]
		var from_a: float = corner[1]
		var to_a: float = corner[2]
		for step in range(7):
			var t := float(step) / 6.0
			var ang := lerpf(from_a, to_a, t)
			pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	if pts.size() > 0:
		pts.append(pts[0])
	return pts


func _open_pending_ficha() -> void:
	var puzzle_id := GameManager.pending_library_puzzle_id
	if puzzle_id < 0:
		return
	GameManager.pending_library_puzzle_id = -1
	var item := GameManager.get_phrase_item(puzzle_id)
	if item.is_empty() or not _is_completed(puzzle_id):
		return
	_open_ficha(item)


func _thumb_daily_badge() -> Panel:
	var badge := Panel.new()
	badge.name = "DailyBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	badge.anchor_top = 1.0
	badge.anchor_bottom = 1.0
	badge.offset_left = 8.0
	badge.offset_top = -48.0
	badge.offset_right = 48.0
	badge.offset_bottom = -8.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.72, 0.22, 0.94)
	style.set_corner_radius_all(14)
	badge.add_theme_stylebox_override("panel", style)
	var icon := TextureRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 6
	icon.offset_top = 6
	icon.offset_right = -6
	icon.offset_bottom = -6
	icon.texture = ICON_DAILY
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(icon)
	return badge


func _ficha_daily_badge() -> Panel:
	var badge := Panel.new()
	badge.name = "DailyBadge"
	badge.visible = false
	badge.custom_minimum_size = Vector2(220, 44)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.72, 0.22, 0.92)
	style.set_corner_radius_all(16)
	badge.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.texture = ICON_DAILY
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := Label.new()
	label.text = tr("DailyBadge")
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.28, 0.16, 0.06, 1))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return badge


func _complete_check() -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(40, 40)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.72, 0.42, 1)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.12, 0.36, 0.22, 0.22)
	style.shadow_size = 4
	badge.add_theme_stylebox_override("panel", style)
	var mark := Label.new()
	mark.text = "✓"
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_override("font", FONT_UI)
	mark.add_theme_font_size_override("font_size", 28)
	mark.add_theme_color_override("font_color", Color(1, 1, 0.94, 1))
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(mark)
	return badge


func _thumb_heart_button(puzzle_id: int) -> Button:
	var heart := Button.new()
	heart.focus_mode = Control.FOCUS_NONE
	heart.custom_minimum_size = Vector2(56, 56)
	heart.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	heart.anchor_left = 1.0
	heart.anchor_right = 1.0
	heart.offset_left = -62.0
	heart.offset_top = 8.0
	heart.offset_right = -6.0
	heart.offset_bottom = 64.0
	var heart_bg := StyleBoxFlat.new()
	heart_bg.bg_color = Color(0.18, 0.1, 0.06, 0.42)
	heart_bg.set_corner_radius_all(22)
	heart.add_theme_stylebox_override("normal", heart_bg)
	heart.add_theme_stylebox_override("hover", heart_bg)
	heart.add_theme_stylebox_override("pressed", heart_bg)
	heart.add_theme_stylebox_override("focus", heart_bg)
	var icon := TextureRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.texture = ICON_HEART
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = Color(0.86, 0.22, 0.28, 1) if _is_favorite(puzzle_id) else Color(1, 1, 1, 0.72)
	heart.add_child(icon)
	heart.pressed.connect(func() -> void:
		if _drag_active:
			return
		SoundManager.play("ButtonClick")
		PlayerPrefs.toggle_favorite(puzzle_id)
		if _filter_favorites:
			_rebuild_index()
		else:
			icon.modulate = Color(0.86, 0.22, 0.28, 1) if _is_favorite(puzzle_id) else Color(1, 1, 1, 0.72)
	)
	return heart


func _count_pill(text: String) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(120, 48)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.96, 0.88, 1)
	style.border_color = Color(0.78, 0.62, 0.42, 0.45)
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.content_margin_left = 16
	style.content_margin_right = 16
	pill.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(label)
	return pill


func _pack_caption(item: Dictionary) -> String:
	var pack := _pack_label(item)
	if pack != "":
		return "⚝ %s" % pack
	return ""


func _pack_label(item: Dictionary) -> String:
	if GameManager.is_daily_puzzle(item):
		return tr("DailyChallenge")
	return str(item.get("pack", "")).strip_edges()


func _puzzle_title(item: Dictionary) -> String:
	var init := str(item.get("description_init", "")).strip_edges()
	if init != "" and init.to_lower() != "frase final":
		return init
	return _pack_label(item)


func _setup_ficha_layout() -> void:
	_ensure_ficha_backdrop()
	if button_ficha_favorite:
		button_ficha_favorite.visible = false
	ficha_title.text = tr("LibrarySheet")
	ficha_subtitle.text = tr("LibraryPuzzleSolved")
	ficha_sources_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ficha_sources.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ficha_context.add_theme_font_size_override("normal_font_size", 42)
	ficha_phrase.add_theme_font_size_override("normal_font_size", 50)
	ficha_phrase.add_theme_constant_override("line_separation", 12)
	ficha_context.add_theme_constant_override("line_separation", 12)
	var phrase_card := ficha_phrase.get_parent() as Panel
	if phrase_card:
		var quote_style := _cream_card_style()
		quote_style.bg_color = Color(1.0, 0.93, 0.78, 0.98)
		quote_style.border_color = Color(0.82, 0.52, 0.22, 0.55)
		phrase_card.add_theme_stylebox_override("panel", quote_style)
	if ficha_body.get_node_or_null("SummaryCard") == null:
		ficha_body.add_child(_create_ficha_summary_card())
	_ensure_info_header()
	_ensure_quote_marks()
	_ensure_ficha_footer()
	_order_ficha_cards()


func _order_ficha_cards() -> void:
	var order := [
		ficha_body.get_node_or_null("SummaryCard"),
		ficha_phrase.get_parent(),
		ficha_image_frame,
		ficha_context.get_parent(),
		ficha_sources_card,
	]
	var index := 0
	for node in order:
		if node and node.get_parent() == ficha_body:
			ficha_body.move_child(node, index)
			index += 1


func _ensure_ficha_backdrop() -> void:
	if ficha_root.get_node_or_null("Backdrop") != null:
		return
	var backdrop := Panel.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.z_index = -1
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.992, 0.965, 0.914, 0.92)
	backdrop.add_theme_stylebox_override("panel", style)
	ficha_root.add_child(backdrop)
	ficha_root.move_child(backdrop, 0)


func _ensure_info_header() -> void:
	ficha_context.offset_top = 120
	if ficha_context.get_parent().get_node_or_null("InfoHeader") != null:
		return
	var card := ficha_context.get_parent() as Control
	var header := HBoxContainer.new()
	header.name = "InfoHeader"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 24
	header.offset_right = -24
	header.offset_top = 16
	header.offset_bottom = 70
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 14)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(header)
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(44, 44)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.45, 0.72, 0.72, 1)
	badge_style.set_corner_radius_all(22)
	badge.add_theme_stylebox_override("panel", badge_style)
	var mark := Label.new()
	mark.text = "i"
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_theme_font_override("font", FONT_UI)
	mark.add_theme_font_size_override("font_size", 28)
	mark.add_theme_color_override("font_color", Color.WHITE)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(mark)
	header.add_child(badge)
	var title := Label.new()
	title.name = "InfoTitle"
	title.text = tr("LibraryInfo")
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_UI)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", INK)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(title)


func _ensure_quote_marks() -> void:
	var card := ficha_phrase.get_parent() as Control
	if card.get_node_or_null("QuoteOpen") != null:
		return
	ficha_phrase.offset_left = 56
	ficha_phrase.offset_right = -56
	for item in [["QuoteOpen", "“", Control.PRESET_TOP_LEFT, Vector2(16, 8)], ["QuoteClose", "”", Control.PRESET_BOTTOM_RIGHT, Vector2(-72, -64)]]:
		var quote := Label.new()
		quote.name = str(item[0])
		quote.text = str(item[1])
		quote.add_theme_font_override("font", FONT_UI)
		quote.add_theme_font_size_override("font_size", 88)
		quote.add_theme_color_override("font_color", Color(0.72, 0.14, 0.16, 1))
		quote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quote.set_anchors_preset(item[2])
		quote.position = item[3]
		card.add_child(quote)


func _ensure_ficha_footer() -> void:
	if ficha_root.get_node_or_null("FooterRow") != null:
		return
	var old := ficha_root.get_node_or_null("FavFooter")
	if old:
		old.queue_free()
	ficha_scroll.offset_bottom = -168
	var row := HBoxContainer.new()
	row.name = "FooterRow"
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.anchor_left = 0.5
	row.anchor_right = 0.5
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	row.offset_left = -520
	row.offset_right = 520
	row.offset_top = -148
	row.offset_bottom = -36
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	row.add_child(_footer_action_button(
		"FavFooter",
		ICON_HEART,
		Color(0.86, 0.22, 0.28, 1),
		Color(1, 0.99, 0.96, 0.96),
		Color(0.78, 0.62, 0.42, 0.45),
		INK,
		_on_ficha_favorite_pressed
	))
	row.add_child(_footer_action_button(
		"PlayAgain",
		ICON_PLAY,
		Color.WHITE,
		Color(1, 0.56, 0.02, 1),
		Color(0.83, 0.41, 0.02, 1),
		Color.WHITE,
		_on_ficha_play_again_pressed
	))
	ficha_root.add_child(row)


func _footer_action_button(
	button_name: String,
	icon_tex: Texture2D,
	icon_mod: Color,
	bg: Color,
	border: Color,
	text_color: Color,
	callback: Callable
) -> Button:
	var button := Button.new()
	button.name = button_name
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(280, 0)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(4)
	style.border_width_bottom = 8
	style.set_corner_radius_all(28)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	var inner := HBoxContainer.new()
	inner.name = "Row"
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 12)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(inner)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(42, 42)
	icon.texture = icon_tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = icon_mod
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(icon)
	var label := Label.new()
	label.name = "Label"
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", text_color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(label)
	return button


func _create_ficha_summary_card() -> Panel:
	var card := Panel.new()
	card.name = "SummaryCard"
	card.custom_minimum_size = Vector2(0, 280)
	card.add_theme_stylebox_override("panel", _cream_card_style())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	margin.add_child(row)
	var icon := TextureRect.new()
	icon.name = "CategoryIcon"
	icon.custom_minimum_size = Vector2(112, 112)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 16)
	row.add_child(col)
	var cat := Label.new()
	cat.name = "CategoryName"
	cat.add_theme_font_override("font", FONT_UI)
	cat.add_theme_font_size_override("font_size", 48)
	cat.add_theme_color_override("font_color", INK)
	col.add_child(cat)
	var meta := Label.new()
	meta.name = "ModeBadge"
	meta.add_theme_font_override("font", FONT_UI)
	meta.add_theme_font_size_override("font_size", 38)
	meta.add_theme_color_override("font_color", Color(0.42, 0.38, 0.24, 0.88))
	col.add_child(meta)
	var pack := Label.new()
	pack.name = "PackLabel"
	pack.add_theme_font_override("font", FONT_UI)
	pack.add_theme_font_size_override("font_size", 38)
	pack.add_theme_color_override("font_color", INK)
	col.add_child(pack)
	col.add_child(_ficha_daily_badge())
	var side := VBoxContainer.new()
	side.alignment = BoxContainer.ALIGNMENT_BEGIN
	side.add_theme_constant_override("separation", 10)
	row.add_child(side)
	var heart := Button.new()
	heart.name = "SummaryHeart"
	heart.custom_minimum_size = Vector2(80, 80)
	heart.focus_mode = Control.FOCUS_NONE
	heart.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	heart.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	heart.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	heart.pressed.connect(_on_ficha_favorite_pressed)
	var heart_icon := TextureRect.new()
	heart_icon.name = "Icon"
	heart_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	heart_icon.texture = ICON_HEART
	heart_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart.add_child(heart_icon)
	side.add_child(heart)
	var stars := HBoxContainer.new()
	stars.name = "Stars"
	stars.alignment = BoxContainer.ALIGNMENT_END
	stars.add_theme_constant_override("separation", 4)
	side.add_child(stars)
	return card


func _cream_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.984, 0.953, 0.98)
	style.border_color = Color(0.78, 0.62, 0.42, 0.45)
	style.set_border_width_all(3)
	style.border_width_bottom = 6
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.29, 0.18, 0.11, 0.14)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 6)
	return style


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
		GameManager.CAT_DAILY:
			return ICON_DAILY
		_:
			return ICON_CITA


func _category_pastel(cat_id: String) -> Color:
	return _category_card_style(GameManager.category_color(cat_id), cat_id).bg_color


func _format_solved_date(unix: int) -> String:
	if unix <= 0:
		return ""
	var date := Time.get_datetime_dict_from_unix_time(unix)
	var months: Array[String] = ["", "ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]
	var month := int(date.get("month", 0))
	var month_name: String = months[month] if month < months.size() else str(month)
	return "%d %s %d" % [int(date.get("day", 0)), month_name, int(date.get("year", 0))]


func _fill_ficha_summary(item: Dictionary) -> void:
	var card := ficha_body.get_node_or_null("SummaryCard") as Panel
	if card == null:
		return
	var cat_id := GameManager.library_category(item)
	card.add_theme_stylebox_override("panel", _category_card_style(GameManager.category_color(cat_id), cat_id))
	var icon := card.find_child("CategoryIcon", true, false) as TextureRect
	if icon:
		icon.texture = _category_icon_for(cat_id)
	var name_label := card.find_child("CategoryName", true, false) as Label
	if name_label:
		name_label.text = GameManager.category_display_name(cat_id)
	var mode := GameManager.level_game_mode(item)
	var mode_name := tr("Cryptogram") if mode == GameManager.MODE_CRYPTOGRAM else tr("Quick")
	var puzzle_id := int(item.get("index", -1))
	var summary := PuzzleSaveManager.get_puzzle_summary(puzzle_id) if typeof(PuzzleSaveManager) != TYPE_NIL else {}
	var date_text := _format_solved_date(int(summary.get("completed_at", 0)))
	var mode_label := card.find_child("ModeBadge", true, false) as Label
	if mode_label:
		mode_label.text = "%s · %s" % [mode_name, date_text] if date_text != "" else mode_name
	var old_date := card.find_child("SolvedDate", true, false) as Label
	if old_date:
		old_date.visible = false
	var pack_label := card.find_child("PackLabel", true, false) as Label
	if pack_label:
		var pack := _pack_label(item)
		pack_label.text = pack if pack != "" else tr("LibraryBaseGame")
	var daily_badge := card.find_child("DailyBadge", true, false) as Control
	if daily_badge:
		daily_badge.visible = false
	var stars := card.find_child("Stars", true, false) as HBoxContainer
	if stars:
		for child in stars.get_children():
			child.queue_free()
		var earned := clampi(int(summary.get("stars_remaining", 0)), 0, 5)
		var total := clampi(int(summary.get("stars_max", 2)), 1, 5)
		for i in range(total):
			stars.add_child(_outlined_star(i < earned, mode == GameManager.MODE_CRYPTOGRAM))


func _outlined_star(filled: bool, cryptogram: bool) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(54, 54)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outline := TextureRect.new()
	outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outline.texture = STAR_ON
	outline.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	outline.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if filled and cryptogram:
		outline.modulate = Color(0.22, 0.12, 0.08, 1)
	elif filled:
		outline.modulate = Color(0.72, 0.38, 0.08, 1)
	else:
		outline.modulate = Color(0.62, 0.52, 0.46, 0.22)
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(outline)
	var fill := TextureRect.new()
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.offset_left = 5
	fill.offset_top = 5
	fill.offset_right = -5
	fill.offset_bottom = -5
	fill.texture = STAR_ON if filled else STAR_OFF
	fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if filled and cryptogram:
		fill.modulate = Color(1, 0.55, 0.14, 1)
	elif filled:
		fill.modulate = Color(1, 0.84, 0.18, 1)
	else:
		fill.modulate = Color(0.62, 0.52, 0.46, 0.38)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(fill)
	return wrap


func _open_ficha(item: Dictionary) -> void:
	SoundManager.play("ButtonClick")
	_ficha_item = item
	var cat_id := GameManager.library_category(item)
	ficha_title.text = tr("LibrarySheet")
	ficha_subtitle.text = tr("LibraryPuzzleSolved")
	_fill_ficha_summary(item)
	var backdrop := ficha_root.get_node_or_null("Backdrop") as Panel
	if backdrop:
		var style := StyleBoxFlat.new()
		style.bg_color = _category_pastel(cat_id)
		backdrop.add_theme_stylebox_override("panel", style)

	var phrase := str(item.get("text", "")).strip_edges()
	var author := str(item.get("description_init", "")).strip_edges()
	if author.to_lower() == "frase final":
		author = ""
	var phrase_bb := "[center]%s[/center]" % _escape_bbcode(phrase)
	if author != "":
		phrase_bb += "\n[center][i][color=#8A6A48]— %s —[/color][/i][/center]" % _escape_bbcode(author)
	ficha_phrase.text = phrase_bb

	var context := str(item.get("description_end", "")).strip_edges()
	if context == "":
		context = tr("PuzzleCompleteFallback")
	ficha_context.text = _escape_bbcode(context)

	var path := GameManager.find_level_image_path(int(item.get("image_number", -1)))
	if path != "":
		var tex := load(path) as Texture2D
		ficha_image.texture = tex
		ficha_image_frame.visible = tex != null
	else:
		ficha_image_frame.visible = false

	var source := str(item.get("source", "")).strip_edges()
	if source == "":
		ficha_sources_card.visible = false
	else:
		ficha_sources_card.visible = true
		ficha_sources.text = source.replace(";", "\n").replace("|", "\n")

	index_root.visible = false
	ficha_root.visible = true
	if ficha_scroll:
		ficha_scroll.scroll_vertical = 0
	_apply_ficha_favorite_button()
	_fit_ficha_cards()


func _fit_ficha_cards() -> void:
	await get_tree().process_frame
	_fit_text_card($FichaRoot/Scroll/Body/PhraseCard as Panel, ficha_phrase, 108.0, 260.0)
	_fit_text_card($FichaRoot/Scroll/Body/ContextCard as Panel, ficha_context, 150.0, 260.0)
	if ficha_sources_card.visible:
		_fit_text_card(ficha_sources_card, ficha_sources, 120.0, 180.0)
	if ficha_image_frame.visible:
		var width := ficha_scroll.size.x
		if width < 8.0:
			width = 1100.0
		ficha_image_frame.custom_minimum_size = Vector2(0, width)


func _fit_text_card(card: Panel, label: RichTextLabel, padding: float, minimum: float) -> void:
	if card == null or label == null:
		return
	card.custom_minimum_size.y = maxf(minimum, float(label.get_content_height()) + padding)


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")


func _category_card_style(accent: Color, cat_id: String = "") -> StyleBoxFlat:
	var parchment := Color(0.992, 0.965, 0.914, 1)
	var mix := 0.86
	if cat_id == GameManager.CAT_CITA or cat_id == GameManager.CAT_EFEMERIDE:
		mix = 0.91
	var style := StyleBoxFlat.new()
	style.bg_color = accent.lerp(parchment, mix)
	style.bg_color.a = 0.78
	style.border_color = accent.lerp(Color(0.78, 0.62, 0.42, 1), 0.55)
	style.border_color.a = 0.28
	style.set_border_width_all(3)
	style.set_corner_radius_all(32)
	style.shadow_color = Color(0.29, 0.18, 0.11, 0.06)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	return style


func _image_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.91, 0.81, 0.61, 1)
	style.border_color = Color(0.71, 0.49, 0.24, 0.45)
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	return style


func _on_index_back_pressed() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SoundManager.play("ButtonClick")
	get_tree().change_scene_to_file(PATH_MAIN)


func _on_button_favorites_pressed() -> void:
	if _drag_active:
		return
	SoundManager.play("ButtonClick")
	if button_favorites:
		GameManager.button_blink(button_favorites)
	_filter_favorites = not _filter_favorites
	_rebuild_index()


func _on_ficha_play_again_pressed() -> void:
	if _drag_active:
		return
	var item := _ficha_item
	var puzzle_id := int(item.get("index", -1))
	if puzzle_id < 0:
		return
	if not get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
		return
	if ficha_root.get_node_or_null("PracticeDialog") != null:
		return
	SoundManager.play("ButtonClick")
	_show_practice_dialog(item)


func _show_practice_dialog(item: Dictionary) -> void:
	var overlay := ColorRect.new()
	overlay.name = "PracticeDialog"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.08, 0.04, 0.02, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 80
	ficha_root.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(1020, 0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 0.965, 0.86, 1)
	card_style.border_color = Color(0.62, 0.4, 0.16, 0.46)
	card_style.set_border_width_all(4)
	card_style.border_width_bottom = 9
	card_style.set_corner_radius_all(40)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 36)
	card.add_child(margin)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 26)
	margin.add_child(inner)
	var lock := TextureRect.new()
	lock.texture = ICON_LOCK
	lock.custom_minimum_size = Vector2(80, 80)
	lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(lock)
	var title := Label.new()
	title.text = tr("LibraryPracticeTitle")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", FONT_UI)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", INK)
	inner.add_child(title)
	var body := Label.new()
	body.text = tr("LibraryPracticeBody")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", FONT_UI)
	body.add_theme_font_size_override("font_size", 40)
	body.add_theme_color_override("font_color", INK_SOFT)
	inner.add_child(body)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 24)
	inner.add_child(buttons)
	var cancel := Button.new()
	cancel.text = tr("Cancel")
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size = Vector2(0, 124)
	cancel.add_theme_font_override("font", FONT_UI)
	cancel.add_theme_font_size_override("font_size", 42)
	cancel.add_theme_color_override("font_color", INK)
	var cancel_style := StyleBoxFlat.new()
	cancel_style.bg_color = Color(1, 0.982, 0.92, 1)
	cancel_style.border_color = Color(0.66, 0.44, 0.2, 0.7)
	cancel_style.set_border_width_all(3)
	cancel_style.border_width_bottom = 8
	cancel_style.set_corner_radius_all(28)
	cancel.add_theme_stylebox_override("normal", cancel_style)
	cancel.add_theme_stylebox_override("hover", cancel_style)
	cancel.add_theme_stylebox_override("pressed", cancel_style)
	cancel.pressed.connect(func() -> void:
		SoundManager.play("ButtonClick")
		overlay.queue_free()
	)
	buttons.add_child(cancel)
	var play := Button.new()
	play.text = tr("LibraryPracticePlay")
	play.focus_mode = Control.FOCUS_NONE
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.custom_minimum_size = Vector2(0, 124)
	play.add_theme_font_override("font", FONT_UI)
	play.add_theme_font_size_override("font_size", 42)
	play.add_theme_color_override("font_color", Color.WHITE)
	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Color(0.96, 0.51, 0.01, 1)
	play_style.border_color = Color(0.83, 0.41, 0.02, 1)
	play_style.set_border_width_all(3)
	play_style.border_width_bottom = 8
	play_style.set_corner_radius_all(28)
	play.add_theme_stylebox_override("normal", play_style)
	play.add_theme_stylebox_override("hover", play_style)
	play.add_theme_stylebox_override("pressed", play_style)
	play.pressed.connect(func() -> void:
		SoundManager.play("ButtonClick")
		overlay.queue_free()
		_start_practice_game(item)
	)
	buttons.add_child(play)


func _start_practice_game(item: Dictionary) -> void:
	var puzzle_id := int(item.get("index", -1))
	if puzzle_id < 0:
		return
	var summary := PuzzleSaveManager.get_puzzle_summary(puzzle_id)
	GameManager.session_source = GameManager.SOURCE_PRACTICE
	GameManager.locked_record_stars = clampi(int(summary.get("stars_remaining", 0)), 0, 5)
	GameManager.allow_completed_replay = true
	GameManager.id_frase = puzzle_id
	GameManager.set_game_mode_actual(GameManager.level_game_mode(item))
	GameManager.set_dificultad_actual(int(item.get("difficulty", 1)))
	GameManager.seleccionar_por_index(puzzle_id)
	PuzzleSaveManager.prepare_current_puzzle_cipher()
	GameManager.set_go_to_game_disable()
	var preview := THEME_PREVIEW.instantiate()
	preview.set("launch_game_on_start", true)
	preview.set("image_path", GameManager.find_level_image_path(int(item.get("image_number", -1))))
	add_child(preview)


func _on_ficha_favorite_pressed() -> void:
	if _drag_active:
		return
	var puzzle_id := int(_ficha_item.get("index", -1))
	if puzzle_id < 0:
		return
	SoundManager.play("ButtonClick")
	PlayerPrefs.toggle_favorite(puzzle_id)
	_apply_ficha_favorite_button()


func _apply_ficha_favorite_button() -> void:
	var on := _is_favorite(int(_ficha_item.get("index", -1)))
	var heart_color := Color(0.86, 0.22, 0.28, 1) if on else Color(0.62, 0.52, 0.46, 0.7)
	var summary_heart := ficha_body.find_child("SummaryHeart", true, false) as Button
	if summary_heart:
		var icon := summary_heart.get_node_or_null("Icon") as TextureRect
		if icon:
			icon.modulate = heart_color
	var footer := ficha_root.find_child("FavFooter", true, false) as Button
	if footer:
		var icon := footer.find_child("Icon", true, false) as TextureRect
		if icon:
			icon.modulate = Color(0.86, 0.22, 0.28, 1)
		var label := footer.find_child("Label", true, false) as Label
		if label:
			label.add_theme_font_size_override("font_size", 38)
			label.text = tr("InFavorites") if on else tr("AddToFavorites")
	var play_again := ficha_root.find_child("PlayAgain", true, false) as Button
	if play_again:
		var play_label := play_again.find_child("Label", true, false) as Label
		if play_label:
			play_label.add_theme_font_size_override("font_size", 38)
			play_label.text = tr("PlayAgain")


func _on_ficha_back_pressed() -> void:
	SoundManager.play("ButtonClick")
	var keep_scroll := index_scroll.scroll_vertical
	ficha_root.visible = false
	index_root.visible = true
	_rebuild_index()
	index_scroll.scroll_vertical = keep_scroll
