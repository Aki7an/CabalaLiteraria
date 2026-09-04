extends ColorRect

const SCENE_FEEDBACK := "res://scenes/MenuFeedback.tscn"
const STAR_EMPTY := Color(0.62, 0.51, 0.34, 0.28)
const GAP := 24.0

@onready var main_card: Panel = $MainCard
@onready var phrase_card: Panel = $MainCard/PhraseCard
@onready var phrase_label: RichTextLabel = $MainCard/PhraseCard/Phrase
@onready var category_label: Label = $MainCard/PhraseCard/Category
@onready var quote_close: Label = $MainCard/PhraseCard/QuoteClose
@onready var stars_card: Panel = $MainCard/StarsCard
@onready var info_card: Panel = $MainCard/StarsCard/InfoCard
@onready var continue_button: Button = $MainCard/ButtonBack
@onready var description_label: RichTextLabel = $MainCard/StarsCard/InfoCard/Description
@onready var stars_text: Label = $MainCard/StarsCard/StarsPill/StarsText
@onready var stars: Array[TextureRect] = [
	$MainCard/StarsCard/Stars/Star1,
	$MainCard/StarsCard/Stars/Star2,
	$MainCard/StarsCard/Stars/Star3,
	$MainCard/StarsCard/Stars/Star4,
	$MainCard/StarsCard/Stars/Star5
]


func _ready() -> void:
	_apply_locale()
	var phrase := GameManager.frase_original_til.strip_edges()
	if phrase == "":
		phrase = GameManager.frase_original.strip_edges()
	phrase_label.text = "[center]%s[/center]" % phrase
	category_label.text = "— %s —" % GameManager.category_display_name()
	description_label.text = GameManager.descripcion_final_actual
	if description_label.text.strip_edges() == "":
		description_label.text = tr("PuzzleCompleteFallback")

	var maximum := GameManager.get_puzzle_difficulty_stars()
	var earned: int = clampi(GameManager.puzzle_stars, 0, maximum)
	stars_text.text = tr("StarsResult") % [earned, maximum]

	for index in range(stars.size()):
		var star := stars[index]
		star.visible = index < maximum
		star.self_modulate = STAR_EMPTY
		star.scale = Vector2.ONE

	await get_tree().process_frame
	await _fit_phrase_card()
	await _fit_stars_card()
	_layout_top_down()
	for star in stars:
		star.pivot_offset = star.size * 0.5
	await _animate_stars(earned)


func _apply_locale() -> void:
	var title := $MainCard/Banner/Title as Label
	if title:
		title.text = tr("CONGRATULATIONS!!!!")
	var solved := $MainCard/Solved as Label
	if solved:
		solved.text = tr("You've solved the sentence")
	var stars_title := $MainCard/StarsCard/Title as Label
	if stars_title:
		stars_title.text = tr("StarsEarned")
	continue_button.text = tr("CONTINUE")


func _fit_phrase_card() -> void:
	phrase_label.fit_content = true
	phrase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	await get_tree().process_frame

	var phrase_height := maxf(float(phrase_label.get_content_height()), 160.0)
	phrase_label.size.y = phrase_height
	category_label.position.y = phrase_label.position.y + phrase_height + 10.0
	quote_close.position.y = maxf(phrase_label.position.y + phrase_height - 100.0, 100.0)
	var card_bottom := category_label.position.y + category_label.size.y + 24.0
	phrase_card.size.y = maxf(card_bottom, 320.0)


func _fit_stars_card() -> void:
	description_label.fit_content = true
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	await get_tree().process_frame

	var desired_description_height := maxf(
		float(description_label.get_content_height()),
		100.0
	)
	var stars_y := phrase_card.position.y + phrase_card.size.y + GAP
	stars_card.position.y = stars_y
	var maximum_stars_height := (
		continue_button.position.y
		- GAP
		- stars_y
	)
	var fixed_height := (
		info_card.position.y
		+ description_label.position.y
		+ 32.0
		+ 28.0
	)
	var maximum_description_height := maxf(
		maximum_stars_height - fixed_height,
		60.0
	)
	var actual_description_height := minf(
		desired_description_height,
		maximum_description_height
	)

	description_label.fit_content = false
	description_label.size.y = actual_description_height
	var needs_scroll := desired_description_height > actual_description_height + 1.0
	description_label.scroll_active = needs_scroll
	description_label.selection_enabled = false
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_card.size.y = (
		description_label.position.y
		+ actual_description_height
		+ 32.0
	)
	stars_card.size.y = info_card.position.y + info_card.size.y + 28.0
	await get_tree().process_frame
	_sync_description_drag_layer(needs_scroll)


func _sync_description_drag_layer(needs_scroll: bool) -> void:
	var layer := info_card.get_node_or_null("DescriptionDrag") as Control
	if not needs_scroll:
		if layer:
			layer.visible = false
		return
	if layer == null:
		layer = Control.new()
		layer.name = "DescriptionDrag"
		layer.mouse_filter = Control.MOUSE_FILTER_STOP
		info_card.add_child(layer)
		layer.gui_input.connect(_on_description_gui_input)
	var bar := description_label.get_v_scroll_bar()
	var bar_w := 36.0
	if bar:
		bar_w = maxf(bar.size.x, 28.0)
	layer.visible = true
	layer.position = description_label.position
	layer.size = Vector2(
		maxf(description_label.size.x - bar_w, 1.0),
		description_label.size.y
	)


func _on_description_gui_input(event: InputEvent) -> void:
	if not description_label.scroll_active:
		return
	var bar := description_label.get_v_scroll_bar()
	if bar == null or bar.max_value <= bar.page:
		return
	var handled := false
	if event is InputEventScreenDrag:
		bar.value -= (event as InputEventScreenDrag).relative.y
		handled = true
	elif event is InputEventPanGesture:
		bar.value += (event as InputEventPanGesture).delta.y
		handled = true
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		var step := 48.0 if bar.page <= 0.0 else maxf(bar.page * 0.18, 24.0)
		if mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			bar.value -= step
			handled = true
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			bar.value += step
			handled = true
	if handled:
		get_viewport().set_input_as_handled()


func _layout_top_down() -> void:
	stars_card.position.y = phrase_card.position.y + phrase_card.size.y + GAP


func _animate_stars(earned: int) -> void:
	for index in range(earned):
		var star := stars[index]
		star.self_modulate = GameManager.star_fill_color()
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(star, "scale", Vector2(1.4, 1.4), 0.12).set_ease(Tween.EASE_OUT)
		tween.tween_property(star, "scale", Vector2(0.88, 0.88), 0.1).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(star, "scale", Vector2(1.22, 1.22), 0.09).set_ease(Tween.EASE_OUT)
		tween.tween_property(star, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_IN)
		await tween.finished
		await get_tree().create_timer(0.06).timeout


func _on_button_back_pressed() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await SignalManager.on_transition_finished
	get_tree().change_scene_to_file(SCENE_FEEDBACK)
