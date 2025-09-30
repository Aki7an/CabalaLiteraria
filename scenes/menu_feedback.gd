extends Node2D
@onready var estrellas1 :FeedbackStars = $LabelPregunta1/Estrellas
@onready var estrellas2 :FeedbackStars = $LabelPregunta2/Estrellas
@onready var estrellas3 :FeedbackStars = $LabelPregunta3/Estrellas
@onready var estrellas4 :FeedbackStars = $LabelPregunta4/Estrellas
@onready var estrellas5 :FeedbackStars = $LabelPregunta5/Estrellas
@onready var estrellas6 :FeedbackStars = $LabelPregunta6/Estrellas
@onready var estrellas7 :FeedbackStars = $LabelPregunta7/Estrellas

@onready var label_pregunta_5 = $LabelPregunta5
@onready var label_pregunta_6 = $LabelPregunta6

@onready var label_id_nivel = $"LabelID Nivel" 
@onready var label_pista_5_disable = $LabelPista5Disable
@onready var label_pista_6_disable = $LabelPista6Disable

func _on_button_send_pressed():
	var ratings := {
	"global": estrellas1.question_stars,
	"difficulty": estrellas2.question_stars,
	"duration": estrellas3.question_stars,
	"hint1": estrellas4.question_stars,
	"hint2": estrellas5.question_stars, 
	"hint3": estrellas6.question_stars,
	"init_letters": estrellas7.question_stars}
	
	PlayFabTools.send_phrase_feedback(GameManager.id_frase,ratings ,"Comentario por consola", true)
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if GameManager.score != 0:
		get_tree().change_scene_to_file("res://scenes/MenuResults.tscn")
		SoundManager.play("ButtonClick")
		print("info printed for feedback", estrellas1.question_stars, estrellas2.question_stars, estrellas3.question_stars, estrellas4.question_stars, estrellas5.question_stars)
	else:
		#game lost
		get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")
		SoundManager.play("ButtonClick")
		print("info printed for feedback", estrellas1.question_stars, estrellas2.question_stars, estrellas3.question_stars, estrellas4.question_stars, estrellas5.question_stars)

func _on_button_cancel_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuResults.tscn")
	SoundManager.play("ButtonClick")

func _ready():
	label_id_nivel.text = "ID NIVEL: " +  str(GameManager.id_frase)
	
	if GameManager.pistas_utilizadas == 0:
		label_pista_5_disable.visible = true
		label_pista_6_disable.visible = true
	elif GameManager.pistas_utilizadas == 1:
		label_pista_5_disable.visible = false
		label_pista_6_disable.visible = true
	else:
		label_pista_5_disable.visible = false
		label_pista_6_disable.visible = false
