extends Control

const TOP_ROWS := 5
const COLOR_INK := Color(0.24, 0.14, 0.08, 1.0)
const COLOR_ORANGE := Color(0.96, 0.47, 0.13, 1.0)
const COLOR_CREAM := Color(1.0, 0.97, 0.89, 1.0)

@onready var button_back: Button = %ButtonBack
@onready var online_rows: VBoxContainer = %OnlineRows
@onready var around_rows: VBoxContainer = %AroundRows
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
			categories[i] == _category_filter
		)
	var modes := [GameManager.MODE_QUICK, GameManager.MODE_CRYPTOGRAM]
	for i in mode_buttons.size():
		_apply_mode_style(mode_buttons[i], modes[i] == _mode_filter)


func _apply_category_style(button: Button, selected: bool) -> void:
	var style := _make_button_style(
		Color(1.0, 0.96, 0.87, 0.92),
		COLOR_ORANGE if selected else Color(0.64, 0.48, 0.3, 0.25),
		24,
		3 if selected else 2
	)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_color", COLOR_ORANGE if selected else COLOR_INK)
	button.add_theme_color_override("font_disabled_color", COLOR_ORANGE if selected else COLOR_INK)


func _apply_mode_style(button: Button, selected: bool) -> void:
	var style := _make_button_style(
		Color(1.0, 0.67, 0.3, 1.0) if selected else Color(1.0, 0.96, 0.87, 0.96),
		Color(0.76, 0.36, 0.11, 0.9) if selected else Color(0.64, 0.48, 0.3, 0.3),
		28,
		2
	)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
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
			_add_competitive_row(around_rows, entry, is_player)
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
	is_player: bool
) -> void:
	var decoded: Dictionary = PlayFabTools.decode_competitive_value(
		int(entry.get("StatValue", 0))
	)
	_add_row(
		container,
		int(entry.get("Position", -1)) + 1,
		"TÚ" if is_player else str(entry.get("DisplayName", "Anónimo")),
		int(decoded.get("stars_earned", 0)),
		int(decoded.get("completed", 0)),
		int(decoded.get("stars_per_puzzle_hundredths", 0)),
		int(decoded.get("aids_used", 0)),
		int(decoded.get("failed_letters", 0)),
		is_player
	)


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
	panel.custom_minimum_size = Vector2(0, 106)
	panel.add_theme_stylebox_override("panel", _make_row_style(is_player))
	container.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	panel.add_child(row)

	var rank_label := _make_label(
		"—" if rank <= 0 else _format_rank(rank),
		27,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	rank_label.custom_minimum_size.x = 92
	if rank in [1, 2, 3]:
		rank_label.add_theme_color_override(
			"font_color",
			[Color(0.95, 0.59, 0.13), Color(0.55, 0.55, 0.55), Color(0.68, 0.36, 0.14)][rank - 1]
		)
	row.add_child(rank_label)
	row.add_child(_make_avatar(player_name, rank))

	var name_label := _make_label(player_name, 27, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_player:
		name_label.add_theme_color_override("font_color", COLOR_ORANGE)
	row.add_child(name_label)

	row.add_child(_make_value_label(
		"—" if stars < 0 else "%d ★" % stars,
		142,
		COLOR_ORANGE if stars >= 0 else COLOR_INK
	))
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


func _make_avatar(player_name: String, rank: int) -> PanelContainer:
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(62, 62)
	var style := StyleBoxFlat.new()
	var colors := [
		Color(0.93, 0.48, 0.23),
		Color(0.46, 0.56, 0.79),
		Color(0.3, 0.66, 0.52),
		Color(0.83, 0.57, 0.23),
	]
	style.bg_color = colors[absi(rank) % colors.size()]
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.31, 0.18, 0.08, 0.32)
	style.corner_radius_top_left = 31
	style.corner_radius_top_right = 31
	style.corner_radius_bottom_left = 31
	style.corner_radius_bottom_right = 31
	avatar.add_theme_stylebox_override("panel", style)
	var initial := _make_label(
		player_name.left(1).to_upper() if player_name != "" else "?",
		29,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	avatar.add_child(initial)
	return avatar


func _make_row_style(is_player: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color(1.0, 0.87, 0.67, 0.7)
		if is_player
		else Color(1.0, 0.985, 0.94, 0.16)
	)
	style.border_width_left = 2 if is_player else 0
	style.border_width_top = 2 if is_player else 0
	style.border_width_right = 2 if is_player else 0
	style.border_width_bottom = 2 if is_player else 1
	style.border_color = (
		Color(0.86, 0.42, 0.13, 0.65)
		if is_player
		else Color(0.64, 0.48, 0.3, 0.16)
	)
	style.corner_radius_top_left = 20 if is_player else 0
	style.corner_radius_top_right = 20 if is_player else 0
	style.corner_radius_bottom_left = 20 if is_player else 0
	style.corner_radius_bottom_right = 20 if is_player else 0
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style


func _make_value_label(
	value: String,
	width: float,
	color: Color = COLOR_INK
) -> Label:
	var label := _make_label(value, 25, HORIZONTAL_ALIGNMENT_CENTER)
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
