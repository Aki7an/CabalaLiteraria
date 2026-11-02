extends Control

const CrazyPuzzle := preload("res://scenes/crazygames/crazygames_puzzle.gd")
const DESIGN := Vector2(1280, 720)
const PIP_FILLED := Color(1, 1, 1, 1)
const PIP_EMPTY := Color(1, 1, 1, 0.38)

@export var run_star_goal: int = 10

@onready var user_name: Label = %UserName
@onready var total_stars: Label = %TotalStars
@onready var runs_completed: Label = %RunsCompleted
@onready var goal_value: Label = %GoalValue
@onready var run_number_label: Label = %RunNumber
@onready var puzzle_image: TextureRect = %PuzzleImage
@onready var puzzles_done: Label = %PuzzlesDone
@onready var run_stars_value: Label = %RunStarsValue
@onready var run_stars_max: Label = %RunStarsMax
@onready var continue_label: Label = %ContinueLabel
@onready var fx_slash: CanvasItem = %FxSlash
@onready var music_slash: CanvasItem = %MusicSlash


func _ready() -> void:
	if get_tree().current_scene == self:
		_fit_to_window()
		var viewport := get_viewport()
		if viewport != null and not viewport.size_changed.is_connected(_fit_to_window):
			viewport.size_changed.connect(_fit_to_window)
	if not SignalManager.audio_prefs_changed.is_connected(_refresh_audio):
		SignalManager.audio_prefs_changed.connect(_refresh_audio)
	refresh()


func refresh() -> void:
	_refresh_player()
	_refresh_progress()
	_refresh_audio()


func _refresh_player() -> void:
	var name := str(GameManager.crazygames_username).strip_edges()
	if name == "":
		name = "CG Player_7A3D"
	user_name.text = name


func _refresh_progress() -> void:
	var order := CrazyPuzzle.saved_run_puzzles()
	var done := 0
	for puzzle_id in order:
		if str(PuzzleSaveManager.get_puzzle_state(puzzle_id).get("status", "")) == "completed":
			done += 1
	var goal := maxi(run_star_goal, 1)
	var earned := 0
	if PlayerProgress.has_run():
		earned = int(PlayerProgress.run.get("stars_earned", 0))
	total_stars.text = str(PlayerProgress.total_stars)
	runs_completed.text = str(maxi(PlayerProgress.run_number() - 1, 0))
	goal_value.text = str(goal)
	run_number_label.text = "Run #%d" % PlayerProgress.run_number()
	puzzles_done.text = "%d de %d" % [done, order.size()]
	run_stars_value.text = str(earned)
	run_stars_max.text = "/ %d" % goal
	continue_label.text = "CONTINUAR RUN" if PlayerProgress.has_run() or done > 0 else "EMPEZAR RUN"
	_paint_pips(done, order.size())
	_show_puzzle_image(_current_puzzle_id(order, done))


func _current_puzzle_id(order: Array[int], done: int) -> int:
	for puzzle_id in order:
		if str(PuzzleSaveManager.get_puzzle_state(puzzle_id).get("status", "")) != "completed":
			return puzzle_id
	if done > 0 and not order.is_empty():
		return order[order.size() - 1]
	return order[0] if not order.is_empty() else -1


func _show_puzzle_image(puzzle_id: int) -> void:
	if puzzle_image == null or puzzle_id < 0:
		return
	var image_number := puzzle_id
	for raw in GameManager.frases_db:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		if int(raw.get("index", -1)) != puzzle_id:
			continue
		image_number = int(raw.get("image_number", puzzle_id))
		break
	var path := GameManager.find_level_image_path(image_number)
	if path == "" or not ResourceLoader.exists(path):
		return
	var texture := load(path) as Texture2D
	if texture != null:
		puzzle_image.texture = texture


func _paint_pips(done: int, total: int) -> void:
	var pips := $RunCard/ProgressPips.get_children()
	var index := 0
	for node in pips:
		if not node is CanvasItem:
			continue
		var pip := node as CanvasItem
		if index >= total:
			pip.visible = false
		else:
			pip.visible = true
			pip.modulate = PIP_FILLED if index < done else PIP_EMPTY
		index += 1


func _refresh_audio(_unused: Variant = null) -> void:
	if fx_slash != null:
		fx_slash.visible = not SoundManager.is_fx_enabled()
	if music_slash != null:
		music_slash.visible = not SoundManager.is_music_enabled()


func _fit_to_window() -> void:
	var view := get_viewport_rect().size
	if view.x < 2.0 or view.y < 2.0:
		return
	var fitted := minf(view.x / DESIGN.x, view.y / DESIGN.y)
	scale = Vector2(fitted, fitted)
	pivot_offset = Vector2.ZERO
	position = (view - DESIGN * fitted) * 0.5


func _on_continue_pressed() -> void:
	SoundManager.play("ButtonClick")
	await PlayerProgress.ensure_loaded()
	PlayerProgress.open_current_puzzle()


func _on_restart_pressed() -> void:
	SoundManager.play("ButtonClick")
	await PlayerProgress.ensure_loaded()
	PlayerProgress.restart_run()
	refresh()


func _on_stats_pressed() -> void:
	_go_to("res://scenes/MenuStats.tscn")


func _on_ranking_pressed() -> void:
	HistoryManager.get_results_filtered("Todas", -1)
	_go_to("res://scenes/LeaderboardFINAL.tscn")


func _on_tutorial_pressed() -> void:
	GameManager.set_go_to_game_disable()
	_go_to("res://scenes/crazygames/MenuTutorialCG.tscn")


func _on_settings_pressed() -> void:
	_go_to("res://scenes/MenuSettings.tscn")


func _on_fx_pressed() -> void:
	var enabling := not SoundManager.is_fx_enabled()
	if not enabling:
		SoundManager.play("ButtonClick")
	SoundManager.toggle_fx_enabled()
	if enabling:
		SoundManager.play("ButtonClick")
	_refresh_audio()


func _on_music_pressed() -> void:
	SoundManager.play("ButtonClick")
	SoundManager.toggle_music_enabled()
	_refresh_audio()


func _go_to(path: String) -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file(path)
