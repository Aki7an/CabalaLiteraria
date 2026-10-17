@tool
extends PanelContainer

const COLOR_LETTER := Color(0.90, 0.50, 0.13, 1)
const COLOR_HIGHLIGHT := Color(0.90, 0.50, 0.13, 1)

@export var numbers: PackedStringArray = PackedStringArray([
	"6", "17", "2", "19", "17", "2", "15", "19", "13", "2", "1"
]):
	set(value):
		numbers = value
		_apply()

@export var letters: PackedStringArray = PackedStringArray([
	"", "E", "", "", "E", "", "", "", "", "", ""
]):
	set(value):
		letters = value
		_apply()

@export var highlight_number := "":
	set(value):
		highlight_number = value
		_apply()

@export var highlight_color := COLOR_HIGHLIGHT:
	set(value):
		highlight_color = value
		_apply()

@export var letter_color := COLOR_LETTER:
	set(value):
		letter_color = value
		_apply()


func _ready() -> void:
	_apply()


func _cipher_tiles() -> Array[Node]:
	var row := get_node_or_null("Row")
	if row == null:
		return []
	var tiles: Array[Node] = []
	for child in row.get_children():
		if "letter_text" in child and "number_text" in child:
			tiles.append(child)
	return tiles


func _apply() -> void:
	if not is_inside_tree():
		return
	var tiles := _cipher_tiles()
	for index in tiles.size():
		var tile := tiles[index]
		if index < numbers.size():
			tile.set("number_text", str(numbers[index]))
		if index < letters.size():
			tile.set("letter_text", str(letters[index]))
		var number := str(tile.get("number_text"))
		var color := highlight_color if highlight_number != "" and number == highlight_number else letter_color
		tile.set("letter_color", color)
