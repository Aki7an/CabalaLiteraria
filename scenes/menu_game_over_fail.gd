extends ColorRect

const scene_to_load_MainMenu = preload("res://scenes/MenuMain.tscn")
const scene_to_load_MenuFeedback = preload("res://scenes/MenuFeedback.tscn")


@onready var rich_text_frase_original = $GameOver/ButtonFx/RichTextFraseOriginal


func _on_button_game_over_pressed():
	SoundManager.play("ButtonClick")
	await AdManager.show_interstitial_after_puzzle()
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(scene_to_load_MainMenu)

func _ready():
	$GameOver/RichTextLabel1.text = tr("Sorry")
	$GameOver/RichTextLabel2.text = tr("FailedScreen")
	$GameOver/RichTextLabel3.text = tr("ThePhraseWas")
	var frase_con_comillas = "[img=120x100]res://images/comillas_abre.png[/img]  " + GameManager.frase_original_til + "  [img=120x100]res://images/comillas_cierra.png[/img]"
	rich_text_frase_original.text = frase_con_comillas

	
	
	


func _on_button_back_pressed():
	SoundManager.play("ButtonClick")
	await AdManager.show_interstitial_after_puzzle()
	TransitionScreen.transition_to_black()
	await SignalManager.on_transition_finished
	get_tree().change_scene_to_packed(scene_to_load_MenuFeedback)
