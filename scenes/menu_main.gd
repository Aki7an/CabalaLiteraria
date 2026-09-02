extends Control

@onready var button_settings: Button = %ButtonSettings
@onready var button_play: Button = %ButtonPlay
@onready var button_ranking: Button = %ButtonRanking
@onready var button_stats: Button = %ButtonStats
@onready var button_tutorial: Button = %ButtonTutorial
@onready var version_label: Label = %VersionLabel
@onready var stars_quick_count: Label = %StarsQuickCount
@onready var stars_crypto_count: Label = %StarsCryptoCount

func _ready() -> void:
	_apply_audio()
	_apply_labels()
	_apply_showcase_word()
	_update_version_label()
	_refresh_star_totals()
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
	var cipher := get_node_or_null("Panel/Brand/Cipher") as Label
	if cipher:
		cipher.text = tr("Cipher")
	var letter := get_node_or_null("Panel/Brand/Letter") as Label
	if letter:
		letter.text = tr("Letter")
	var ranking := get_node_or_null("Panel/Actions/ColRanking/ButtonRanking/Label") as Label
	if ranking:
		ranking.text = tr("Leaderboard")
	var stats := get_node_or_null("Panel/Actions/ColStats/ButtonStats/Label") as Label
	if stats:
		stats.text = tr("Stats")
	var tutorial := get_node_or_null("Panel/Actions/ColTutorial/ButtonTutorial/Label") as Label
	if tutorial:
		tutorial.text = tr("Tutorial")
	var play := get_node_or_null("Panel/PlayWrap/ButtonPlay/Play") as Label
	if play:
		play.text = tr("PLAY")


func _showcase_word() -> String:
	var translated := tr("ShowcaseWord").strip_edges()
	if not translated.is_empty() and translated != "ShowcaseWord":
		return translated
	match TranslationServer.get_locale().substr(0, 2):
		"en", "de", "fr":
			return "CODE"
		"eu":
			return "KODEA"
		"it":
			return "CODICE"
		"pt":
			return "CÓDIGO"
		_:
			return "CÓDIGO"


func _showcase_cipher_number(letter: String) -> int:
	var key := GameManager._hint_letter_key(letter)
	if key.length() != 1:
		return 0
	var code := key.unicode_at(0)
	if code >= 65 and code <= 90:
		return code - 64
	return 0


func _apply_showcase_word() -> void:
	var showcase := get_node_or_null("%Showcase") as HBoxContainer
	if showcase == null:
		showcase = get_node_or_null("Panel/Showcase") as HBoxContainer
	if showcase == null or showcase.get_child_count() == 0:
		return
	var letters: Array[String] = []
	var word := _showcase_word().to_upper()
	for i in word.length():
		var ch := word.substr(i, 1)
		if GameManager.is_excluded_character(ch):
			continue
		letters.append(ch)
	if letters.is_empty():
		return
	var template := showcase.get_child(0) as Control
	while showcase.get_child_count() < letters.size():
		showcase.add_child(template.duplicate())
	var letter_size := 140
	var number_size := 60
	match letters.size():
		5:
			letter_size = 108
			number_size = 48
		6:
			letter_size = 88
			number_size = 40
		_:
			if letters.size() > 6:
				letter_size = 72
				number_size = 34
	for i in showcase.get_child_count():
		var tile := showcase.get_child(i) as Control
		if i >= letters.size():
			tile.visible = false
			continue
		tile.visible = true
		var letter_label := tile.find_child("Letter", true, false) as Label
		var number_label := tile.find_child("Number", true, false) as Label
		if letter_label:
			letter_label.text = letters[i]
			letter_label.add_theme_font_size_override("font_size", letter_size)
		if number_label:
			number_label.text = str(_showcase_cipher_number(letters[i]))
			number_label.add_theme_font_size_override("font_size", number_size)

func _update_version_label() -> void:
	if version_label == null:
		return
	version_label.text = "%s\n%s" % [tr("Version"), PlayerPrefs.version_display()]

func _on_app_version_changed(_version_text: String) -> void:
	_update_version_label()

func _apply_audio() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),
		linear_to_db(PlayerPrefs.volumen_musica))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SoundFx"),
		linear_to_db(PlayerPrefs.volumen_fx))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not PlayerPrefs.mute_musica)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SoundFx"), not PlayerPrefs.mute_fx)

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

func _on_button_ranking_pressed() -> void:
	HistoryManager.get_results_filtered("Todas", -1)
	_go_to("res://scenes/LeaderboardFINAL.tscn", button_ranking)

func _on_button_stats_pressed() -> void:
	_go_to("res://scenes/MenuStats.tscn", button_stats)

func _on_button_tutorial_pressed() -> void:
	_go_to("res://scenes/MenuTutorial.tscn", button_tutorial)
