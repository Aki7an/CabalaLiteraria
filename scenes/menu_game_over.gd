extends ColorRect

const scene_to_load_MenuResults = preload("res://scenes/MenuResults.tscn")
const scene_to_load_MenuFeedback = preload("res://scenes/MenuFeedback.tscn")


@onready var rich_text_frase_info_extra = $GameOver/Label/RichTextFraseInfoExtra
@onready var rich_text_frase_original = $GameOver/Label/RichTextFraseOriginal


func _on_button_game_over_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(scene_to_load_MenuResults)
	SoundManager.play("ButtonClick")

func _ready():
	
	
	var frase_con_comillas = "[img=120x100]res://images/comillas_abre.png[/img]  " + GameManager.frase_original_til + "  [img=120x100]res://images/comillas_cierra.png[/img]"
	rich_text_frase_original.text = frase_con_comillas
	rich_text_frase_info_extra.text = GameManager.descripcion_final_actual
	
	
	


func _on_button_back_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	# TBD decide if prompt feedback menu
	#get_tree().change_scene_to_packed(scene_to_load_MenuResults)
	get_tree().change_scene_to_packed(scene_to_load_MenuFeedback)
	SoundManager.play("ButtonClick")
