extends Control

const TOP_ROWS := 5
const COLOR_INK := Color(0.24, 0.14, 0.08, 1.0)
const COLOR_ORANGE := Color(0.96, 0.47, 0.13, 1.0)
const COLOR_CREAM := Color(1.0, 0.97, 0.89, 1.0)
const MEDAL_TEXTURES := [
	preload("res://images/leaderboard_medal_gold.svg"),
	preload("res://images/leaderboard_medal_silver.svg"),
	preload("res://images/leaderboard_medal_bronze.svg"),
]

@onready var button_back: Button = %ButtonBack
@onready var online_rows: VBoxContainer = %OnlineRows
@onready var around_rows: VBoxContainer = %AroundRows
@onready var around_frame: PanelContainer = %AroundFrame
@onready var online_status: Label = %OnlineStatus
@onready var category_buttons: Array[Button] = [
	%FilterGlobal,
	%FilterQuotes,
	%FilterEvents,
	%FilterCuriosities,
	%FilterFragments,
]
@onready var mode_buttons: Array[Button] = [
	%FilterQuick,
	%FilterCryptogram,
]

var _category_filter := "global"
var _mode_filter := GameManager.MODE_QUICK
var _loading := false


func _ready() -> void:
	button_back.pressed.connect(_on_button_back_pressed)
	var categories := [
		"global",
		GameManager.CAT_CITA,
		GameManager.CAT_EFEMERIDE,
		GameManager.CAT_CURIOSIDADES,
		GameManager.CAT_FRAGMENTO,
	]
	for i in category_buttons.size():
		var category: String = categories[i]
		category_buttons[i].pressed.connect(func() -> void: _select_category(category))
	var modes := [GameManager.MODE_QUICK, GameManager.MODE_CRYPTOGRAM]
	for i in mode_buttons.size():
		var mode: String = modes[i]
		mode_buttons[i].pressed.connect(func() -> void: _select_mode(mode))
	_update_filter_styles()
	_load_online_ranking()


func _select_category(value: String) -> void:
	if _loading or value == _category_filter:
		return
	_category_filter = value
	_update_filter_styles()
	_load_online_ranking()


func _select_mode(value: String) -> void:
	if _loading or value == _mode_filter:
		return
	_mode_filter = value
	_update_filter_styles()
	_load_online_ranking()


func _update_filter_styles() -> void:
	var categories := [
		"global",
		GameManager.CAT_CITA,
		GameManager.CAT_EFEMERIDE,
		GameManager.CAT_CURIOSIDADES,
		GameManager.CAT_FRAGMENTO,
	]
	for i in category_buttons.size():
		_apply_category_style(
			category_buttons[i],
			categories[i],
			categories[i] == _category_filter
		)
	var modes := [GameManager.MODE_QUICK, GameManager.MODE_CRYPTOGRAM]
	for i in mode_buttons.size():
		_apply_mode_style(mode_buttons[i], modes[i] == _mode_filter)
	_apply_around_frame_style()


func _category_icon_box_color(category_id: String) -> Color:
	match category_id:
		GameManager.CAT_CITA:
			return Color("a4b5f4")
		GameManager.CAT_EFEMERIDE:
			return Color("f0b0aa")
		GameManager.CAT_CURIOSIDADES:
			return Color("f6e07a")
		GameManager.CAT_FRAGMENTO:
			return Color("9ed8dc")
		_:
			return Color("fff0d6")


func _apply_category_style(button: Button, category_id: String, selected: bool) -> void:
	var icon_box := _category_icon_box_color(category_id)
	var background := icon_box.lerp(Color.WHITE, 0.42)
	var border := (
		icon_box.darkened(0.12)
		if selected
		else Color(icon_box.r, icon_box.g, icon_box.b, 0.55)
	)
	var style := _make_button_style(background, border, 34, 5 if selected else 2)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_color", COLOR_ORANGE if selected else COLOR_INK)
	button.add_theme_color_override("font_disabled_color", COLOR_ORANGE if selected else COLOR_INK)
	var text_label := button.get_node_or_null("Text") as Label
	if text_label != null:
		text_label.add_theme_color_override(
			"font_color",
			COLOR_ORANGE if selected else COLOR_INK
		)


func _around_frame_colors() -> Dictionary:
	match _category_filter:
		GameManager.CAT_CITA:
			return {
				"bg": Color(0.90, 0.84, 0.96, 1.0),
				"border": Color(0.62, 0.42, 0.78, 0.42),
			}
		GameManager.CAT_EFEMERIDE:
			return {
				"bg": Color(0.98, 0.84, 0.84, 1.0),
				"border": Color(0.82, 0.40, 0.40, 0.42),
			}
		GameManager.CAT_CURIOSIDADES:
			return {
				"bg": Color(0.99, 0.95, 0.76, 1.0),
				"border": Color(0.82, 0.68, 0.22, 0.42),
			}
		GameManager.CAT_FRAGMENTO:
			return {
				"bg": Color(0.76, 0.93, 0.91, 1.0),
				"border": Color(0.22, 0.66, 0.62, 0.42),
			}
		_:
			return {
				"bg": Color(1.0, 0.965, 0.91, 1.0),
				"border": Color(0.82, 0.62, 0.38, 0.40),
			}


func _apply_around_frame_style() -> void:
	var colors: Dictionary = _around_frame_colors()
	var style := StyleBoxFlat.new()
	style.bg_color = colors.bg
	style.border_color = colors.border
	style.set_border_width_all(3)
	style.set_corner_radius_all(36)
	style.content_margin_left = 14
	style.content_margin_top = 14
	style.content_margin_right = 14
	style.content_margin_bottom = 14
	around_frame.add_theme_stylebox_override("panel", style)


func _apply_mode_style(button: Button, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color(1.0, 0.69, 0.31, 1.0)
		if selected
		else Color(1.0, 0.976, 0.925, 1.0)
	)
	style.border_color = (
		Color(0.91, 0.42, 0.1, 1.0)
		if selected
		else Color(0.78, 0.66, 0.48, 0.62)
	)
	style.set_border_width_all(3)
	var is_quick := button == mode_buttons[0]
	style.corner_radius_top_left = 34 if is_quick else 5
	style.corner_radius_bottom_left = 18 if is_quick else 5
	style.corner_radius_top_right = 5 if is_quick else 34
	style.corner_radius_bottom_right = 5 if is_quick else 18
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_color", COLOR_INK)
	button.add_theme_color_override("font_disabled_color", COLOR_INK)


func _make_button_style(
	background: Color,
	border: Color,
	radius: int,
	border_width: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _set_filters_disabled(disabled: bool) -> void:
	for button in category_buttons:
		button.disabled = disabled
	for button in mode_buttons:
		button.disabled = disabled


func _load_online_ranking() -> void:
	_loading = true
	_set_filters_disabled(true)
	_clear_rows(online_rows)
	_clear_rows(around_rows)
	online_status.visible = true
	online_status.text = "Cargando clasificación online…"

	if typeof(PlayFabTools) == TYPE_NIL:
		_show_online_unavailable()
		return
	if not PlayFabTools.is_logged_in():
		for attempt in 50:
			if PlayFabTools.is_logged_in():
				break
			await get_tree().create_timer(0.2).timeout
	if not PlayFabTools.is_logged_in():
		_show_online_unavailable()
		return

	await PlayFabTools.submit_competitive_rankings(GameManager.player_name)
	var statistic: String = PlayFabTools.competitive_stat_name(
		_category_filter,
		_mode_filter
	)
	var top_result := await _fetch_leaderboard("GetLeaderboard", statistic, TOP_ROWS)
	var around_result := await _fetch_leaderboard(
		"GetLeaderboardAroundPlayer",
		statistic,
		3
	)
	if not bool(top_result.get("ok", false)):
		_show_online_unavailable()
		return

	online_status.visible = false
	var top_entries: Array = top_result.get("entries", [])
	for i in mini(TOP_ROWS, top_entries.size()):
		_add_competitive_row(online_rows, top_entries[i], false)
	for i in range(mini(TOP_ROWS, top_entries.size()), TOP_ROWS):
		_add_placeholder_row(online_rows, i + 1)

	var around_entries: Array = around_result.get("entries", [])
	if around_entries.is_empty():
		_add_placeholder_row(around_rows, 0, "TÚ — sin posición")
	else:
		for entry_value in around_entries:
			var entry: Dictionary = entry_value
			var is_player := (
				str(entry.get("PlayFabId", "")) == str(PlayFabTools.playfab_id)
			)
			_add_competitive_row(around_rows, entry, is_player, true)
	_loading = false
	_set_filters_disabled(false)


func _fetch_leaderboard(
	endpoint: String,
	statistic: String,
	max_results: int
) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = 20
	add_child(request)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Accept-Encoding: identity",
		"X-Authorization: " + str(PlayFabTools.session_ticket),
		"X-ReportErrorAsSuccess: true",
	])
	var body := {
		"StatisticName": statistic,
		"MaxResultsCount": max_results,
	}
	if endpoint == "GetLeaderboard":
		body["StartPosition"] = 0
	var url := "https://%s.playfabapi.com/Client/%s" % [
		PlayFabTools.TITLE_ID,
		endpoint,
	]
	if request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body)) != OK:
		request.queue_free()
		return {"ok": false, "entries": []}
	var response: Array = await request.request_completed
	var http_code := int(response[1])
	var text := (response[3] as PackedByteArray).get_string_from_utf8()
	request.queue_free()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"ok": false, "entries": []}
	var json: Dictionary = parsed
	if int(json.get("code", http_code)) != 200:
		return {"ok": false, "entries": []}
	var entries_value: Variant = json.get("data", {}).get("Leaderboard", [])
	return {
		"ok": entries_value is Array,
		"entries": entries_value if entries_value is Array else [],
	}


func _add_competitive_row(
	container: VBoxContainer,
	entry: Dictionary,
	is_player: bool,
	around_player := false
) -> void:
	var decoded: Dictionary = PlayFabTools.decode_competitive_value(
		int(entry.get("StatValue", 0))
	)
	_add_row(
		container,
		int(entry.get("Position", -1)) + 1,
		_row_display_name(entry, is_player, around_player),
		int(decoded.get("stars_earned", 0)),
		int(decoded.get("completed", 0)),
		int(decoded.get("stars_per_puzzle_hundredths", 0)),
		int(decoded.get("aids_used", 0)),
		int(decoded.get("failed_letters", 0)),
		is_player
	)


func _has_online_name() -> bool:
	var local_name := str(GameManager.player_name).strip_edges()
	return local_name != "" and local_name != "---" and local_name != "BAD"


func _row_display_name(
	entry: Dictionary,
	is_player: bool,
	around_player: bool
) -> String:
	var local_name := str(GameManager.player_name).strip_edges()
	if is_player:
		return local_name if _has_online_name() else "TÚ"
	if around_player and not _has_online_name():
		return "-"
	var remote_name := str(entry.get("DisplayName", "")).strip_edges()
	return remote_name if remote_name != "" else "-"


func _add_placeholder_row(
	container: VBoxContainer,
	rank: int,
	name: String = "—"
) -> void:
	_add_row(container, rank, name, -1, -1, -1, -1, -1, false)


func _add_row(
	container: VBoxContainer,
	rank: int,
	player_name: String,
	stars: int,
	puzzles: int,
	average_hundredths: int,
	aids: int,
	failed_letters: int,
	is_player: bool
) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 124)
	panel.add_theme_stylebox_override("panel", _make_row_style(is_player))
	container.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	if rank in [1, 2, 3] and stars >= 0:
		row.add_child(_make_medal(rank))
	else:
		var rank_label := _make_label(
			"—" if rank <= 0 else _format_rank(rank),
			34,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		rank_label.custom_minimum_size.x = 92
		if is_player:
			rank_label.add_theme_color_override("font_color", COLOR_ORANGE)
		row.add_child(rank_label)

	var name_label := _make_label(player_name, 34, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_player:
		name_label.add_theme_color_override("font_color", COLOR_ORANGE)
	row.add_child(name_label)

	row.add_child(_make_stars_value(stars))
	row.add_child(_make_value_label("—" if puzzles < 0 else str(puzzles), 105))
	row.add_child(_make_value_label(
		"—" if average_hundredths < 0 else _format_average(average_hundredths),
		146
	))
	row.add_child(_make_value_label("—" if aids < 0 else str(aids), 105))
	row.add_child(_make_value_label(
		"—" if failed_letters < 0 else str(failed_letters),
		126
	))


func _make_medal(rank: int) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(92, 118)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var medal := TextureRect.new()
	medal.set_anchors_preset(Control.PRESET_FULL_RECT)
	medal.texture = MEDAL_TEXTURES[rank - 1]
	medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(medal)

	var number := Label.new()
	number.text = str(rank)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.set_anchors_preset(Control.PRESET_FULL_RECT)
	number.offset_bottom = -28
	number.add_theme_font_size_override("font_size", 36)
	number.add_theme_color_override("font_color", _medal_number_color(rank))
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(number)
	return wrap


func _medal_number_color(rank: int) -> Color:
	match rank:
		1:
			return Color("8c4b08")
		2:
			return Color("626a70")
		_:
			return Color("693416")


func _make_stars_value(stars: int) -> HBoxContainer:
	var value := HBoxContainer.new()
	value.custom_minimum_size.x = 142
	value.alignment = BoxContainer.ALIGNMENT_CENTER
	value.add_theme_constant_override("separation", 5)
	if stars < 0:
		value.add_child(_make_label("—", 32, HORIZONTAL_ALIGNMENT_CENTER))
		return value
	var number := _make_label(str(stars), 35, HORIZONTAL_ALIGNMENT_RIGHT)
	number.add_theme_color_override("font_color", COLOR_ORANGE)
	value.add_child(number)
	var star := _make_label("★", 49, HORIZONTAL_ALIGNMENT_LEFT)
	star.add_theme_color_override("font_color", Color(1.0, 0.68, 0.08, 1.0))
	value.add_child(star)
	return value


func _player_row_colors() -> Dictionary:
	var accent := _category_icon_box_color(_category_filter)
	if _category_filter == "global":
		return {
			"bg": Color(1.0, 0.86, 0.64, 1.0),
			"border": Color(0.94, 0.45, 0.12, 0.9),
		}
	return {
		"bg": accent.darkened(0.08),
		"border": accent.darkened(0.32),
	}


func _make_row_style(is_player: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if is_player:
		var colors: Dictionary = _player_row_colors()
		style.bg_color = colors.bg
		style.border_color = colors.border
	else:
		style.bg_color = Color(1.0, 0.985, 0.94, 0.1)
		style.border_color = Color(0.72, 0.6, 0.42, 0.18)
	style.border_width_left = 2 if is_player else 0
	style.border_width_top = 2 if is_player else 0
	style.border_width_right = 2 if is_player else 0
	style.border_width_bottom = 2 if is_player else 1
	style.corner_radius_top_left = 24 if is_player else 0
	style.corner_radius_top_right = 24 if is_player else 0
	style.corner_radius_bottom_left = 24 if is_player else 0
	style.corner_radius_bottom_right = 24 if is_player else 0
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style


func _make_value_label(
	value: String,
	width: float,
	color: Color = COLOR_INK
) -> Label:
	var label := _make_label(value, 32, HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size.x = width
	label.add_theme_color_override("font_color", color)
	return label


func _make_label(value: String, size: int, alignment: int) -> Label:
	var label := Label.new()
	label.text = value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", COLOR_INK)
	return label


func _clear_rows(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()


func _show_online_unavailable() -> void:
	online_status.visible = true
	online_status.text = "Clasificación online no disponible"
	for i in TOP_ROWS:
		_add_placeholder_row(online_rows, i + 1)
	_add_placeholder_row(around_rows, 0, "TÚ — sin conexión")
	_loading = false
	_set_filters_disabled(false)


func _format_average(hundredths: int) -> String:
	return ("%.2f" % (float(hundredths) / 100.0)).replace(".", ",")


func _format_rank(value: int) -> String:
	if value < 1000:
		return str(value)
	var source := str(value)
	var chunks: Array[String] = []
	while source.length() > 3:
		chunks.push_front(source.right(3))
		source = source.substr(0, source.length() - 3)
	chunks.push_front(source)
	return ".".join(chunks)


func _on_button_back_pressed() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")
