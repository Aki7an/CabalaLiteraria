extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const PATH_GAME := "res://scenes/App.tscn"

@export var style_next: StyleBoxFlat
@export var style_next_hover: StyleBoxFlat
@export var style_next_pressed: StyleBoxFlat
@export var style_play: StyleBoxFlat
@export var style_play_hover: StyleBoxFlat
@export var style_play_pressed: StyleBoxFlat
@export var style_dot_on: StyleBoxFlat
@export var style_dot_off: StyleBoxFlat
@export var style_check_off: StyleBoxFlat
@export var style_check_on: StyleBoxFlat

@onready var _pages: Array[Control] = [
	$TutorialCard/Pages/Page1,
	$TutorialCard/Pages/Page2,
	$TutorialCard/Pages/Page3,
	$TutorialCard/Pages/Page4,
	$TutorialCard/Pages/Page5,
]
@onready var _dots: Array[Button] = [
	$TutorialCard/Dots/Dot1,
	$TutorialCard/Dots/Dot2,
	$TutorialCard/Dots/Dot3,
	$TutorialCard/Dots/Dot4,
	$TutorialCard/Dots/Dot5,
]
@onready var _step_badge: Label = $TutorialCard/StepBadge
@onready var _next_button: Button = %ButtonNext
@onready var _play_button: Button = %ButtonPlay
@onready var _skip_row: Button = %SkipRow
@onready var _skip_box: Panel = %SkipBox
@onready var _skip_mark: Label = %SkipMark
@onready var _skip_label: Label = %SkipLabel

var _page_index := 0


func _ready() -> void:
	for page in _pages:
		_fit_page(page)
		page.visible = true
	_load_skip_from_prefs()
	_apply_locale()
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	await tree.process_frame
	if not is_inside_tree():
		return
	_show_page(0, false)


func _is_pregame() -> bool:
	return GameManager.go_to_game


func _apply_locale() -> void:
	for page in _pages:
		if page.has_method("apply_locale"):
			page.apply_locale()
	_skip_label.text = tr("TutSkipAtStart")
	_sync_footer()


func _load_skip_from_prefs() -> void:
	var skip := not PlayerPrefs.mostrar_tuto_antes_partida
	_skip_row.set_pressed_no_signal(skip)
	_apply_skip_visual(skip)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		_on_next_pressed()
	elif event.is_action_pressed("ui_left") and _page_index > 0:
		_show_page(_page_index - 1)


func _on_dot_pressed(index: int) -> void:
	_show_page(index)


func _on_next_pressed() -> void:
	if _page_index < _pages.size() - 1:
		_show_page(_page_index + 1)
	elif _is_pregame():
		_go_to_game()
	else:
		_go_to_main()


func _on_play_pressed() -> void:
	_go_to_game()


func _on_skip_toggled(pressed: bool) -> void:
	SoundManager.play("ButtonClick")
	_apply_skip_visual(pressed)
	PlayerPrefs.set_mostrar_tutorial(not pressed)


func _apply_skip_visual(pressed: bool) -> void:
	_skip_mark.text = "✓" if pressed else ""
	if _skip_box:
		_skip_box.add_theme_stylebox_override("panel", style_check_on if pressed else style_check_off)


func _fit_page(page: Control) -> void:
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.position = Vector2.ZERO


func _show_page(index: int, animate := true) -> void:
	_page_index = clampi(index, 0, _pages.size() - 1)
	for page_index in range(_pages.size()):
		var page := _pages[page_index]
		_fit_page(page)
		page.visible = page_index == _page_index
		page.modulate.a = 1.0
		if page.has_method("set_active"):
			page.set_active(page.visible)
		if page.visible and animate:
			page.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(page, "modulate:a", 1.0, 0.24)
	_step_badge.text = "%d / %d" % [_page_index + 1, _pages.size()]
	_sync_footer()
	for dot_index in range(_dots.size()):
		var selected := dot_index == _page_index
		var style := style_dot_on if selected else style_dot_off
		_dots[dot_index].add_theme_stylebox_override("normal", style)
		_dots[dot_index].add_theme_stylebox_override("hover", style)
		_dots[dot_index].add_theme_stylebox_override("pressed", style)
	if animate:
		SoundManager.play("ButtonClick")


func _sync_footer() -> void:
	var last := _page_index == _pages.size() - 1
	var pregame := _is_pregame()
	_play_button.visible = pregame
	_play_button.text = tr("Play").to_upper()
	if pregame:
		_next_button.visible = not last
		_next_button.text = tr("Next")
		_next_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		_next_button.offset_left = -500.0
		_next_button.offset_top = -230.0
		_next_button.offset_right = -28.0
		_next_button.offset_bottom = -110.0
		_next_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	else:
		_next_button.visible = true
		_next_button.text = tr("EXIT") if last else tr("Next")
		_next_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_next_button.offset_left = -236.0
		_next_button.offset_top = -230.0
		_next_button.offset_right = 236.0
		_next_button.offset_bottom = -110.0
		_next_button.grow_horizontal = Control.GROW_DIRECTION_BOTH


func _go_to_game() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	GameManager.set_go_to_game_disable()
	SignalManager.partida_iniciada.emit()
	get_tree().change_scene_to_file(PATH_GAME)


func _go_to_main() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	GameManager.set_go_to_game_disable()
	get_tree().change_scene_to_file(PATH_MAIN)


func _on_button_back_pressed() -> void:
	if _is_pregame():
		_go_to_game()
	else:
		_go_to_main()
