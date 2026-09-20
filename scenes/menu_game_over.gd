extends ColorRect

const SCENE_FEEDBACK := "res://scenes/MenuFeedback.tscn"
const SCENE_MENU_MAIN := "res://scenes/MenuMain.tscn"
const SHARE_DIALOG := preload("res://scenes/share_solve_dialog.gd")
const STAR_EMPTY := Color(0.62, 0.51, 0.34, 0.28)
const GAP := 24.0
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const TYPING_SFX := preload("res://audio/Modular UI - Tech Typing-003.ogg")
const RESOLVED_HIT_SFX := preload("res://audio/HitSolid_SFXB.2355.wav")
const BANNER_CHIME_SFX := preload("res://audio/MultimediaChime_SFXB.2894.wav")
const STAR_OUTLINE: Texture2D = preload("res://images/contorno_estrella.png")
const INTRO_CONTINUE_AT := 5.0

@onready var main_card: Panel = $MainCard
@onready var phrase_card: Panel = $MainCard/PhraseCard
@onready var phrase_label: RichTextLabel = $MainCard/PhraseCard/Phrase
@onready var category_label: Label = $MainCard/PhraseCard/Category
@onready var quote_open: Label = $MainCard/PhraseCard/QuoteOpen
@onready var quote_close: Label = $MainCard/PhraseCard/QuoteClose
@onready var banner: Panel = $MainCard/Banner
@onready var banner_left: Panel = $MainCard/BannerLeft
@onready var banner_right: Panel = $MainCard/BannerRight
@onready var solved_label: Label = $MainCard/Solved
@onready var confetti_left: Label = $MainCard/ConfettiLeft
@onready var confetti_right: Label = $MainCard/ConfettiRight
@onready var stars_card: Panel = $MainCard/StarsCard
@onready var stars_title: Label = $MainCard/StarsCard/Title
@onready var time_pill: Panel = $MainCard/StarsCard/TimePill
@onready var info_card: Panel = $MainCard/StarsCard/InfoCard
@onready var continue_button: Button = $MainCard/ButtonBack
@onready var feedback_button: Button = $MainCard/ButtonFeedback
@onready var share_title: Label = $MainCard/ShareTitle
@onready var share_x_button: Button = $MainCard/ButtonShareX
@onready var share_ig_button: Button = $MainCard/ButtonShareInstagram
@onready var share_fb_button: Button = $MainCard/ButtonShareFacebook
@onready var share_tt_button: Button = $MainCard/ButtonShareTikTok
@onready var description_label: RichTextLabel = $MainCard/StarsCard/InfoCard/Description
@onready var time_text: Label = $MainCard/StarsCard/TimePill/TimeText
@onready var stars: Array[TextureRect] = [
	$MainCard/StarsCard/Stars/Star1,
	$MainCard/StarsCard/Stars/Star2,
	$MainCard/StarsCard/Stars/Star3,
	$MainCard/StarsCard/Stars/Star4,
	$MainCard/StarsCard/Stars/Star5
]

var _phrase := ""
var _stamp: Control
var _gleam: ColorRect
var _banner_rest: Dictionary = {}
var _info_rest_y := 0.0
var _body_scroll: ScrollContainer
var _drag_held := false
var _drag_active := false
var _drag_origin := Vector2.ZERO
var _drag_scroll_origin := 0
var _share_asked := false
var _typing_sfx: AudioStreamPlayer
var _earned := 0
var _maximum := 0
var _leaving := false
var _continue_blink: Tween


func _ready() -> void:
	SoundManager.play_victory_then_menu_music()
	_apply_locale()
	_phrase = GameManager.frase_original_til.strip_edges()
	if _phrase == "":
		_phrase = GameManager.frase_original.strip_edges()
	phrase_label.text = "[center]%s[/center]" % _escape_bbcode(_phrase)
	category_label.text = "— %s —" % GameManager.category_display_name()
	var info := GameManager.descripcion_final_actual.strip_edges()
	if info == "":
		info = tr("PuzzleCompleteFallback")
	description_label.text = "[center]%s[/center]" % _escape_bbcode(info)

	var maximum := GameManager.get_puzzle_difficulty_stars()
	var earned: int = clampi(GameManager.puzzle_stars, 0, maximum)
	if GameManager.is_practice_session() and GameManager.locked_record_stars >= 0:
		earned = clampi(GameManager.locked_record_stars, 0, maximum)
	_earned = earned
	_maximum = maximum
	if time_text:
		var elapsed := _format_play_time(int(GameManager.tiempo_partida))
		var template := tr("TimeTaken")
		if "%s" in template:
			time_text.text = template % elapsed
		else:
			time_text.text = "%s: %s" % [tr("Time"), elapsed]

	for index in range(stars.size()):
		var star := stars[index]
		star.visible = index < maximum
		star.self_modulate = STAR_EMPTY
		star.scale = Vector2.ONE

	await get_tree().process_frame
	await _fit_phrase_card()
	await _fit_stars_card()
	_layout_top_down()
	_install_body_scroll()
	for star in stars:
		star.pivot_offset = star.size * 0.5
	_prepare_intro_pose()
	await _play_victory_intro(earned, maximum)
	_play_continue_at(0.12)
	await _ask_share_if_needed()


func _apply_locale() -> void:
	var is_daily := GameManager.session_source == GameManager.SOURCE_DAILY
	if banner:
		var title := banner.get_node_or_null("Title") as Label
		if title:
			title.text = tr("DailyCongrats") if is_daily else tr("CONGRATULATIONS!!!!")
	if solved_label:
		solved_label.text = tr("DailyCompleted") if is_daily else tr("You've solved the sentence")
	if stars_title:
		stars_title.text = tr("StarsEarned")
	continue_button.text = tr("RecogerEstrellas")
	continue_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	continue_button.add_theme_font_size_override("font_size", 40)
	if feedback_button:
		feedback_button.text = tr("RatePuzzle")
	if share_title:
		share_title.text = tr("ShareSocialTitle")
		share_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for button in _share_social_buttons():
		button.text = ""
	if share_x_button:
		share_x_button.tooltip_text = tr("ShareOnX")
	if share_ig_button:
		share_ig_button.tooltip_text = tr("ShareOnInstagram")
	if share_fb_button:
		share_fb_button.tooltip_text = tr("ShareOnFacebook")
	if share_tt_button:
		share_tt_button.tooltip_text = tr("ShareOnTikTok")


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")


func _format_play_time(total_sec: int) -> String:
	var seconds := maxi(total_sec, 0)
	var hours := seconds / 3600
	var minutes := (seconds % 3600) / 60
	var rest := seconds % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, rest]
	return "%d:%02d" % [minutes, rest]


func _fit_phrase_card() -> void:
	phrase_label.fit_content = true
	phrase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	phrase_label.scroll_active = false
	phrase_label.selection_enabled = false
	phrase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame

	var phrase_height := maxf(float(phrase_label.get_content_height()), 160.0)
	var category_space := 10.0 + category_label.size.y + 24.0
	var desired_card := phrase_label.position.y + phrase_height + category_space
	var card_height := maxf(desired_card, 320.0)
	phrase_card.size.y = card_height
	phrase_label.fit_content = false
	phrase_label.size.y = phrase_height
	category_label.position.y = phrase_label.position.y + phrase_height + 10.0
	quote_close.position.y = maxf(phrase_label.position.y + phrase_height - 100.0, 100.0)
	_hide_drag_layer(phrase_card, "PhraseDrag")


func _fit_stars_card() -> void:
	description_label.fit_content = true
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.scroll_active = false
	description_label.selection_enabled = false
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame

	var desired_description_height := maxf(
		float(description_label.get_content_height()),
		100.0
	)
	description_label.fit_content = false
	description_label.size.y = desired_description_height
	info_card.size.y = (
		description_label.position.y
		+ desired_description_height
		+ 32.0
	)
	stars_card.size.y = info_card.position.y + info_card.size.y + 28.0
	_hide_drag_layer(info_card, "DescriptionDrag")


func _hide_drag_layer(host: Control, layer_name: String) -> void:
	var layer := host.get_node_or_null(layer_name) as Control
	if layer:
		layer.visible = false


func _layout_top_down() -> void:
	var y := banner.position.y + banner.size.y + 8.0
	if solved_label:
		solved_label.position.y = y
		y = solved_label.position.y + solved_label.size.y + 8.0
	phrase_card.position.y = y
	stars_card.position.y = phrase_card.position.y + phrase_card.size.y + GAP
	var button_h := continue_button.size.y
	var share_h := 140.0
	var margin := 36.0
	var gap := 20.0
	var available := main_card.size.x - margin * 2.0
	var continue_w := minf(640.0, available * 0.58)
	var feedback_w := available - gap - continue_w
	var bottom_y := main_card.size.y - button_h - 36.0
	var social_buttons := _share_social_buttons()
	var social_n := social_buttons.size()
	var social_gap := 16.0
	var title_h := 68.0
	var share_y := bottom_y - gap - share_h
	if social_n > 0:
		var btn_w := (available - social_gap * float(social_n - 1)) / float(social_n)
		for i in range(social_n):
			var button := social_buttons[i]
			button.position = Vector2(margin + float(i) * (btn_w + social_gap), share_y)
			button.size = Vector2(btn_w, share_h)
	if share_title:
		share_title.position = Vector2(margin, share_y - 10.0 - title_h)
		share_title.size = Vector2(available, title_h)
	if feedback_button:
		feedback_button.position = Vector2(margin, bottom_y)
		feedback_button.size = Vector2(feedback_w, button_h)
	continue_button.position = Vector2(margin + feedback_w + gap, bottom_y)
	continue_button.size = Vector2(continue_w, button_h)


func _body_scroll_nodes() -> Array[Control]:
	var nodes: Array[Control] = []
	if solved_label:
		nodes.append(solved_label)
	nodes.append(phrase_card)
	nodes.append(stars_card)
	return nodes


func _install_body_scroll() -> void:
	var top := banner.position.y + banner.size.y + 6.0
	var bottom := continue_button.position.y - GAP
	if share_title:
		bottom = minf(bottom, share_title.position.y - GAP)
	else:
		for button in _share_social_buttons():
			bottom = minf(bottom, button.position.y - GAP)
	var viewport_height := bottom - top
	if viewport_height < 160.0:
		return

	var content_nodes := _body_scroll_nodes()
	var content_bottom := 0.0
	for node in content_nodes:
		content_bottom = maxf(content_bottom, node.position.y + node.size.y)
	content_bottom += 28.0
	if content_bottom <= bottom + 1.0:
		return

	var scroll := ScrollContainer.new()
	scroll.name = "BodyScroll"
	scroll.position = Vector2(0.0, top)
	scroll.size = Vector2(main_card.size.x, viewport_height)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.scroll_deadzone = 16
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.clip_contents = true

	var body := Control.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(body)

	for node in content_nodes:
		var local: Vector2 = node.position
		node.reparent(body)
		node.position = Vector2(local.x, local.y - top)
	body.custom_minimum_size = Vector2(
		main_card.size.x,
		content_bottom - top
	)
	main_card.add_child(scroll)
	_body_scroll = scroll
	for node in [banner, banner_left, banner_right, confetti_left, confetti_right, continue_button, feedback_button, share_title]:
		if node:
			node.z_index = 8
	for button in _share_social_buttons():
		button.z_index = 8


func _input(event: InputEvent) -> void:
	if _body_scroll == null or not is_instance_valid(_body_scroll):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_body_drag_press(event.pressed, event.position)
	elif event is InputEventMouseMotion and _drag_held:
		_handle_body_drag_motion(event.position)
	elif event is InputEventScreenTouch:
		_handle_body_drag_press(event.pressed, event.position)
	elif event is InputEventScreenDrag and _drag_held:
		_handle_body_drag_motion(event.position)


func _handle_body_drag_press(pressed: bool, position: Vector2) -> void:
	if pressed:
		if not _body_scroll.get_global_rect().has_point(position):
			return
		if continue_button.get_global_rect().has_point(position):
			return
		if feedback_button and feedback_button.get_global_rect().has_point(position):
			return
		if share_title and share_title.get_global_rect().has_point(position):
			return
		for button in _share_social_buttons():
			if button.get_global_rect().has_point(position):
				return
		_drag_held = true
		_drag_active = false
		_drag_origin = position
		_drag_scroll_origin = _body_scroll.scroll_vertical
		return
	if _drag_active:
		get_viewport().set_input_as_handled()
	_drag_held = false
	_drag_active = false


func _handle_body_drag_motion(position: Vector2) -> void:
	var delta := position.y - _drag_origin.y
	if not _drag_active and absf(delta) >= 14.0:
		_drag_active = true
	if not _drag_active:
		return
	_body_scroll.scroll_vertical = _drag_scroll_origin - int(delta)
	get_viewport().set_input_as_handled()


func _set_bbcode_phrase(raw: String) -> void:
	phrase_label.text = "[center]%s[/center]" % _escape_bbcode(raw)


func _set_green_phrase(cutoff: int) -> void:
	var out := ""
	for i in _phrase.length():
		var ch := _phrase.substr(i, 1)
		var escaped := _escape_bbcode(ch)
		if not _is_letter(ch):
			out += escaped
		elif i < cutoff:
			out += "[color=#000000]%s[/color]" % escaped
		else:
			out += "*"
	phrase_label.text = "[center]%s[/center]" % out


func _is_letter(ch: String) -> bool:
	return ch.to_upper() != ch.to_lower()


func _mix_reveal(source: String, ratio: float) -> String:
	var cutoff := int(ceili(float(source.length()) * clampf(ratio, 0.0, 1.0)))
	var out := ""
	for i in source.length():
		var ch := source.substr(i, 1)
		if i < cutoff or not _is_letter(ch):
			out += ch
		else:
			out += "*"
	return out


func _exit_tree() -> void:
	_stop_phrase_typing_sfx()


func _start_phrase_typing_sfx() -> void:
	_stop_phrase_typing_sfx()
	var stream := TYPING_SFX.duplicate()
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_typing_sfx = AudioStreamPlayer.new()
	_typing_sfx.bus = "SoundFx"
	_typing_sfx.stream = stream
	_typing_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_typing_sfx)
	_typing_sfx.play()


func _stop_phrase_typing_sfx() -> void:
	if is_instance_valid(_typing_sfx):
		_typing_sfx.stop()
		_typing_sfx.queue_free()
	_typing_sfx = null


func _play_paper_hit() -> void:
	if SoundManager.has_node("PaperStamp"):
		SoundManager.play("PaperStamp")
	else:
		SoundManager.play("ClickCelda")


func _play_resolved_hit() -> void:
	_play_oneshot_sfx(RESOLVED_HIT_SFX)


func _play_banner_chime() -> void:
	_play_oneshot_sfx(BANNER_CHIME_SFX, -10.0)


func _play_oneshot_sfx(stream: AudioStream, volume_db := 0.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = "SoundFx"
	player.stream = stream
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func _play_continue_at(delay_s: float) -> void:
	await get_tree().create_timer(delay_s).timeout
	if not is_instance_valid(continue_button):
		return
	continue_button.disabled = false
	continue_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if feedback_button:
		feedback_button.disabled = false
		feedback_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_share_buttons_disabled(false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(continue_button, "modulate:a", 1.0, 0.36)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if feedback_button:
		tween.tween_property(feedback_button, "modulate:a", 1.0, 0.36)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if share_title:
		tween.tween_property(share_title, "modulate:a", 1.0, 0.36)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for button in _share_social_buttons():
		tween.tween_property(button, "modulate:a", 1.0, 0.36)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_start_continue_blink()


func _hide_node(node: CanvasItem, alpha := 0.0) -> void:
	if node:
		node.modulate.a = alpha


func _prepare_intro_pose() -> void:
	_set_bbcode_phrase(_mix_reveal(_phrase, 0.0))
	_hide_node(quote_open)
	_hide_node(quote_close)
	_hide_node(solved_label)
	_hide_node(confetti_left)
	_hide_node(confetti_right)
	_hide_node(stars_card)
	_hide_node(info_card)
	for star in stars:
		star.modulate.a = 0.0

	_banner_rest = {
		"banner": banner.position,
		"left": banner_left.position,
		"right": banner_right.position,
	}
	banner.position.y -= 118.0
	banner_left.position.y -= 118.0
	banner_right.position.y -= 118.0
	banner.pivot_offset = Vector2(banner.size.x * 0.5, banner.size.y)
	_hide_node(banner)
	_hide_node(banner_left)
	_hide_node(banner_right)

	_info_rest_y = info_card.position.y
	info_card.position.y = _info_rest_y + 18.0

	continue_button.modulate.a = 0.0
	continue_button.disabled = true
	continue_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if feedback_button:
		feedback_button.modulate.a = 0.0
		feedback_button.disabled = true
		feedback_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if share_title:
		share_title.modulate.a = 0.0
	for button in _share_social_buttons():
		button.modulate.a = 0.0
		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_stamp = _make_stamp()
	phrase_card.add_child(_stamp)
	_gleam = ColorRect.new()
	_gleam.color = Color(1, 0.97, 0.86, 0.42)
	_gleam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gleam.size = Vector2(18.0, phrase_card.size.y)
	_gleam.position = Vector2(-18.0, 0.0)
	phrase_card.add_child(_gleam)


func _make_stamp() -> Control:
	var stamp := Control.new()
	stamp.name = "ResolvedStamp"
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.size = Vector2(340, 108)
	stamp.position = Vector2(
		maxf(phrase_card.size.x - 390.0, 40.0),
		maxf(phrase_card.size.y - 168.0, 40.0)
	)
	stamp.pivot_offset = stamp.size * 0.5
	stamp.rotation_degrees = -13.0
	stamp.modulate.a = 0.0
	stamp.scale = Vector2(1.16, 1.16)

	var plate := Panel.new()
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.78, 0.16, 0.12, 0.08)
	style.border_color = Color(0.72, 0.14, 0.11, 0.88)
	style.set_border_width_all(6)
	style.set_corner_radius_all(10)
	plate.add_theme_stylebox_override("panel", style)
	stamp.add_child(plate)

	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = tr("SolvedStamp")
	if label.text == "SolvedStamp":
		label.text = "¡RESUELTO!"
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(0.72, 0.13, 0.1, 0.92))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.add_child(label)
	return stamp


func _play_victory_intro(earned: int, maximum: int) -> void:
	var wipe := _animate_decipher_wipe()
	await get_tree().create_timer(1.10).timeout
	_animate_quotes()
	await wipe
	await get_tree().create_timer(0.48).timeout
	_animate_stamp()
	await get_tree().create_timer(0.82).timeout
	_animate_banner()
	await get_tree().create_timer(0.90).timeout
	_animate_stars_intro(earned, maximum)
	await get_tree().create_timer(0.50).timeout
	await _animate_info_intro()


func _animate_decipher_wipe() -> Signal:
	_start_phrase_typing_sfx()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(_apply_reveal, 0.0, 1.0, 1.60)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _gleam:
		_gleam.modulate.a = 0.55
		tween.tween_property(_gleam, "position:x", phrase_card.size.x + 8.0, 1.60)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_gleam, "modulate:a", 0.0, 1.60)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		_stop_phrase_typing_sfx()
		_set_green_phrase(_phrase.length())
		if _gleam:
			_gleam.queue_free()
			_gleam = null
	)
	return tween.finished


func _apply_reveal(ratio: float) -> void:
	var cutoff := int(ceili(float(_phrase.length()) * clampf(ratio, 0.0, 1.0)))
	_set_green_phrase(cutoff)


func _animate_quotes() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for quote in [quote_open, quote_close]:
		if quote == null:
			continue
		quote.scale = Vector2(0.72, 0.72)
		quote.pivot_offset = quote.size * 0.5
		tween.tween_property(quote, "modulate:a", 1.0, 0.42)
		tween.tween_property(quote, "scale", Vector2.ONE, 0.48)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _animate_stamp() -> void:
	if _stamp == null:
		return
	var rest_y := _stamp.position.y
	_stamp.position.y = rest_y - 64.0
	const DROP_S := 0.72
	const SQUASH_S := 0.10
	const SETTLE_S := 0.18
	var tween := create_tween()
	tween.tween_property(_stamp, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(_stamp, "position:y", rest_y, DROP_S)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_stamp, "scale", Vector2.ONE, DROP_S)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_callback(_play_paper_hit)
	tween.tween_property(_stamp, "scale", Vector2(0.985, 1.02), SQUASH_S)
	tween.tween_property(_stamp, "scale", Vector2.ONE, SETTLE_S)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var sfx := create_tween()
	sfx.tween_interval(0.50)
	sfx.tween_callback(_play_resolved_hit)


func _animate_banner() -> void:
	_play_banner_chime()
	var rest: Vector2 = _banner_rest.get("banner", banner.position)
	var rest_left: Vector2 = _banner_rest.get("left", banner_left.position)
	var rest_right: Vector2 = _banner_rest.get("right", banner_right.position)
	var tween := create_tween()
	tween.set_parallel(true)
	for node in [banner, banner_left, banner_right, confetti_left, confetti_right, solved_label]:
		if node:
			tween.tween_property(node, "modulate:a", 1.0, 0.48)
	tween.tween_property(banner, "position", rest, 0.80)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(banner_left, "position", rest_left, 0.80)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(banner_right, "position", rest_right, 0.80)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(_play_paper_hit)
	tween.set_parallel(false)
	tween.tween_property(banner, "scale", Vector2(1.0, 0.985), 0.10)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.18)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _animate_stars_intro(earned: int, maximum: int) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(stars_card, "modulate:a", 1.0, 0.42)
	if stars_title:
		stars_title.modulate.a = 1.0
	if time_pill:
		time_pill.modulate.a = 1.0
	info_card.modulate.a = 0.0
	for index in range(stars.size()):
		var star := stars[index]
		if index >= maximum:
			continue
		if index < earned:
			star.self_modulate = GameManager.star_fill_color()
			star.scale = Vector2(0.68, 0.68)
			tween.tween_property(star, "modulate:a", 1.0, 0.22)
			var pop := create_tween()
			pop.tween_property(star, "scale", Vector2(1.08, 1.08), 0.32)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			pop.tween_property(star, "scale", Vector2.ONE, 0.28)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_flash_star(star)
		else:
			star.texture = STAR_OUTLINE
			star.self_modulate = Color(0.72, 0.58, 0.38, 0.55)
			tween.tween_property(star, "modulate:a", 1.0, 0.40)


func _flash_star(star: TextureRect) -> void:
	var flash := TextureRect.new()
	flash.texture = star.texture
	flash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.modulate = Color(1, 0.96, 0.7, 0.55)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.pivot_offset = star.size * 0.5
	star.add_child(flash)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.7, 1.7), 0.55)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(flash.queue_free)


func _animate_info_intro() -> void:
	if info_card == null:
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(info_card, "modulate:a", 1.0, 0.70)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(info_card, "position:y", _info_rest_y, 0.70)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


func _start_continue_blink() -> void:
	if _leaving or continue_button == null or not is_instance_valid(continue_button):
		return
	if is_instance_valid(_continue_blink):
		_continue_blink.kill()
	continue_button.pivot_offset = continue_button.size * 0.5
	_continue_blink = create_tween()
	_continue_blink.set_loops()
	_continue_blink.set_trans(Tween.TRANS_SINE)
	_continue_blink.set_ease(Tween.EASE_IN_OUT)
	_continue_blink.tween_property(continue_button, "scale", Vector2(1.06, 1.06), 0.45)
	_continue_blink.tween_property(continue_button, "scale", Vector2.ONE, 0.45)


func _stop_continue_blink() -> void:
	if is_instance_valid(_continue_blink):
		_continue_blink.kill()
	_continue_blink = null
	if continue_button:
		continue_button.scale = Vector2.ONE


func _on_button_back_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	_stop_continue_blink()
	SoundManager.play("ButtonClick")
	continue_button.disabled = true
	if feedback_button:
		feedback_button.disabled = true
	_set_share_buttons_disabled(true)
	await _ask_share_if_needed()
	var collect_count := _earned
	if GameManager.is_practice_session():
		collect_count = 0
	if collect_count > 0:
		StarCollectOverlay.capture_earned(stars, collect_count, GameManager.game_mode_actual)
	StarCollectOverlay.show_white_cover()
	await get_tree().process_frame
	await get_tree().process_frame
	await AdManager.show_interstitial_after_puzzle()
	await EventLoggerAutoload.submit_if_consented()
	get_tree().change_scene_to_file(SCENE_MENU_MAIN)


func _on_share_x_pressed() -> void:
	await _share_to("x")


func _on_share_instagram_pressed() -> void:
	await _share_to("instagram")


func _on_share_facebook_pressed() -> void:
	await _share_to("facebook")


func _on_share_tiktok_pressed() -> void:
	await _share_to("tiktok")


func _share_to(network: String) -> void:
	if _leaving or ShareManager.is_busy():
		return
	SoundManager.play("ButtonClick")
	_set_share_buttons_disabled(true)
	await ShareManager.share_current_result_to_network(network)
	if not _leaving:
		_set_share_buttons_disabled(false)


func _share_social_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for button in [share_x_button, share_ig_button, share_fb_button, share_tt_button]:
		if button:
			buttons.append(button)
	return buttons


func _set_share_buttons_disabled(disabled: bool) -> void:
	for button in _share_social_buttons():
		button.disabled = disabled
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP


func _on_button_feedback_pressed() -> void:
	SoundManager.play("ButtonClick")
	await _confirm_share_then_go(SCENE_FEEDBACK)


func _ask_share_if_needed() -> void:
	if _share_asked or PlayerPrefs.hide_share_solve_dialog:
		return
	_share_asked = true
	var dialog := SHARE_DIALOG.new()
	add_child(dialog)
	await dialog.finished


func _confirm_share_then_go(next_scene: String) -> void:
	if _leaving:
		return
	_leaving = true
	await _ask_share_if_needed()
	await EventLoggerAutoload.submit_if_consented()
	TransitionScreen.transition_to_black()
	await SignalManager.on_transition_finished
	get_tree().change_scene_to_file(next_scene)
