extends ColorRect

const SCENE_MENU_MAIN := preload("res://scenes/MenuMain.tscn")
const STAR_YELLOW := Color(1.0, 0.82, 0.12, 1.0)
const STAR_EMPTY := Color(0.62, 0.51, 0.34, 0.28)
const GAP := 24.0

@onready var main_card: Panel = $MainCard
@onready var phrase_card: Panel = $MainCard/PhraseCard
@onready var phrase_label: RichTextLabel = $MainCard/PhraseCard/Phrase
@onready var category_label: Label = $MainCard/PhraseCard/Category
@onready var quote_close: Label = $MainCard/PhraseCard/QuoteClose
@onready var stars_card: Panel = $MainCard/StarsCard
@onready var info_card: Panel = $MainCard/StarsCard/InfoCard
@onready var unlock_card: Panel = $MainCard/UnlockCard
@onready var continue_button: Button = $MainCard/ButtonBack
@onready var description_label: RichTextLabel = $MainCard/StarsCard/InfoCard/Description
@onready var stars_text: Label = $MainCard/StarsCard/StarsPill/StarsText
@onready var xp_label: Label = $MainCard/UnlockCard/RewardXP/Title
@onready var map_progress_label: Label = $MainCard/UnlockCard/RewardMap/Subtitle
@onready var stars: Array[TextureRect] = [
	$MainCard/StarsCard/Stars/Star1,
	$MainCard/StarsCard/Stars/Star2,
	$MainCard/StarsCard/Stars/Star3,
	$MainCard/StarsCard/Stars/Star4,
	$MainCard/StarsCard/Stars/Star5
]


func _ready() -> void:
	var phrase := GameManager.frase_original_til.strip_edges()
	if phrase == "":
		phrase = GameManager.frase_original.strip_edges()
	phrase_label.text = "[center]%s[/center]" % phrase
	category_label.text = "— %s —" % GameManager.category_display_name()
	description_label.text = GameManager.descripcion_final_actual
	if description_label.text.strip_edges() == "":
		description_label.text = "Has completado correctamente este puzle."

	var maximum := GameManager.get_puzzle_difficulty_stars()
	var earned: int = clampi(GameManager.puzzle_stars, 0, maximum)
	stars_text.text = "Resultado: %d de %d" % [earned, maximum]
	xp_label.text = "+%d XP" % (earned * 10)
	_update_map_progress()

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
	var unlock_height := unlock_card.size.y
	var maximum_stars_height := (
		continue_button.position.y
		- GAP
		- unlock_height
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
	description_label.scroll_active = (
		desired_description_height > actual_description_height + 1.0
	)
	info_card.size.y = (
		description_label.position.y
		+ actual_description_height
		+ 32.0
	)
	stars_card.size.y = info_card.position.y + info_card.size.y + 28.0


func _layout_top_down() -> void:
	stars_card.position.y = phrase_card.position.y + phrase_card.size.y + GAP
	unlock_card.position.y = stars_card.position.y + stars_card.size.y + GAP


func _update_map_progress() -> void:
	var available_ids := {}
	for item_value in GameManager.frases_db:
		if item_value is Dictionary:
			var puzzle_id := int((item_value as Dictionary).get("index", -1))
			if puzzle_id >= 0:
				available_ids[puzzle_id] = true

	var completed_ids := {}
	for entry_value in HistoryManager.get_history():
		if entry_value is Dictionary:
			var entry: Dictionary = entry_value
			if bool(entry.get("partida_ganada", false)):
				completed_ids[int(entry.get("id", -1))] = true

	var total := available_ids.size()
	var remaining := maxi(total - completed_ids.size(), 0)
	var remaining_percent := 0
	if total > 0:
		remaining_percent = int(round(100.0 * float(remaining) / float(total)))
	map_progress_label.text = "%d %% por completar" % remaining_percent


func _animate_stars(earned: int) -> void:
	for index in range(earned):
		var star := stars[index]
		star.self_modulate = STAR_YELLOW
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
	get_tree().change_scene_to_packed(SCENE_MENU_MAIN)
