@tool
extends VBoxContainer

@export var number_text := "0":
	set(value):
		number_text = value
		_apply()

@export var letter_text := "":
	set(value):
		letter_text = value
		_apply()

@export var letter_color := Color(0.90, 0.50, 0.13, 1):
	set(value):
		letter_color = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	$Number.text = number_text
	$Tile/Letter.text = letter_text
	$Tile/Letter.add_theme_color_override("font_color", letter_color)
