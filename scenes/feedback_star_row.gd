extends HBoxContainer
class_name FeedbackStarRow

signal rating_changed(value: int)

const STAR_ON := preload("res://images/estrella_plano.png")
const STAR_OFF := preload("res://images/contorno_estrella.png")

var question_stars: int = 0
var _buttons: Array[Button] = []
var _icons: Array[TextureRect] = []


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 14)
	var fill := GameManager.star_fill_color()
	for index in range(5):
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(88, 88)
		button.flat = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var icon := TextureRect.new()
		icon.texture = STAR_OFF
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.modulate = Color(0.72, 0.68, 0.6, 0.45)
		button.add_child(icon)
		button.pressed.connect(_on_star_pressed.bind(index + 1))
		add_child(button)
		_buttons.append(button)
		_icons.append(icon)
	_paint(0, fill)


func _on_star_pressed(value: int) -> void:
	question_stars = value
	_paint(value, GameManager.star_fill_color())
	rating_changed.emit(value)
	SoundManager.play("ButtonClick")


func _paint(value: int, fill: Color) -> void:
	for index in range(_icons.size()):
		var on := index < value
		_icons[index].texture = STAR_ON if on else STAR_OFF
		_icons[index].modulate = fill if on else Color(0.72, 0.68, 0.6, 0.45)
