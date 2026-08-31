@tool
extends Panel

const COLOR_TILE := Color(1.0, 0.98, 0.92, 1)
const COLOR_SPACE := Color(0.10, 0.09, 0.08, 1)

@export var number := 0:
	set(value):
		number = value
		_apply()

@export var letter := "":
	set(value):
		letter = value
		_apply()

@export var fill_color := COLOR_TILE:
	set(value):
		fill_color = value
		_apply()

@export var is_space := false:
	set(value):
		is_space = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	var style := get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var flat := (style as StyleBoxFlat).duplicate() as StyleBoxFlat
		flat.bg_color = COLOR_SPACE if is_space else fill_color
		add_theme_stylebox_override("panel", flat)
	$Number.visible = not is_space
	$Letter.visible = not is_space and letter != ""
	$Number.text = str(number)
	$Letter.text = letter
