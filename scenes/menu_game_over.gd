extends ColorRect

const SCENE_MENU_RESULTS := preload("res://scenes/MenuResults.tscn")
const SCENE_MENU_FEEDBACK := preload("res://scenes/MenuFeedback.tscn")

@onready var phrase_label: RichTextLabel = $MainCard/PhraseCard/Phrase
@onready var category_label: Label = $MainCard/PhraseCard/Category
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
	_update_stars()


func _update_stars() -> void:
	var earned: int = clampi(GameManager.puzzle_stars, 0, stars.size())
	for index in range(stars.size()):
		stars[index].self_modulate = (
			Color(1, 1, 1, 1)
			if index < earned
			else Color(0.62, 0.51, 0.34, 0.22)
		)
	stars_text.text = "Resultado: %d de 5" % earned
	xp_label.text = "+%d XP" % (earned * 10)


func _on_button_game_over_pressed() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(SCENE_MENU_RESULTS)
	SoundManager.play("ButtonClick")


func _on_button_back_pressed() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(SCENE_MENU_FEEDBACK)
	SoundManager.play("ButtonClick")
