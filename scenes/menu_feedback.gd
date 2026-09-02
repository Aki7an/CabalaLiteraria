extends Control

const SCENE_MENU_MAIN := "res://scenes/MenuMain.tscn"

const COPY_KEYS := {
	"title": "FeedbackTitle",
	"subtitle": "FeedbackSubtitle",
	"global": "FeedbackGlobal",
	"difficulty": "Difficulty",
	"duration": "FeedbackDuration",
	"hint1": "HINT 1",
	"hint2": "HINT 2",
	"hint3": "HINT 3",
	"reveal": "FeedbackReveal",
	"unused": "FeedbackUnused",
	"omit": "FeedbackOmit",
	"send": "FeedbackSend",
	"sending": "FeedbackSending",
}

@onready var title_label: Label = $Card/Header/Title
@onready var subtitle_label: Label = $Card/Header/LevelId
@onready var hint1_row: Control = $Card/Scroll/Rows/RowHint1
@onready var hint2_row: Control = $Card/Scroll/Rows/RowHint2
@onready var hint3_row: Control = $Card/Scroll/Rows/RowHint3
@onready var reveal_row: Control = $Card/Scroll/Rows/RowLetters
@onready var hint1_disabled: Label = $Card/Scroll/Rows/RowHint1/Content/Disabled
@onready var hint2_disabled: Label = $Card/Scroll/Rows/RowHint2/Content/Disabled
@onready var hint3_disabled: Label = $Card/Scroll/Rows/RowHint3/Content/Disabled
@onready var reveal_disabled: Label = $Card/Scroll/Rows/RowLetters/Content/Disabled
@onready var button_omit: Button = $Card/Buttons/ButtonCancel
@onready var button_send: Button = $Card/Buttons/ButtonSend

@onready var estrellas1: FeedbackStarRow = $Card/Scroll/Rows/RowGlobal/Content/Stars
@onready var estrellas2: FeedbackStarRow = $Card/Scroll/Rows/RowDifficulty/Content/Stars
@onready var estrellas3: FeedbackStarRow = $Card/Scroll/Rows/RowDuration/Content/Stars
@onready var estrellas4: FeedbackStarRow = $Card/Scroll/Rows/RowHint1/Content/Stars
@onready var estrellas5: FeedbackStarRow = $Card/Scroll/Rows/RowHint2/Content/Stars
@onready var estrellas6: FeedbackStarRow = $Card/Scroll/Rows/RowHint3/Content/Stars
@onready var estrellas7: FeedbackStarRow = $Card/Scroll/Rows/RowLetters/Content/Stars

var _busy := false


func _ready() -> void:
	_apply_copy()
	_apply_locks()


func _copy(key: String) -> String:
	return tr(str(COPY_KEYS.get(key, key)))


func _apply_copy() -> void:
	title_label.text = _copy("title")
	subtitle_label.text = _copy("subtitle") % str(GameManager.id_frase)
	$Card/Scroll/Rows/RowGlobal/Content/Title.text = _copy("global")
	$Card/Scroll/Rows/RowDifficulty/Content/Title.text = _copy("difficulty")
	$Card/Scroll/Rows/RowDuration/Content/Title.text = _copy("duration")
	$Card/Scroll/Rows/RowHint1/Content/Title.text = _copy("hint1")
	$Card/Scroll/Rows/RowHint2/Content/Title.text = _copy("hint2")
	$Card/Scroll/Rows/RowHint3/Content/Title.text = _copy("hint3")
	$Card/Scroll/Rows/RowLetters/Content/Title.text = _copy("reveal")
	hint1_disabled.text = _copy("unused")
	hint2_disabled.text = _copy("unused")
	hint3_disabled.text = _copy("unused")
	reveal_disabled.text = _copy("unused")
	button_omit.text = _copy("omit")
	button_send.text = _copy("send")


func _apply_locks() -> void:
	_set_row_enabled(hint1_row, hint1_disabled, estrellas4, GameManager.pista_1)
	_set_row_enabled(hint2_row, hint2_disabled, estrellas5, GameManager.pista_2)
	_set_row_enabled(hint3_row, hint3_disabled, estrellas6, GameManager.pista_3)
	var used_reveal := (
		GameManager.reveal_errors_count + GameManager.reveal_success_count
	) > 0
	_set_row_enabled(reveal_row, reveal_disabled, estrellas7, used_reveal)


func _set_row_enabled(
	row: Control,
	disabled_label: Label,
	stars: FeedbackStarRow,
	enabled: bool
) -> void:
	disabled_label.visible = not enabled
	stars.visible = enabled
	stars.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	row.modulate.a = 1.0 if enabled else 0.55


func _on_button_send_pressed() -> void:
	if _busy:
		return
	_busy = true
	button_send.disabled = true
	button_omit.disabled = true
	button_send.text = _copy("sending")
	var used_reveal := (
		GameManager.reveal_errors_count + GameManager.reveal_success_count
	) > 0
	var ratings := {
		"global": estrellas1.question_stars,
		"difficulty": estrellas2.question_stars,
		"duration": estrellas3.question_stars,
		"hint1": estrellas4.question_stars if GameManager.pista_1 else 0,
		"hint2": estrellas5.question_stars if GameManager.pista_2 else 0,
		"hint3": estrellas6.question_stars if GameManager.pista_3 else 0,
		"init_letters": estrellas7.question_stars if used_reveal else 0,
	}
	await PlayFabTools.send_phrase_feedback(GameManager.id_frase, ratings, "", true)
	await _go_main_menu()


func _on_button_cancel_pressed() -> void:
	if _busy:
		return
	await _go_main_menu()


func _go_main_menu() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await SignalManager.on_transition_finished
	get_tree().change_scene_to_file(SCENE_MENU_MAIN)
