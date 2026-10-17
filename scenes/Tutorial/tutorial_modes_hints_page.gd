extends VBoxContainer

@onready var _page_title: Label = %PageTitle
@onready var _title_1: Label = %Title1
@onready var _title_2: Label = %Title2
@onready var _body_rapido: RichTextLabel = %BodyRapido
@onready var _body_desafio: RichTextLabel = %BodyDesafio
@onready var _time_quick: Label = %TimeQuick
@onready var _time_desafio: Label = %TimeDesafio
@onready var _body_2: Label = %Body2
@onready var _mode_quick: Label = %ModeQuickTitle
@onready var _mode_desafio: Label = %ModeDesafioTitle
@onready var _hint_1: Label = %HintBody1
@onready var _hint_2: Label = %HintBody2
@onready var _hint_3: Label = %HintBody3
@onready var _hint_cost: Label = %HintCost
@onready var _chars_quick: Label = %CharsQuick
@onready var _chars_desafio: Label = %CharsDesafio


func _ready() -> void:
	apply_locale()


func apply_locale() -> void:
	_page_title.text = tr("HowToPlay").to_upper()
	_title_1.text = tr("TutC6Title").to_upper()
	_title_2.text = tr("TutC7Title").to_upper()
	_body_rapido.text = tr("TutC6Rapido")
	_body_desafio.text = tr("TutC6Desafio")
	_time_quick.text = tr("TutPaceBrief")
	_time_desafio.text = tr("TutPaceSlow")
	_chars_quick.text = tr("TutCharsQuick")
	_chars_desafio.text = tr("TutCharsDesafio")
	_body_2.text = tr("TutC7Body")
	_mode_quick.text = tr("Quick").to_upper()
	_mode_desafio.text = tr("Cryptogram").to_upper()
	_hint_1.text = tr("TutHintCard1")
	_hint_2.text = tr("TutHintCard2")
	_hint_3.text = tr("TutHintCard3")
	_hint_cost.text = tr("TutHintStarCost")


func set_active(_active: bool) -> void:
	pass
