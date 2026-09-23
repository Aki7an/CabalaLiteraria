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
@onready var stars_quick_icon: TextureRect = $Panel/StarTotals/Rows/QuickRow/Star
@onready var stars_crypto_icon: TextureRect = $Panel/StarTotals/Rows/CryptoRow/Star

const TITLE_LETTER_GREEN := Color(0.22, 0.62, 0.28, 1)
const TITLE_SPANISH_LETTERS := 5
const TITLE_SPANISH_WIDTH_SCALE := 0.8
const TITLE_SAFETY_PX := 24.0
const TITLE_LETTER_SIZE := 96
const TITLE_NUMBER_SIZE := 42
const TITLE_NUMBER_TOP_GAP := 12.0
const TITLE_LETTER_EMBOLDEN := 0.85
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const FONT_TITLE_LETTER: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const ICON_LOCK: Texture2D = preload("res://images/ui_icon_lock.svg")
const INTRO_ICON_MIRA: Texture2D = preload("res://images/intro_icon_mira.png")
const INTRO_ICON_DESCIFRA: Texture2D = preload("res://images/intro_icon_descifra.png")
const INTRO_ICON_DESCUBRE: Texture2D = preload("res://images/intro_icon_descubre.png")
const INTRO_WORD_COLORS: Array[Color] = [
	Color(0.48, 0.24, 0.10, 1),
	Color(0.82, 0.42, 0.08, 1),
	Color(0.98, 0.62, 0.12, 1),
]
const INTRO_LETTER_SIZE := 108
const INTRO_ICON_SIZE := 176
const PATH_SHOP := "res://scenes/MenuShop.tscn"

var _title_letter_font: FontVariation
var _play_blink_token := 0

func _ready() -> void:
	SoundManager.apply_audio_prefs()
	_refresh_audio_buttons()
	if not SignalManager.audio_prefs_changed.is_connected(_refresh_audio_buttons):
		SignalManager.audio_prefs_changed.connect(_refresh_audio_buttons)
	GameManager.session_source = GameManager.SOURCE_NONE
	GameManager.locked_record_stars = -1
	_apply_labels()
	_update_version_label()
	_refresh_star_totals()
	if _should_play_main_intro():
		_prepare_intro_hidden()
	call_deferred("_boot_visuals")
	_refresh_daily_button()
	if not SignalManager.full_game_changed.is_connected(_refresh_daily_button):
		SignalManager.full_game_changed.connect(_refresh_daily_button)
	if not SignalManager.daily_puzzle_changed.is_connected(_refresh_daily_button):
		SignalManager.daily_puzzle_changed.connect(_refresh_daily_button)
	if not HistoryManager.stats_updated.is_connected(_refresh_star_totals):
		HistoryManager.stats_updated.connect(_refresh_star_totals)
	SignalManager.app_version_changed.connect(_on_app_version_changed)
	SignalManager.fit_text.emit()
	GameManager.reset_game_paremeters()
	GameManager.resetear_partida_terminada()


func _refresh_star_totals(_unused: Variant = null) -> void:
	var dashboard: Dictionary = HistoryManager.get_stats_dashboard()
	var quick := int(dashboard.get("stars_quick", 0))
	var crypto := int(dashboard.get("stars_cryptogram", 0))
	if stars_quick_count:
		stars_quick_count.text = str(StarCollectOverlay.displayed_total(quick, GameManager.MODE_QUICK))
	if stars_crypto_count:
		stars_crypto_count.text = str(StarCollectOverlay.displayed_total(crypto, GameManager.MODE_CRYPTOGRAM))


func _play_pending_star_collect() -> void:
	var covering := StarCollectOverlay.is_covering()
	if covering:
		StarCollectOverlay.fade_white_cover(StarCollectOverlay.collect_duration())
	if not StarCollectOverlay.has_pending():
		if covering:
			await get_tree().create_timer(0.85).timeout
		return
	var is_crypto: bool = StarCollectOverlay.pending_mode == GameManager.MODE_CRYPTOGRAM
	var icon := stars_crypto_icon if is_crypto else stars_quick_icon
	var counter := stars_crypto_count if is_crypto else stars_quick_count
	var dashboard: Dictionary = HistoryManager.get_stats_dashboard()
	var actual: int = int(dashboard.get("stars_cryptogram" if is_crypto else "stars_quick", 0))
	var start_value: int = StarCollectOverlay.displayed_total(actual, StarCollectOverlay.pending_mode)
	if counter:
		counter.text = str(start_value)
	await StarCollectOverlay.play_to_target(icon, counter, start_value)
	_refresh_star_totals()

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
	await get_tree().process_frame


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


func _title_letter_typeface() -> Font:
	if _title_letter_font == null:
		_title_letter_font = FontVariation.new()
		_title_letter_font.base_font = FONT_TITLE_LETTER
		_title_letter_font.variation_embolden = TITLE_LETTER_EMBOLDEN
	return _title_letter_font


func _style_title_letter(letter_label: Label, letter_size: int, color: Color) -> void:
	letter_label.add_theme_font_override("font", _title_letter_typeface())
	letter_label.add_theme_font_size_override("font_size", letter_size)
	letter_label.add_theme_color_override("font_color", color)
	letter_label.add_theme_constant_override("outline_size", 5)
	letter_label.add_theme_color_override("font_outline_color", color)


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
			_style_title_letter(
				letter_label,
				letter_size,
				TITLE_LETTER_GREEN if revealed_green else Color(0.364706, 0.25098, 0.215686, 1)
			)
		if number_label:
			number_label.text = str(_showcase_cipher_number(letters[i]))
			number_label.add_theme_font_size_override("font_size", number_size)


func _title_row_metrics(row: HBoxContainer) -> Dictionary:
	var parent := row.get_parent() as Control
	var available := parent.size.x if parent != null else row.size.x
	available = maxf(available - TITLE_SAFETY_PX * 2.0, 1.0)
	var count := _visible_tiles(row).size()
	if count <= 0:
		return {"width": 0.0, "letter": TITLE_LETTER_SIZE, "number": TITLE_NUMBER_SIZE}
	var sep := float(row.get_theme_constant("separation"))
	var spanish_max := (
		(available - sep * float(TITLE_SPANISH_LETTERS - 1))
		/ float(TITLE_SPANISH_LETTERS)
		* TITLE_SPANISH_WIDTH_SCALE
	)
	var fit_width := (available - sep * float(count - 1)) / float(count)
	var tile_width := minf(fit_width, spanish_max)
	var font_scale := clampf(tile_width / maxf(spanish_max, 1.0), 0.42, 1.0)
	return {
		"width": tile_width,
		"letter": maxi(roundi(float(TITLE_LETTER_SIZE) * font_scale), 32),
		"number": maxi(roundi(float(TITLE_NUMBER_SIZE) * font_scale), 16),
	}


func _layout_title_row(row: HBoxContainer) -> void:
	if row == null:
		return
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var visible_tiles := _visible_tiles(row)
	if visible_tiles.is_empty():
		return
	var metrics := _title_row_metrics(row)
	var tile_width: float = metrics["width"]
	var letter_size: int = metrics["letter"]
	var number_size: int = metrics["number"]
	for tile in visible_tiles:
		tile.size_flags_horizontal = 0
		tile.custom_minimum_size.x = tile_width
		tile.size.x = tile_width
		tile.clip_contents = true
		var letter_label := tile.find_child("Letter", true, false) as Label
		var number_label := tile.find_child("Number", true, false) as Label
		if letter_label:
			letter_label.add_theme_font_override("font", _title_letter_typeface())
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
	_play_blink_token += 1
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
	if not PlayerPrefs.onboarding_completed:
		_start_onboarding()
		return
	_go_to("res://scenes/MenuSelectCategory.tscn", button_play)


func _start_onboarding() -> void:
	_play_blink_token += 1
	TransitionScreen.transition_to_black()
	if button_play is Button:
		GameManager.button_blink(button_play)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	GameManager.prepare_onboarding_puzzle(1)
	GameManager.launch_prepared_game()


func _on_button_shop_pressed() -> void:
	_go_to("res://scenes/MenuShop.tscn", button_shop)


func _on_button_daily_pressed() -> void:
	_go_to("res://scenes/MenuDaily.tscn", button_daily)


func _refresh_daily_button() -> void:
	if button_daily == null:
		return
	var locked := not GameManager.has_daily_access()
	var done := PlayerPrefs.is_daily_completed_today()
	var title := button_daily.get_node_or_null("Label") as Label
	if title:
		title.text = tr("DailyChallenge")
		title.modulate.a = 1.0
	var status := button_daily.get_node_or_null("Status") as Label
	if status:
		status.visible = false
	var daily_icon := button_daily.get_node_or_null("Icon") as CanvasItem
	if daily_icon:
		daily_icon.modulate.a = 1.0
	var lock := button_daily.get_node_or_null("PurchaseLock") as Control
	if lock:
		lock.visible = locked
	var badge := button_daily.get_node_or_null("TodayBadge") as Panel
	if badge:
		badge.visible = not locked
		var badge_label := badge.get_node_or_null("Label") as Label
		if badge_label:
			if done:
				var done_text := tr("DailyDone")
				badge_label.text = "HECHO" if done_text == "DailyDone" else done_text
			else:
				badge_label.text = tr("Today")
		_style_daily_badge(badge, done)
	var stamp := button_daily.get_node_or_null("CompletedStamp") as Control
	if stamp:
		stamp.visible = false


func _style_daily_badge(badge: Panel, done: bool) -> void:
	var style := StyleBoxFlat.new()
	if done:
		style.bg_color = Color(0.22, 0.62, 0.28, 1)
		style.shadow_color = Color(0.08, 0.29, 0.12, 0.28)
	else:
		style.bg_color = Color(0.82, 0.16, 0.14, 1)
		style.shadow_color = Color(0.29, 0.12, 0.08, 0.28)
	style.set_corner_radius_all(18)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	badge.add_theme_stylebox_override("panel", style)
	badge.offset_left = -36.0 if done else -15.88
	badge.offset_right = -4.0 if done else -16.05


func _show_daily_locked_dialog() -> void:
	if get_node_or_null("DailyLockDialog") != null:
		return
	SoundManager.play("ButtonClick")
	if button_daily:
		GameManager.button_blink(button_daily)
	var overlay := ColorRect.new()
	overlay.name = "DailyLockDialog"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.08, 0.04, 0.02, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 80
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(980, 0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 0.965, 0.86, 1)
	card_style.border_color = Color(0.62, 0.4, 0.16, 0.46)
	card_style.set_border_width_all(4)
	card_style.border_width_bottom = 9
	card_style.set_corner_radius_all(40)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 36)
	card.add_child(margin)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 24)
	margin.add_child(inner)
	var lock := TextureRect.new()
	lock.texture = ICON_LOCK
	lock.custom_minimum_size = Vector2(80, 80)
	lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(lock)
	var title := Label.new()
	title.add_theme_font_override("font", FONT_UI)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08, 1))
	title.text = tr("DailyChallenge")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(title)
	var body := Label.new()
	body.add_theme_font_override("font", FONT_UI)
	body.add_theme_font_size_override("font_size", 36)
	body.add_theme_color_override("font_color", Color(0.28, 0.17, 0.1, 1))
	body.text = tr("DailyLockedBody")
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(body)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 24)
	inner.add_child(buttons)
	var cancel := Button.new()
	cancel.text = tr("Back")
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size = Vector2(0, 110)
	cancel.add_theme_font_override("font", FONT_UI)
	cancel.add_theme_font_size_override("font_size", 36)
	cancel.add_theme_color_override("font_color", Color(0.32, 0.18, 0.08, 1))
	var cancel_style := StyleBoxFlat.new()
	cancel_style.bg_color = Color(1, 0.982, 0.92, 1)
	cancel_style.border_color = Color(0.66, 0.44, 0.2, 0.7)
	cancel_style.set_border_width_all(3)
	cancel_style.border_width_bottom = 8
	cancel_style.set_corner_radius_all(30)
	cancel.add_theme_stylebox_override("normal", cancel_style)
	cancel.add_theme_stylebox_override("hover", cancel_style)
	cancel.add_theme_stylebox_override("pressed", cancel_style)
	cancel.pressed.connect(func() -> void:
		SoundManager.play("ButtonClick")
		overlay.queue_free()
	)
	buttons.add_child(cancel)
	var shop := Button.new()
	var shop_text := tr("ShopGoToStore")
	if shop_text == "ShopGoToStore":
		shop_text = "Ir a la tienda"
	shop.text = shop_text
	shop.focus_mode = Control.FOCUS_NONE
	shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop.custom_minimum_size = Vector2(0, 110)
	shop.add_theme_font_override("font", FONT_UI)
	shop.add_theme_font_size_override("font_size", 36)
	shop.add_theme_color_override("font_color", Color.WHITE)
	var shop_style := StyleBoxFlat.new()
	shop_style.bg_color = Color(0.96, 0.51, 0.01, 1)
	shop_style.border_color = Color(0.83, 0.41, 0.02, 1)
	shop_style.set_border_width_all(3)
	shop_style.border_width_bottom = 8
	shop_style.set_corner_radius_all(30)
	shop.add_theme_stylebox_override("normal", shop_style)
	shop.add_theme_stylebox_override("hover", shop_style)
	shop.add_theme_stylebox_override("pressed", shop_style)
	shop.pressed.connect(func() -> void:
		overlay.queue_free()
		_go_to(PATH_SHOP, button_shop)
	)
	buttons.add_child(shop)


func _center_stamp_pivot(stamp: Control) -> void:
	if is_instance_valid(stamp):
		stamp.pivot_offset = stamp.size * 0.5


func _on_button_library_pressed() -> void:
	_go_to("res://scenes/MenuLibrary.tscn", button_library)


func _on_button_ranking_pressed() -> void:
	HistoryManager.get_results_filtered("Todas", -1)
	_go_to("res://scenes/LeaderboardFINAL.tscn", button_ranking)

func _on_button_stats_pressed() -> void:
	_go_to("res://scenes/MenuStats.tscn", button_stats)

func _on_button_tutorial_pressed() -> void:
	GameManager.set_go_to_game_disable()
	_go_to("res://scenes/MenuTutorial.tscn", button_tutorial)


func _boot_visuals() -> void:
	await _apply_title_tiles()
	if _should_play_main_intro():
		await _play_main_intro()
		GameManager.main_menu_intro_played = true
	await _play_pending_star_collect()
	_start_play_blink_loop()


func _should_play_main_intro() -> bool:
	if Engine.has_meta("store_screenshot"):
		return false
	if GameManager.main_menu_intro_played:
		return false
	if StarCollectOverlay.has_pending() or StarCollectOverlay.is_covering():
		return false
	return true


func _intro_chrome() -> Array[Control]:
	var nodes: Array[Control] = []
	for node in [
		$Panel/StarTotals,
		button_fx,
		button_music,
		button_settings,
		$Panel/PlayWrap,
		$Panel/Shortcuts,
		$Panel/Actions,
		version_label,
	]:
		if node is Control:
			nodes.append(node)
	return nodes


func _prepare_intro_hidden() -> void:
	for node in _intro_chrome():
		node.modulate.a = 0.0
		if node != get_node_or_null("Panel/PlayWrap"):
			node.visible = false
	var tagline := get_node_or_null("Panel/TaglineRow") as Control
	if tagline:
		tagline.modulate.a = 0.0
	if button_play:
		button_play.disabled = true
		button_play.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _play_main_intro() -> void:
	var panel := $Panel as Control
	if panel:
		panel.clip_contents = false
	var wash := _ensure_intro_wash()
	var words := _ensure_intro_words()
	var blocker := _ensure_intro_blocker()
	var cipher_row := _title_cipher_row()
	var letter_row := get_node_or_null("Panel/TitleBlock/ShowcaseLetra") as HBoxContainer
	_set_row_tiles_alpha(cipher_row, 0.0)
	_set_row_tiles_alpha(letter_row, 0.0)
	if wash:
		wash.modulate.a = 1.0
		var wash_tw := create_tween()
		wash_tw.tween_property(wash, "modulate:a", 0.0, 2.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_layout_title_row(cipher_row)
	_layout_title_row(letter_row)
	await get_tree().process_frame
	var cipher_size := _row_final_tile_size(cipher_row)
	var letter_size := _row_final_tile_size(letter_row)
	_lock_title_tile_size(cipher_row, cipher_size)
	_lock_title_tile_size(letter_row, letter_size)
	await get_tree().process_frame
	await _animate_title_row(cipher_row, 1.0, cipher_size)
	await _animate_title_row(letter_row, -1.0, letter_size)
	_layout_title_row(cipher_row)
	_layout_title_row(letter_row)
	_lock_title_tile_size(cipher_row, _row_final_tile_size(cipher_row))
	_lock_title_tile_size(letter_row, _row_final_tile_size(letter_row))
	await _fade_control(get_node_or_null("Panel/TaglineRow") as Control, 1.0, 0.28)
	await _fade_intro_words(words, true)
	await get_tree().create_timer(1.35).timeout
	await _fade_intro_words(words, false)
	if words:
		words.visible = false
	await _slide_chrome_in()
	await _animate_play_entrance()
	if wash:
		wash.queue_free()
	var overlay := $Panel.get_node_or_null("IntroOverlay")
	if overlay:
		overlay.queue_free()
	if blocker:
		blocker.queue_free()
	if panel:
		panel.clip_contents = true
	if button_play:
		button_play.disabled = false
		button_play.mouse_filter = Control.MOUSE_FILTER_STOP
	var stars := get_node_or_null("Panel/StarTotals") as Control
	if stars:
		stars.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ensure_intro_wash() -> ColorRect:
	var panel := $Panel as Control
	var existing := panel.get_node_or_null("IntroWash") as ColorRect
	if existing:
		return existing
	var wash := ColorRect.new()
	wash.name = "IntroWash"
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color.WHITE
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(wash)
	var fondo := panel.get_node_or_null("Fondo2")
	if fondo:
		panel.move_child(wash, fondo.get_index() + 1)
	return wash


func _ensure_intro_blocker() -> ColorRect:
	var existing := get_node_or_null("IntroBlocker") as ColorRect
	if existing:
		return existing
	var blocker := ColorRect.new()
	blocker.name = "IntroBlocker"
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0, 0, 0, 0)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.z_index = 40
	add_child(blocker)
	return blocker


func _intro_letter_color(t: float) -> Color:
	var x := clampf(t, 0.0, 1.0)
	if x <= 0.5:
		return INTRO_WORD_COLORS[0].lerp(INTRO_WORD_COLORS[1], x * 2.0)
	return INTRO_WORD_COLORS[1].lerp(INTRO_WORD_COLORS[2], (x - 0.5) * 2.0)


func _intro_word_text(key: String, fallback: String) -> String:
	var text := tr(key).strip_edges()
	if text.is_empty() or text == key:
		text = fallback
	return text.to_upper()


func _ensure_intro_words() -> HBoxContainer:
	var panel := $Panel as Control
	var existing := panel.get_node_or_null("IntroWords")
	if existing:
		existing.queue_free()
	var box := HBoxContainer.new()
	box.name = "IntroWords"
	box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	box.anchor_left = 0.04
	box.anchor_right = 0.96
	box.anchor_top = 0.372
	box.anchor_bottom = 0.708
	box.offset_left = 0.0
	box.offset_right = 0.0
	box.offset_top = 0.0
	box.offset_bottom = 0.0
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var keys := ["IntroObserve", "IntroDecipher", "IntroDiscover"]
	var fallbacks := ["MIRA", "DESCIFRA", "DESCUBRE"]
	var icons: Array[Texture2D] = [INTRO_ICON_MIRA, INTRO_ICON_DESCIFRA, INTRO_ICON_DESCUBRE]
	var words: Array[String] = []
	var total_letters := 0
	var max_letters := 1
	for i in keys.size():
		var word := _intro_word_text(keys[i], fallbacks[i])
		words.append(word)
		total_letters += word.length()
		max_letters = maxi(max_letters, word.length())
	var view_w := size.x if size.x > 2.0 else 1206.0
	var col_w := (view_w * 0.92 - 16.0) / 3.0
	var letter_size := clampi(int((col_w - 8.0) / float(max_letters) * 1.5), 42, 78)
	var icon_side := mini(INTRO_ICON_SIZE, int(col_w * 0.62))
	var letter_index := 0
	for i in keys.size():
		var col := VBoxContainer.new()
		col.name = keys[i]
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 12)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.modulate.a = 0.0
		var icon := TextureRect.new()
		icon.texture = icons[i]
		icon.custom_minimum_size = Vector2(icon_side, icon_side)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(icon)
		var letters := HBoxContainer.new()
		letters.alignment = BoxContainer.ALIGNMENT_CENTER
		letters.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		letters.add_theme_constant_override("separation", 1)
		letters.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var word: String = words[i]
		for j in word.length():
			var t := 0.0 if total_letters <= 1 else float(letter_index) / float(total_letters - 1)
			var glyph := Label.new()
			glyph.text = word.substr(j, 1)
			glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_style_title_letter(glyph, letter_size, _intro_letter_color(t))
			letters.add_child(glyph)
			letter_index += 1
		col.add_child(letters)
		box.add_child(col)
	panel.add_child(box)
	return box


func _title_cipher_row() -> HBoxContainer:
	var row := get_node_or_null("%Showcase") as HBoxContainer
	if row == null:
		row = get_node_or_null("Panel/TitleBlock/Showcase") as HBoxContainer
	return row


func _visible_tiles(row: HBoxContainer) -> Array[Control]:
	var tiles: Array[Control] = []
	if row == null:
		return tiles
	for child in row.get_children():
		if child is Control and (child as Control).visible:
			tiles.append(child)
	return tiles


func _set_row_tiles_alpha(row: HBoxContainer, alpha: float) -> void:
	for tile in _visible_tiles(row):
		tile.modulate.a = alpha


func _row_final_tile_size(row: HBoxContainer) -> Vector2:
	if row == null:
		return Vector2.ZERO
	var metrics := _title_row_metrics(row)
	var width: float = metrics["width"]
	var tiles := _visible_tiles(row)
	var height := 0.0
	if not tiles.is_empty():
		height = maxf(tiles[0].size.y, tiles[0].custom_minimum_size.y)
	if width < 1.0 and not tiles.is_empty():
		width = tiles[0].custom_minimum_size.x
	if width < 1.0 and not tiles.is_empty():
		width = tiles[0].size.x
	if height < 1.0:
		height = width
	return Vector2(width, height)


func _lock_title_tile_size(row: HBoxContainer, tile_size: Vector2) -> void:
	if row == null or tile_size.x < 1.0 or tile_size.y < 1.0:
		return
	for tile in _visible_tiles(row):
		tile.size_flags_horizontal = 0
		tile.custom_minimum_size = tile_size
		tile.size = tile_size


func _intro_overlay() -> Control:
	var panel := $Panel as Control
	var existing := panel.get_node_or_null("IntroOverlay") as Control
	if existing:
		return existing
	var overlay := Control.new()
	overlay.name = "IntroOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 8
	panel.add_child(overlay)
	return overlay


func _animate_title_row(row: HBoxContainer, direction: float, tile_size: Vector2) -> void:
	var tiles := _visible_tiles(row)
	if tiles.is_empty():
		return
	if direction < 0.0:
		tiles.reverse()
		SoundManager.play("IntroLetra")
	else:
		SoundManager.play("IntroCifra")
	var overlay := _intro_overlay()
	var travel := size.x * 0.78
	var jobs: Array[Dictionary] = []
	for tile in tiles:
		var parent := tile.get_parent()
		var dummy := Control.new()
		dummy.name = "TileSlot"
		dummy.custom_minimum_size = tile_size
		dummy.size_flags_horizontal = 0
		dummy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dest := tile.global_position
		var idx := tile.get_index()
		parent.add_child(dummy)
		parent.move_child(dummy, idx)
		tile.reparent(overlay)
		tile.set_anchors_preset(Control.PRESET_TOP_LEFT)
		tile.size_flags_horizontal = 0
		tile.custom_minimum_size = tile_size
		tile.size = tile_size
		tile.modulate.a = 0.0
		tile.global_position = Vector2(dest.x + travel * direction, dest.y)
		jobs.append({
			"tile": tile,
			"dummy": dummy,
			"parent": parent,
			"dest": dest,
		})
	var last: Tween = null
	for i in jobs.size():
		var tile: Control = jobs[i]["tile"]
		var dest: Vector2 = jobs[i]["dest"]
		var tw := create_tween()
		tw.tween_callback(func() -> void:
			if is_instance_valid(tile):
				tile.modulate.a = 1.0
				tile.size = tile_size
		).set_delay(float(i) * 0.075)
		tw.tween_property(tile, "global_position", dest, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		last = tw
	if last:
		await last.finished
	for job in jobs:
		var tile: Control = job["tile"]
		var dummy: Control = job["dummy"]
		var parent: Node = job["parent"]
		if is_instance_valid(tile) and is_instance_valid(parent):
			var idx := dummy.get_index() if is_instance_valid(dummy) else parent.get_child_count()
			tile.reparent(parent)
			parent.move_child(tile, idx)
			tile.custom_minimum_size = tile_size
			tile.size = tile_size
			tile.modulate.a = 1.0
		if is_instance_valid(dummy):
			dummy.free()


func _fade_control(node: Control, alpha: float, duration: float) -> void:
	if node == null:
		return
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", alpha, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished


func _fade_intro_words(box: Control, appearing: bool) -> void:
	if box == null:
		return
	var last: Tween = null
	for i in box.get_child_count():
		var label := box.get_child(i) as CanvasItem
		if label == null:
			continue
		var tw := create_tween()
		var target := 1.0 if appearing else 0.0
		if appearing:
			var word_sfx := ["IntroWordObserva", "IntroWordDescifra", "IntroWordDescubre"]
			if i < word_sfx.size():
				SoundManager.play(word_sfx[i])
		tw.tween_property(label, "modulate:a", target, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		last = tw
		if i < box.get_child_count() - 1:
			await get_tree().create_timer(0.12).timeout
	if last:
		await last.finished


func _slide_chrome_in() -> void:
	var from_above: Array[Control] = []
	for node in [$Panel/StarTotals, button_fx, button_music, button_settings]:
		if node is Control:
			from_above.append(node)
	var from_below: Array[Control] = []
	for node in [$Panel/Shortcuts, $Panel/Actions, version_label]:
		if node is Control:
			from_below.append(node)
	var play_wrap := get_node_or_null("Panel/PlayWrap") as Control
	if play_wrap:
		play_wrap.modulate.a = 0.0
	for node in from_above + from_below:
		node.visible = true
	SoundManager.play("IntroButtons")
	var tw := create_tween()
	tw.set_parallel(true)
	for node in from_above:
		_tween_slide(tw, node, Vector2(0, -220), 0.48)
	for node in from_below:
		_tween_slide(tw, node, Vector2(0, 280), 0.48)
	await tw.finished
	for node in from_above + from_below:
		if is_instance_valid(node):
			node.modulate.a = 1.0


func _tween_slide(tw: Tween, node: Control, offset: Vector2, duration: float) -> void:
	if node == null:
		return
	var dest := node.position
	node.modulate.a = 1.0
	node.position = dest + offset
	tw.tween_property(node, "position", dest, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _animate_play_entrance() -> void:
	var wrap := get_node_or_null("Panel/PlayWrap") as Control
	if wrap == null or button_play == null:
		return
	wrap.modulate.a = 1.0
	var dest := wrap.position
	wrap.position = Vector2(dest.x - size.x, dest.y)
	SoundManager.play("IntroJugar")
	var overs := [78.0, 42.0, 20.0, 8.0]
	var tw := create_tween()
	tw.tween_property(wrap, "position:x", dest.x + overs[0], 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(wrap, "position:x", dest.x - overs[1], 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(wrap, "position:x", dest.x + overs[2], 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(wrap, "position:x", dest.x - overs[3], 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(wrap, "position:x", dest.x, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	wrap.position = dest
	button_play.modulate.a = 1.0
	await _blink_play_scale()


func _start_play_blink_loop() -> void:
	_play_blink_token += 1
	var token := _play_blink_token
	_run_play_blink_loop(token)


func _run_play_blink_loop(token: int) -> void:
	while is_inside_tree() and token == _play_blink_token:
		await get_tree().create_timer(10.0).timeout
		if token != _play_blink_token or not is_inside_tree():
			return
		if button_play == null or not button_play.is_visible_in_tree() or button_play.disabled:
			continue
		await _blink_play_scale()


func _blink_play_scale() -> void:
	if button_play == null or not is_instance_valid(button_play):
		return
	button_play.pivot_offset = button_play.size * 0.5
	button_play.scale = Vector2.ONE
	for _i in 2:
		SoundManager.play("IntroJugarBlink")
		var blink := create_tween()
		blink.tween_property(button_play, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		blink.tween_property(button_play, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await blink.finished
