extends VBoxContainer

@onready var _page_title: Label = %PageTitle
@onready var _title_1: Label = %Title1
@onready var _title_2: Label = %Title2
@onready var _body_leave: Label = %BodyLeave
@onready var _body_restart: Label = %BodyRestart
@onready var _body_daily_a: Label = %BodyDailyA
@onready var _body_daily_b: Label = %BodyDailyB
@onready var _abandon_title: Label = %AbandonTitle
@onready var _restart_title: Label = %RestartTitle
@onready var _progress_saved: Label = %ProgressSaved
@onready var _no_board: Label = %NoBoard
@onready var _today_badge: Label = %TodayBadge
@onready var _solved_badge: Label = %SolvedBadge
@onready var _collection_title: Label = %CollectionTitle
@onready var _library_badge: Label = %LibraryBadge


func _ready() -> void:
	apply_locale()


func apply_locale() -> void:
	_page_title.text = tr("HowToPlay").to_upper()
	_title_1.text = tr("TutC9Title").to_upper()
	_title_2.text = tr("TutC10Title").to_upper()
	_body_leave.text = tr("TutC9Leave")
	_body_restart.text = tr("TutC9Restart")
	_body_daily_a.text = tr("TutC10P1")
	_body_daily_b.text = tr("TutC10P2")
	_abandon_title.text = tr("TutAbandon").to_upper()
	_restart_title.text = tr("TutRestart").to_upper()
	_progress_saved.text = tr("TutProgressSaved").to_upper()
	_no_board.text = tr("TutNoBoard").to_upper()
	_today_badge.text = tr("TutTodayChallenge").to_upper()
	_solved_badge.text = tr("TutSolvedShort").to_upper()
	_collection_title.text = tr("Collection")
	_library_badge.text = tr("Library").to_upper()


func set_active(_active: bool) -> void:
	pass
