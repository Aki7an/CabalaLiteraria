extends Control

@onready var button_settings: Button = %ButtonSettings
@onready var button_music: Button = %ButtonMusic
@onready var button_fx: Button = %ButtonFx
@onready var button_play: Button = %ButtonPlay
@onready var button_shop: Button = %ButtonShop
@onready var button_daily: Button = %ButtonDaily
@onready var button_library: Button = %ButtonLibrary
@onready var button_ranking: Button = %ButtonRanking
@onready var button_stats: Button = %ButtonStats
@onready var button_tutorial: Button = %ButtonTutorial
@onready var version_label: Label = %VersionLabel
@onready var stars_quick_count: Label = %StarsQuickCount
@onready var stars_crypto_count: Label = %StarsCryptoCount

const TITLE_LETTER_GREEN := Color(0.22, 0.62, 0.28, 1)
const TITLE_SPANISH_LETTERS := 5
const TITLE_SPANISH_WIDTH_SCALE := 0.8
const TITLE_SAFETY_PX := 24.0
const TITLE_LETTER_SIZE := 78
const TITLE_NUMBER_SIZE := 34
const TITLE_NUMBER_TOP_GAP := 14.0

func _ready() -> void:
	SoundManager.apply_audio_prefs()
	_refresh_audio_buttons()
	if not SignalManager.audio_prefs_changed.is_connected(_refresh_audio_buttons):
		SignalManager.audio_prefs_changed.connect(_refresh_audio_buttons)
	GameManager.session_source = GameManager.SOURCE_NONE
	_layout_home_buttons()
	_apply_labels()
	_apply_title_tiles()
	_update_version_label()
	_refresh_star_totals()
	_refresh_daily_button()
	if not HistoryManager.stats_updated.is_connected(_refresh_star_totals):
		HistoryManager.stats_updated.connect(_refresh_star_totals)
	SignalManager.app_version_changed.connect(_on_app_version_changed)
	SignalManager.fit_text.emit()
	GameManager.reset_game_paremeters()
	GameManager.resetear_partida_terminada()


func _refresh_star_totals(_unused: Variant = null) -> void:
	var dashboard: Dictionary = HistoryManager.get_stats_dashboard()
	if stars_quick_count:
		stars_quick_count.text = str(int(dashboard.get("stars_quick", 0)))
	if stars_crypto_count:
		stars_crypto_count.text = str(int(dashboard.get("stars_cryptogram", 0)))

func _apply_labels() -> void:
	var tagline := get_node_or_null("Panel/TaglineRow/Tagline") as Label
	if tagline:
		tagline.text = tr("Tagline")
	var shop := get_node_or_null("Panel/Shortcuts/ColShop/ButtonShop/Label") as Label
	if shop:
		shop.text = tr("Shop")
	var daily := get_node_or_null("Panel/Shortcuts/ColDaily/ButtonDaily/Label") as Label
	if daily:
		daily.text = tr("DailyChallenge")
	var library := get_node_or_null("Panel/Shortcuts/ColLibrary/ButtonLibrary/Label") as Label
	if library:
		library.text = tr("Library")
	var ranking := get_node_or_null("Panel/Actions/ColRanking/ButtonRanking/Label") as Label
	if ranking:
		ranking.text = tr("Leaderboard")
	var stats := get_node_or_null("Panel/Actions/ColStats/ButtonStats/Label") as Label
	if stats:
		stats.text = tr("Stats")
	var tutorial := get_node_or_null("Panel/Actions/ColTutorial/ButtonTutorial/Label") as Label
	if tutorial:
		tutorial.text = tr("HowToPlay")
	var play := get_node_or_null("Panel/PlayWrap/ButtonPlay/Play") as Label
	if play:
		play.text = tr("PLAY")


func _showcase_cipher_number(letter: String) -> int:
	var key := GameManager._hint_letter_key(letter)
	if key.length() != 1:
		return 0
	var code := key.unicode_at(0)
	if code >= 65 and code <= 90:
		return code - 64
	return 0


func _title_word(key: String, fallback: String) -> String:
	var translated := tr(key).strip_edges()
	if translated.is_empty():
		translated = fallback
	var out := ""
	for i in translated.length():
		var ch := translated.substr(i, 1).to_upper()
		if GameManager.is_excluded_character(ch):
			continue
		out += ch
	return out if not out.is_empty() else fallback


func _apply_title_tiles() -> void:
	var brand := get_node_or_null("Panel/Brand") as Control
	if brand:
		brand.visible = false
	var cipher_row := get_node_or_null("%Showcase") as HBoxContainer
	if cipher_row == null:
		cipher_row = get_node_or_null("Panel/TitleBlock/Showcase") as HBoxContainer
	if cipher_row == null:
		cipher_row = get_node_or_null("Panel/Showcase") as HBoxContainer
	if cipher_row == null:
		return
	var cipher_word := _title_word("Cipher", "CIFRA")
	var letter_word := _title_word("Letter", "LETRA")
	_fill_tile_row(cipher_row, cipher_word, false)
	var letter_row := _ensure_letter_row(cipher_row)
	if letter_row:
		_fill_tile_row(letter_row, letter_word, true)
	await get_tree().process_frame
	_layout_title_row(cipher_row)
	if letter_row:
		_layout_title_row(letter_row)


func _ensure_letter_row(cipher_row: HBoxContainer) -> HBoxContainer:
	var parent := cipher_row.get_parent()
	if parent == null:
		return null
	var existing := parent.get_node_or_null("ShowcaseLetra") as HBoxContainer
	if existing:
		return existing
	var row := cipher_row.duplicate() as HBoxContainer
	row.name = "ShowcaseLetra"
	row.unique_name_in_owner = false
	parent.add_child(row)
	return row


func _fill_tile_row(row: HBoxContainer, word: String, revealed_green: bool) -> void:
	var letters: Array[String] = []
	for i in word.length():
		var ch := word.substr(i, 1)
		if GameManager.is_excluded_character(ch):
			continue
		letters.append(ch)
	if letters.is_empty() or row.get_child_count() == 0:
		return
	var template := row.get_child(0) as Control
	while row.get_child_count() < letters.size():
		row.add_child(template.duplicate())
	var letter_size := TITLE_LETTER_SIZE
	var number_size := TITLE_NUMBER_SIZE
	for i in row.get_child_count():
		var tile := row.get_child(i) as Control
		if i >= letters.size():
			tile.visible = false
			continue
		tile.visible = true
		var letter_label := tile.find_child("Letter", true, false) as Label
		var number_label := tile.find_child("Number", true, false) as Label
		if letter_label:
			letter_label.text = letters[i]
			letter_label.add_theme_font_size_override("font_size", letter_size)
			letter_label.add_theme_color_override(
				"font_color",
				TITLE_LETTER_GREEN if revealed_green else Color(0.364706, 0.25098, 0.215686, 1)
			)
		if number_label:
			number_label.text = str(_showcase_cipher_number(letters[i]))
			number_label.add_theme_font_size_override("font_size", number_size)


func _layout_title_row(row: HBoxContainer) -> void:
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var parent := row.get_parent() as Control
	var available := parent.size.x if parent != null else row.size.x
	available = maxf(available - TITLE_SAFETY_PX * 2.0, 1.0)
	var visible_tiles: Array[Control] = []
	for child in row.get_children():
		if child is Control and (child as Control).visible:
			visible_tiles.append(child)
	if visible_tiles.is_empty():
		return
	var count := visible_tiles.size()
	var sep := float(row.get_theme_constant("separation"))
	var spanish_max := (
		(available - sep * float(TITLE_SPANISH_LETTERS - 1))
		/ float(TITLE_SPANISH_LETTERS)
		* TITLE_SPANISH_WIDTH_SCALE
	)
	var fit_width := (available - sep * float(count - 1)) / float(count)
	var tile_width := minf(fit_width, spanish_max)
	var font_scale := clampf(tile_width / spanish_max, 0.42, 1.0)
	var letter_size := maxi(roundi(float(TITLE_LETTER_SIZE) * font_scale), 32)
	var number_size := maxi(roundi(float(TITLE_NUMBER_SIZE) * font_scale), 16)
	for tile in visible_tiles:
		tile.size_flags_horizontal = 0
		tile.custom_minimum_size.x = tile_width
		var letter_label := tile.find_child("Letter", true, false) as Label
		var number_label := tile.find_child("Number", true, false) as Label
		if letter_label:
			letter_label.add_theme_font_size_override("font_size", letter_size)
		if number_label:
			number_label.add_theme_font_size_override("font_size", number_size)
		_nudge_title_number(tile, number_size)


func _nudge_title_number(tile: Control, number_size: int) -> void:
	var number := tile.find_child("Number", true, false) as Label
	if number == null:
		return
	var font := number.get_theme_font("font")
	var line_h := float(number_size) * 1.2
	if font:
		line_h = font.get_height(number_size)
	var parent := number.get_parent()
	if parent != tile:
		var reserved_h := number.size.y
		if reserved_h < 1.0:
			reserved_h = line_h
		var slot := Control.new()
		slot.name = "NumberSlot"
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.custom_minimum_size.y = reserved_h
		var idx := number.get_index()
		parent.add_child(slot)
		parent.move_child(slot, idx)
		var spacer := parent.get_child(0) as Control
		if spacer and spacer != slot and spacer.name.begins_with("Spacer"):
			spacer.visible = false
		number.reparent(tile)
	number.set_anchors_preset(Control.PRESET_TOP_WIDE)
	number.offset_left = 0.0
	number.offset_right = 0.0
	number.offset_top = TITLE_NUMBER_TOP_GAP
	number.offset_bottom = TITLE_NUMBER_TOP_GAP + line_h
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _update_version_label() -> void:
	if version_label == null:
		return
	version_label.text = "%s\n%s" % [tr("Version"), PlayerPrefs.version_display()]

func _on_app_version_changed(_version_text: String) -> void:
	_update_version_label()

func _refresh_audio_buttons(_unused: Variant = null) -> void:
	_set_audio_button_state(button_music, SoundManager.is_music_enabled())
	_set_audio_button_state(button_fx, SoundManager.is_fx_enabled())


func _set_audio_button_state(button: Button, enabled: bool) -> void:
	if button == null:
		return
	var icon := button.get_node_or_null("Icon") as TextureRect
	var slash := button.get_node_or_null("Slash") as TextureRect
	if icon:
		icon.modulate = Color(0.32, 0.2, 0.12, 1.0 if enabled else 0.38)
	if slash:
		slash.visible = not enabled


func _on_button_music_pressed() -> void:
	SoundManager.play("ButtonClick")
	SoundManager.toggle_music_enabled()


func _on_button_fx_pressed() -> void:
	var enabling := not SoundManager.is_fx_enabled()
	if not enabling:
		SoundManager.play("ButtonClick")
	SoundManager.toggle_fx_enabled()
	if enabling:
		SoundManager.play("ButtonClick")


func _go_to(path: String, blink_node: Control = null) -> void:
	TransitionScreen.transition_to_black()
	if blink_node is Button:
		GameManager.button_blink(blink_node)
	elif blink_node is TextureButton:
		GameManager.button_blink_texture(blink_node)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file(path)

func _on_button_settings_pressed() -> void:
	_go_to("res://scenes/MenuSettings.tscn", button_settings)

func _on_button_play_pressed() -> void:
	_go_to("res://scenes/MenuSelectCategory.tscn", button_play)

func _on_button_shop_pressed() -> void:
	SoundManager.play("ButtonClick")
	if button_shop:
		GameManager.button_blink(button_shop)


func _on_button_daily_pressed() -> void:
	_go_to("res://scenes/MenuDaily.tscn", button_daily)


func _layout_home_buttons() -> void:
	var shortcuts := get_node_or_null("Panel/Shortcuts") as HBoxContainer
	if shortcuts:
		var daily_col := shortcuts.get_node_or_null("ColDaily")
		var library_col := shortcuts.get_node_or_null("ColLibrary")
		var shop_col := shortcuts.get_node_or_null("ColShop")
		if daily_col:
			shortcuts.move_child(daily_col, 0)
		if library_col:
			shortcuts.move_child(library_col, 1)
		if shop_col:
			shortcuts.move_child(shop_col, 2)
	var actions := get_node_or_null("Panel/Actions") as HBoxContainer
	if actions:
		var stats_col := actions.get_node_or_null("ColStats")
		var ranking_col := actions.get_node_or_null("ColRanking")
		var tutorial_col := actions.get_node_or_null("ColTutorial")
		if stats_col:
			actions.move_child(stats_col, 0)
		if ranking_col:
			actions.move_child(ranking_col, 1)
		if tutorial_col:
			actions.move_child(tutorial_col, 2)
	_refresh_daily_button()


func _refresh_daily_button() -> void:
	if button_daily == null:
		return
	var done := PlayerPrefs.is_daily_completed_today()
	var title := button_daily.get_node_or_null("Label") as Label
	if title:
		title.text = ("✓  %s" % tr("DailyChallenge")) if done else tr("DailyChallenge")
		title.anchor_top = 0.62 if done else 0.67
		title.anchor_bottom = 0.84 if done else 0.93
	var status := _ensure_daily_status_label()
	if status:
		status.visible = done
		status.text = tr("DailyCompletedShort")
	var badge := _ensure_today_badge()
	if badge:
		badge.visible = not done
		var badge_label := badge.get_node_or_null("Label") as Label
		if badge_label:
			badge_label.text = tr("Today")


func _ensure_daily_status_label() -> Label:
	if button_daily == null:
		return null
	var existing := button_daily.get_node_or_null("Status") as Label
	if existing:
		return existing
	var status := Label.new()
	status.name = "Status"
	status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	status.anchor_left = 0.04
	status.anchor_top = 0.80
	status.anchor_right = 0.96
	status.anchor_bottom = 0.97
	status.offset_left = 0
	status.offset_top = 0
	status.offset_right = 0
	status.offset_bottom = 0
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color", Color(0.22, 0.5, 0.3, 1))
	status.add_theme_font_size_override("font_size", 24)
	var font := button_daily.get_node_or_null("Label") as Label
	if font and font.get_theme_font("font"):
		status.add_theme_font_override("font", font.get_theme_font("font"))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_daily.add_child(status)
	return status


func _ensure_today_badge() -> Panel:
	if button_daily == null:
		return null
	var existing := button_daily.get_node_or_null("TodayBadge") as Panel
	if existing:
		return existing
	var badge := Panel.new()
	badge.name = "TodayBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.offset_left = -118.0
	badge.offset_top = 10.0
	badge.offset_right = -10.0
	badge.offset_bottom = 52.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.82, 0.16, 0.14, 1)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.29, 0.12, 0.08, 0.28)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	badge.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.name = "Label"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = tr("Today")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 22)
	var font := button_daily.get_node_or_null("Label") as Label
	if font and font.get_theme_font("font"):
		label.add_theme_font_override("font", font.get_theme_font("font"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)
	button_daily.add_child(badge)
	return badge


func _on_button_library_pressed() -> void:
	_go_to("res://scenes/MenuLibrary.tscn", button_library)


func _on_button_ranking_pressed() -> void:
	HistoryManager.get_results_filtered("Todas", -1)
	_go_to("res://scenes/LeaderboardFINAL.tscn", button_ranking)

func _on_button_stats_pressed() -> void:
	_go_to("res://scenes/MenuStats.tscn", button_stats)

func _on_button_tutorial_pressed() -> void:
	_go_to("res://scenes/MenuTutorial.tscn", button_tutorial)
