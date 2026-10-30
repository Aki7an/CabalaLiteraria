extends ColorRect

const PUZZLE_SELECTION := "res://scenes/MenuSelectLevelByID.tscn"
const SETTINGS_SCENE := preload("res://scenes/MenuSettings.tscn")

const HORIZONTAL_CANVAS := Vector2(1280, 720)

var _leaving := false
var _horizontal_stacked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	z_index = 120
	get_tree().paused = true
	SoundManager.fade_to_menu_music()
	$Card/Title.text = tr("PauseTitle")
	$Card/Subtitle.text = tr("PauseSavedWhilePlaying")
	$Card/Actions/ButtonContinue.text = tr("KeepPlaying")
	$Card/Actions/ButtonRestart.text = tr("RestartPuzzle")
	$Card/Actions/ButtonOptions/Row/Text.text = tr("Options").to_upper()
	$Card/Actions/ButtonExit.text = tr("ExitToMenu")
	$Card/SaveNote.text = tr("ProgressAutoSaved")
	if Distribution.is_horizontal():
		_apply_horizontal_layout()
		call_deferred("_apply_horizontal_layout")


func _apply_horizontal_layout() -> void:
	var canvas := _cover_horizontal_canvas()
	color = Color(0.04, 0.045, 0.05, 0.72)
	_style_horizontal_card()
	if not _horizontal_stacked:
		_stack_horizontal_content()
		_horizontal_stacked = true
	_place_horizontal_card(canvas)


func _cover_horizontal_canvas() -> Vector2:
	var canvas_size := HORIZONTAL_CANVAS
	var host := get_parent() as Control
	if host != null:
		var canvas := host.get_parent() as Control
		if canvas != null and canvas.size.x >= 320.0 and canvas.size.y >= 240.0:
			canvas_size = canvas.size
		host.set_anchors_preset(Control.PRESET_TOP_LEFT)
		host.offset_left = 0.0
		host.offset_top = 0.0
		host.offset_right = canvas_size.x
		host.offset_bottom = canvas_size.y
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = canvas_size
	return canvas_size


func _style_horizontal_card() -> void:
	var card := $Card as Panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.19, 0.21, 0.8)
	style.set_border_width_all(2)
	style.border_width_bottom = 4
	style.border_color = Color(1, 1, 1, 0.16)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", style)
	card.clip_contents = false


func _stack_horizontal_content() -> void:
	var card := $Card
	var icon := card.get_node("MenuIcon") as Label
	var title := card.get_node("Title") as Label
	var subtitle := card.get_node("Subtitle") as Label
	var actions := card.get_node("Actions") as VBoxContainer
	var note := card.get_node("SaveNote") as Label

	icon.add_theme_font_size_override("font_size", 28)
	icon.add_theme_color_override("font_color", Color(0.93, 0.94, 0.95))
	icon.custom_minimum_size = Vector2(0, 30)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.97, 0.96, 0.94))
	title.custom_minimum_size = Vector2(0, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.84, 0.86, 0.88, 0.92))
	subtitle.custom_minimum_size = Vector2(0, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	note.add_theme_font_size_override("font_size", 15)
	note.add_theme_color_override("font_color", Color(0.8, 0.82, 0.84, 0.9))
	note.custom_minimum_size = Vector2(0, 24)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	actions.add_theme_constant_override("separation", 10)
	var gap := actions.get_node("OptionsGap") as Control
	gap.custom_minimum_size = Vector2(0, 6)
	for button_name in ["ButtonOptions", "ButtonContinue", "ButtonRestart", "ButtonExit"]:
		var button := actions.get_node(button_name) as Button
		button.custom_minimum_size = Vector2(0, 58)
		button.add_theme_font_size_override("font_size", 22)
	var options_text := actions.get_node("ButtonOptions/Row/Text") as Label
	options_text.add_theme_font_size_override("font_size", 22)
	var options_icon := actions.get_node("ButtonOptions/Row/Icon") as TextureRect
	options_icon.custom_minimum_size = Vector2(28, 28)

	var margin := MarginContainer.new()
	margin.name = "HorizontalFit"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 6)
	margin.add_child(stack)

	for node in [icon, title, subtitle, actions, note]:
		node.reparent(stack)
		node.set_anchors_preset(Control.PRESET_TOP_LEFT)
		node.offset_left = 0.0
		node.offset_top = 0.0
		node.offset_right = 0.0
		node.offset_bottom = 0.0
		node.position = Vector2.ZERO
		node.layout_mode = 2
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _place_horizontal_card(canvas: Vector2) -> void:
	var card := $Card as Control
	var width := minf(700.0, canvas.x - 40.0)
	var height := minf(528.0, canvas.y - 28.0)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -width * 0.5
	card.offset_top = -height * 0.5
	card.offset_right = width * 0.5
	card.offset_bottom = height * 0.5


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _on_button_seguir_pressed() -> void:
	SoundManager.play("ButtonClick")
	SoundManager.fade_to_game_music()
	get_tree().paused = false
	queue_free()


func _on_button_reiniciar_pressed() -> void:
	SoundManager.play("ButtonClick")
	SoundManager.fade_to_game_music()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tree := get_tree()
	GameManager.puzzle_enter_pending = true
	if GameManager.is_onboarding_session():
		var stage := GameManager.onboarding_stage
		if stage < 1:
			stage = 1
		for node in tree.get_nodes_in_group("OnboardingGuide"):
			if is_instance_valid(node):
				node.process_mode = Node.PROCESS_MODE_DISABLED
				node.queue_free()
		GameManager.prepare_onboarding_puzzle(stage)
		GameManager.clear_resolution_runtime_state()
	else:
		PuzzleSaveManager.reset_resolution_keep_attempt()
	tree.paused = false
	tree.change_scene_to_file("res://scenes/App.tscn")


func _on_button_options_pressed() -> void:
	SoundManager.play("ButtonClick")
	if has_node("SettingsOverlay"):
		return
	var overlay := SETTINGS_SCENE.instantiate()
	overlay.name = "SettingsOverlay"
	overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(overlay)
	if overlay is Control:
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_button_salir_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	SoundManager.play("ButtonClick")
	process_mode = Node.PROCESS_MODE_ALWAYS
	PuzzleSaveManager.save_current_now()
	var tree := get_tree()
	var leaving_onboarding := GameManager.is_onboarding_session()
	if leaving_onboarding:
		GameManager.session_source = GameManager.SOURCE_NONE
		GameManager.onboarding_stage = 0
	for group_name in ["OnboardingGuide", "BasicStartTutorial"]:
		for node in tree.get_nodes_in_group(group_name):
			if is_instance_valid(node):
				node.process_mode = Node.PROCESS_MODE_DISABLED
				node.queue_free()
	# La subida de la traza usa HTTPRequest, que no avanza con el árbol en pausa.
	tree.paused = false
	EventLoggerAutoload.submit_if_consented(EventLoggerAutoload.OUTCOME_ABANDONED)
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if not is_instance_valid(tree):
		return
	if leaving_onboarding:
		tree.change_scene_to_file(Distribution.home_scene())
		return
	tree.change_scene_to_file(PUZZLE_SELECTION)
