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
const TITLE_LETTER_SIZE := 96
const TITLE_NUMBER_SIZE := 42
const TITLE_NUMBER_TOP_GAP := 12.0
const TITLE_LETTER_EMBOLDEN := 0.85
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const FONT_TITLE_LETTER: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const ICON_LOCK: Texture2D = preload("res://images/ui_icon_lock.svg")
const PATH_SHOP := "res://scenes/MenuShop.tscn"

var _title_letter_font: FontVariation

func _ready() -> void:
	SoundManager.apply_audio_prefs()
	_refresh_audio_buttons()
	if not SignalManager.audio_prefs_changed.is_connected(_refresh_audio_buttons):
		SignalManager.audio_prefs_changed.connect(_refresh_audio_buttons)
	GameManager.session_source = GameManager.SOURCE_NONE
	GameManager.locked_record_stars = -1
	_apply_labels()
	_apply_title_tiles()
	_update_version_label()
	_refresh_star_totals()
	_refresh_daily_button()
	if not SignalManager.full_game_changed.is_connected(_refresh_daily_button):
		SignalManager.full_game_changed.connect(_refresh_daily_button)
	if not HistoryManager.stats_updated.is_connected(_refresh_star_totals):
		HistoryManager.stats_updated.connect(_refresh_star_totals)
	SignalManager.app_version_changed.connect(_on_app_version_changed)
	SignalManager.fit_text.emit()
	GameManager.reset_game_paremeters()
	GameManager.resetear_partida_terminada()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
		GameManager.advance_daily_to_next()
		_refresh_daily_button()
		get_viewport().set_input_as_handled()


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
	_go_to("res://scenes/MenuShop.tscn", button_shop)


func _on_button_daily_pressed() -> void:
	if not GameManager.has_full_game():
		_show_daily_locked_dialog()
		return
	_go_to("res://scenes/MenuDaily.tscn", button_daily)


func _refresh_daily_button() -> void:
	if button_daily == null:
		return
	var locked := not GameManager.has_full_game()
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
	var badge := button_daily.get_node_or_null("TodayBadge") as Control
	if badge:
		badge.visible = not locked and not done
		var badge_label := badge.get_node_or_null("Label") as Label
		if badge_label:
			badge_label.text = tr("Today")
	var stamp := button_daily.get_node_or_null("CompletedStamp") as Control
	if stamp:
		stamp.visible = not locked and done
		var stamp_label := stamp.get_node_or_null("Label") as Label
		if stamp_label:
			var done_text := tr("DailyDone")
			stamp_label.text = "HECHO" if done_text == "DailyDone" else done_text
		if stamp.visible:
			call_deferred("_center_stamp_pivot", stamp)


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
	_go_to("res://scenes/MenuTutorial.tscn", button_tutorial)
