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
const STAR_TEXTURE: Texture2D = preload("res://images/estrella_plano.png")

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
var _load_token := 0
var _last_top_entries: Array = []
var _last_around_entries: Array = []
var _around_page_start := -1
var _around_can_up := false
var _around_can_down := false
var _around_checked_last := -2
var _around_probe_for := -2
var _around_paging := false
var _around_arrows: Control
var _around_arrow_up: Button
var _around_arrow_down: Button
var _around_arrow_blink: Tween


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
	_create_around_arrows()
	_style_info_button()
	_cache_category_editor_look()
	_apply_locale()
	_update_filter_styles()
	_loading = true
	_show_loading_status()
	_apply_view()
	get_tree().create_timer(0.01).timeout.connect(
		_submit_rankings_in_background,
		CONNECT_ONE_SHOT
	)
	_load_online_ranking()


func _apply_locale() -> void:
	$Header/Title.text = tr("Records")
	_mode_label(%FilterQuick).text = tr("QuickUpper")
	_mode_label(%FilterCryptogram).text = tr("CryptogramUpper")
	%FilterGlobal.get_node("Text").text = tr("Global")
	%FilterQuotes.get_node("Text").text = GameManager.category_display_name(GameManager.CAT_CITA).to_upper()
	%FilterEvents.get_node("Text").text = GameManager.category_display_name(GameManager.CAT_EFEMERIDE).to_upper()
	%FilterCuriosities.get_node("Text").text = GameManager.category_display_name(GameManager.CAT_CURIOSIDADES).to_upper()
	%FilterFragments.get_node("Text").text = GameManager.category_display_name(GameManager.CAT_FRAGMENTO).to_upper()
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
	header.get_node("Average/Text").text = tr("RankStarsPer").replace("★", "").strip_edges()
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
	if value == "around" and _around_page_start >= 0:
		_return_to_centered_around()
		return
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
	_layout_around_arrows()


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


func _submit_rankings_in_background() -> void:
	if typeof(PlayFabTools) == TYPE_NIL:
		return
	await PlayFabTools.submit_competitive_rankings(GameManager.player_name)


func _show_loading_status() -> void:
	online_status.visible = true
	online_status.text = tr("RankLoading")


func _wait_for_playfab_login() -> bool:
	if typeof(PlayFabTools) == TYPE_NIL:
		return false
	if PlayFabTools.is_logged_in():
		return true
	var started := Time.get_ticks_msec()
	while not PlayFabTools.is_logged_in() and Time.get_ticks_msec() - started < 2500:
		await get_tree().create_timer(0.05).timeout
	return PlayFabTools.is_logged_in()


func _load_online_ranking() -> void:
	_load_token += 1
	var token := _load_token
	_around_page_start = -1
	_around_can_up = false
	_around_can_down = false
	_around_checked_last = -2
	_around_probe_for = -2
	_around_paging = false
	_loading = true
	_set_filters_disabled(true)
	if typeof(PlayFabTools) == TYPE_NIL:
		_show_online_unavailable()
		return
	var statistic: String = PlayFabTools.competitive_stat_name(
		_category_filter,
		_mode_filter
	)
	var cached: Dictionary = PlayFabTools.get_cached_leaderboard(statistic)
	if not cached.is_empty():
		_paint_rankings(
			cached.get("top", {"ok": false, "entries": []}),
			cached.get("around", {"ok": false, "entries": []}),
			false
		)
		_finish_loading()
		_note_centered_around(statistic, token)
	else:
		_clear_rows(online_rows)
		_clear_rows(around_rows)
		_show_loading_status()
		_apply_view()

	if not await _wait_for_playfab_login():
		if token != _load_token:
			return
		if cached.is_empty():
			_show_online_unavailable()
		else:
			_finish_loading()
		return
	if token != _load_token:
		return

	var fetched: Dictionary = await _fetch_leaderboards_parallel(statistic)
	if token != _load_token:
		return
	var top_result: Dictionary = fetched.get("top", {"ok": false, "entries": []})
	var around_result: Dictionary = fetched.get("around", {"ok": false, "entries": []})
	if not bool(top_result.get("ok", false)) and not bool(around_result.get("ok", false)):
		if cached.is_empty():
			_show_online_unavailable()
		else:
			_finish_loading()
		return

	PlayFabTools.store_cached_leaderboard(statistic, top_result, around_result)
	_paint_rankings(top_result, around_result, false)
	_finish_loading()
	_note_centered_around(statistic, token)
	await _load_player_languages(_last_top_entries, _last_around_entries)
	if token != _load_token:
		return
	_paint_rankings(top_result, around_result, true)
	_note_centered_around(statistic, token)


func _finish_loading() -> void:
	_loading = false
	online_status.visible = false
	_apply_view()
	_set_filters_disabled(false)


func _paint_rankings(top_result: Dictionary, around_result: Dictionary, keep_view: bool) -> void:
	var top_entries: Array = top_result.get("entries", [])
	var around_entries: Array = around_result.get("entries", [])
	if around_entries.is_empty():
		around_entries = _around_fallback_entries(top_entries)
	_last_top_entries = top_entries
	_last_around_entries = around_entries
	_player_languages = PlayFabTools.cached_player_languages(
		_ranking_ids(top_entries, around_entries)
	)
	_clear_rows(online_rows)
	_clear_rows(around_rows)
	_my_rank = 0
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
	_around_page_start = -1
	_sync_around_arrows(around_entries, false, around_entries.size() < AROUND_ROWS)
	_refresh_my_place_label()
	if not keep_view:
		online_status.visible = false
		_loading = false
		_apply_view()


func _ranking_ids(top_entries: Array, around_entries: Array) -> Array:
	var ids: Array = []
	for entry_value in top_entries:
		if entry_value is Dictionary:
			ids.append(str(entry_value.get("PlayFabId", "")))
	for entry_value in around_entries:
		if entry_value is Dictionary:
			ids.append(str(entry_value.get("PlayFabId", "")))
	if typeof(PlayFabTools) != TYPE_NIL and str(PlayFabTools.playfab_id) != "":
		ids.append(str(PlayFabTools.playfab_id))
	return ids


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


func _fetch_leaderboards_parallel(statistic: String) -> Dictionary:
	var state := {
		"left": 2,
		"top": {"ok": false, "entries": []},
		"around": {"ok": false, "entries": []},
	}
	_start_leaderboard_request(state, "top", "GetLeaderboard", statistic, TOP_ROWS)
	_start_leaderboard_request(
		state,
		"around",
		"GetLeaderboardAroundPlayer",
		statistic,
		AROUND_ROWS
	)
	var started := Time.get_ticks_msec()
	while int(state["left"]) > 0 and Time.get_ticks_msec() - started < 20000:
		await get_tree().process_frame
	return {
		"top": state["top"],
		"around": state["around"],
	}


func _start_leaderboard_request(
	state: Dictionary,
	slot: String,
	endpoint: String,
	statistic: String,
	max_results: int,
	start_position: int = 0
) -> void:
	var request := HTTPRequest.new()
	request.timeout = 12
	add_child(request)
	var body := {
		"StatisticName": statistic,
		"MaxResultsCount": max_results,
	}
	if endpoint == "GetLeaderboard":
		body["StartPosition"] = maxi(0, start_position)
	var err := request.request(
		"https://%s.playfabapi.com/Client/%s" % [PlayFabTools.TITLE_ID, endpoint],
		PackedStringArray([
			"Content-Type: application/json",
			"Accept: application/json",
			"Accept-Encoding: identity",
			"X-Authorization: " + str(PlayFabTools.session_ticket),
			"X-ReportErrorAsSuccess: true",
		]),
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	if err != OK:
		state["left"] = int(state["left"]) - 1
		request.queue_free()
		return
	var on_done := func(_result: int, http_code: int, _headers: PackedStringArray, response_body: PackedByteArray) -> void:
		state[slot] = _parse_leaderboard_response(
			endpoint,
			statistic,
			http_code,
			response_body.get_string_from_utf8()
		)
		state["left"] = int(state["left"]) - 1
		request.queue_free()
	request.request_completed.connect(on_done, CONNECT_ONE_SHOT)


func _parse_leaderboard_response(
	endpoint: String,
	statistic: String,
	http_code: int,
	text: String
) -> Dictionary:
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
	if typeof(PlayFabTools) == TYPE_NIL:
		return
	_player_languages = await PlayFabTools.fetch_player_languages(
		_ranking_ids(top_entries, around_entries)
	)


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
	value.add_child(_make_star_icon(40, GameManager.star_fill_color(_mode_filter)))
	return value


func _make_star_icon(px: float, color: Color) -> TextureRect:
	var star := TextureRect.new()
	star.texture = STAR_TEXTURE
	star.custom_minimum_size = Vector2(px, px)
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.modulate = color
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return star


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
	_around_page_start = -1
	_around_can_up = false
	_around_can_down = false
	_around_checked_last = -2
	_around_probe_for = -2
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


func _return_to_centered_around() -> void:
	_view = "around"
	_update_filter_styles()
	_load_online_ranking()


func _note_centered_around(statistic: String, token: int) -> void:
	if token != _load_token or _around_page_start >= 0:
		return
	if _last_around_entries.size() < AROUND_ROWS or _around_can_down:
		return
	var last := _entry_position(_last_around_entries[_last_around_entries.size() - 1])
	if last == _around_checked_last or last == _around_probe_for:
		return
	_around_probe_for = last
	_probe_more_below(statistic, token, last)


func _probe_more_below(statistic: String, token: int, last: int) -> void:
	var result := await _fetch_leaderboard_range(statistic, last + 1, 1)
	if token != _load_token or _around_page_start >= 0 or _last_around_entries.is_empty():
		return
	if _entry_position(_last_around_entries[_last_around_entries.size() - 1]) != last:
		return
	_around_checked_last = last
	if _around_probe_for == last:
		_around_probe_for = -2
	var found: Array = result.get("entries", [])
	_around_can_down = bool(result.get("ok", false)) and not found.is_empty()


func _sync_around_arrows(entries: Array, has_more_below: bool, below_known: bool) -> void:
	if entries.is_empty():
		_around_can_up = false
		_around_can_down = false
		return
	var first := _entry_position(entries[0])
	var last := _entry_position(entries[entries.size() - 1])
	_around_can_up = first > 0
	if below_known:
		_around_can_down = has_more_below
		_around_checked_last = last
	elif last != _around_checked_last:
		_around_can_down = false


func _entry_position(entry: Variant) -> int:
	if entry is Dictionary:
		return int((entry as Dictionary).get("Position", 0))
	return 0


func _page_around(direction: int) -> void:
	if _loading or _around_paging or _view != "around" or typeof(PlayFabTools) == TYPE_NIL:
		return
	if direction < 0 and not _around_can_up:
		return
	if direction > 0 and not _around_can_down:
		return
	if _last_around_entries.is_empty():
		return
	SoundManager.play("ButtonClick")
	var first := _entry_position(_last_around_entries[0])
	var last := _entry_position(_last_around_entries[_last_around_entries.size() - 1])
	var start := maxi(0, first - AROUND_ROWS) if direction < 0 else last + 1
	_around_paging = true
	_load_token += 1
	var token := _load_token
	var statistic := PlayFabTools.competitive_stat_name(_category_filter, _mode_filter)
	var result := await _fetch_leaderboard_range(statistic, start, AROUND_ROWS + 1)
	if token != _load_token:
		return
	var raw: Array = result.get("entries", [])
	if not bool(result.get("ok", false)) or raw.is_empty():
		if direction > 0:
			_around_can_down = false
			_around_checked_last = last
		else:
			_around_can_up = false
		_around_paging = false
		return
	var has_more := raw.size() > AROUND_ROWS
	var shown: Array = raw.slice(0, AROUND_ROWS)
	_paint_around_page(shown, has_more)
	await _load_player_languages([], shown)
	if token != _load_token:
		return
	_paint_around_page(shown, has_more)
	_around_paging = false


func _paint_around_page(entries: Array, has_more_below: bool) -> void:
	var kept_rank := _my_rank
	_last_around_entries = entries
	_player_languages = PlayFabTools.cached_player_languages(_ranking_ids([], entries)) if typeof(PlayFabTools) != TYPE_NIL else {}
	_clear_rows(around_rows)
	var found_player := false
	for entry_value in entries:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		var is_player := _is_local_player(entry)
		if is_player:
			_my_rank = int(entry.get("Position", -1)) + 1
			found_player = true
		_add_competitive_row(around_rows, entry, is_player, true)
	if not found_player:
		_my_rank = kept_rank
	_around_page_start = _entry_position(entries[0]) if not entries.is_empty() else -1
	_sync_around_arrows(entries, has_more_below, true)
	_refresh_my_place_label()
	_apply_view()


func _fetch_leaderboard_range(statistic: String, start: int, count: int) -> Dictionary:
	var state := {
		"left": 1,
		"page": {"ok": false, "entries": []},
	}
	_start_leaderboard_request(state, "page", "GetLeaderboard", statistic, count, start)
	var started := Time.get_ticks_msec()
	while int(state["left"]) > 0 and Time.get_ticks_msec() - started < 20000:
		await get_tree().process_frame
	return state["page"]


func _create_around_arrows() -> void:
	var host := Control.new()
	host.name = "AroundArrows"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.z_index = 45
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	$MainCard.add_child(host)
	_around_arrows = host
	_around_arrow_up = _make_around_arrow(-1)
	_around_arrow_down = _make_around_arrow(1)
	host.add_child(_around_arrow_up)
	host.add_child(_around_arrow_down)
	_around_arrow_blink = create_tween()
	_around_arrow_blink.set_loops()
	_around_arrow_blink.set_trans(Tween.TRANS_SINE)
	_around_arrow_blink.set_ease(Tween.EASE_IN_OUT)
	_around_arrow_blink.tween_property(host, "modulate", Color(1.12, 1.04, 0.82, 1), 0.42)
	_around_arrow_blink.tween_property(host, "modulate", Color.WHITE, 0.42)
	set_process(true)


func _process(_delta: float) -> void:
	_layout_around_arrows()


func _layout_around_arrows() -> void:
	if _around_arrows == null or _around_arrow_up == null or _around_arrow_down == null:
		return
	var show_list := (
		_view == "around"
		and not _loading
		and not info_overlay.visible
		and around_rows.visible
		and around_rows.get_child_count() > 0
	)
	if not show_list:
		_around_arrow_up.visible = false
		_around_arrow_down.visible = false
		_around_arrows.visible = false
		return
	var rows_rect := around_rows.get_global_rect()
	var origin := rows_rect.position - _around_arrows.get_global_rect().position
	var diameter := 96.0
	var margin := 20.0
	var circle := Vector2(diameter, diameter)
	for button in [_around_arrow_up, _around_arrow_down]:
		button.custom_minimum_size = circle
		button.size = circle
		button.pivot_offset = circle * 0.5
		var arrow := button.get_child(0) as Polygon2D
		if arrow:
			arrow.position = circle * 0.5
			var tip := diameter * 0.19
			var base := diameter * 0.15
			if button == _around_arrow_up:
				arrow.polygon = PackedVector2Array([
					Vector2(0, -tip),
					Vector2(-base, tip * 0.78),
					Vector2(base, tip * 0.78),
				])
			else:
				arrow.polygon = PackedVector2Array([
					Vector2(-base, -tip * 0.78),
					Vector2(base, -tip * 0.78),
					Vector2(0, tip),
				])
	var x := origin.x + rows_rect.size.x - diameter - margin
	_around_arrow_up.position = Vector2(x, origin.y + margin)
	_around_arrow_down.position = Vector2(x, origin.y + rows_rect.size.y - diameter - margin)
	_around_arrow_up.visible = _around_can_up
	_around_arrow_down.visible = _around_can_down
	_around_arrows.visible = _around_arrow_up.visible or _around_arrow_down.visible


func _make_around_arrow(direction: int) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_stylebox_override("normal", _around_arrow_style(false))
	button.add_theme_stylebox_override("hover", _around_arrow_style(true))
	button.add_theme_stylebox_override("pressed", _around_arrow_style(true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func() -> void:
		_page_around(direction)
	)
	var arrow := Polygon2D.new()
	arrow.color = Color(0.42, 0.18, 0.05, 1)
	button.add_child(arrow)
	return button


func _around_arrow_style(hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.968, 0.84, 1) if hovered else Color(0.996, 0.941, 0.776, 0.96)
	style.border_color = Color(0.878, 0.443, 0.102, 1)
	style.set_border_width_all(5)
	style.set_corner_radius_all(96)
	style.shadow_color = Color(0.41, 0.22, 0.05, 0.28)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style


func _on_button_back_pressed() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")
