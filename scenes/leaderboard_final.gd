extends Control

const TOP_ROWS := 10
const AROUND_ROWS := 9
const COLOR_INK := Color(0.24, 0.14, 0.08, 1.0)
const COLOR_ORANGE := Color(0.96, 0.47, 0.13, 1.0)
const COLOR_TAB := Color(1.0, 0.69, 0.22, 1.0)
const COLOR_CREAM := Color(1.0, 0.97, 0.89, 1.0)
const FLAG_TEXTURES := {
	"es": preload("res://GUI/Library/Demo/Demo_CountryFlag/Language_Flag_s_01_Esp.png"),
	"en": preload("res://images/Banderas/usa_rect.svg"),
	"eu": preload("res://images/Banderas/euskara_rect.svg"),
	"de": preload("res://GUI/Library/Demo/Demo_CountryFlag/Language_Flag_s_01_Deu.png"),
	"pt": preload("res://GUI/Library/Demo/Demo_CountryFlag/Language_Flag_s_01_Prt.png"),
	"it": preload("res://GUI/Library/Demo/Demo_CountryFlag/Language_Flag_s_01_Ita.png"),
	"fr": preload("res://GUI/Library/Demo/Demo_CountryFlag/Language_Flag_s_01_Fra.png"),
}
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
@onready var view_buttons: Array[Button] = [
	%FilterAround,
	%FilterTop,
]
@onready var ranking_title: Label = %RankingTitle
@onready var button_info: Button = %ButtonInfo
@onready var button_my_place: Button = %ButtonMyPlace
@onready var info_overlay: Control = %InfoOverlay
@onready var info_rules: RichTextLabel = %Rules
@onready var button_close_info: Button = %ButtonClose
@onready var ellipsis: Label = $MainCard/AroundFrame/TableBody/Ellipsis

var _category_filter := "global"
var _mode_filter := GameManager.MODE_QUICK
var _view := "around"
var _my_rank := 0
var _loading := false
var _player_languages: Dictionary = {}
var _category_editor_modulate: Dictionary = {}
var _category_editor_styles: Dictionary = {}


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
	%FilterAround.pressed.connect(func() -> void: _select_view("around"))
	%FilterTop.pressed.connect(func() -> void: _select_view("top"))
	button_info.pressed.connect(_show_info)
	button_close_info.pressed.connect(_hide_info)
	info_overlay.get_node("Dim").gui_input.connect(_on_info_dim_input)
	button_my_place.pressed.connect(func() -> void: _select_view("around"))
	_style_info_button()
	_cache_category_editor_look()
	_apply_locale()
	_update_filter_styles()
	_loading = true
	_show_loading_status()
	_apply_view()
	_load_online_ranking()


func _apply_locale() -> void:
	$Header/Title.text = tr("Records")
	_mode_label(%FilterQuick).text = tr("QuickUpper")
	_mode_label(%FilterCryptogram).text = tr("CryptogramUpper")
	%FilterGlobal.get_node("Text").text = tr("Global")
	%FilterQuotes.get_node("Text").text = tr("QuotesFilter")
	%FilterEvents.get_node("Text").text = tr("Ephemerides").to_upper()
	%FilterCuriosities.get_node("Text").text = tr("Curiosities").to_upper()
	%FilterFragments.get_node("Text").text = tr("FragmentsFilter")
	ranking_title.text = tr("RankByStars")
	%FilterAround.text = tr("RankNearMe")
	%FilterTop.text = tr("RankTopPlaces")
	info_rules.text = tr("RankRules")
	button_close_info.text = "OK"
	var header := $MainCard/AroundFrame/TableBody/TableHeader
	header.get_node("Position").text = tr("RankPos")
	header.get_node("Language").text = tr("RankLanguage")
	header.get_node("Player").text = tr("RankPlayer")
	header.get_node("Stars").text = tr("RankStars")
	header.get_node("Puzzles").text = tr("RankPuzzles")
	header.get_node("Average").text = tr("RankStarsPer")
	_refresh_my_place_label()


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


func _select_view(value: String) -> void:
	if value == _view:
		return
	_view = value
	_update_filter_styles()
	_apply_view()


func _apply_view() -> void:
	var show_top := _view == "top"
	var ready := not _loading
	online_rows.visible = ready and show_top
	around_rows.visible = ready and not show_top
	if ellipsis:
		ellipsis.visible = false
	if _loading:
		_show_loading_status()


func _show_info() -> void:
	SoundManager.play("ButtonClick")
	info_overlay.visible = true


func _hide_info() -> void:
	info_overlay.visible = false


func _on_info_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hide_info()


func _mode_label(button: Button) -> Label:
	return button.get_node("Center/Content/Text") as Label


func _style_info_button() -> void:
	# Infoed.png ya es el botón. Un StyleBoxFlat detrás asoma como aro
	# blanco/crema en runtime (F5), porque el icono no llena los 72 px.
	var style := StyleBoxEmpty.new()
	button_info.flat = true
	button_info.add_theme_stylebox_override("normal", style)
	button_info.add_theme_stylebox_override("hover", style)
	button_info.add_theme_stylebox_override("pressed", style)
	button_info.add_theme_stylebox_override("disabled", style)
	button_info.add_theme_stylebox_override("focus", style)


func _refresh_my_place_label() -> void:
	if _my_rank > 0:
		button_my_place.text = tr("RankMyPlace") % _my_rank
		button_my_place.visible = true
	else:
		button_my_place.text = tr("RankMyPlace") % "—"
		button_my_place.visible = true


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
	_apply_view_style(%FilterAround, _view == "around")
	_apply_view_style(%FilterTop, _view == "top")
	_apply_around_frame_style()


func _category_icon_box_color(category_id: String) -> Color:
	match category_id:
		GameManager.CAT_CITA:
			return Color("c5d0f8")
		GameManager.CAT_EFEMERIDE:
			return Color("f5d0cc")
		GameManager.CAT_CURIOSIDADES:
			return Color("f6e07a")
		GameManager.CAT_FRAGMENTO:
			return Color("b4e6ea")
		_:
			return Color("d4e0f8")


func _cache_category_editor_look() -> void:
	for button in category_buttons:
		if not _category_editor_modulate.has(button):
			_category_editor_modulate[button] = button.self_modulate
		var base := button.get_theme_stylebox("normal")
		if not _category_editor_styles.has(button) and base is StyleBoxFlat:
			_category_editor_styles[button] = (base as StyleBoxFlat).duplicate()


func _apply_category_style(button: Button, _category_id: String, selected: bool) -> void:
	if _category_editor_modulate.has(button):
		button.self_modulate = _category_editor_modulate[button]
	if _category_editor_styles.has(button):
		var style := (_category_editor_styles[button] as StyleBoxFlat).duplicate() as StyleBoxFlat
		if selected:
			style.border_color = COLOR_ORANGE
			style.set_border_width_all(4)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_stylebox_override("disabled", style)
	var icon := button.get_node_or_null("Icon") as TextureRect
	if icon:
		icon.modulate = Color.WHITE
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
	around_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())


func _apply_mode_style(button: Button, selected: bool) -> void:
	_apply_rounded_tab_style(button, selected, 32)


func _apply_view_style(button: Button, selected: bool) -> void:
	_apply_rounded_tab_style(button, selected, 32)
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(1, 0.984, 0.94, 1)
	pill.border_color = Color(0.82, 0.62, 0.38, 0.55)
	pill.set_border_width_all(3)
	pill.set_corner_radius_all(48)
	pill.content_margin_left = 28
	pill.content_margin_right = 28
	button_my_place.add_theme_stylebox_override("normal", pill)
	button_my_place.add_theme_stylebox_override("hover", pill)
	button_my_place.add_theme_stylebox_override("pressed", pill)
	button_my_place.add_theme_color_override("font_color", COLOR_INK)
	button_my_place.visible = true


func _apply_rounded_tab_style(button: Button, selected: bool, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_TAB if selected else Color(1.0, 0.984, 0.94, 1.0)
	if selected:
		style.set_border_width_all(0)
	else:
		style.border_color = Color(0.82, 0.7, 0.51, 0.42)
		style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	var ink := Color(0.22, 0.13, 0.07, 1) if selected else Color(0.45, 0.32, 0.2, 0.75)
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_disabled_color", ink)
	var label := button.get_node_or_null("Center/Content/Text") as Label
	if label:
		label.add_theme_color_override("font_color", ink)


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
	for button in view_buttons:
		button.disabled = disabled


func _show_loading_status() -> void:
	online_status.visible = true
	online_status.text = tr("RankLoading")


func _load_online_ranking() -> void:
	_loading = true
	_set_filters_disabled(true)
	_clear_rows(online_rows)
	_clear_rows(around_rows)
	_show_loading_status()
	_apply_view()

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
		AROUND_ROWS
	)
	if (
		bool(top_result.get("ok", false))
		and (top_result.get("entries", []) as Array).is_empty()
		and not bool(around_result.get("ok", false))
	):
		await get_tree().create_timer(0.4).timeout
		around_result = await _fetch_leaderboard(
			"GetLeaderboardAroundPlayer",
			statistic,
			AROUND_ROWS
		)
		top_result = await _fetch_leaderboard("GetLeaderboard", statistic, TOP_ROWS)
	if not bool(top_result.get("ok", false)) and not bool(around_result.get("ok", false)):
		_show_online_unavailable()
		return

	var top_entries: Array = top_result.get("entries", [])
	_my_rank = 0
	var around_entries: Array = around_result.get("entries", [])
	if around_entries.is_empty():
		around_entries = _around_fallback_entries(top_entries)
	await _load_player_languages(top_entries, around_entries)
	for i in mini(TOP_ROWS, top_entries.size()):
		var top_entry: Dictionary = top_entries[i]
		_add_competitive_row(online_rows, top_entry, _is_local_player(top_entry))
	for i in range(mini(TOP_ROWS, top_entries.size()), TOP_ROWS):
		_add_placeholder_row(online_rows, i + 1)
	if around_entries.is_empty():
		_add_local_player_row(around_rows)
	else:
		for entry_value in around_entries:
			var entry: Dictionary = entry_value
			var is_player := _is_local_player(entry)
			if is_player:
				_my_rank = int(entry.get("Position", -1)) + 1
			_add_competitive_row(around_rows, entry, is_player, true)
		if _my_rank <= 0:
			_add_local_player_row(around_rows)
	_refresh_my_place_label()
	_loading = false
	online_status.visible = false
	_apply_view()
	_set_filters_disabled(false)


func _is_local_player(entry: Dictionary) -> bool:
	if typeof(PlayFabTools) == TYPE_NIL:
		return false
	return str(entry.get("PlayFabId", "")) == str(PlayFabTools.playfab_id)


func _around_fallback_entries(top_entries: Array) -> Array:
	if top_entries.is_empty():
		return []
	for entry_value in top_entries:
		if _is_local_player(entry_value):
			return top_entries
	return top_entries


func _add_local_player_row(container: VBoxContainer) -> void:
	if typeof(HistoryManager) == TYPE_NIL:
		_add_placeholder_row(container, 0, tr("RankYouNoPos"))
		return
	var record: Dictionary = HistoryManager.get_competitive_record(
		_category_filter,
		_mode_filter
	)
	var stars := int(record.get("stars_earned", 0))
	var puzzles := int(record.get("completed", 0))
	if stars <= 0 and puzzles <= 0:
		_add_placeholder_row(container, 0, tr("RankYouNoPos"))
		return
	var hundredths := 0
	if puzzles > 0:
		hundredths = int(round(float(stars) * 100.0 / float(puzzles)))
	var local_name := str(GameManager.player_name).strip_edges()
	var name := local_name if local_name != "" else tr("RankYou")
	_add_row(
		container,
		_my_rank,
		"%s %s" % [name, tr("RankYouTag")],
		stars,
		puzzles,
		hundredths,
		int(record.get("aids_used", 0)),
		int(record.get("failed_letters", 0)),
		true,
		_language_for_id(str(PlayFabTools.playfab_id) if typeof(PlayFabTools) != TYPE_NIL else "")
	)


func _fetch_leaderboard(
	endpoint: String,
	statistic: String,
	max_results: int
) -> Dictionary:
	var with_profile := await _fetch_leaderboard_request(
		endpoint,
		statistic,
		max_results,
		true
	)
	if bool(with_profile.get("ok", false)):
		return with_profile
	return await _fetch_leaderboard_request(endpoint, statistic, max_results, false)


func _fetch_leaderboard_request(
	endpoint: String,
	statistic: String,
	max_results: int,
	include_profile: bool
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
	if include_profile:
		body["ProfileConstraints"] = {
			"ShowDisplayName": true,
			"ShowAvatarUrl": true,
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
		push_warning(
			"PlayFab %s (%s) falló: %s" % [
				endpoint,
				statistic,
				str(json.get("errorMessage", json.get("error", http_code))),
			]
		)
		return {"ok": false, "entries": []}
	var data: Variant = json.get("data", {})
	var entries_value: Variant = data.get("Leaderboard", []) if data is Dictionary else []
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
		is_player,
		_row_language(entry, is_player)
	)


func _row_display_name(
	entry: Dictionary,
	is_player: bool,
	_around_player: bool
) -> String:
	if is_player:
		var local_name := str(GameManager.player_name).strip_edges()
		var base := local_name if local_name != "" else tr("RankYou")
		return "%s %s" % [base, tr("RankYouTag")]
	var remote_name := str(entry.get("DisplayName", "")).strip_edges()
	return remote_name if remote_name != "" else "-"


func _add_placeholder_row(
	container: VBoxContainer,
	rank: int,
	name: String = "—"
) -> void:
	_add_row(container, rank, name, -1, -1, -1, -1, -1, false, "")


func _load_player_languages(top_entries: Array, around_entries: Array) -> void:
	_player_languages = {}
	if typeof(PlayFabTools) == TYPE_NIL:
		return
	var ids: Array = []
	for entry_value in top_entries:
		if entry_value is Dictionary:
			ids.append(str(entry_value.get("PlayFabId", "")))
	for entry_value in around_entries:
		if entry_value is Dictionary:
			ids.append(str(entry_value.get("PlayFabId", "")))
	if str(PlayFabTools.playfab_id) != "":
		ids.append(str(PlayFabTools.playfab_id))
	_player_languages = await PlayFabTools.fetch_player_languages(ids)


func _language_for_id(playfab_id: String) -> String:
	return str(_player_languages.get(playfab_id, ""))


func _row_language(entry: Dictionary, _is_player: bool) -> String:
	return _language_for_id(str(entry.get("PlayFabId", "")))


func _add_row(
	container: VBoxContainer,
	rank: int,
	player_name: String,
	stars: int,
	puzzles: int,
	average_hundredths: int,
	_aids: int,
	_failed_letters: int,
	is_player: bool,
	language: String = ""
) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 124)
	panel.add_theme_stylebox_override("panel", _make_row_style(is_player))
	container.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	if rank >= 1 and rank <= 3:
		row.add_child(_make_medal(rank))
	else:
		var rank_label := _make_label(
			"—" if rank <= 0 else _format_rank(rank),
			40,
			HORIZONTAL_ALIGNMENT_CENTER
		)
		rank_label.custom_minimum_size.x = 100
		row.add_child(rank_label)

	row.add_child(_make_flag(language))

	var name_label := _make_label(player_name, 40, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	row.add_child(_make_stars_value(stars))
	row.add_child(_make_value_label("—" if puzzles < 0 else str(puzzles), 130))
	row.add_child(_make_value_label(
		"—" if average_hundredths < 0 else _format_average(average_hundredths),
		168
	))


func _make_medal(rank: int) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(100, 118)
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
	number.add_theme_font_size_override("font_size", 42)
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
	value.custom_minimum_size.x = 168
	value.alignment = BoxContainer.ALIGNMENT_CENTER
	value.add_theme_constant_override("separation", 5)
	if stars < 0:
		value.add_child(_make_label("—", 40, HORIZONTAL_ALIGNMENT_CENTER))
		return value
	var number := _make_label(str(stars), 42, HORIZONTAL_ALIGNMENT_RIGHT)
	number.add_theme_color_override("font_color", COLOR_ORANGE)
	value.add_child(number)
	var star := _make_label("★", 56, HORIZONTAL_ALIGNMENT_LEFT)
	star.add_theme_color_override("font_color", GameManager.star_fill_color(_mode_filter))
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


func _make_flag(language: String) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(128, 64)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var code := language.strip_edges().to_lower()
	if not FLAG_TEXTURES.has(code):
		var empty := _make_label("-", 40, HORIZONTAL_ALIGNMENT_CENTER)
		empty.set_anchors_preset(Control.PRESET_FULL_RECT)
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(empty)
		return wrap
	var flag := TextureRect.new()
	flag.set_anchors_preset(Control.PRESET_CENTER)
	flag.offset_left = -40
	flag.offset_top = -26
	flag.offset_right = 40
	flag.offset_bottom = 26
	flag.texture = FLAG_TEXTURES[code]
	flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(flag)
	return wrap


func _make_row_style(is_player: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if is_player:
		style.bg_color = Color(1.0, 0.90, 0.72, 1.0)
		style.border_color = Color(0.96, 0.62, 0.22, 0.95)
		style.set_border_width_all(3)
		style.set_corner_radius_all(22)
	else:
		style.bg_color = Color(1, 1, 1, 0)
		style.set_border_width_all(0)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _make_value_label(
	value: String,
	width: float,
	color: Color = COLOR_INK
) -> Label:
	var label := _make_label(value, 40, HORIZONTAL_ALIGNMENT_CENTER)
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
	online_status.text = tr("RankUnavailable")
	for i in TOP_ROWS:
		_add_placeholder_row(online_rows, i + 1)
	_add_placeholder_row(around_rows, 0, tr("RankYouOffline"))
	_my_rank = 0
	_refresh_my_place_label()
	_loading = false
	_apply_view()
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
