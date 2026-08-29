extends ColorRect

const SCENE_MENU_MAIN := preload("res://scenes/MenuMain.tscn")
const STAR_YELLOW := Color(1.0, 0.82, 0.12, 1.0)
const STAR_EMPTY := Color(0.62, 0.51, 0.34, 0.28)
const GAP := 24.0
const BOTTOM_PAD := 28.0
const STARS_MIN_HEIGHT := 420.0

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

	var earned: int = clampi(GameManager.puzzle_stars, 0, stars.size())
	stars_text.text = "Resultado: %d de 5" % earned
	xp_label.text = "+%d XP" % (earned * 10)

	for star in stars:
		star.self_modulate = STAR_EMPTY
		star.scale = Vector2.ONE

	await get_tree().process_frame
	_fit_phrase_card()
	_layout_bottom_stack()
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


func _layout_bottom_stack() -> void:
	var card_h := main_card.size.y
	var button_h := continue_button.size.y
	var unlock_h := unlock_card.size.y
	var stars_h := stars_card.size.y

	# Anchor Continuar near the bottom; stack Unlock + Stars above it.
	continue_button.position.y = card_h - BOTTOM_PAD - button_h
	unlock_card.position.y = continue_button.position.y - GAP - unlock_h
	stars_card.position.y = unlock_card.position.y - GAP - stars_h

	var min_stars_y := phrase_card.position.y + phrase_card.size.y + GAP
	if stars_card.position.y >= min_stars_y:
		return

	# Phrase grew: shrink StarsCard so the stack still fits above Continuar.
	var available := unlock_card.position.y - GAP - min_stars_y
	stars_h = maxf(available, STARS_MIN_HEIGHT)
	stars_card.size.y = stars_h
	_fit_info_card_to_stars(stars_h)
	stars_card.position.y = unlock_card.position.y - GAP - stars_h
	if stars_card.position.y < min_stars_y:
		stars_card.position.y = min_stars_y
		unlock_card.position.y = stars_card.position.y + stars_h + GAP
		continue_button.position.y = unlock_card.position.y + unlock_h + GAP


func _fit_info_card_to_stars(stars_h: float) -> void:
	var info_top := info_card.position.y
	var info_bottom := stars_h - 28.0
	if info_bottom <= info_top + 120.0:
		return
	info_card.size.y = info_bottom - info_top
	description_label.size.y = maxf(info_card.size.y - description_label.position.y - 24.0, 80.0)


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
