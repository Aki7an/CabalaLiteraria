extends Control

@onready var _page_title: Label = %PageTitle
@onready var _title_1: Label = %Title1
@onready var _body_1: Label = %Body1
@onready var _hint_1: Label = %HintBody1
@onready var _hint_2: Label = %HintBody2
@onready var _hint_3: Label = %HintBody3
@onready var _hint_cost: Label = %HintCost
@onready var _title_2: Label = %Title2
@onready var _runs_intro: Label = %RunsIntro
@onready var _runs_choice: Label = %RunsChoice
@onready var _runs_level: Label = %RunsLevel


func _ready() -> void:
	apply_locale()


func apply_locale() -> void:
	_page_title.text = tr("HowToPlay").to_upper()
	_title_1.text = tr("TutC7Title").to_upper()
	_body_1.text = tr("TutC7Body")
	_hint_1.text = tr("TutHintCard1")
	_hint_2.text = tr("TutHintCard2")
	_hint_3.text = tr("TutHintCard3")
	_hint_cost.text = tr("TutHintStarCost")
	_title_2.text = tr("TutCgRunsTitle").to_upper()
	_runs_intro.text = tr("TutCgRunsIntro")
	_runs_choice.text = tr("TutCgRunsChoice")
	_runs_level.text = tr("TutCgRunsLevel")


func set_active(_active: bool) -> void:
	pass
