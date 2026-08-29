extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const MODE_QUICK := "quick"
const MODE_CRYPTOGRAM := "cryptogram"

const COLOR_INK := Color(0.325, 0.2, 0.125, 1)
const COLOR_MUTED := Color(0.45, 0.32, 0.22, 0.78)
const COLOR_CREAM := Color(0.992, 0.965, 0.914, 1)
const COLOR_CARD := Color(1, 0.984, 0.953, 0.98)
const COLOR_TEAL := Color(0.165, 0.655, 0.647, 1)
const COLOR_TEAL_SOFT := Color(0.82, 0.93, 0.91, 1)
const COLOR_BLUE := Color(0.72, 0.88, 0.95, 1)
const COLOR_GREEN := Color(0.78, 0.91, 0.78, 1)
const COLOR_ORANGE := Color(0.98, 0.84, 0.72, 1)
const COLOR_FAIL := Color(0.86, 0.27, 0.27, 1)

const TEX_TROPHY := preload("res://GUI/Library/Demo/Demo_Icon/Icon_ColorIcon_Trophy01.png")
const TEX_STAR := preload("res://images/estrella_plano.png")
const TEX_STAR_OFF := preload("res://images/contorno_estrella.png")
const TEX_TIMER := preload("res://GUI/Library/Demo/Demo_Icon/Icon_ColorIcon_Timer.png")
const TEX_BULB := preload("res://images/Bombilla.png")
const TEX_SEARCH := preload("res://GUI/Library/Demo/Demo_Icon/Icon_WhiteIcon_Search.png")
const TEX_CROSS := preload("res://images/Cruz.png")
const TEX_LOCK := preload("res://images/Candado.png")
const TEX_QUICK := preload("res://images/mode_quick.svg")
const TEX_CALENDAR := preload("res://GUI/Library/Demo/Demo_Icon/IconGroup_MenuIcon02_Calendar.png")
const TEX_EYE := preload("res://images/lupa-con-un-ojo.png")
const TEX_CITAS := preload("res://images/Citas.png")
const TEX_EFEM := preload("res://images/Efemerides.png")
const TEX_CURIO := preload("res://images/Adivinanza.png")
const TEX_FRAG := preload("res://images/FragmentosLiterarios.png")
const FONT_TITLE := preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_BODY := preload("res://fonts/Fonts/Montserrat/static/Montserrat-SemiBold.ttf")
const FONT_REGULAR := preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")
const CHART_SCRIPT := preload("res://scenes/stats_line_chart.gd")

const LOCALIZED := {
	"es": {
		"title": "ESTADÍSTICAS",
		"subtitle": "Tu progreso en CifraLetra",
		"games": "PARTIDAS",
		"games_sub": "Jugadas",
		"wins": "VICTORIAS",
		"wins_sub": "%s%% de éxito",
		"time": "TIEMPO JUGADO",
		"time_sub": "Promedio por partida %s",
		"progress_title": "PROGRESO POR TEMÁTICA Y TIPO",
		"quick": "RÁPIDO",
		"cryptogram": "CRIPTOGRAMA",
		"hints_title": "USO DE AYUDAS",
		"hints_used": "PISTAS USADAS",
		"letters_revealed": "LETRAS REVELADAS",
		"letters_failed": "LETRAS REVELADAS FALLADAS",
		"searches": "BÚSQUEDAS (PISTA)",
		"avg_title": "TIEMPO MEDIO POR PARTIDA",
		"best_title": "MEJOR PROGRESO PERSONAL",
		"best_sub": "Estrellas en un puzzle",
		"best_tip": "Las estrellas obtenidas en cada puzzle determinan tu progreso.",
		"empty_best": "Completa un puzzle para ver tu mejor marca.",
	},
	"en": {
		"title": "STATISTICS",
		"subtitle": "Your progress in CifraLetra",
		"games": "GAMES",
		"games_sub": "Played",
		"wins": "WINS",
		"wins_sub": "%s%% success",
		"time": "TIME PLAYED",
		"time_sub": "Average per game %s",
		"progress_title": "PROGRESS BY THEME AND TYPE",
		"quick": "QUICK",
		"cryptogram": "CRYPTOGRAM",
		"hints_title": "HINTS USED",
		"hints_used": "HINTS USED",
		"letters_revealed": "LETTERS REVEALED",
		"letters_failed": "FAILED LETTER REVEALS",
		"searches": "SEARCHES (HINT)",
		"avg_title": "AVERAGE TIME PER GAME",
		"best_title": "BEST PERSONAL PROGRESS",
		"best_sub": "Stars on a puzzle",
		"best_tip": "The stars earned on each puzzle determine your progress.",
		"empty_best": "Complete a puzzle to see your best mark.",
	},
	"eu": {
		"title": "ESTATISTIKAK",
		"subtitle": "Zure aurrerapena CifraLetra-n",
		"games": "PARTIDAK",
		"games_sub": "Jokatuta",
		"wins": "GARAIPENAK",
		"wins_sub": "%s%% arrakasta",
		"time": "JOKATUTAKO DENBORA",
		"time_sub": "Batez bestekoa partidan %s",
		"progress_title": "GAIAREN ETA MOTAREN ARABERAKO AURRERAPENA",
		"quick": "AZKARRA",
		"cryptogram": "KRIPTOGRAMA",
		"hints_title": "LAGUNTZEN ERABILERA",
		"hints_used": "PISTAK",
		"letters_revealed": "AGERTUTAKO LETRAK",
		"letters_failed": "HUTS EGINDAKO LETRAK",
		"searches": "BILAKETAK (PISTA)",
		"avg_title": "BATEZ BESTEKO DENBORA",
		"best_title": "HOBEKIN AURRERAPENA",
		"best_sub": "Izar puzzle batean",
		"best_tip": "Puzzle bakoitzean lortutako izarrek zehazten dute zure aurrerapena.",
		"empty_best": "Osatu puzzle bat zure markarik onena ikusteko.",
	},
}

var _selected_mode := MODE_QUICK
var _dashboard: Dictionary = {}
var _progress_list: VBoxContainer
var _tab_quick: Button
var _tab_crypto: Button
var _chart: Control
var _kpi_games: Label
var _kpi_games_sub: Label
var _kpi_wins: Label
var _kpi_wins_sub: Label
var _kpi_time: Label
var _kpi_time_sub: Label
var _hint_labels: Dictionary = {}
var _avg_value: Label
var _best_stars: Array[TextureRect] = []
var _best_score: Label
var _best_meta_level: Label
var _best_meta_date: Label
var _title_label: Label
var _subtitle_label: Label
var _section_labels: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh()
	if not HistoryManager.stats_updated.is_connected(_on_stats_updated):
		HistoryManager.stats_updated.connect(_on_stats_updated)
	_play_intro_motion()


func _on_stats_updated() -> void:
	_refresh()


func _copy(key: String) -> String:
	var locale := GameManager.locale_code()
	var pack: Dictionary = LOCALIZED.get(locale, LOCALIZED["es"])
	if not pack.has(key):
		pack = LOCALIZED["en"] if LOCALIZED["en"].has(key) else LOCALIZED["es"]
	return str(pack.get(key, key))


func _refresh() -> void:
	_dashboard = HistoryManager.get_stats_dashboard()
	_apply_localized_static()
	_apply_kpis()
	_apply_hints()
	_apply_avg_chart()
	_apply_best()
	_rebuild_progress_rows()
	_update_tabs()


func _apply_localized_static() -> void:
	_title_label.text = _copy("title")
	_subtitle_label.text = _copy("subtitle")
	_section_labels["progress"].text = _copy("progress_title")
	_section_labels["hints"].text = _copy("hints_title")
	_section_labels["best"].text = _copy("best_title")
	_tab_quick.text = "  " + _copy("quick")
	_tab_crypto.text = "  " + _copy("cryptogram")
	_section_labels["avg"].text = _copy("avg_title")
	_section_labels["best_sub"].text = _copy("best_sub")
	_section_labels["best_tip"].text = _copy("best_tip")
	_hint_labels["hints_title"].text = _copy("hints_used")
	_hint_labels["letters_title"].text = _copy("letters_revealed")
	_hint_labels["failed_title"].text = _copy("letters_failed")
	_hint_labels["search_title"].text = _copy("searches")


func _apply_kpis() -> void:
	_kpi_games.text = str(int(_dashboard.get("matches", 0)))
	_kpi_games_sub.text = _copy("games_sub")
	_kpi_wins.text = str(int(_dashboard.get("wins", 0)))
	var rate := float(_dashboard.get("win_rate", 0.0))
	_kpi_wins_sub.text = _copy("wins_sub") % ("%.1f" % rate)
	_kpi_time.text = str(_dashboard.get("total_play_label", "0 s"))
	_kpi_time_sub.text = _copy("time_sub") % str(_dashboard.get("avg_play_label", "0 s"))


func _apply_hints() -> void:
	_hint_labels["hints"].text = str(int(_dashboard.get("hints_used", 0)))
	_hint_labels["letters"].text = str(int(_dashboard.get("letters_revealed", 0)))
	_hint_labels["failed"].text = str(int(_dashboard.get("letters_failed", 0)))
	_hint_labels["search"].text = str(int(_dashboard.get("searches", 0)))


func _apply_avg_chart() -> void:
	_avg_value.text = str(_dashboard.get("avg_play_label", "0 s"))
	if _chart and _chart.has_method("set_values"):
		_chart.call("set_values", _dashboard.get("avg_series_minutes", []))


func _apply_best() -> void:
	var best: Dictionary = _dashboard.get("best", {})
	var stars := clampi(int(best.get("stars", 0)), 0, 5)
	for i in range(_best_stars.size()):
		_best_stars[i].texture = TEX_STAR if i < stars else TEX_STAR_OFF
		_best_stars[i].modulate = Color(1, 1, 1, 1) if i < stars else Color(0.55, 0.42, 0.3, 0.45)
	_best_score.text = "%d / 5" % stars
	if bool(best.get("has_data", false)):
		var title := str(best.get("title", "")).strip_edges()
		var level := str(best.get("level", "")).strip_edges()
		if title != "" and level != "":
			_best_meta_level.text = "%s – %s" % [title, level]
		elif level != "":
			_best_meta_level.text = level
		else:
			_best_meta_level.text = GameManager.category_display_name(str(best.get("category", "")))
		_best_meta_date.text = str(best.get("date", "—"))
	else:
		_best_meta_level.text = _copy("empty_best")
		_best_meta_date.text = ""


func _rebuild_progress_rows() -> void:
	for child in _progress_list.get_children():
		child.queue_free()
	var progress: Dictionary = _dashboard.get("progress", {})
	var rows: Array = progress.get(_selected_mode, [])
	var colors := {
		GameManager.CAT_CITA: Color(0.22, 0.67, 0.55, 1),
		GameManager.CAT_EFEMERIDE: Color(0.55, 0.42, 0.78, 1),
		GameManager.CAT_CURIOSIDADES: Color(0.93, 0.55, 0.28, 1),
		GameManager.CAT_FRAGMENTO: Color(0.30, 0.55, 0.86, 1),
	}
	var icons := {
		GameManager.CAT_CITA: TEX_CITAS,
		GameManager.CAT_EFEMERIDE: TEX_EFEM,
		GameManager.CAT_CURIOSIDADES: TEX_CURIO,
		GameManager.CAT_FRAGMENTO: TEX_FRAG,
	}
	for row in rows:
		var category := str(row.get("category", ""))
		_progress_list.add_child(
			_make_progress_row(
				GameManager.category_display_name(category),
				icons.get(category, TEX_CITAS),
				colors.get(category, COLOR_TEAL),
				int(row.get("done", 0)),
				int(row.get("total", 0)),
				int(row.get("percent", 0))
			)
		)


func _update_tabs() -> void:
	_style_tab(_tab_quick, _selected_mode == MODE_QUICK)
	_style_tab(_tab_crypto, _selected_mode == MODE_CRYPTOGRAM)


func _style_tab(button: Button, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(22)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	if active:
		style.bg_color = COLOR_TEAL
		style.border_color = COLOR_TEAL.darkened(0.12)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
	else:
		style.bg_color = Color(0.97, 0.93, 0.86, 1)
		style.border_color = Color(0.78, 0.66, 0.48, 0.55)
		button.add_theme_color_override("font_color", COLOR_INK)
		button.add_theme_color_override("font_hover_color", COLOR_INK)
		button.add_theme_color_override("font_pressed_color", COLOR_INK)
	style.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)


func _on_tab_quick_pressed() -> void:
	_selected_mode = MODE_QUICK
	SoundManager.play("ButtonClick")
	_update_tabs()
	_rebuild_progress_rows()


func _on_tab_crypto_pressed() -> void:
	_selected_mode = MODE_CRYPTOGRAM
	SoundManager.play("ButtonClick")
	_update_tabs()
	_rebuild_progress_rows()


func _on_button_back_pressed() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SoundManager.play("ButtonClick")
	get_tree().change_scene_to_file(PATH_MAIN)


func _play_intro_motion() -> void:
	var scroll := get_node_or_null("Panel/Scroll") as ScrollContainer
	if scroll == null:
		return
	var content := scroll.get_node_or_null("Content") as Control
	if content == null:
		return
	content.modulate.a = 0.0
	content.position.y = 28.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(content, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var header := get_node_or_null("Panel/Header") as Control
	if header:
		header.modulate.a = 0.0
		tween.tween_property(header, "modulate:a", 1.0, 0.35).set_delay(0.05)


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

	var header := _build_header()
	panel.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 36
	scroll.offset_top = 280
	scroll.offset_right = -36
	scroll.offset_bottom = -36
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 28)
	scroll.add_child(content)
	var sync_width := func() -> void:
		content.custom_minimum_size.x = maxf(scroll.size.x, 1.0)
	scroll.resized.connect(sync_width)

	content.add_child(_build_kpi_row())
	content.add_child(_build_progress_card())
	content.add_child(_build_hints_card())
	content.add_child(_build_avg_card())
	content.add_child(_build_best_card())

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	content.add_child(spacer)
	sync_width.call_deferred()


func _build_header() -> Control:
	var header := Control.new()
	header.name = "Header"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 260

	var back := Button.new()
	back.name = "ButtonBack"
	back.position = Vector2(36, 48)
	back.custom_minimum_size = Vector2(96, 96)
	back.focus_mode = Control.FOCUS_NONE
	var back_style := _flat(Color(0.455, 0.275, 0.137, 1), 28)
	back_style.set_border_width_all(6)
	back_style.border_color = Color(0.627, 0.42, 0.224, 1)
	back_style.shadow_color = Color(0.23, 0.13, 0.07, 0.28)
	back_style.shadow_size = 8
	back_style.shadow_offset = Vector2(0, 6)
	back.add_theme_stylebox_override("normal", back_style)
	back.add_theme_stylebox_override("hover", back_style)
	back.add_theme_stylebox_override("pressed", back_style)
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

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title_label.offset_top = 54
	_title_label.offset_bottom = 140
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", FONT_TITLE)
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.add_theme_color_override("font_color", COLOR_INK)
	header.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "Subtitle"
	_subtitle_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_subtitle_label.offset_top = 138
	_subtitle_label.offset_bottom = 190
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_override("font", FONT_REGULAR)
	_subtitle_label.add_theme_font_size_override("font_size", 28)
	_subtitle_label.add_theme_color_override("font_color", COLOR_MUTED)
	header.add_child(_subtitle_label)

	return header


func _build_kpi_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "KpiRow"
	row.add_theme_constant_override("separation", 18)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var games := _make_kpi_card(COLOR_BLUE, TEX_TROPHY, _copy("games"), "0", _copy("games_sub"))
	_kpi_games = games.get_node("Box/Value")
	_kpi_games_sub = games.get_node("Box/Sub")
	row.add_child(games)

	var wins := _make_kpi_card(COLOR_GREEN, TEX_STAR, _copy("wins"), "0", _copy("wins_sub") % "0.0")
	_kpi_wins = wins.get_node("Box/Value")
	_kpi_wins_sub = wins.get_node("Box/Sub")
	row.add_child(wins)

	var time_card := _make_kpi_card(COLOR_ORANGE, TEX_TIMER, _copy("time"), "0 s", _copy("time_sub") % "0 s")
	_kpi_time = time_card.get_node("Box/Value")
	_kpi_time_sub = time_card.get_node("Box/Sub")
	row.add_child(time_card)
	return row


func _make_kpi_card(bg: Color, icon_tex: Texture2D, title: String, value: String, sub: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 250)
	card.add_theme_stylebox_override("panel", _soft_card(bg, 28))

	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 8)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)

	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(72, 72)
	icon_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var icon_bg := _flat(Color(1, 1, 1, 0.55), 18)
	icon_wrap.add_theme_stylebox_override("panel", icon_bg)
	box.add_child(icon_wrap)

	var icon := TextureRect.new()
	icon.texture = icon_tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(48, 48)
	icon_wrap.add_child(icon)

	var title_l := Label.new()
	title_l.name = "Title"
	title_l.text = title
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_l.add_theme_font_override("font", FONT_BODY)
	title_l.add_theme_font_size_override("font_size", 22)
	title_l.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(title_l)

	var value_l := Label.new()
	value_l.name = "Value"
	value_l.text = value
	value_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_l.add_theme_font_override("font", FONT_TITLE)
	value_l.add_theme_font_size_override("font_size", 54)
	value_l.add_theme_color_override("font_color", COLOR_INK)
	box.add_child(value_l)

	var sub_l := Label.new()
	sub_l.name = "Sub"
	sub_l.text = sub
	sub_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_l.add_theme_font_override("font", FONT_REGULAR)
	sub_l.add_theme_font_size_override("font_size", 18)
	sub_l.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(sub_l)
	return card


func _build_progress_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "ProgressCard"
	card.add_theme_stylebox_override("panel", _soft_card(COLOR_CARD, 34))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	card.add_child(box)

	var title := _section_title(_copy("progress_title"))
	_section_labels["progress"] = title
	box.add_child(title)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 14)
	box.add_child(tabs)

	_tab_quick = Button.new()
	_tab_quick.focus_mode = Control.FOCUS_NONE
	_tab_quick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_quick.custom_minimum_size = Vector2(0, 78)
	_tab_quick.add_theme_font_override("font", FONT_BODY)
	_tab_quick.add_theme_font_size_override("font_size", 28)
	_tab_quick.icon = TEX_QUICK
	_tab_quick.expand_icon = true
	_tab_quick.pressed.connect(_on_tab_quick_pressed)
	tabs.add_child(_tab_quick)

	_tab_crypto = Button.new()
	_tab_crypto.focus_mode = Control.FOCUS_NONE
	_tab_crypto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_crypto.custom_minimum_size = Vector2(0, 78)
	_tab_crypto.add_theme_font_override("font", FONT_BODY)
	_tab_crypto.add_theme_font_size_override("font_size", 28)
	_tab_crypto.icon = TEX_LOCK
	_tab_crypto.expand_icon = true
	_tab_crypto.pressed.connect(_on_tab_crypto_pressed)
	tabs.add_child(_tab_crypto)

	_progress_list = VBoxContainer.new()
	_progress_list.name = "ProgressList"
	_progress_list.add_theme_constant_override("separation", 16)
	box.add_child(_progress_list)
	return card


func _make_progress_row(name_text: String, icon_tex: Texture2D, bar_color: Color, done: int, total: int, percent: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.custom_minimum_size = Vector2(0, 78)

	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(68, 68)
	var icon_style := _flat(bar_color.lightened(0.55), 18)
	icon_wrap.add_theme_stylebox_override("panel", icon_style)
	row.add_child(icon_wrap)

	var icon := TextureRect.new()
	icon.texture = icon_tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(44, 44)
	icon_wrap.add_child(icon)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 8)
	row.add_child(mid)

	var name_l := Label.new()
	name_l.text = name_text
	name_l.add_theme_font_override("font", FONT_BODY)
	name_l.add_theme_font_size_override("font_size", 26)
	name_l.add_theme_color_override("font_color", COLOR_INK)
	mid.add_child(name_l)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maxi(total, 1)
	bar.value = done
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 18)
	var bg := _flat(Color(0.93, 0.88, 0.8, 1), 10)
	var fill := _flat(bar_color, 10)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	mid.add_child(bar)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(120, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)

	var fraction := Label.new()
	fraction.text = "%d/%d" % [done, total]
	fraction.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fraction.add_theme_font_override("font", FONT_BODY)
	fraction.add_theme_font_size_override("font_size", 24)
	fraction.add_theme_color_override("font_color", COLOR_INK)
	right.add_child(fraction)

	var pct := Label.new()
	pct.text = "%d%%" % percent
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.add_theme_font_override("font", FONT_REGULAR)
	pct.add_theme_font_size_override("font_size", 20)
	pct.add_theme_color_override("font_color", COLOR_MUTED)
	right.add_child(pct)
	return row


func _build_hints_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "HintsCard"
	card.add_theme_stylebox_override("panel", _soft_card(COLOR_CARD, 34))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	card.add_child(box)

	var title := _section_title(_copy("hints_title"))
	_section_labels["hints"] = title
	box.add_child(title)

	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 10)
	box.add_child(grid)

	var h1 := _make_hint_cell(TEX_BULB, Color(1, 0.9, 0.55, 1), _copy("hints_used"), "0", false)
	_hint_labels["hints"] = h1.get_node("Value")
	_hint_labels["hints_title"] = h1.get_node("Title")
	grid.add_child(h1)

	var h2 := _make_hint_cell(TEX_EYE, Color(0.78, 0.7, 0.92, 1), _copy("letters_revealed"), "0", false)
	_hint_labels["letters"] = h2.get_node("Value")
	_hint_labels["letters_title"] = h2.get_node("Title")
	grid.add_child(h2)

	var h3 := _make_hint_cell(TEX_CROSS, Color(0.95, 0.72, 0.72, 1), _copy("letters_failed"), "0", true)
	_hint_labels["failed"] = h3.get_node("Value")
	_hint_labels["failed_title"] = h3.get_node("Title")
	grid.add_child(h3)

	var h4 := _make_hint_cell(TEX_SEARCH, Color(0.98, 0.82, 0.62, 1), _copy("searches"), "0", false)
	_hint_labels["search"] = h4.get_node("Value")
	_hint_labels["search_title"] = h4.get_node("Title")
	grid.add_child(h4)
	return card


func _make_hint_cell(icon_tex: Texture2D, bg: Color, title: String, value: String, danger: bool) -> VBoxContainer:
	var cell := VBoxContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override("separation", 8)
	cell.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(74, 74)
	icon_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_wrap.add_theme_stylebox_override("panel", _flat(bg, 20))
	cell.add_child(icon_wrap)

	var icon := TextureRect.new()
	icon.texture = icon_tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(42, 42)
	if icon_tex == TEX_SEARCH:
		icon.modulate = COLOR_INK
	icon_wrap.add_child(icon)

	var title_l := Label.new()
	title_l.name = "Title"
	title_l.text = title
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_l.add_theme_font_override("font", FONT_REGULAR)
	title_l.add_theme_font_size_override("font_size", 16)
	title_l.add_theme_color_override("font_color", COLOR_MUTED)
	cell.add_child(title_l)

	var value_l := Label.new()
	value_l.name = "Value"
	value_l.text = value
	value_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_l.add_theme_font_override("font", FONT_TITLE)
	value_l.add_theme_font_size_override("font_size", 42)
	value_l.add_theme_color_override("font_color", COLOR_FAIL if danger else COLOR_INK)
	cell.add_child(value_l)
	return cell


func _build_avg_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "AvgCard"
	card.custom_minimum_size = Vector2(0, 210)
	card.add_theme_stylebox_override("panel", _soft_card(COLOR_CARD, 34))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	card.add_child(row)

	var left := HBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 14)
	row.add_child(left)

	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(84, 84)
	icon_wrap.add_theme_stylebox_override("panel", _flat(Color(0.45, 0.32, 0.22, 1), 22))
	left.add_child(icon_wrap)

	var icon := TextureRect.new()
	icon.texture = TEX_TIMER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(48, 48)
	icon_wrap.add_child(icon)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(texts)

	var title := Label.new()
	title.text = _copy("avg_title")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", FONT_BODY)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLOR_MUTED)
	_section_labels["avg"] = title
	texts.add_child(title)

	_avg_value = Label.new()
	_avg_value.text = "0 s"
	_avg_value.add_theme_font_override("font", FONT_TITLE)
	_avg_value.add_theme_font_size_override("font_size", 42)
	_avg_value.add_theme_color_override("font_color", COLOR_INK)
	texts.add_child(_avg_value)

	_chart = Control.new()
	_chart.set_script(CHART_SCRIPT)
	_chart.custom_minimum_size = Vector2(420, 160)
	_chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_chart)
	return card


func _build_best_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "BestCard"
	card.add_theme_stylebox_override("panel", _soft_card(COLOR_CARD, 34))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	card.add_child(box)

	var title := _section_title(_copy("best_title"))
	_section_labels["best"] = title
	box.add_child(title)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	box.add_child(top)

	var stars_row := HBoxContainer.new()
	stars_row.add_theme_constant_override("separation", 8)
	top.add_child(stars_row)
	_best_stars.clear()
	for i in range(5):
		var star := TextureRect.new()
		star.texture = TEX_STAR_OFF
		star.custom_minimum_size = Vector2(58, 58)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stars_row.add_child(star)
		_best_stars.append(star)

	var score_box := VBoxContainer.new()
	score_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(score_box)

	_best_score = Label.new()
	_best_score.text = "0 / 5"
	_best_score.add_theme_font_override("font", FONT_TITLE)
	_best_score.add_theme_font_size_override("font_size", 52)
	_best_score.add_theme_color_override("font_color", COLOR_INK)
	score_box.add_child(_best_score)

	var best_sub := Label.new()
	best_sub.text = _copy("best_sub")
	best_sub.add_theme_font_override("font", FONT_REGULAR)
	best_sub.add_theme_font_size_override("font_size", 24)
	best_sub.add_theme_color_override("font_color", COLOR_MUTED)
	_section_labels["best_sub"] = best_sub
	score_box.add_child(best_sub)

	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 24)
	box.add_child(meta)

	var level_wrap := HBoxContainer.new()
	level_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_wrap.add_theme_constant_override("separation", 10)
	meta.add_child(level_wrap)

	var cal := TextureRect.new()
	cal.texture = TEX_CALENDAR
	cal.custom_minimum_size = Vector2(36, 36)
	cal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	level_wrap.add_child(cal)

	_best_meta_level = Label.new()
	_best_meta_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_best_meta_level.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_best_meta_level.add_theme_font_override("font", FONT_REGULAR)
	_best_meta_level.add_theme_font_size_override("font_size", 24)
	_best_meta_level.add_theme_color_override("font_color", COLOR_INK)
	level_wrap.add_child(_best_meta_level)

	var date_wrap := HBoxContainer.new()
	date_wrap.add_theme_constant_override("separation", 10)
	meta.add_child(date_wrap)

	var clock := TextureRect.new()
	clock.texture = TEX_TIMER
	clock.custom_minimum_size = Vector2(32, 32)
	clock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	date_wrap.add_child(clock)

	_best_meta_date = Label.new()
	_best_meta_date.add_theme_font_override("font", FONT_REGULAR)
	_best_meta_date.add_theme_font_size_override("font_size", 24)
	_best_meta_date.add_theme_color_override("font_color", COLOR_MUTED)
	date_wrap.add_child(_best_meta_date)

	var tip := PanelContainer.new()
	tip.add_theme_stylebox_override("panel", _flat(Color(1, 0.95, 0.78, 1), 18))
	box.add_child(tip)

	var tip_row := HBoxContainer.new()
	tip_row.add_theme_constant_override("separation", 12)
	tip.add_child(tip_row)

	var tip_star := TextureRect.new()
	tip_star.texture = TEX_STAR
	tip_star.custom_minimum_size = Vector2(28, 28)
	tip_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tip_star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tip_row.add_child(tip_star)

	var tip_text := Label.new()
	tip_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_text.add_theme_font_override("font", FONT_REGULAR)
	tip_text.add_theme_font_size_override("font_size", 22)
	tip_text.add_theme_color_override("font_color", COLOR_MUTED)
	_section_labels["best_tip"] = tip_text
	tip_row.add_child(tip_text)
	return card


func _section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_TITLE)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", COLOR_INK)
	return label


func _soft_card(bg: Color, radius: int) -> StyleBoxFlat:
	var style := _flat(bg, radius)
	style.set_border_width_all(3)
	style.border_color = Color(0.78, 0.62, 0.42, 0.45)
	style.shadow_color = Color(0.29, 0.18, 0.11, 0.14)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	return style


func _flat(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.anti_aliasing_size = 0.5
	return style
