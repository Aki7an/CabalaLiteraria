extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const MODE_QUICK := "quick"
const MODE_CRYPTOGRAM := "cryptogram"
const COLOR_INK := Color(0.325, 0.2, 0.125, 1)
const COLOR_STAR_QUICK := Color(1.0, 0.82, 0.12, 1)
const COLOR_STAR_CRYPTO := Color(1.0, 0.48, 0.08, 1)
const COLOR_STAR_TOTAL := Color(0.86, 0.12, 0.12, 1)
const STAR_TEXTURE: Texture2D = preload("res://images/estrella_plano.png")
const ICON_QUICK: Texture2D = preload("res://images/mode_quick.svg")
const ICON_CRYPTO: Texture2D = preload("res://images/CriptogramaIcono.png")
const DRAG_THRESHOLD := 14.0
const CATEGORY_ROWS := {
	"RowCita": "cita",
	"RowEfemeride": "efemeride",
	"RowCuriosidades": "curiosidades",
	"RowFragmento": "fragmento",
}

@onready var _header: Control = $Panel/Header
@onready var _scroll: ScrollContainer = $Panel/Scroll
@onready var _content: VBoxContainer = $Panel/Scroll/Content
@onready var _title_label: Label = %Title
@onready var _your_progress_title: Label = %TitleYourProgress
@onready var _stars_label: Label = %LabelStars
@onready var _star_bar: ProgressBar = %StarBar
@onready var _puzzles_label: Label = %LabelPuzzles
@onready var _quick_title: Label = %LabelQuickTitle
@onready var _quick_matches: Label = %LabelQuickMatches
@onready var _quick_stars: Node = %LabelQuickStars
@onready var _quick_avg: Label = %LabelQuickAvg
@onready var _crypto_title: Label = %LabelCryptoTitle
@onready var _crypto_matches: Label = %LabelCryptoMatches
@onready var _crypto_stars: Node = %LabelCryptoStars
@onready var _crypto_avg: Label = %LabelCryptoAvg
@onready var _by_category_title: Label = %TitleByCategory
@onready var _legend_quick: Label = %LegendQuick
@onready var _legend_crypto: Label = %LegendCrypto
@onready var _aids_title: Label = %TitleAids
@onready var _aids_card: PanelContainer = $Panel/Scroll/Content/Aids
@onready var _hint_used: Label = %LabelHintUsed
@onready var _hint_used_title: Label = %HintUsedTitle
@onready var _hint_letters: Label = %LabelHintLetters
@onready var _hint_letters_title: Label = %HintLettersTitle
@onready var _hint_failed: Label = %LabelHintFailed
@onready var _hint_failed_title: Label = %HintFailedTitle
@onready var _gomas_value: Label = %LabelGomas
@onready var _gomas_title: Label = %GomasTitle
@onready var _play_time_value: Label = %LabelPlayTime
@onready var _play_time_title: Label = %PlayTimeTitle
@onready var _marks_title: Label = %TitleMarks
@onready var _perfect_value: Label = %PerfectValue
@onready var _perfect_title: Label = %PerfectTitle
@onready var _fastest_value: Label = %FastestValue
@onready var _fastest_title: Label = %FastestTitle
@onready var _perfect_crypto: Label = %PerfectValueCrypto
@onready var _perfect_crypto_title: Label = %PerfectTitleCrypto
@onready var _fastest_crypto: Label = %FastestValueCrypto
@onready var _fastest_crypto_title: Label = %FastestTitleCrypto
@onready var _progress_list: VBoxContainer = %ProgressList

var _dashboard: Dictionary = {}
var _tpl_stars := ""
var _tpl_puzzles := ""
var _tpl_cat_stars := ""
var _fit_queued := false
var _drag_held := false
var _drag_active := false
var _drag_origin := Vector2.ZERO
var _drag_scroll_origin := 0


func _ready() -> void:
	_tpl_stars = _stars_label.text
	_tpl_puzzles = _puzzles_label.text
	var sample := _row_child(_progress_list.get_node_or_null("RowCita"), "Meta/StarsQuick")
	if sample:
		_tpl_cat_stars = str(sample.get("text"))
	_refresh()
	_ensure_challenge_card()
	if _scroll:
		_scroll.scroll_deadzone = 16
		_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	if _content:
		_make_content_drag_through(_content)
	ScrollOverflowHint.attach(_scroll)
	if not HistoryManager.stats_updated.is_connected(_on_stats_updated):
		HistoryManager.stats_updated.connect(_on_stats_updated)
	if not resized.is_connected(_schedule_fit):
		resized.connect(_schedule_fit)
	if _scroll and not _scroll.resized.is_connected(_schedule_fit):
		_scroll.resized.connect(_schedule_fit)
	_play_intro_motion()
	_schedule_fit()


func _on_stats_updated() -> void:
	_refresh()


func _input(event: InputEvent) -> void:
	if not is_instance_valid(_scroll) or not _scroll.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_drag_press(event.pressed, event.position)
	elif event is InputEventMouseMotion and _drag_held:
		_handle_drag_motion(event.position)
	elif event is InputEventScreenTouch:
		_handle_drag_press(event.pressed, event.position)
	elif event is InputEventScreenDrag and _drag_held:
		_handle_drag_motion(event.position)


func _handle_drag_press(pressed: bool, position: Vector2) -> void:
	if pressed:
		if not _scroll.get_global_rect().has_point(position):
			return
		_drag_held = true
		_drag_active = false
		_drag_origin = position
		_drag_scroll_origin = _scroll.scroll_vertical
		return
	if _drag_active:
		get_viewport().set_input_as_handled()
	_drag_held = false
	_drag_active = false


func _handle_drag_motion(position: Vector2) -> void:
	var delta := position.y - _drag_origin.y
	if not _drag_active and absf(delta) >= DRAG_THRESHOLD:
		_drag_active = true
	if not _drag_active:
		return
	_scroll.scroll_vertical = _drag_scroll_origin - int(delta)
	get_viewport().set_input_as_handled()


func _make_content_drag_through(node: Node) -> void:
	for child in node.get_children():
		_make_content_drag_through(child)
	if node is Button:
		return
	if node is Control and node != _scroll:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _refresh() -> void:
	_dashboard = HistoryManager.get_stats_dashboard()
	_apply_static()
	_apply_hero()
	_apply_modes()
	_apply_categories()
	_apply_aids()
	_apply_marks()
	_schedule_fit()


func _apply_static() -> void:
	_title_label.text = _t("Stats", _title_label.text).to_upper()
	_your_progress_title.text = _t("StatsYourProgress", _your_progress_title.text).to_upper()
	_by_category_title.text = _t("StatsByCategory", _by_category_title.text).to_upper()
	_aids_title.text = _t("StatsPerfQuick", _aids_title.text).to_upper()
	_set_title_icon(_aids_card, ICON_QUICK)
	_lock_perf_title_row(_aids_card)
	_marks_title.text = _t("PersonalMarks", _marks_title.text).to_upper()
	_quick_title.text = _t("Quick", _quick_title.text).to_upper()
	_crypto_title.text = _t("Cryptogram", _crypto_title.text).to_upper()
	_legend_quick.text = _t("Quick", _legend_quick.text)
	_legend_crypto.text = _t("Cryptogram", _legend_crypto.text)
	_hint_used_title.text = _t("StatsPistas", _hint_used_title.text)
	_hint_letters_title.text = _t("StatsRevealed", _hint_letters_title.text)
	_hint_failed_title.text = _t("StatsFails", _hint_failed_title.text)
	if _gomas_title:
		_gomas_title.text = _t("StatsGomas", _gomas_title.text)
	if _play_time_title:
		_play_time_title.text = _t("StatsPlayTimeQuick", _play_time_title.text)
	_perfect_title.text = _t("StatsPerfectQuick", _perfect_title.text)
	_fastest_title.text = _t("StatsBestTimeQuick", _fastest_title.text)
	if _perfect_crypto_title:
		_perfect_crypto_title.text = _t("StatsPerfectCrypto", _perfect_crypto_title.text)
	if _fastest_crypto_title:
		_fastest_crypto_title.text = _t("StatsBestTimeCrypto", _fastest_crypto_title.text)
	_set_cat_label("RowCita", GameManager.CAT_CITA)
	_set_cat_label("RowEfemeride", GameManager.CAT_EFEMERIDE)
	_set_cat_label("RowCuriosidades", GameManager.CAT_CURIOSIDADES)
	_set_cat_label("RowFragmento", GameManager.CAT_FRAGMENTO)


func _row_inner(row: Node) -> Node:
	if row == null:
		return null
	var inner := row.get_node_or_null("Inner")
	return inner if inner else row


func _row_child(row: Node, path: String) -> Node:
	var inner := _row_inner(row)
	return inner.get_node_or_null(path) if inner else null


func _set_cat_name(row_name: String, key: String) -> void:
	var name_l := _row_child(_progress_list.get_node_or_null(row_name), "Name") as Label
	if name_l:
		name_l.text = _t(key, name_l.text)


func _set_cat_label(row_name: String, category_id: String) -> void:
	var name_l := _row_child(_progress_list.get_node_or_null(row_name), "Name") as Label
	if name_l:
		name_l.text = GameManager.category_display_name(category_id)


func _apply_hero() -> void:
	var summary: Dictionary = _dashboard.get("star_summary", {})
	var earned := int(summary.get("earned", 0))
	var available := int(summary.get("available", 0))
	_stars_label.text = _fill(_t("StatsStarsOf", _tpl_stars), earned, available)
	var hero_star := _content.get_node_or_null("YourProgress/Box/StarsRow/StarIcon") as TextureRect
	if hero_star:
		hero_star.modulate = COLOR_STAR_TOTAL
	_star_bar.max_value = 100.0
	_star_bar.value = float(summary.get("percentage", 0.0))
	_puzzles_label.text = _fill(
		_t("StatsPuzzlesSolved", _tpl_puzzles),
		int(_dashboard.get("completed_puzzles", 0)),
		int(_dashboard.get("total_puzzles", 0))
	)


func _apply_modes() -> void:
	var q_matches := int(_dashboard.get("matches_quick", 0))
	var c_matches := int(_dashboard.get("matches_cryptogram", 0))
	_quick_matches.text = _matches_text(q_matches)
	_crypto_matches.text = _matches_text(c_matches)
	_set_star_line(_quick_stars, str(int(_dashboard.get("stars_quick", 0))), COLOR_STAR_QUICK)
	_set_star_line(_crypto_stars, str(int(_dashboard.get("stars_cryptogram", 0))), COLOR_STAR_CRYPTO)
	_quick_avg.text = _avg_text(q_matches, str(_dashboard.get("avg_quick_label", "—")))
	_crypto_avg.text = _avg_text(c_matches, str(_dashboard.get("avg_cryptogram_label", "—")))


func _apply_categories() -> void:
	var progress: Variant = _dashboard.get("progress", {})
	var quick_rows: Variant = progress.get(MODE_QUICK, []) if progress is Dictionary else []
	var crypto_rows: Variant = progress.get(MODE_CRYPTOGRAM, []) if progress is Dictionary else []
	for row in _progress_list.get_children():
		var category := str(CATEGORY_ROWS.get(row.name, ""))
		if category.is_empty():
			continue
		_fill_category_row(row, _row_for(quick_rows, category), _row_for(crypto_rows, category))


func _fill_category_row(row: Node, quick: Dictionary, crypto: Dictionary) -> void:
	_set_bar(_row_child(row, "Bars/BarQuick") as ProgressBar, quick)
	_set_bar(_row_child(row, "Bars/BarCrypto") as ProgressBar, crypto)
	_set_cat_stars(_row_child(row, "Meta/StarsQuick"), quick, COLOR_STAR_QUICK)
	_set_cat_stars(_row_child(row, "Meta/StarsCrypto"), crypto, COLOR_STAR_CRYPTO)


func _set_bar(bar: ProgressBar, data: Dictionary) -> void:
	if bar == null:
		return
	var available := int(data.get("stars_available", 0))
	var earned := int(data.get("stars_earned", 0))
	bar.max_value = 100.0
	bar.value = (100.0 * float(earned) / float(available)) if available > 0 else 0.0


func _set_cat_stars(node: Node, data: Dictionary, star_color: Color) -> void:
	if node == null:
		return
	var template := _t("StatsCatStars", _tpl_cat_stars if not _tpl_cat_stars.is_empty() else "%d/%d★")
	var plain := _fill(template, int(data.get("stars_earned", 0)), int(data.get("stars_available", 0)))
	_set_star_line(node, plain, star_color)


func _set_star_line(node: Node, raw: String, star_color: Color) -> void:
	if node == null:
		return
	var numbers := raw.replace("★", "").strip_edges()
	if numbers.is_empty():
		numbers = raw
	var base_size := 38
	if node is RichTextLabel:
		base_size = (node as RichTextLabel).get_theme_font_size("normal_font_size")
	elif node is Label:
		base_size = (node as Label).get_theme_font_size("font_size")
	if base_size <= 0:
		base_size = 38
	var star_size := maxi(28, int(round(float(base_size) * 1.15)))
	if node is RichTextLabel:
		var rtl := node as RichTextLabel
		rtl.bbcode_enabled = true
		rtl.fit_content = true
		rtl.scroll_active = false
		rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
		rtl.clear()
		rtl.push_color(COLOR_INK)
		rtl.add_text(numbers + " ")
		rtl.pop()
		rtl.add_image(STAR_TEXTURE, star_size, star_size, star_color)
		return
	if node is Label:
		(node as Label).text = numbers
		(node as Label).add_theme_color_override("font_color", COLOR_INK)


func _apply_aids() -> void:
	_ensure_challenge_card()
	var quick: Dictionary = _dashboard.get("perf_quick", {})
	_hint_used.text = str(int(quick.get("hints", 0)))
	_hint_failed.text = str(int(quick.get("failed", 0)))
	_hint_letters.text = str(int(quick.get("revealed", 0)))
	if _gomas_value:
		_gomas_value.text = str(int(quick.get("gomas", 0)))
	if _play_time_value:
		_play_time_value.text = str(quick.get("time_label", "—"))
	var crypto_card := _content.get_node_or_null("Challenges")
	if crypto_card:
		_fill_perf_card(crypto_card, "StatsPerfCrypto", "StatsPlayTimeCrypto", _dashboard.get("perf_cryptogram", {}))


func _fill_perf_card(card: Node, title_key: String, time_key: String, data: Dictionary) -> void:
	_set_named_label(card, "TitleAids", _t(title_key, "").to_upper())
	_set_title_icon(card, ICON_CRYPTO if title_key == "StatsPerfCrypto" else ICON_QUICK)
	_lock_perf_title_row(card)
	_set_named_label(card, "HintUsedTitle", _t("StatsPistas", "Pistas"))
	_set_named_label(card, "HintFailedTitle", _t("StatsFails", "Fallos"))
	_set_named_label(card, "HintLettersTitle", _t("StatsRevealed", "Reveladas"))
	_set_named_label(card, "GomasTitle", _t("StatsGomas", "Gomas"))
	_set_named_label(card, "PlayTimeTitle", _t(time_key, ""))
	_set_named_label(card, "LabelHintUsed", str(int(data.get("hints", 0))))
	_set_named_label(card, "LabelHintFailed", str(int(data.get("failed", 0))))
	_set_named_label(card, "LabelHintLetters", str(int(data.get("revealed", 0))))
	_set_named_label(card, "LabelGomas", str(int(data.get("gomas", 0))))
	_set_named_label(card, "LabelPlayTime", str(data.get("time_label", "—")))


func _set_title_icon(card: Node, texture: Texture2D) -> void:
	if card == null:
		return
	var icon := card.find_child("TitleIcon", true, false) as TextureRect
	if icon:
		icon.texture = texture


func _lock_perf_title_row(card: Node) -> void:
	if card == null:
		return
	var cluster := card.find_child("TitleCluster", true, false) as Control
	if cluster:
		cluster.size_flags_horizontal = 0
	var title := card.find_child("TitleAids", true, false) as Label
	if title:
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.clip_text = false
	for line_name in ["LineL", "LineR"]:
		var line := card.find_child(line_name, true, false) as Control
		if line:
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.custom_minimum_size = Vector2(24, line.custom_minimum_size.y)


func _set_named_label(root: Node, node_name: String, text: String) -> void:
	if root == null:
		return
	var node := root.find_child(node_name, true, false)
	if node is Label:
		var label := node as Label
		label.text = text
		if node_name == "TitleAids":
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.clip_text = false


func _ensure_challenge_card() -> void:
	if _content == null or _aids_card == null:
		return
	if _content.get_node_or_null("Challenges") != null:
		return
	var clone := _aids_card.duplicate()
	clone.name = "Challenges"
	_clear_unique_names(clone)
	_content.add_child(clone)
	_content.move_child(clone, _aids_card.get_index() + 1)
	_make_content_drag_through(clone)


func _clear_unique_names(node: Node) -> void:
	node.unique_name_in_owner = false
	for child in node.get_children():
		_clear_unique_names(child)


func _apply_marks() -> void:
	_perfect_value.text = str(int(_dashboard.get("perfect_quick", 0)))
	_fastest_value.text = str(_dashboard.get("fastest_quick_label", "—"))
	if _perfect_crypto:
		_perfect_crypto.text = str(int(_dashboard.get("perfect_cryptogram", 0)))
	if _fastest_crypto:
		_fastest_crypto.text = str(_dashboard.get("fastest_cryptogram_label", "—"))


func _row_for(rows: Variant, category: String) -> Dictionary:
	if not (rows is Array):
		return {}
	for row_value in rows:
		if row_value is Dictionary and str(row_value.get("category", "")) == category:
			return row_value
	return {}


func _matches_text(count: int) -> String:
	if count == 1:
		return _t("StatsMatchOne", "1 partida")
	return _t("StatsMatches", "%d partidas") % count


func _avg_text(matches: int, raw: String) -> String:
	var value := "—" if matches <= 0 or raw.is_empty() or raw == "0 s" else raw
	var template := _t("StatsAvgSuffix", "%s media")
	return template % value if "%s" in template else "%s %s" % [value, template]


func _fill(template: String, a: Variant, b: Variant) -> String:
	if "%d" in template:
		return template % [int(a), int(b)]
	if "%s" in template:
		return template % [str(a), str(b)]
	return template


func _t(key: String, fallback: String) -> String:
	var value := tr(key)
	if value.is_empty():
		return fallback
	return value


func _schedule_fit() -> void:
	if _fit_queued:
		return
	_fit_queued = true
	call_deferred("_fit_section_gaps")


func _fit_section_gaps() -> void:
	_fit_queued = false
	if _content == null or _scroll == null:
		return
	_content.add_theme_constant_override("separation", 0)
	await get_tree().process_frame
	if not is_inside_tree() or _content == null or _scroll == null:
		return
	var height := 0.0
	var visible_n := 0
	for kid in _content.get_children():
		var control := kid as Control
		if control == null or not control.visible:
			continue
		height += maxf(control.size.y, control.get_combined_minimum_size().y)
		visible_n += 1
	var gaps := maxi(visible_n - 1, 0)
	var leftover := _scroll.size.y - height
	var sep := 24
	if gaps > 0 and leftover > 0.0:
		sep = maxi(24, mini(36, int(floor(leftover / float(gaps)))))
	_content.add_theme_constant_override("separation", sep)


func _on_button_back_pressed() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SoundManager.play("ButtonClick")
	get_tree().change_scene_to_file(PATH_MAIN)


func _play_intro_motion() -> void:
	if _content == null:
		return
	_content.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_content, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _header:
		_header.modulate.a = 0.0
		tween.tween_property(_header, "modulate:a", 1.0, 0.35).set_delay(0.05)
