extends Control

const CrazyPuzzle := preload("res://scenes/crazygames/crazygames_puzzle.gd")
const SCENE_PATH := "res://scenes/crazygames/RunStatus.tscn"
const DESIGN := Vector2(1280, 720)
const SETTINGS_SCENE := "res://scenes/MenuSettings.tscn"
const STAR_ON: Texture2D = preload("res://images/estrella_plano.png")
const STAR_OFF: Texture2D = preload("res://images/estrella_hueca.png")
const STAR_GOLD := Color(1, 0.78, 0.16, 1)
const OPEN_STARS := 3

@export var run_star_goal: int = 10
@export var color_hard: Color = Color(0.9, 0.27, 0.27, 1)
@export var color_mid: Color = Color(0.22, 0.48, 0.92, 1)
@export var color_easy: Color = Color(0.18, 0.72, 0.38, 1)

@onready var level_label: Label = %LevelLabel
@onready var run_stars: Label = %RunStars
@onready var match_title: Label = %MatchTitle
@onready var choice_title: Label = %ChoiceTitle
@onready var title_done: Label = %TitleDone
@onready var complete_note: Label = %CompleteNote
@onready var slot_row: Container = %Slots
@onready var choice_row: Container = %Choices
@onready var fx_slash: CanvasItem = %FxSlash
@onready var music_slash: CanvasItem = %MusicSlash
@onready var star_row: Container = %StarRow


func _ready() -> void:
	if get_tree().current_scene == self:
		_fit_to_window()
		var viewport := get_viewport()
		if viewport != null and not viewport.size_changed.is_connected(_fit_to_window):
			viewport.size_changed.connect(_fit_to_window)
	if not SignalManager.audio_prefs_changed.is_connected(_refresh_audio):
		SignalManager.audio_prefs_changed.connect(_refresh_audio)
	if not SignalManager.fit_text.is_connected(refresh):
		SignalManager.fit_text.connect(refresh)
	_refresh_audio()
	await PlayerProgress.ensure_loaded()
	if not is_inside_tree():
		return
	refresh()
	await _play_incoming_stars()


func refresh() -> void:
	PlayerProgress.ensure_sequence_run()
	var length := CrazyPuzzle.FIRST_RUN_LENGTH
	var steps := PlayerProgress.run_steps()
	var goal := maxi(run_star_goal, CrazyPuzzle.FIRST_RUN_STAR_GOAL)
	var earned := 0
	if PlayerProgress.has_run():
		earned = int(PlayerProgress.run.get("stars_earned", 0))
	var incoming := _incoming_star_count()
	var shown := maxi(0, earned - incoming)
	var step := mini(steps.size() + 1, length) if length > 0 else 1
	_apply_copy(step, length)
	run_stars.text = "%d / %d" % [shown, goal]
	var finished := steps.size() >= length and length > 0
	choice_title.visible = not finished
	title_done.visible = finished
	complete_note.visible = finished
	_paint_goal(shown, goal)
	_arm_incoming_slots(shown, incoming, goal)
	_paint_slots(steps, length)
	_paint_choices(_offer_rows(steps), steps.is_empty())
	var played := 0
	if PlayerProgress.has_run():
		played = int(PlayerProgress.run.get("puzzles_played", 0))
	$ButtonRestart.visible = not steps.is_empty() or shown > 0 or played > 0
	_refresh_audio()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()


func _apply_copy(step: int, length: int) -> void:
	_plain($ProgressCard/Title, tr("RunProgressTitle"))
	_plain(level_label, tr("RunLevel") % PlayerProgress.run_number())
	_plain($ButtonHow/Label, tr("HowToPlay"))
	_plain($ButtonRank/Label, tr("Leaderboard"))
	_plain($ButtonRestart/Label, tr("RunRestart"))
	_plain(choice_title, tr("RunChooseNext"))
	_plain(title_done, tr("RunCompleteTitle"))
	_plain(complete_note, tr("RunCompleteNote"))
	if length <= 0:
		_plain(match_title, tr("RunMatchTitle"))
	else:
		_plain(match_title, tr("RunMatchHeading") % [step, length])


func _plain(node: Label, value: String) -> void:
	if node == null:
		return
	node.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	node.text = value


func _offer_rows(steps: Array[int]) -> Array[int]:
	var rows: Array[int] = []
	for stars in [3, 2, 1]:
		var seq := CrazyPuzzle.sequence(stars)
		var used := 0
		for puzzle_id in steps:
			if seq.has(puzzle_id):
				used += 1
		rows.append(seq[used] if used < seq.size() else -1)
	return rows


func _paint_slots(steps: Array[int], length: int) -> void:
	var slots := _slot_nodes(length)
	for index in slots.size():
		var slot: Panel = slots[index]
		var step_text := tr("RunSlotIndex") % [index + 1, length]
		if index < steps.size():
			var puzzle_id := steps[index]
			var summary := PuzzleSaveManager.get_puzzle_summary(puzzle_id)
			var maximum := int(summary.get("stars_max", OPEN_STARS))
			if maximum <= 0:
				maximum = OPEN_STARS
			maximum = clampi(maximum, 1, OPEN_STARS)
			var earned := clampi(int(summary.get("stars_remaining", 0)), 0, maximum)
			slot.call("show_completed", step_text, _texture_for(puzzle_id), earned, maximum)
		else:
			slot.call("show_open", step_text, OPEN_STARS, index == steps.size())


func _paint_choices(offered: Array[int], first_step: bool) -> void:
	var index := 0
	for node in choice_row.get_children():
		if not node.has_method("present"):
			continue
		if index >= offered.size() or offered[index] < 0:
			node.visible = false
			index += 1
			continue
		var puzzle_id := offered[index]
		var stars := 3 - index
		var enabled := not first_step or puzzle_id == CrazyPuzzle.PELE_ID
		node.call("present", puzzle_id, _texture_for(puzzle_id), stars, _accent(stars), enabled)
		if node.has_signal("chosen") and not node.chosen.is_connected(_on_choice_chosen):
			node.chosen.connect(_on_choice_chosen)
		index += 1


func _paint_goal(earned: int, goal: int) -> void:
	var icons := _goal_icons()
	var shown := mini(goal, icons.size())
	for index in icons.size():
		var icon := icons[index]
		icon.visible = index < shown
		var filled := index < earned
		icon.texture = STAR_ON if filled else STAR_OFF
		icon.modulate = STAR_GOLD


func _goal_icons() -> Array[TextureRect]:
	var icons: Array[TextureRect] = []
	for node in star_row.get_children():
		if node is TextureRect and str(node.name).begins_with("Star"):
			icons.append(node)
	return icons


func _incoming_star_count() -> int:
	if typeof(StarCollectOverlay) == TYPE_NIL or not StarCollectOverlay.has_pending():
		return 0
	return StarCollectOverlay.carried_count()


func _arm_incoming_slots(before: int, incoming: int, goal: int) -> void:
	if incoming <= 0:
		return
	var icons := _goal_icons()
	var limit := mini(goal, icons.size())
	for offset in incoming:
		var index := before + offset
		if index < 0 or index >= limit:
			continue
		var icon := icons[index]
		icon.visible = true
		icon.texture = STAR_ON
		icon.modulate = Color(STAR_GOLD.r, STAR_GOLD.g, STAR_GOLD.b, 0.0)


func _incoming_targets(before: int, incoming: int, goal: int) -> Array:
	var icons := _goal_icons()
	var limit := mini(goal, icons.size())
	var targets: Array = []
	for offset in incoming:
		var index := before + offset
		if index < 0 or index >= limit:
			break
		targets.append(icons[index])
	if targets.is_empty():
		return targets
	while targets.size() < incoming:
		targets.append(targets[targets.size() - 1])
	return targets


func _play_incoming_stars() -> void:
	if typeof(StarCollectOverlay) == TYPE_NIL:
		return
	var incoming := _incoming_star_count()
	if incoming <= 0:
		if StarCollectOverlay.is_covering():
			await StarCollectOverlay.fade_white_cover(0.45)
		return
	var earned := 0
	if PlayerProgress.has_run():
		earned = int(PlayerProgress.run.get("stars_earned", 0))
	var before := maxi(0, earned - incoming)
	var goal := maxi(run_star_goal, CrazyPuzzle.FIRST_RUN_STAR_GOAL)
	var targets := _incoming_targets(before, incoming, goal)
	if targets.is_empty():
		StarCollectOverlay.clear()
		_paint_goal(earned, goal)
		run_stars.text = "%d / %d" % [earned, goal]
		if StarCollectOverlay.is_covering():
			await StarCollectOverlay.fade_white_cover(0.45)
		return
	if StarCollectOverlay.is_covering():
		await StarCollectOverlay.fade_white_cover(0.45)
	await StarCollectOverlay.play_to_slots(targets, func(index: int) -> void:
		run_stars.text = "%d / %d" % [mini(before + index + 1, earned), goal]
	, true)
	if not is_inside_tree():
		return
	_paint_goal(earned, goal)
	run_stars.text = "%d / %d" % [earned, goal]


func _slot_nodes(needed: int) -> Array[Panel]:
	var doomed: Array[Node] = []
	for child in slot_row.get_children():
		if bool(child.get_meta("generated", false)):
			doomed.append(child)
	for node in doomed:
		slot_row.remove_child(node)
		node.free()
	var slots: Array[Panel] = []
	for child in slot_row.get_children():
		if child is Panel and child.has_method("show_open"):
			slots.append(child)
	if needed <= 0:
		for slot in slots:
			slot.visible = false
		return []
	if slots.is_empty():
		return []
	var template := slots[0]
	while slots.size() < needed:
		var copy := template.duplicate() as Panel
		copy.set_meta("generated", true)
		slot_row.add_child(copy)
		slots.append(copy)
	var used: Array[Panel] = []
	for index in slots.size():
		var slot := slots[index]
		slot.visible = index < needed
		if index < needed:
			used.append(slot)
	return used


func _accent(stars: int) -> Color:
	if stars >= 3:
		return color_hard
	if stars == 2:
		return color_mid
	return color_easy


func _texture_for(puzzle_id: int) -> Texture2D:
	var item := GameManager.get_phrase_item(puzzle_id)
	var image_number := puzzle_id
	if not item.is_empty():
		image_number = int(item.get("image_number", puzzle_id))
	return GameManager.level_texture(GameManager.find_level_image_path(image_number))


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


func _on_choice_chosen(puzzle_id: int) -> void:
	if puzzle_id <= 0:
		return
	PlayerProgress.ensure_sequence_run()
	var steps := PlayerProgress.run_steps()
	if steps.is_empty() and puzzle_id != CrazyPuzzle.PELE_ID:
		return
	if not _offer_rows(steps).has(puzzle_id):
		return
	SoundManager.play("ButtonClick")
	await PlayerProgress.ensure_loaded()
	PlayerProgress.open_run_puzzle(puzzle_id)


func _on_restart_pressed() -> void:
	SoundManager.play("ButtonClick")
	await PlayerProgress.ensure_loaded()
	PlayerProgress.restart_run()
	refresh()


func _on_tutorial_pressed() -> void:
	GameManager.set_go_to_game_disable()
	_go_to("res://scenes/crazygames/MenuTutorialCG.tscn")


func _on_ranking_pressed() -> void:
	HistoryManager.get_results_filtered("Todas", -1)
	_go_to("res://scenes/LeaderboardFINAL.tscn")


func _on_settings_pressed() -> void:
	if get_tree() != null:
		get_tree().set_meta("cifra_return_scene", SCENE_PATH)
	_go_to(SETTINGS_SCENE)


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
