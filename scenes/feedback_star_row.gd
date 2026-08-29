extends HBoxContainer
class_name FeedbackStarRow

signal rating_changed(value: int)

const STAR_TEX := preload("res://images/estrella_plano.png")
const COLOR_ON := Color(1.0, 0.82, 0.12, 1.0)
const COLOR_OFF := Color(0.7, 0.62, 0.5, 0.35)

var question_stars: int = 0
var _buttons: Array[Button] = []
var _icons: Array[TextureRect] = []


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 10)
	for index in range(5):
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(72, 72)
		button.flat = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var icon := TextureRect.new()
		icon.texture = STAR_TEX
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.self_modulate = COLOR_OFF
		button.add_child(icon)
		button.pressed.connect(_on_star_pressed.bind(index + 1))
		add_child(button)
		_buttons.append(button)
		_icons.append(icon)


func _on_star_pressed(value: int) -> void:
	question_stars = value
	for index in range(_icons.size()):
		_icons[index].self_modulate = COLOR_ON if index < value else COLOR_OFF
	rating_changed.emit(value)
	SoundManager.play("ButtonClick")
