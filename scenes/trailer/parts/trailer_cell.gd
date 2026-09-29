@tool
extends Panel

const COLOR_TILE := Color(0.975, 0.965, 0.945, 1)
const COLOR_SPACE := Color(0.10, 0.09, 0.08, 1)
const COLOR_FILL := Color(0.78, 0.76, 0.74, 1)

@export var cipher_letter := "":
	set(value):
		cipher_letter = value
		_apply()

@export var cipher_number := 0:
	set(value):
		cipher_number = value
		_apply()

@export var is_space := false:
	set(value):
		is_space = value
		_apply()

@export var start_letter := "":
	set(value):
		start_letter = value
		_apply()

@export var is_fixed := false:
	set(value):
		is_fixed = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	var style := get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var flat := (style as StyleBoxFlat).duplicate() as StyleBoxFlat
		flat.bg_color = COLOR_SPACE if is_space else COLOR_TILE
		add_theme_stylebox_override("panel", flat)
	$Number.visible = not is_space and not is_fixed
	$Number.text = str(cipher_number)
	var shown := start_letter.strip_edges()
	if is_fixed and shown == "":
		shown = cipher_letter
	$Letter.visible = not is_space and shown != ""
	$Letter.text = shown


func show_letter(text: String, color: Color, bg: Color) -> void:
	if is_space or is_fixed:
		return
	$Letter.text = text
	$Letter.visible = text != ""
	$Letter.add_theme_color_override("font_color", color)
	_set_bg(bg)


func clear_letter() -> void:
	if is_fixed:
		return
	show_letter("", Color(0.18, 0.12, 0.08, 1), COLOR_TILE)


func set_bg(color: Color) -> void:
	_set_bg(color)


func _set_bg(color: Color) -> void:
	var style := get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var flat := (style as StyleBoxFlat).duplicate() as StyleBoxFlat
		flat.bg_color = color
		add_theme_stylebox_override("panel", flat)
