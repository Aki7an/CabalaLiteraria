extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const MODE_LOCAL := "local"
const MODE_ONLINE := "online"
const MAX_ROWS := 10

const COLOR_INK := Color(0.325, 0.2, 0.125, 1)
const COLOR_MUTED := Color(0.45, 0.32, 0.22, 0.78)
const COLOR_CREAM := Color(0.992, 0.965, 0.914, 1)
const COLOR_CARD := Color(1, 0.984, 0.953, 0.98)
const COLOR_TEAL := Color(0.165, 0.655, 0.647, 1)
const COLOR_SCORE := Color(0.08, 0.55, 0.55, 1)
const COLOR_GOLD := Color(0.98, 0.86, 0.42, 1)
const COLOR_SILVER := Color(0.72, 0.86, 0.95, 1)
const COLOR_BRONZE := Color(0.98, 0.72, 0.55, 1)

const TEX_CITAS := preload("res://images/Citas.png")
const TEX_EFEM := preload("res://images/Efemerides.png")
const TEX_CURIO := preload("res://images/Adivinanza.png")
const TEX_FRAG := preload("res://images/FragmentosLiterarios.png")
const TEX_COIN := preload("res://images/Coin.png")
const TEX_PIN := preload("res://GUI/Library/Demo/Demo_ItemIcon_(OriginalSize)/itemicon_map_pin.png")
const FONT_TITLE := preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_BODY := preload("res://fonts/Fonts/Montserrat/static/Montserrat-SemiBold.ttf")
const FONT_REGULAR := preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")

const LOCALIZED := {
	"es": {
		"title": "Clasificación",
		"local": "Local",
		"online": "Online",
		"easy": "Fácil",
		"normal": "Normal",
		"hard": "Difícil",
		"pro": "Pro",
		"top10": "Top 10",
		"my_position": "Mi posición",
		"empty": "Aún no hay puntuaciones",
		"loading": "Cargando…",
		"online_error": "No se pudo cargar el ranking online",
	},
	"en": {
		"title": "Leaderboard",
		"local": "Local",
		"online": "Online",
		"easy": "Easy",
		"normal": "Normal",
		"hard": "Hard",
		"pro": "Pro",
		"top10": "Top 10",
		"my_position": "My position",
		"empty": "No scores yet",
		"loading": "Loading…",
		"online_error": "Could not load online ranking",
	},
	"eu": {
		"title": "Sailkapena",
		"local": "Lokala",
		"online": "Online",
		"easy": "Erraza",
		"normal": "Normala",
		"hard": "Zaila",
		"pro": "Pro",
		"top10": "Top 10",
		"my_position": "Nire posizioa",
		"empty": "Oraindik ez dago puntuaziorik",
		"loading": "Kargatzen…",
		"online_error": "Ezin izan da online sailkapena kargatu",
	},
}

var _mode := MODE_LOCAL
var _difficulty := 1
var _entries: Array[Dictionary] = []
var _player_rank := -1
var _loading := false

var _tab_local: Button
var _tab_online: Button
var _diff_buttons: Dictionary = {}
var _podium_slots: Array[Dictionary] = []
var _list: VBoxContainer
var _status_label: Label
var _title_label: Label
var _top_label: Label
var _my_pos_button: Button
var _my_pos_label: Label
var _http: HTTPRequest
var _row_nodes: Array[Control] = []
var _load_token := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_http = HTTPRequest.new()
	_http.timeout = 30
	add_child(_http)
	var last_diff := int(GameManager.dificultad_ultima_partida)
	if last_diff >= 1 and last_diff <= 4:
		_difficulty = last_diff
	_build_ui()
	_apply_localized()
	_update_mode_tabs()
	_update_diff_tabs()
	_refresh()
	_play_intro_motion()


func _copy(key: String) -> String:
	var locale := GameManager.locale_code()
	var pack: Dictionary = LOCALIZED.get(locale, LOCALIZED["es"])
	if not pack.has(key):
		pack = LOCALIZED["en"] if LOCALIZED["en"].has(key) else LOCALIZED["es"]
	return str(pack.get(key, key))


func _apply_localized() -> void:
	_title_label.text = _copy("title")
	_tab_local.text = _copy("local")
	_tab_online.text = _copy("online")
	_diff_buttons[1].text = _copy("easy")
	_diff_buttons[2].text = _copy("normal")
	_diff_buttons[3].text = _copy("hard")
	_diff_buttons[4].text = _copy("pro")
	_top_label.text = _copy("top10")
	_my_pos_label.text = _copy("my_position")


func _on_button_back_pressed() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SoundManager.play("ButtonClick")
	get_tree().change_scene_to_file(PATH_MAIN)


func _on_mode_local() -> void:
	_mode = MODE_LOCAL
	_loading = false
	_http.cancel_request()
	SoundManager.play("ButtonClick")
	_update_mode_tabs()
	_refresh()


func _on_mode_online() -> void:
	_mode = MODE_ONLINE
	_loading = false
	_http.cancel_request()
	SoundManager.play("ButtonClick")
	_update_mode_tabs()
	_refresh()


func _on_diff(diff: int) -> void:
	_difficulty = diff
	_loading = false
	_http.cancel_request()
	SoundManager.play("ButtonClick")
	_update_diff_tabs()
	_refresh()


func _on_my_position() -> void:
	SoundManager.play("ButtonClick")
	if _player_rank <= 0:
		return
	if _player_rank <= 3:
		_highlight_podium(_player_rank - 1)
		return
	var list_index := _player_rank - 4
	if list_index < 0 or list_index >= _row_nodes.size():
		return
	var row := _row_nodes[list_index]
	var scroll := get_node_or_null("Panel/Scroll") as ScrollContainer
	if scroll:
		scroll.ensure_control_visible(row)
	_pulse_row(row)


func _refresh() -> void:
	_status_label.visible = true
	_status_label.text = _copy("loading")
	if _mode == MODE_LOCAL:
		_load_local()
	else:
		_load_online()


func _load_local() -> void:
	var raw: Array = HistoryManager.get_results_filtered("Todas", _difficulty)
	_entries = _dedupe_best_by_player(raw)
	_player_rank = _find_player_rank()
	_status_label.visible = _entries.is_empty()
	_status_label.text = _copy("empty")
	_render()


func _load_online() -> void:
	_load_token += 1
	var token := _load_token
	_loading = true
	_entries.clear()
	_player_rank = -1
	_status_label.visible = true
	_status_label.text = _copy("loading")
	_render()
	if typeof(PlayFabTools) != TYPE_NIL and not PlayFabTools.is_logged_in():
		var custom_id: String = PlayFabTools._get_device_custom_id()
		var ok: bool = await PlayFabTools.login_with_custom_id(custom_id, true)
		if token != _load_token:
			return
		if not ok:
			_loading = false
			_status_label.visible = true
			_status_label.text = _copy("online_error")
			return
	var ticket := ""
	var title_id := ""
	if typeof(PlayFabTools) != TYPE_NIL:
		ticket = str(PlayFabTools.session_ticket)
		title_id = str(PlayFabTools.TITLE_ID)
	if ticket == "" or title_id == "":
		_loading = false
		_status_label.visible = true
		_status_label.text = _copy("online_error")
		return
	var stat := _stat_name_for_diff(_difficulty)
	var ok_lb := await _fetch_playfab(stat, ticket, title_id)
	if token != _load_token:
		return
	_loading = false
	if not ok_lb:
		_status_label.visible = true
		_status_label.text = _copy("online_error")
		_render()
		return
	_player_rank = _find_player_rank()
	_status_label.visible = _entries.is_empty()
	_status_label.text = _copy("empty")
	_render()


func _stat_name_for_diff(diff: int) -> String:
	match diff:
		1:
			return "Score_Facil"
		2:
			return "Score_Normal"
		3, 4:
			return "Score_Dificil"
		_:
			return "Score_Facil"


func _fetch_playfab(stat_name: String, ticket: String, title_id: String) -> bool:
	var url := "https://%s.playfabapi.com/Client/GetLeaderboard" % title_id
	var body := {
		"StatisticName": stat_name,
		"StartPosition": 0,
		"MaxResultsCount": MAX_ROWS,
	}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Accept-Encoding: identity",
		"X-Authorization: " + ticket,
		"X-ReportErrorAsSuccess: true",
	])
	_http.cancel_request()
	var err := _http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		push_warning("Leaderboard request failed to start: %s" % err)
		return false
	var r: Array = await _http.request_completed
	var response_code: int = int(r[1])
	var text: String = (r[3] as PackedByteArray).get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("Leaderboard bad JSON (%s): %s" % [response_code, text.left(240)])
		return false
	var json: Dictionary = parsed
	var code := int(json.get("code", response_code))
	if code != 200:
		push_warning("Leaderboard API error %s: %s" % [code, str(json.get("errorMessage", text.left(240)))])
		return false
	var data: Dictionary = json.get("data", {})
	var entries: Array = data.get("Leaderboard", [])
	_entries.clear()
	for item in entries:
		if not (item is Dictionary):
			continue
		var entry: Dictionary = item
		var raw_score := int(entry.get("StatValue", 0))
		var category := _category_from_encoded_score(raw_score)
		_entries.append({
			"name": str(entry.get("DisplayName", "Anon")),
			"score": int(raw_score / 10),
			"category": category,
			"playfab_id": str(entry.get("PlayFabId", "")),
		})
	return true


func _category_from_encoded_score(raw_score: int) -> String:
	match int(raw_score % 10):
		1:
			return GameManager.CAT_FRAGMENTO
		2:
			return GameManager.CAT_EFEMERIDE
		3:
			return GameManager.CAT_CURIOSIDADES
		4:
			return GameManager.CAT_CITA
		_:
			return ""


func _dedupe_best_by_player(raw: Array) -> Array[Dictionary]:
	var best: Dictionary = {}
	for item in raw:
		if not (item is Dictionary):
			continue
		var e: Dictionary = item
		var name := str(e.get("jugador_nombre", "-")).strip_edges()
		if name == "":
			name = "-"
		var score := int(e.get("score", 0))
		if best.has(name) and int(best[name].get("score", 0)) >= score:
			continue
		best[name] = {
			"name": name,
			"score": score,
			"category": GameManager.normalize_category(str(e.get("categoria", ""))),
		}
	var out: Array[Dictionary] = []
	for key in best.keys():
		out.append(best[key])
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	if out.size() > MAX_ROWS:
		out = out.slice(0, MAX_ROWS)
	return out


func _find_player_rank() -> int:
	var me := str(GameManager.player_name).strip_edges()
	if me == "" or me == "BAD" or me == "---":
		return -1
	for i in range(_entries.size()):
		if str(_entries[i].get("name", "")).strip_edges().to_lower() == me.to_lower():
			return i + 1
	return -1


func _render() -> void:
	for i in range(3):
		_fill_podium_slot(i, _entries[i] if i < _entries.size() else {})
	for child in _list.get_children():
		child.queue_free()
	_row_nodes.clear()
	for i in range(3, mini(_entries.size(), MAX_ROWS)):
		var row := _make_list_row(i + 1, _entries[i], i % 2 == 1)
		_list.add_child(row)
		_row_nodes.append(row)
	_my_pos_button.disabled = _player_rank <= 0


func _fill_podium_slot(index: int, entry: Dictionary) -> void:
	var slot: Dictionary = _podium_slots[index]
	var has := not entry.is_empty()
	slot["name"].text = str(entry.get("name", "—")) if has else "—"
	slot["score"].text = GameManager.formatear_numero(int(entry.get("score", 0))) if has else "—"
	slot["name"].modulate.a = 1.0 if has else 0.45
	slot["score"].modulate.a = 1.0 if has else 0.45


func _make_list_row(rank: int, entry: Dictionary, alt: bool) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 78)
	row.add_theme_stylebox_override("panel", _row_style(alt, rank == _player_rank))
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	row.add_child(box)

	var rank_l := Label.new()
	rank_l.custom_minimum_size = Vector2(48, 0)
	rank_l.text = str(rank)
	rank_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_l.add_theme_font_override("font", FONT_TITLE)
	rank_l.add_theme_font_size_override("font_size", 30)
	rank_l.add_theme_color_override("font_color", COLOR_INK)
	box.add_child(rank_l)

	var name_l := Label.new()
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.text = str(entry.get("name", "—"))
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_l.add_theme_font_override("font", FONT_BODY)
	name_l.add_theme_font_size_override("font_size", 28)
	name_l.add_theme_color_override("font_color", COLOR_INK)
	box.add_child(name_l)

	var cat_wrap := HBoxContainer.new()
	cat_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_wrap.size_flags_stretch_ratio = 1.35
	cat_wrap.add_theme_constant_override("separation", 8)
	box.add_child(cat_wrap)

	var category := str(entry.get("category", ""))
	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(42, 42)
	icon_wrap.add_theme_stylebox_override("panel", _flat(_category_tint(category), 12))
	cat_wrap.add_child(icon_wrap)
	var icon := TextureRect.new()
	icon.texture = _category_icon(category)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(28, 28)
	icon_wrap.add_child(icon)

	var cat_l := Label.new()
	cat_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cat_l.text = GameManager.category_display_name(category) if category != "" else "—"
	cat_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cat_l.clip_text = true
	cat_l.add_theme_font_override("font", FONT_REGULAR)
	cat_l.add_theme_font_size_override("font_size", 22)
	cat_l.add_theme_color_override("font_color", COLOR_MUTED)
	cat_wrap.add_child(cat_l)

	var score_l := Label.new()
	score_l.custom_minimum_size = Vector2(150, 0)
	score_l.text = GameManager.formatear_numero(int(entry.get("score", 0)))
	score_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_l.add_theme_font_override("font", FONT_TITLE)
	score_l.add_theme_font_size_override("font_size", 28)
	score_l.add_theme_color_override("font_color", COLOR_SCORE)
	box.add_child(score_l)
	return row


func _category_icon(category: String) -> Texture2D:
	match GameManager.normalize_category(category):
		GameManager.CAT_CITA:
			return TEX_CITAS
		GameManager.CAT_EFEMERIDE:
			return TEX_EFEM
		GameManager.CAT_CURIOSIDADES:
			return TEX_CURIO
		GameManager.CAT_FRAGMENTO:
			return TEX_FRAG
		_:
			return TEX_EFEM


func _category_tint(category: String) -> Color:
	var base := GameManager.category_color(category) if category != "" else COLOR_TEAL
	return base.lightened(0.45)


func _update_mode_tabs() -> void:
	_style_pill(_tab_local, _mode == MODE_LOCAL)
	_style_pill(_tab_online, _mode == MODE_ONLINE)


func _update_diff_tabs() -> void:
	for diff in _diff_buttons.keys():
		_style_seg(_diff_buttons[diff], int(diff) == _difficulty)


func _style_pill(button: Button, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(28)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	if active:
		style.bg_color = COLOR_TEAL
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
	else:
		style.bg_color = Color(0.98, 0.94, 0.88, 1)
		style.set_border_width_all(2)
		style.border_color = Color(0.78, 0.66, 0.48, 0.55)
		button.add_theme_color_override("font_color", COLOR_INK)
		button.add_theme_color_override("font_hover_color", COLOR_INK)
		button.add_theme_color_override("font_pressed_color", COLOR_INK)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)


func _style_seg(button: Button, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(18)
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	if active:
		style.bg_color = COLOR_TEAL
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
	else:
		style.bg_color = Color(0, 0, 0, 0)
		button.add_theme_color_override("font_color", COLOR_INK)
		button.add_theme_color_override("font_hover_color", COLOR_INK)
		button.add_theme_color_override("font_pressed_color", COLOR_INK)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)


func _row_style(alt: bool, highlight: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(18)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	if highlight:
		style.bg_color = Color(0.92, 0.97, 0.94, 1)
		style.set_border_width_all(3)
		style.border_color = COLOR_TEAL
	elif alt:
		style.bg_color = Color(0.97, 0.93, 0.87, 1)
	else:
		style.bg_color = Color(1, 0.98, 0.94, 1)
	return style


func _highlight_podium(index: int) -> void:
	if index < 0 or index >= _podium_slots.size():
		return
	var block: Control = _podium_slots[index]["block"]
	var tween := create_tween()
	tween.tween_property(block, "scale", Vector2(1.06, 1.06), 0.12)
	tween.tween_property(block, "scale", Vector2.ONE, 0.18)


func _pulse_row(row: Control) -> void:
	var tween := create_tween()
	tween.tween_property(row, "modulate", Color(1.1, 1.05, 0.9, 1), 0.12)
	tween.tween_property(row, "modulate", Color.WHITE, 0.2)


func _play_intro_motion() -> void:
	var content := get_node_or_null("Panel/Scroll/Content") as Control
	var filters := get_node_or_null("Panel/Filters") as Control
	for node in [filters, content]:
		if node == null:
			continue
		node.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	if filters:
		tween.tween_property(filters, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if content:
		tween.tween_property(content, "modulate:a", 1.0, 0.45).set_delay(0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var podium := get_node_or_null("Panel/Scroll/Content") as Control
	if podium:
		for slot in _podium_slots:
			var block: Control = slot.get("block")
			if block == null:
				continue
			block.scale = Vector2(0.92, 0.92)
			tween.tween_property(block, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _flat(COLOR_CREAM, 0))
	add_child(panel)

	var fondo := preload("res://scenes/fondo.tscn").instantiate()
	fondo.name = "Fondo"
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fondo)

	panel.add_child(_build_header())
	panel.add_child(_build_filters())

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 36
	scroll.offset_top = 470
	scroll.offset_right = -36
	scroll.offset_bottom = -150
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	panel.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	scroll.add_child(content)

	content.add_child(_build_podium())
	content.add_child(_build_top_header())
	content.add_child(_build_list_card())
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_override("font", FONT_REGULAR)
	_status_label.add_theme_font_size_override("font_size", 26)
	_status_label.add_theme_color_override("font_color", COLOR_MUTED)
	content.add_child(_status_label)

	panel.add_child(_build_footer())
	# Width sync once after layout — avoid resized↔minimum_size feedback loops.
	call_deferred("_sync_content_width")
	get_tree().create_timer(0.05).timeout.connect(_sync_content_width)


func _sync_content_width() -> void:
	var scroll := get_node_or_null("Panel/Scroll") as ScrollContainer
	var content := get_node_or_null("Panel/Scroll/Content") as Control
	if scroll == null or content == null:
		return
	var target := maxf(scroll.size.x, 1.0)
	if not is_equal_approx(content.custom_minimum_size.x, target):
		content.custom_minimum_size.x = target


func _build_header() -> Control:
	var header := Control.new()
	header.name = "Header"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 230
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var back := Button.new()
	back.position = Vector2(36, 48)
	back.custom_minimum_size = Vector2(96, 96)
	back.focus_mode = Control.FOCUS_NONE
	var back_style := _flat(Color(0.455, 0.275, 0.137, 1), 28)
	back_style.set_border_width_all(6)
	back_style.border_color = Color(0.627, 0.42, 0.224, 1)
	back_style.shadow_color = Color(0.23, 0.13, 0.07, 0.28)
	back_style.shadow_size = 8
	back_style.shadow_offset = Vector2(0, 6)
	for state in ["normal", "hover", "pressed"]:
		back.add_theme_stylebox_override(state, back_style)
	back.pressed.connect(_on_button_back_pressed)
	header.add_child(back)

	var arrow := Control.new()
	arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arrow.offset_left = 18
	arrow.offset_top = 18
	arrow.offset_right = -18
	arrow.offset_bottom = -18
	arrow.set_script(load("res://scenes/editable_back_arrow.gd"))
	back.add_child(arrow)

	var brand := HBoxContainer.new()
	brand.set_anchors_preset(Control.PRESET_TOP_WIDE)
	brand.offset_top = 40
	brand.offset_bottom = 110
	brand.alignment = BoxContainer.ALIGNMENT_CENTER
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(brand)

	var cifra := Label.new()
	cifra.text = "Cifra"
	cifra.add_theme_font_override("font", FONT_TITLE)
	cifra.add_theme_font_size_override("font_size", 52)
	cifra.add_theme_color_override("font_color", COLOR_INK)
	brand.add_child(cifra)
	var letra := Label.new()
	letra.text = "Letra"
	letra.add_theme_font_override("font", FONT_TITLE)
	letra.add_theme_font_size_override("font_size", 52)
	letra.add_theme_color_override("font_color", COLOR_TEAL)
	brand.add_child(letra)

	_title_label = Label.new()
	_title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title_label.offset_top = 120
	_title_label.offset_bottom = 190
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", FONT_TITLE)
	_title_label.add_theme_font_size_override("font_size", 56)
	_title_label.add_theme_color_override("font_color", COLOR_INK)
	header.add_child(_title_label)
	return header


func _build_filters() -> Control:
	var filters := VBoxContainer.new()
	filters.name = "Filters"
	filters.set_anchors_preset(Control.PRESET_TOP_WIDE)
	filters.offset_left = 36
	filters.offset_right = -36
	filters.offset_top = 220
	filters.offset_bottom = 450
	filters.add_theme_constant_override("separation", 16)
	filters.add_child(_build_mode_tabs())
	filters.add_child(_build_diff_tabs())
	return filters


func _build_mode_tabs() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_tab_local = Button.new()
	_tab_local.focus_mode = Control.FOCUS_NONE
	_tab_local.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_local.custom_minimum_size = Vector2(0, 78)
	_tab_local.add_theme_font_override("font", FONT_BODY)
	_tab_local.add_theme_font_size_override("font_size", 30)
	_tab_local.pressed.connect(_on_mode_local)
	row.add_child(_tab_local)
	_tab_online = Button.new()
	_tab_online.focus_mode = Control.FOCUS_NONE
	_tab_online.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_online.custom_minimum_size = Vector2(0, 78)
	_tab_online.add_theme_font_override("font", FONT_BODY)
	_tab_online.add_theme_font_size_override("font_size", 30)
	_tab_online.pressed.connect(_on_mode_online)
	row.add_child(_tab_online)
	return row


func _build_diff_tabs() -> PanelContainer:
	var card := PanelContainer.new()
	var shell := _soft_card(COLOR_CARD, 28)
	shell.content_margin_left = 8
	shell.content_margin_right = 8
	shell.content_margin_top = 8
	shell.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", shell)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	for pair in [[1, "easy"], [2, "normal"], [3, "hard"], [4, "pro"]]:
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 64)
		btn.add_theme_font_override("font", FONT_BODY)
		btn.add_theme_font_size_override("font_size", 24)
		var diff := int(pair[0])
		btn.pressed.connect(func() -> void: _on_diff(diff))
		row.add_child(btn)
		_diff_buttons[diff] = btn
	return card


func _build_podium() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _soft_card(COLOR_CARD, 34))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	card.add_child(row)

	# Visual order: 2, 1, 3
	var order := [1, 0, 2]
	var heights := [230.0, 180.0, 150.0]
	var colors := [COLOR_GOLD, COLOR_SILVER, COLOR_BRONZE]
	_podium_slots.resize(3)
	for visual_i in range(3):
		var rank_index := int(order[visual_i])
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_END
		col.add_theme_constant_override("separation", 8)
		row.add_child(col)

		var medal := Control.new()
		medal.custom_minimum_size = Vector2(96, 96)
		medal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(medal)
		var coin := TextureRect.new()
		coin.texture = TEX_COIN
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		coin.modulate = colors[rank_index]
		medal.add_child(coin)
		var medal_l := Label.new()
		medal_l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		medal_l.text = str(rank_index + 1)
		medal_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		medal_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		medal_l.add_theme_font_override("font", FONT_TITLE)
		medal_l.add_theme_font_size_override("font_size", 34)
		medal_l.add_theme_color_override("font_color", Color.WHITE)
		medal.add_child(medal_l)

		var name_l := Label.new()
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.add_theme_font_override("font", FONT_BODY)
		name_l.add_theme_font_size_override("font_size", 28)
		name_l.add_theme_color_override("font_color", COLOR_INK)
		col.add_child(name_l)

		var score_l := Label.new()
		score_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_l.add_theme_font_override("font", FONT_TITLE)
		score_l.add_theme_font_size_override("font_size", 30)
		score_l.add_theme_color_override("font_color", COLOR_SCORE)
		col.add_child(score_l)

		var block := Panel.new()
		block.custom_minimum_size = Vector2(0, heights[rank_index])
		block.pivot_offset = Vector2(80, heights[rank_index])
		block.add_theme_stylebox_override("panel", _flat(colors[rank_index], 22))
		col.add_child(block)

		_podium_slots[rank_index] = {
			"name": name_l,
			"score": score_l,
			"block": block,
		}
	return card


func _build_top_header() -> Control:
	var wrap := HBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_theme_constant_override("separation", 16)
	var left := ColorRect.new()
	left.custom_minimum_size = Vector2(120, 3)
	left.color = Color(0.7, 0.55, 0.4, 0.55)
	wrap.add_child(left)
	_top_label = Label.new()
	_top_label.add_theme_font_override("font", FONT_TITLE)
	_top_label.add_theme_font_size_override("font_size", 30)
	_top_label.add_theme_color_override("font_color", COLOR_INK)
	wrap.add_child(_top_label)
	var right := ColorRect.new()
	right.custom_minimum_size = Vector2(120, 3)
	right.color = Color(0.7, 0.55, 0.4, 0.55)
	wrap.add_child(right)
	return wrap


func _build_list_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _soft_card(COLOR_CARD, 28))
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	card.add_child(_list)
	return card


func _build_footer() -> Control:
	var footer := Control.new()
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -140
	footer.offset_bottom = -30

	_my_pos_button = Button.new()
	_my_pos_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_my_pos_button.offset_left = 48
	_my_pos_button.offset_right = -48
	_my_pos_button.focus_mode = Control.FOCUS_NONE
	var style := _soft_card(Color(1, 0.97, 0.9, 1), 34)
	style.set_border_width_all(4)
	style.border_color = COLOR_TEAL
	for state in ["normal", "hover", "pressed", "disabled"]:
		_my_pos_button.add_theme_stylebox_override(state, style)
	_my_pos_button.pressed.connect(_on_my_position)
	footer.add_child(_my_pos_button)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_my_pos_button.add_child(row)

	var pin := TextureRect.new()
	pin.texture = TEX_PIN
	pin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pin.custom_minimum_size = Vector2(40, 40)
	pin.modulate = COLOR_TEAL
	row.add_child(pin)
	_my_pos_label = Label.new()
	_my_pos_label.add_theme_font_override("font", FONT_BODY)
	_my_pos_label.add_theme_font_size_override("font_size", 32)
	_my_pos_label.add_theme_color_override("font_color", COLOR_SCORE)
	row.add_child(_my_pos_label)
	return footer


func _soft_card(bg: Color, radius: int) -> StyleBoxFlat:
	var style := _flat(bg, radius)
	style.set_border_width_all(3)
	style.border_color = Color(0.78, 0.62, 0.42, 0.45)
	style.shadow_color = Color(0.29, 0.18, 0.11, 0.14)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style


func _flat(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.anti_aliasing_size = 0.5
	return style
