extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const MODE_QUICK := "quick"
const MODE_CRYPTOGRAM := "cryptogram"

const PROGRESS_ROWS := {
	"RowCita": "cita",
	"RowEfemeride": "efemeride",
	"RowCuriosidades": "curiosidades",
	"RowFragmento": "fragmento",
}

@onready var _header: Control = $Panel/Header
@onready var _content: Control = $Panel/Content
@onready var _title_label: Label = $Panel/Header/Title
@onready var _subtitle_label: Label = $Panel/Header/Subtitle
@onready var _kpi_wins_stars: Label = $Panel/Header/StarTotals/StarQuick/Count
@onready var _kpi_time_stars: Label = $Panel/Header/StarTotals/StarCrypto/Count
@onready var _kpi_games: Label = $Panel/Content/KpiRow/GamesCard/Box/Value
@onready var _kpi_games_sub: Label = $Panel/Content/KpiRow/GamesCard/Box/Sub
@onready var _kpi_wins: Label = $Panel/Content/KpiRow/QuickCard/Box/Value
@onready var _kpi_wins_sub: Label = $Panel/Content/KpiRow/QuickCard/Box/Sub
@onready var _kpi_wins_title: Label = $Panel/Content/KpiRow/QuickCard/Box/Title
@onready var _kpi_time: Label = $Panel/Content/KpiRow/CryptoCard/Box/Value
@onready var _kpi_time_sub: Label = $Panel/Content/KpiRow/CryptoCard/Box/Sub
@onready var _kpi_time_title: Label = $Panel/Content/KpiRow/CryptoCard/Box/Title
@onready var _progress_title: Label = $Panel/Content/ProgressCard/Box/Title
@onready var _tab_quick: Button = $Panel/Content/ProgressCard/Box/Tabs/TabQuick
@onready var _tab_crypto: Button = $Panel/Content/ProgressCard/Box/Tabs/TabCrypto
@onready var _progress_list: VBoxContainer = $Panel/Content/ProgressCard/Box/ProgressList
@onready var _hints_title: Label = $Panel/Content/HintsCard/Box/Title
@onready var _hint_used_title: Label = $Panel/Content/HintsCard/Box/Grid/HintUsed/Title
@onready var _hint_used_value: Label = $Panel/Content/HintsCard/Box/Grid/HintUsed/Value
@onready var _hint_letters_title: Label = $Panel/Content/HintsCard/Box/Grid/HintLetters/Title
@onready var _hint_letters_value: Label = $Panel/Content/HintsCard/Box/Grid/HintLetters/Value
@onready var _hint_failed_title: Label = $Panel/Content/HintsCard/Box/Grid/HintFailed/Title
@onready var _hint_failed_value: Label = $Panel/Content/HintsCard/Box/Grid/HintFailed/Value
@onready var _avg_title: Label = $Panel/Content/AvgCard/Box/Title
@onready var _avg_quick_title: Label = $Panel/Content/AvgCard/Box/Modes/AvgQuick/Content/Texts/Title
@onready var _avg_quick_value: Label = $Panel/Content/AvgCard/Box/Modes/AvgQuick/Content/Texts/Value
@onready var _avg_crypto_title: Label = $Panel/Content/AvgCard/Box/Modes/AvgCrypto/Content/Texts/Title
@onready var _avg_crypto_value: Label = $Panel/Content/AvgCard/Box/Modes/AvgCrypto/Content/Texts/Value
@onready var _results_title: Label = $Panel/Content/ResultsCard/Box/Title
@onready var _perfect_title: Label = $Panel/Content/ResultsCard/Box/Body/PerfectCard/Box/Title
@onready var _results_total: Label = $Panel/Content/ResultsCard/Box/Body/PerfectCard/Box/Value
@onready var _fastest_title: Label = $Panel/Content/ResultsCard/Box/Body/FastestCard/Box/Title
@onready var _results_percent: Label = $Panel/Content/ResultsCard/Box/Body/FastestCard/Box/Value
@onready var _results_average: Label = $Panel/Content/ResultsCard/Box/Body/FastestCard/Box/Sub

var _dashboard: Dictionary = {}


func _ready() -> void:
	_refresh()
	if not HistoryManager.stats_updated.is_connected(_on_stats_updated):
		HistoryManager.stats_updated.connect(_on_stats_updated)
	_play_intro_motion()


func _on_stats_updated() -> void:
	_refresh()


func _copy(key: String) -> String:
	const MAP := {
		"title": "STATS",
		"games": "StatsGames",
		"wins": "StatsQuickGames",
		"time": "StatsCryptoGames",
		"perfect_title": "PerfectPuzzles",
		"fastest_title": "FastestPuzzle",
		"fastest_sub": "FastestPuzzleId",
		"progress_title": "ProgressTitle",
		"quick": "Quick",
		"cryptogram": "Cryptogram",
		"hints_title": "HintsUsage",
		"hints_used": "USED HINTS",
		"letters_revealed": "LettersRevealed",
		"letters_failed": "LettersFailed",
		"avg_title": "AvgTimePerGame",
		"results_title": "PersonalMarks",
	}
	return tr(str(MAP.get(key, key)))


func _refresh() -> void:
	_dashboard = HistoryManager.get_stats_dashboard()
	_apply_localized_static()
	_apply_kpis()
	_apply_hints()
	_apply_avg_times()
	_apply_results()
	_apply_progress()


func _apply_localized_static() -> void:
	_title_label.text = _copy("title")
	_subtitle_label.visible = false
	_progress_title.text = _copy("progress_title")
	_hints_title.text = _copy("hints_title")
	_results_title.text = _copy("results_title")
	_avg_title.text = _copy("avg_title")
	_tab_quick.text = "  " + _copy("quick")
	_tab_crypto.text = "  " + _copy("cryptogram")
	_hint_used_title.text = _copy("hints_used")
	_hint_letters_title.text = _copy("letters_revealed")
	_hint_failed_title.text = _copy("letters_failed")
	_kpi_wins_title.text = _copy("wins")
	_kpi_time_title.text = _copy("time")
	$Panel/Content/KpiRow/GamesCard/Box/Title.text = _copy("games")
	_perfect_title.text = _copy("perfect_title")
	_fastest_title.text = _copy("fastest_title")
	_avg_quick_title.text = _copy("quick")
	_avg_crypto_title.text = _copy("cryptogram")


func _apply_kpis() -> void:
	_kpi_games.text = str(int(_dashboard.get("matches", 0)))
	_kpi_games_sub.text = ""
	_kpi_wins.text = str(int(_dashboard.get("matches_quick", 0)))
	_kpi_wins_sub.text = ""
	_kpi_time.text = str(int(_dashboard.get("matches_cryptogram", 0)))
	_kpi_time_sub.text = ""
	_kpi_wins_stars.text = str(int(_dashboard.get("stars_quick", 0)))
	_kpi_time_stars.text = str(int(_dashboard.get("stars_cryptogram", 0)))


func _apply_hints() -> void:
	_hint_used_value.text = str(int(_dashboard.get("hints_used", 0)))
	_hint_letters_value.text = str(int(_dashboard.get("letters_revealed", 0)))
	_hint_failed_value.text = str(int(_dashboard.get("letters_failed", 0)))


func _apply_avg_times() -> void:
	_avg_quick_value.text = str(_dashboard.get("avg_quick_label", "0 s"))
	_avg_crypto_value.text = str(_dashboard.get("avg_cryptogram_label", "0 s"))


func _apply_results() -> void:
	_results_total.text = str(int(_dashboard.get("perfect_puzzles", 0)))
	_results_percent.text = str(_dashboard.get("fastest_label", "—"))
	var fastest_id := int(_dashboard.get("fastest_id", -1))
	_results_average.text = (
		_copy("fastest_sub") % fastest_id if fastest_id >= 0 else "—"
	)


func _progress_row_for(rows: Variant, category: String) -> Dictionary:
	if not (rows is Array):
		return {}
	for row_value in rows:
		if row_value is Dictionary and str(row_value.get("category", "")) == category:
			return row_value
	return {}


func _apply_progress() -> void:
	var progress: Variant = _dashboard.get("progress", {})
	var quick_rows: Variant = progress.get(MODE_QUICK, []) if progress is Dictionary else []
	var crypto_rows: Variant = progress.get(MODE_CRYPTOGRAM, []) if progress is Dictionary else []
	for row in _progress_list.get_children():
		var category := str(PROGRESS_ROWS.get(row.name, ""))
		if category.is_empty():
			continue
		var name_l := row.get_node_or_null("Identity/Name") as Label
		if name_l:
			name_l.text = GameManager.category_display_name(category)
		_fill_progress_cell(row.get_node_or_null("QuickCell"), _progress_row_for(quick_rows, category))
		_fill_progress_cell(row.get_node_or_null("CryptoCell"), _progress_row_for(crypto_rows, category))


func _fill_progress_cell(cell: Node, data: Dictionary) -> void:
	if cell == null:
		return
	var earned := int(data.get("stars_earned", 0))
	var available := int(data.get("stars_available", 0))
	var percent := int(data.get("percent", 0))
	var bar := cell.get_node_or_null("BarRow/Bar") as ProgressBar
	if bar:
		bar.max_value = maxi(available, 1)
		bar.value = earned
	var stars := cell.get_node_or_null("Stars") as Label
	if stars:
		stars.text = "%d / %d ★" % [earned, available]
	var percent_l := cell.get_node_or_null("Percent") as Label
	if percent_l:
		percent_l.text = "%d%%" % percent


func _on_button_back_pressed() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SoundManager.play("ButtonClick")
	get_tree().change_scene_to_file(PATH_MAIN)


func _play_intro_motion() -> void:
	if _content == null:
		return
	_content.modulate.a = 0.0
	var rest_top := _content.offset_top
	_content.offset_top = rest_top + 20.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_content, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_content, "offset_top", rest_top, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _header:
		_header.modulate.a = 0.0
		tween.tween_property(_header, "modulate:a", 1.0, 0.35).set_delay(0.05)
