extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const MODE_QUICK := "quick"
const MODE_CRYPTOGRAM := "cryptogram"
const STANDARD_BACK_BUTTON := preload("res://scenes/StandardBackButton.tscn")

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
const TEX_CRYPTO := preload("res://images/mode_scroll.svg")
const TEX_CALENDAR := preload("res://GUI/Library/Demo/Demo_Icon/IconGroup_MenuIcon02_Calendar.png")
const TEX_EYE := preload("res://images/lupa-con-un-ojo.png")
const TEX_CITAS := preload("res://images/Citas.png")
const TEX_EFEM := preload("res://images/Efemerides.png")
const TEX_CURIO := preload("res://images/Adivinanza.png")
const TEX_FRAG := preload("res://images/FragmentosLiterarios.png")
const FONT_TITLE := preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_BODY := preload("res://fonts/Fonts/Montserrat/static/Montserrat-SemiBold.ttf")
const FONT_REGULAR := preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")

const LOCALIZED := {
	"es": {
		"title": "ESTADÍSTICAS",
		"subtitle": "Tu progreso en CifraLetra",
		"games": "PARTIDAS JUGADAS",
		"games_sub": "",
		"wins": "PUZLES COMPLETADOS",
		"wins_sub": "%d%% del total",
		"time": "TIEMPO JUGADO",
		"time_sub": "Promedio por partida %s",
		"progress_title": "PROGRESO POR TEMÁTICA Y TIPO",
		"quick": "RÁPIDO",
		"cryptogram": "CRIPTOGRAMA",
		"hints_title": "USO DE AYUDAS",
		"hints_used": "PISTAS USADAS",
		"letters_revealed": "LETRAS REVELADAS",
		"letters_failed": "LETRAS REVELADAS FALLADAS",
		"avg_title": "TIEMPO MEDIO POR PARTIDA",
		"results_title": "RESUMEN DE ESTRELLAS OBTENIDAS",
		"results_total": "%d / %d ★",
		"results_percent": "%s%% del total",
		"results_average": "%s ★ / puzle",
		"puzzles_count": "%d puzles",
		"updated_note": "Las estadísticas se actualizan al completar un puzle.",
	},
	"en": {
		"title": "STATISTICS",
		"subtitle": "Your progress in CifraLetra",
		"games": "GAMES PLAYED",
		"games_sub": "",
		"wins": "PUZZLES COMPLETED",
		"wins_sub": "%d%% of total",
		"time": "TIME PLAYED",
		"time_sub": "Average per game %s",
		"progress_title": "PROGRESS BY THEME AND TYPE",
		"quick": "QUICK",
		"cryptogram": "CRYPTOGRAM",
		"hints_title": "HINTS USED",
		"hints_used": "HINTS USED",
		"letters_revealed": "LETTERS REVEALED",
		"letters_failed": "FAILED LETTER REVEALS",
		"avg_title": "AVERAGE TIME PER GAME",
		"results_title": "EARNED STAR SUMMARY",
		"results_total": "%d / %d ★",
		"results_percent": "%s%% of total",
		"results_average": "%s ★ / puzzle",
		"puzzles_count": "%d puzzles",
		"updated_note": "Statistics update when a puzzle is completed.",
	},
	"eu": {
		"title": "ESTATISTIKAK",
		"subtitle": "Zure aurrerapena CifraLetra-n",
		"games": "JOKATUTAKO PARTIDAK",
		"games_sub": "",
		"wins": "OSATUTAKO PUZZLEAK",
		"wins_sub": "Guztizkoaren %% %d",
		"time": "JOKATUTAKO DENBORA",
		"time_sub": "Batez bestekoa partidan %s",
		"progress_title": "GAIA ETA MOTAREN ARABERAKO AURRERAPENA",
		"quick": "AZKARRA",
		"cryptogram": "KRIPTOGRAMA",
		"hints_title": "LAGUNTZEN ERABILERA",
		"hints_used": "PISTAK",
		"letters_revealed": "AGERTUTAKO LETRAK",
		"letters_failed": "HUTS EGINDAKO LETRAK",
		"avg_title": "PARTIDAKO BATEZ BESTEKO DENBORA",
		"results_title": "LORTUTAKO IZARREN LABURPENA",
		"results_total": "%d / %d ★",
		"results_percent": "Guztizkoaren %s%%",
		"results_average": "%s ★ / puzzle",
		"puzzles_count": "%d puzzle",
		"updated_note": "Estatistikak puzzle bat osatzean eguneratzen dira.",
	},
}

var _selected_mode := MODE_QUICK
var _dashboard: Dictionary = {}
var _progress_list: VBoxContainer
var _tab_quick: Button
var _tab_crypto: Button
var _kpi_games: Label
var _kpi_games_sub: Label
var _kpi_wins: Label
var _kpi_wins_sub: Label
var _kpi_time: Label
var _kpi_time_sub: Label
var _hint_labels: Dictionary = {}
var _avg_quick_value: Label
var _avg_crypto_value: Label
var _results_total: Label
var _results_percent: Label
var _results_average: Label
var _average_stars: Array[TextureRect] = []
var _result_counts: Dictionary = {}
var _result_bars: Dictionary = {}
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
	_apply_avg_times()
	_apply_results()
	_rebuild_progress_rows()
	_update_tabs()


func _apply_localized_static() -> void:
	_title_label.text = _copy("title")
	_subtitle_label.text = _copy("subtitle")
	_section_labels["progress"].text = _copy("progress_title")
	_section_labels["hints"].text = _copy("hints_title")
	_section_labels["results"].text = _copy("results_title")
	_tab_quick.text = "  " + _copy("quick")
	_tab_crypto.text = "  " + _copy("cryptogram")
	_section_labels["avg"].text = _copy("avg_title")
	_hint_labels["hints_title"].text = _copy("hints_used")
	_hint_labels["letters_title"].text = _copy("letters_revealed")
	_hint_labels["failed_title"].text = _copy("letters_failed")


func _apply_kpis() -> void:
	_kpi_games.text = str(int(_dashboard.get("matches", 0)))
	_kpi_games_sub.text = _copy("games_sub")
	_kpi_wins.text = str(int(_dashboard.get("completed_puzzles", 0)))
	_kpi_wins_sub.text = _copy("wins_sub") % int(
		round(float(_dashboard.get("completed_percent", 0.0)))
	)
	_kpi_time.text = str(_dashboard.get("total_play_label", "0 s"))
	_kpi_time_sub.text = _copy("time_sub") % str(_dashboard.get("avg_play_label", "0 s"))


func _apply_hints() -> void:
	_hint_labels["hints"].text = str(int(_dashboard.get("hints_used", 0)))
	_hint_labels["letters"].text = str(int(_dashboard.get("letters_revealed", 0)))
	_hint_labels["failed"].text = str(int(_dashboard.get("letters_failed", 0)))


func _apply_avg_times() -> void:
	_avg_quick_value.text = str(_dashboard.get("avg_quick_label", "0 s"))
	_avg_crypto_value.text = str(_dashboard.get("avg_cryptogram_label", "0 s"))


func _apply_results() -> void:
	var summary: Dictionary = _dashboard.get("star_summary", {})
	var earned := int(summary.get("earned", 0))
	var available := int(summary.get("available", 0))
	var percentage := float(summary.get("percentage", 0.0))
	var completed := int(_dashboard.get("completed_puzzles", 0))
	var average := float(earned) / float(completed) if completed > 0 else 0.0
	_results_total.text = _copy("results_total") % [earned, available]
	_results_percent.text = _copy("results_percent") % (
		("%.1f" % percentage).replace(".", ",")
	)
	_results_average.text = _copy("results_average") % (
		("%.2f" % average).replace(".", ",")
	)
	var rounded_average := clampi(int(round(average)), 0, 5)
	for index in range(_average_stars.size()):
		var average_star := _average_stars[index]
		average_star.texture = TEX_STAR if index < rounded_average else TEX_STAR_OFF
		average_star.modulate = (
			GameManager.star_fill_color(_selected_mode)
			if index < rounded_average
			else Color(0.55, 0.42, 0.3, 0.5)
		)
	var distribution: Dictionary = summary.get("distribution", {})
	var maximum_count := 1
	for star_value in range(1, 6):
		maximum_count = maxi(maximum_count, int(distribution.get(star_value, 0)))
	for stars in range(1, 6):
		if _result_counts.has(stars):
			var count := int(distribution.get(stars, 0))
			(_result_counts[stars] as Label).text = _copy("puzzles_count") % count
			if _result_bars.has(stars):
				var bar := _result_bars[stars] as ProgressBar
				bar.max_value = maximum_count
				bar.value = count


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
				int(row.get("stars_earned", 0)),
				int(row.get("stars_available", 0)),
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
		style.bg_color = Color(1.0, 0.69, 0.31, 1.0)
		style.border_color = Color(0.91, 0.45, 0.12, 1.0)
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
	content.add_child(_build_results_card())
	content.add_child(_build_update_note())

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	content.add_child(spacer)
	sync_width.call_deferred()


func _build_header() -> Control:
	var header := Control.new()
	header.name = "Header"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 260

	var back := STANDARD_BACK_BUTTON.instantiate() as Button
	back.name = "ButtonBack"
	back.position = Vector2(36, 48)
	back.pressed.connect(_on_button_back_pressed)
	header.add_child(back)

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

	for ornament_data in [
		{"text": "✦  ❧", "left": 190.0, "right": 340.0},
		{"text": "❧  ✦", "left": 866.0, "right": 1016.0},
	]:
		var ornament := Label.new()
		ornament.position = Vector2(float(ornament_data["left"]), 64)
		ornament.size = Vector2(
			float(ornament_data["right"]) - float(ornament_data["left"]),
			72
		)
		ornament.text = str(ornament_data["text"])
		ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ornament.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ornament.add_theme_font_override("font", FONT_TITLE)
		ornament.add_theme_font_size_override("font_size", 35)
		ornament.add_theme_color_override(
			"font_color",
			Color(0.92, 0.58, 0.16, 0.72)
		)
		header.add_child(ornament)

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

	var wins := _make_kpi_card(COLOR_GREEN, TEX_STAR, _copy("wins"), "0", _copy("wins_sub"))
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
	_tab_crypto.icon = TEX_CRYPTO
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
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 88)

	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(72, 72)
	var icon_style := _flat(bar_color.lightened(0.55), 18)
	icon_wrap.add_theme_stylebox_override("panel", icon_style)
	row.add_child(icon_wrap)

	var icon := TextureRect.new()
	icon.texture = icon_tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(48, 48)
	icon_wrap.add_child(icon)

	var name_l := Label.new()
	name_l.text = name_text
	name_l.custom_minimum_size.x = 245
	name_l.add_theme_font_override("font", FONT_BODY)
	name_l.add_theme_font_size_override("font_size", 24)
	name_l.add_theme_color_override("font_color", COLOR_INK)
	row.add_child(name_l)

	var stars := HBoxContainer.new()
	stars.custom_minimum_size.x = 174
	stars.add_theme_constant_override("separation", 2)
	row.add_child(stars)
	var filled_stars := clampi(int(round(float(percent) / 20.0)), 0, 5)
	for index in range(5):
		var star := TextureRect.new()
		star.texture = TEX_STAR if index < filled_stars else TEX_STAR_OFF
		star.custom_minimum_size = Vector2(32, 32)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.modulate = (
			GameManager.star_fill_color(_selected_mode)
			if index < filled_stars
			else Color(0.55, 0.42, 0.3, 0.5)
		)
		stars.add_child(star)

	var fraction := Label.new()
	fraction.custom_minimum_size.x = 145
	fraction.text = "%d / %d ★" % [done, total]
	fraction.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fraction.add_theme_font_override("font", FONT_BODY)
	fraction.add_theme_font_size_override("font_size", 22)
	fraction.add_theme_color_override("font_color", COLOR_INK)
	row.add_child(fraction)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maxi(total, 1)
	bar.value = done
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(155, 16)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := _flat(Color(0.93, 0.88, 0.8, 1), 10)
	var fill := _flat(bar_color, 10)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)

	var pct := Label.new()
	pct.custom_minimum_size.x = 64
	pct.text = "%d%%" % percent
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.add_theme_font_override("font", FONT_REGULAR)
	pct.add_theme_font_size_override("font_size", 21)
	pct.add_theme_color_override("font_color", COLOR_MUTED)
	row.add_child(pct)
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
	card.custom_minimum_size = Vector2(0, 250)
	card.add_theme_stylebox_override("panel", _soft_card(COLOR_CARD, 34))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	card.add_child(box)

	var title := _section_title(_copy("avg_title"))
	_section_labels["avg"] = title
	box.add_child(title)

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 18)
	box.add_child(modes)

	var quick := _make_mode_time_cell(TEX_QUICK, _copy("quick"))
	_avg_quick_value = quick.get_node("Content/Texts/Value")
	modes.add_child(quick)

	var crypto := _make_mode_time_cell(TEX_CRYPTO, _copy("cryptogram"))
	_avg_crypto_value = crypto.get_node("Content/Texts/Value")
	modes.add_child(crypto)
	return card


func _make_mode_time_cell(icon_texture: Texture2D, title_text: String) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.custom_minimum_size = Vector2(0, 145)
	cell.add_theme_stylebox_override(
		"panel",
		_flat(Color(0.98, 0.95, 0.88, 0.92), 24)
	)
	var content := HBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 16)
	cell.add_child(content)

	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.custom_minimum_size = Vector2(76, 76)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(icon)

	var texts := VBoxContainer.new()
	texts.name = "Texts"
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(texts)

	var mode_title := Label.new()
	mode_title.text = title_text
	mode_title.add_theme_font_override("font", FONT_BODY)
	mode_title.add_theme_font_size_override("font_size", 25)
	mode_title.add_theme_color_override("font_color", COLOR_MUTED)
	texts.add_child(mode_title)

	var value := Label.new()
	value.name = "Value"
	value.text = "0 s"
	value.add_theme_font_override("font", FONT_TITLE)
	value.add_theme_font_size_override("font_size", 40)
	value.add_theme_color_override("font_color", COLOR_INK)
	texts.add_child(value)
	return cell


func _build_results_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "ResultsCard"
	card.add_theme_stylebox_override("panel", _soft_card(COLOR_CARD, 34))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	card.add_child(box)

	var title := _section_title(_copy("results_title"))
	_section_labels["results"] = title
	box.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	box.add_child(body)

	var summary := PanelContainer.new()
	summary.custom_minimum_size.x = 360
	summary.add_theme_stylebox_override(
		"panel",
		_flat(Color(1.0, 0.965, 0.875, 0.75), 24)
	)
	body.add_child(summary)

	var summary_box := VBoxContainer.new()
	summary_box.alignment = BoxContainer.ALIGNMENT_CENTER
	summary_box.add_theme_constant_override("separation", 8)
	summary.add_child(summary_box)

	var total_row := HBoxContainer.new()
	total_row.alignment = BoxContainer.ALIGNMENT_CENTER
	total_row.add_theme_constant_override("separation", 10)
	summary_box.add_child(total_row)

	var total_icon := TextureRect.new()
	total_icon.texture = TEX_STAR
	total_icon.custom_minimum_size = Vector2(76, 76)
	total_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	total_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	total_icon.modulate = Color(1.0, 0.62, 0.08, 1.0)
	total_row.add_child(total_icon)

	_results_total = Label.new()
	_results_total.text = "0 / 0 ★"
	_results_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_total.add_theme_font_override("font", FONT_TITLE)
	_results_total.add_theme_font_size_override("font_size", 39)
	_results_total.add_theme_color_override("font_color", COLOR_INK)
	total_row.add_child(_results_total)

	_results_percent = Label.new()
	_results_percent.text = "0,0% del total"
	_results_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_percent.add_theme_font_override("font", FONT_BODY)
	_results_percent.add_theme_font_size_override("font_size", 22)
	_results_percent.add_theme_color_override("font_color", COLOR_INK)
	summary_box.add_child(_results_percent)

	var separator := HSeparator.new()
	separator.add_theme_stylebox_override(
		"separator",
		_flat(Color(0.79, 0.65, 0.42, 0.35), 1)
	)
	summary_box.add_child(separator)

	var average_title := Label.new()
	average_title.text = "Promedio general"
	average_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	average_title.add_theme_font_override("font", FONT_REGULAR)
	average_title.add_theme_font_size_override("font_size", 18)
	average_title.add_theme_color_override("font_color", COLOR_MUTED)
	summary_box.add_child(average_title)

	var average_stars := HBoxContainer.new()
	average_stars.alignment = BoxContainer.ALIGNMENT_CENTER
	average_stars.add_theme_constant_override("separation", 3)
	summary_box.add_child(average_stars)
	_average_stars.clear()
	for _index in range(5):
		var star := TextureRect.new()
		star.texture = TEX_STAR_OFF
		star.custom_minimum_size = Vector2(32, 32)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.modulate = Color(0.55, 0.42, 0.3, 0.5)
		average_stars.add_child(star)
		_average_stars.append(star)

	_results_average = Label.new()
	_results_average.text = "0,00 ★ / puzle"
	_results_average.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_average.add_theme_font_override("font", FONT_BODY)
	_results_average.add_theme_font_size_override("font_size", 21)
	_results_average.add_theme_color_override("font_color", COLOR_MUTED)
	summary_box.add_child(_results_average)

	var distribution := VBoxContainer.new()
	distribution.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	distribution.add_theme_constant_override("separation", 6)
	body.add_child(distribution)

	_result_counts.clear()
	_result_bars.clear()
	for stars in range(5, 0, -1):
		distribution.add_child(_make_result_row(stars))
	return card


func _make_result_row(stars: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 54)
	row.add_theme_constant_override("separation", 8)

	var star_group := HBoxContainer.new()
	star_group.custom_minimum_size.x = 170
	star_group.add_theme_constant_override("separation", 2)
	row.add_child(star_group)
	for index in range(5):
		var star := TextureRect.new()
		star.texture = TEX_STAR if index < stars else TEX_STAR_OFF
		star.custom_minimum_size = Vector2(32, 32)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.modulate = (
			GameManager.star_fill_color(_selected_mode)
			if index < stars
			else Color(0.55, 0.42, 0.3, 0.5)
		)
		star_group.add_child(star)

	var description := Label.new()
	description.custom_minimum_size.x = 115
	description.text = "%d %s" % [stars, "estrella" if stars == 1 else "estrellas"]
	description.add_theme_font_override("font", FONT_REGULAR)
	description.add_theme_font_size_override("font_size", 17)
	description.add_theme_color_override("font_color", COLOR_INK)
	row.add_child(description)

	var count := Label.new()
	count.custom_minimum_size.x = 130
	count.text = "0 puzles"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.add_theme_font_override("font", FONT_BODY)
	count.add_theme_font_size_override("font_size", 18)
	count.add_theme_color_override("font_color", COLOR_INK)
	row.add_child(count)
	_result_counts[stars] = count

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 1
	bar.value = 0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(105, 13)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_stylebox_override(
		"background",
		_flat(Color(0.93, 0.88, 0.79, 1.0), 8)
	)
	bar.add_theme_stylebox_override(
		"fill",
		_flat(Color(1.0, 0.65, 0.16, 1.0), 8)
	)
	row.add_child(bar)
	_result_bars[stars] = bar
	return row


func _build_update_note() -> PanelContainer:
	var note := PanelContainer.new()
	note.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	note.custom_minimum_size = Vector2(710, 70)
	var style := _flat(Color(1.0, 0.973, 0.91, 0.82), 28)
	style.set_border_width_all(2)
	style.border_color = Color(0.78, 0.64, 0.43, 0.28)
	style.content_margin_left = 28
	style.content_margin_right = 28
	note.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	note.add_child(row)

	var icon := TextureRect.new()
	icon.texture = TEX_TIMER
	icon.custom_minimum_size = Vector2(34, 34)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = COLOR_MUTED
	row.add_child(icon)

	var label := Label.new()
	label.text = _copy("updated_note")
	label.add_theme_font_override("font", FONT_REGULAR)
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", COLOR_MUTED)
	row.add_child(label)
	return note


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
