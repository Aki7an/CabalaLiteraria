extends Control

signal closed

const NOTE: Texture2D = preload("res://images/ui_icon_music_note.svg")
const SLASH: Texture2D = preload("res://images/ui_icon_mute_slash.svg")
const FONT: Font = preload("res://GUI/new_font_Rubik_semibold.tres")

const COPY := {
	"es": {"now": "Sonando ahora:", "list": "Lista de canciones"},
	"en": {"now": "Now playing:", "list": "Song list"},
	"de": {"now": "Jetzt läuft:", "list": "Liedliste"},
	"fr": {"now": "En lecture :", "list": "Liste des morceaux"},
	"eu": {"now": "Orain entzuten:", "list": "Abesti zerrenda"},
	"it": {"now": "In riproduzione:", "list": "Lista dei brani"},
	"pt": {"now": "A tocar agora:", "list": "Lista de músicas"},
}

var _now_title: Label
var _mute_slash: TextureRect
var _list: VBoxContainer
var _refresh_queued := false
var _closing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("MusicPanel")
	_build()
	if not SignalManager.audio_prefs_changed.is_connected(_queue_refresh):
		SignalManager.audio_prefs_changed.connect(_queue_refresh)
	if not SoundManager.now_playing_changed.is_connected(_queue_refresh):
		SoundManager.now_playing_changed.connect(_queue_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.06, 0.02, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 40.0
	card.offset_top = 240.0
	card.offset_right = -40.0
	card.offset_bottom = -180.0
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", _card_style())
	add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(column)

	var now_row := HBoxContainer.new()
	now_row.add_theme_constant_override("separation", 18)
	now_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(now_row)

	var mute := Button.new()
	mute.custom_minimum_size = Vector2(122, 122)
	mute.focus_mode = Control.FOCUS_NONE
	mute.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var mute_normal := _chunky(Color(1, 0.56, 0.02), Color(0.72, 0.32, 0.02))
	var mute_pressed := _chunky(Color(0.9, 0.4, 0.015), Color(0.65, 0.25, 0.01), true)
	mute.add_theme_stylebox_override("normal", mute_normal)
	mute.add_theme_stylebox_override("hover", mute_normal)
	mute.add_theme_stylebox_override("pressed", mute_pressed)
	mute.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	mute.pressed.connect(_on_mute_pressed)
	now_row.add_child(mute)

	var note := TextureRect.new()
	note.texture = NOTE
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	note.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	note.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	note.offset_left = 26.0
	note.offset_top = 26.0
	note.offset_right = -26.0
	note.offset_bottom = -26.0
	mute.add_child(note)

	_mute_slash = TextureRect.new()
	_mute_slash.texture = SLASH
	_mute_slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mute_slash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mute_slash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mute_slash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mute_slash.offset_left = 22.0
	_mute_slash.offset_top = 22.0
	_mute_slash.offset_right = -22.0
	_mute_slash.offset_bottom = -22.0
	_mute_slash.visible = false
	mute.add_child(_mute_slash)

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 4)
	now_row.add_child(titles)

	var now_label := Label.new()
	now_label.text = _copy("now")
	_style_label(now_label, 28, Color(0.45, 0.3, 0.14))
	titles.add_child(now_label)

	_now_title = Label.new()
	_now_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_label(_now_title, 40, Color(0.2, 0.12, 0.06))
	titles.add_child(_now_title)

	var close_button := _icon_button("cross", Color(0.45, 0.28, 0.16))
	close_button.custom_minimum_size = Vector2(78, 78)
	close_button.pressed.connect(_close)
	now_row.add_child(close_button)

	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", _frame_style())
	column.add_child(frame)

	var frame_margin := MarginContainer.new()
	frame_margin.add_theme_constant_override("margin_left", 18)
	frame_margin.add_theme_constant_override("margin_top", 16)
	frame_margin.add_theme_constant_override("margin_right", 18)
	frame_margin.add_theme_constant_override("margin_bottom", 16)
	frame_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(frame_margin)

	var frame_box := VBoxContainer.new()
	frame_box.add_theme_constant_override("separation", 12)
	frame_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame_margin.add_child(frame_box)

	var heading := Label.new()
	heading.text = _copy("list")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(heading, 32, Color(0.32, 0.2, 0.1))
	frame_box.add_child(heading)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 3)
	rule.color = Color(0.72, 0.55, 0.28, 0.45)
	frame_box.add_child(rule)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame_box.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 12)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func _process(_delta: float) -> void:
	if not _refresh_queued or _closing:
		return
	_refresh_queued = false
	_refresh()


func _queue_refresh() -> void:
	if _closing or not is_inside_tree():
		return
	_apply_now_playing()
	_refresh_queued = true


func _apply_now_playing() -> void:
	if _now_title == null or _mute_slash == null:
		return
	var line: String = SoundManager.current_track_line()
	_now_title.text = line if not line.is_empty() else "—"
	var enabled: bool = SoundManager.is_music_enabled()
	_mute_slash.visible = not enabled


func _refresh() -> void:
	_refresh_queued = false
	if _closing or not is_inside_tree():
		return
	_apply_now_playing()
	for child in _list.get_children():
		_list.remove_child(child)
		child.free()
	for row in SoundManager.local_music_catalog():
		_list.add_child(_make_row(row))


func _make_row(info: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _row_style(bool(info.get("playing", false))))
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(box)

	var number := Label.new()
	number.custom_minimum_size = Vector2(64, 0)
	number.text = str(info.get("number", ""))
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(number, 30, Color(0.4, 0.26, 0.12))
	box.add_child(number)

	var title := Label.new()
	title.text = str(info.get("title", ""))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style_label(title, 30, Color(0.2, 0.13, 0.08))
	box.add_child(title)

	var play := _icon_button("play", Color(0.1, 0.42, 0.58))
	play.pressed.connect(_on_play_track.bind(int(info.get("index", -1))))
	box.add_child(play)

	var included := bool(info.get("included", true))
	var mark_color := Color(0.15, 0.62, 0.36) if included else Color(0.78, 0.22, 0.18)
	var mark := _icon_button("check" if included else "cross", mark_color)
	mark.pressed.connect(_on_toggle_track.bind(int(info.get("index", -1))))
	box.add_child(mark)
	return row


func _on_play_track(index: int) -> void:
	SoundManager.play("ButtonClick")
	SoundManager.play_local_track(index)


func _on_toggle_track(index: int) -> void:
	SoundManager.play("ButtonClick")
	var included := false
	for row in SoundManager.local_music_catalog():
		if int(row.get("index", -2)) == index:
			included = bool(row.get("included", true))
			break
	SoundManager.set_track_included(index, not included)


func _on_mute_pressed() -> void:
	SoundManager.play("ButtonClick")
	SoundManager.toggle_music_enabled()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close()
	elif event is InputEventScreenTouch and event.pressed:
		_close()


func _close() -> void:
	if _closing:
		return
	_closing = true
	SoundManager.play("ButtonClick")
	closed.emit()
	queue_free()


func _copy(key: String) -> String:
	var code := str(PlayerPrefs.idioma).substr(0, 2).to_lower()
	var table: Dictionary = COPY.get(code, COPY["es"])
	return str(table.get(key, COPY["es"].get(key, key)))


func _style_label(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _icon_button(shape: String, glyph_color: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(86, 86)
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var normal := _chunky(Color(1, 0.97, 0.9), Color(0.72, 0.55, 0.32))
	var pressed := _chunky(Color(0.93, 0.84, 0.68), Color(0.6, 0.44, 0.24), true)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var glyph := Glyph.new(shape, glyph_color)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.offset_left = 16.0
	glyph.offset_top = 16.0
	glyph.offset_right = -16.0
	glyph.offset_bottom = -16.0
	button.add_child(glyph)
	return button


func _card_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 0.965, 0.86, 1)
	box.border_width_left = 4
	box.border_width_top = 4
	box.border_width_right = 4
	box.border_width_bottom = 8
	box.border_color = Color(0.62, 0.4, 0.16, 0.55)
	box.set_corner_radius_all(38)
	box.shadow_color = Color(0.14, 0.08, 0.03, 0.32)
	box.shadow_size = 24
	box.shadow_offset = Vector2(0, 16)
	return box


func _frame_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 0.94, 0.82, 1)
	box.border_width_left = 3
	box.border_width_top = 3
	box.border_width_right = 3
	box.border_width_bottom = 3
	box.border_color = Color(0.72, 0.52, 0.26, 0.55)
	box.set_corner_radius_all(28)
	return box


func _row_style(playing: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 0.86, 0.55, 1) if playing else Color(1, 0.975, 0.92, 1)
	box.set_corner_radius_all(22)
	box.content_margin_left = 8
	box.content_margin_top = 8
	box.content_margin_right = 8
	box.content_margin_bottom = 8
	if playing:
		box.border_width_left = 4
		box.border_width_top = 4
		box.border_width_right = 4
		box.border_width_bottom = 4
		box.border_color = Color(0.85, 0.48, 0.05, 1)
	return box


func _chunky(fill: Color, edge: Color, pressed := false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(22)
	box.border_color = edge
	if pressed:
		box.border_width_left = 3
		box.border_width_top = 7
		box.border_width_right = 3
		box.border_width_bottom = 3
	else:
		box.border_width_left = 3
		box.border_width_top = 3
		box.border_width_right = 3
		box.border_width_bottom = 7
	return box


class Glyph extends Control:
	var shape := "play"
	var tint := Color.WHITE

	func _init(next_shape: String = "play", next_tint: Color = Color.WHITE) -> void:
		shape = next_shape
		tint = next_tint
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var bounds := size
		if bounds.x < 2.0 or bounds.y < 2.0:
			return
		var width := maxf(bounds.y * 0.14, 4.0)
		match shape:
			"play":
				draw_colored_polygon(PackedVector2Array([
					Vector2(bounds.x * 0.28, bounds.y * 0.16),
					Vector2(bounds.x * 0.28, bounds.y * 0.84),
					Vector2(bounds.x * 0.84, bounds.y * 0.5),
				]), tint)
			"check":
				draw_polyline(PackedVector2Array([
					Vector2(bounds.x * 0.16, bounds.y * 0.52),
					Vector2(bounds.x * 0.40, bounds.y * 0.76),
					Vector2(bounds.x * 0.84, bounds.y * 0.24),
				]), tint, width, true)
			"cross":
				draw_line(
					Vector2(bounds.x * 0.24, bounds.y * 0.24),
					Vector2(bounds.x * 0.76, bounds.y * 0.76),
					tint, width, true
				)
				draw_line(
					Vector2(bounds.x * 0.76, bounds.y * 0.24),
					Vector2(bounds.x * 0.24, bounds.y * 0.76),
					tint, width, true
				)
