extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const PATH_GAME := "res://scenes/App.tscn"
const PATH_SELECTION := "res://scenes/MenuSelectCategory.tscn"

@export var style_next: StyleBoxFlat
@export var style_next_hover: StyleBoxFlat
@export var style_next_pressed: StyleBoxFlat
@export var style_play: StyleBoxFlat
@export var style_play_hover: StyleBoxFlat
@export var style_play_pressed: StyleBoxFlat
@export var style_dot_on: StyleBoxFlat
@export var style_dot_off: StyleBoxFlat

@onready var _pages: Array[Control] = [
	$TutorialCard/Pages/Page1,
	$TutorialCard/Pages/Page2,
	$TutorialCard/Pages/Page3,
	$TutorialCard/Pages/Page4,
]
@onready var _dots: Array[Button] = [
	$TutorialCard/Dots/Dot1,
	$TutorialCard/Dots/Dot2,
	$TutorialCard/Dots/Dot3,
	$TutorialCard/Dots/Dot4,
]
@onready var _step_badge: Label = $TutorialCard/StepBadge
@onready var _next_button: Button = $TutorialCard/ButtonNext

var _page_index := 0


func _ready() -> void:
	for page in _pages:
		_fit_page(page)
		page.visible = true
	_apply_locale()
	await get_tree().process_frame
	_show_page(0, false)


func _apply_locale() -> void:
	var page1 := _pages[0]
	_set_tr(page1.get_node_or_null("TitleRow/Title"), "TutTitle1")
	_set_tr(page1.get_node_or_null("Body1"), "TutBody1a")
	_set_tr(page1.get_node_or_null("Body2"), "TutBody1b")
	_set_tr(page1.get_node_or_null("Caption1"), "TutCap1")
	_set_tr(page1.get_node_or_null("Caption2"), "TutCap2")
	_set_tr(page1.get_node_or_null("Caption3"), "TutCap3")
	_set_tr(page1.get_node_or_null("Caption4"), "TutCap4")
	var page2 := _pages[1]
	_set_tr(page2.get_node_or_null("TitleRow/Title"), "TutTitle2")
	_set_tr(page2.get_node_or_null("Body1"), "TutBody2a")
	_set_tr(page2.get_node_or_null("Body2"), "TutBody2b")
	_set_tr(page2.get_node_or_null("Preview/Box/TopBar/Curiosidades/Label"), "Curiosities")
	_set_tr(page2.get_node_or_null("Preview/Box/TopBar/Stats/StarsTitle"), "TutStarsPuzzle")
	_set_tr(page2.get_node_or_null("Preview/Box/TopBar/Stats/Mode/Label"), "TutQuickGame")
	_set_tr(page2.get_node_or_null("Preview/Box/Actions/Tema/Row/Title"), "THEME")
	_set_tr(page2.get_node_or_null("Preview/Box/Actions/Pista/Row/Title"), "TutHint")
	_set_tr(page2.get_node_or_null("Preview/Box/Actions/Revelar/Row/Title"), "TutReveal")
	_set_tr(page2.get_node_or_null("Preview/Box/Colors/Erase/Row/Title"), "ERASE")
	_set_tr(page2.get_node_or_null("Preview/Box/Caption"), "TutCaption2")
	_set_tr(page2.get_node_or_null("Tip"), "TutTipColorsFree")
	var letters := page2.get_node_or_null("Preview/Box/TopBar/Stats/Letters") as Label
	if letters:
		letters.text = "%s 43 / 167" % tr("LETTERS")
	var page3 := _pages[2]
	_set_tr(page3.get_node_or_null("TitleRow/Title"), "TutTitle3")
	_set_tr(page3.get_node_or_null("Intro"), "TutIntro3")
	_set_tr(page3.get_node_or_null("Actions/PistaCol/PistaCard/PistaBox/Title"), "TutHint")
	_set_tr(page3.get_node_or_null("Actions/PistaCol/PistaText"), "TutHintExplain")
	_set_tr(page3.get_node_or_null("Actions/RevelarCol/RevelarCard/RevelarBox/Title"), "TutReveal")
	_set_tr(page3.get_node_or_null("Actions/RevelarCol/RevelarText"), "TutRevealExplain")
	_set_tr(page3.get_node_or_null("Summary"), "TutSummary3")
	var page4 := _pages[3]
	_set_tr(page4.get_node_or_null("TitleRow/Title"), "TutTitle4")
	_set_tr(page4.get_node_or_null("Intro"), "TutIntro4")
	_set_tr(page4.get_node_or_null("Modes/QuickCard/QuickBox/Title"), "Quick")
	_set_tr(page4.get_node_or_null("Modes/QuickCard/QuickBox/Text"), "TutQuickDesc")
	_set_tr(page4.get_node_or_null("Modes/CryptoCard/CryptoBox/Title"), "Cryptogram")
	_set_tr(page4.get_node_or_null("Modes/CryptoCard/CryptoBox/Text"), "TutCryptoDesc")
	_set_tr(page4.get_node_or_null("SaveCard/SaveRow/Texts/Title"), "TutSaveTitle")
	_set_tr(page4.get_node_or_null("SaveCard/SaveRow/Texts/Text"), "TutSaveText")
	_set_tr(page4.get_node_or_null("StarsCard/StarsRow/Text"), "TutStarsGoal")


func _set_tr(node: Node, key: String) -> void:
	if node is Label or node is Button or node is RichTextLabel:
		node.text = tr(key)


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
	else:
		_finish_tutorial()


func _fit_page(page: Control) -> void:
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.position = Vector2.ZERO


func _show_page(index: int, animate := true) -> void:
	_page_index = clampi(index, 0, _pages.size() - 1)
	var last := _page_index == _pages.size() - 1
	for page_index in range(_pages.size()):
		var page := _pages[page_index]
		_fit_page(page)
		page.visible = page_index == _page_index
		page.modulate.a = 1.0
		if page.visible and animate:
			page.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(page, "modulate:a", 1.0, 0.24)
	_step_badge.text = "%d / %d" % [_page_index + 1, _pages.size()]
	_next_button.text = tr("LetsPlay") if last else tr("Next")
	_next_button.add_theme_stylebox_override("normal", style_play if last else style_next)
	_next_button.add_theme_stylebox_override(
		"hover",
		style_play_hover if last else style_next_hover
	)
	_next_button.add_theme_stylebox_override(
		"pressed",
		style_play_pressed if last else style_next_pressed
	)
	for dot_index in range(_dots.size()):
		var selected := dot_index == _page_index
		var style := style_dot_on if selected else style_dot_off
		_dots[dot_index].add_theme_stylebox_override("normal", style)
		_dots[dot_index].add_theme_stylebox_override("hover", style)
		_dots[dot_index].add_theme_stylebox_override("pressed", style)
	if animate:
		SoundManager.play("ButtonClick")


func _finish_tutorial() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if GameManager.go_to_game:
		SignalManager.partida_iniciada.emit()
		get_tree().change_scene_to_file(PATH_GAME)
	else:
		get_tree().change_scene_to_file(PATH_SELECTION)


func _on_button_back_pressed() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if GameManager.go_to_game:
		SignalManager.partida_iniciada.emit()
		get_tree().change_scene_to_file(PATH_GAME)
	else:
		get_tree().change_scene_to_file(PATH_MAIN)
