extends Control

const SCENE_MENU_MAIN := "res://scenes/MenuMain.tscn"

@onready var label_id: Label = $Panel/Header/LevelId
@onready var hint2_row: Control = $Panel/Scroll/Rows/RowHint2
@onready var hint3_row: Control = $Panel/Scroll/Rows/RowHint3
@onready var hint2_disabled: Label = $Panel/Scroll/Rows/RowHint2/Content/Disabled
@onready var hint3_disabled: Label = $Panel/Scroll/Rows/RowHint3/Content/Disabled

@onready var estrellas1: FeedbackStarRow = $Panel/Scroll/Rows/RowGlobal/Content/Stars
@onready var estrellas2: FeedbackStarRow = $Panel/Scroll/Rows/RowDifficulty/Content/Stars
@onready var estrellas3: FeedbackStarRow = $Panel/Scroll/Rows/RowDuration/Content/Stars
@onready var estrellas4: FeedbackStarRow = $Panel/Scroll/Rows/RowHint1/Content/Stars
@onready var estrellas5: FeedbackStarRow = $Panel/Scroll/Rows/RowHint2/Content/Stars
@onready var estrellas6: FeedbackStarRow = $Panel/Scroll/Rows/RowHint3/Content/Stars
@onready var estrellas7: FeedbackStarRow = $Panel/Scroll/Rows/RowLetters/Content/Stars


func _ready() -> void:
	label_id.text = "ID NIVEL: %s" % str(GameManager.id_frase)
	_apply_hint_locks()


func _apply_hint_locks() -> void:
	var used_1 := GameManager.pistas_utilizadas_1 > 0
	var used_2 := GameManager.pistas_utilizadas_2 > 0
	hint2_disabled.visible = not used_1
	estrellas5.visible = used_1
	hint2_row.modulate.a = 1.0 if used_1 else 0.55
	hint3_disabled.visible = not used_2
	estrellas6.visible = used_2
	hint3_row.modulate.a = 1.0 if used_2 else 0.55


func _on_button_send_pressed() -> void:
	var ratings := {
		"global": estrellas1.question_stars,
		"difficulty": estrellas2.question_stars,
		"duration": estrellas3.question_stars,
		"hint1": estrellas4.question_stars,
		"hint2": estrellas5.question_stars,
		"hint3": estrellas6.question_stars,
		"init_letters": estrellas7.question_stars
	}
	PlayFabTools.send_phrase_feedback(GameManager.id_frase, ratings, "", true)
	await _go_main_menu()


func _on_button_cancel_pressed() -> void:
	await _go_main_menu()


func _go_main_menu() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await SignalManager.on_transition_finished
	get_tree().change_scene_to_file(SCENE_MENU_MAIN)
