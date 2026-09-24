extends Control

const FONT_TITLE: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const WORD_COLORS: Array[Color] = [
	Color(0.48, 0.24, 0.10, 1),
	Color(0.82, 0.42, 0.08, 1),
	Color(0.98, 0.62, 0.12, 1),
]
const KEYS := ["IntroObserve", "IntroDecipher", "IntroDiscover"]
const FALLBACKS := ["MIRA", "DESCIFRA", "DESCUBRE"]

@export var letter_size: int = 68
@export var letter_embolden: float = 0.85

var _font: FontVariation


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_fill_words")


func prepare_intro() -> void:
	visible = true
	_fill_words()
	for row in intro_rows():
		row.modulate.a = 0.0


func intro_rows() -> Array[CanvasItem]:
	var rows: Array[CanvasItem] = []
	for key in KEYS:
		var row := find_child(key, true, false) as CanvasItem
		if row:
			rows.append(row)
	return rows


func _title_font() -> Font:
	if _font == null:
		_font = FontVariation.new()
		_font.base_font = FONT_TITLE
		_font.variation_embolden = letter_embolden
	return _font


func _word_text(key: String, fallback: String) -> String:
	var text := tr(key).strip_edges()
	if text.is_empty() or text == key:
		text = fallback
	return text.to_upper()


func _letter_color(t: float) -> Color:
	var x := clampf(t, 0.0, 1.0)
	if x <= 0.5:
		return WORD_COLORS[0].lerp(WORD_COLORS[1], x * 2.0)
	return WORD_COLORS[1].lerp(WORD_COLORS[2], (x - 0.5) * 2.0)


func _fill_words() -> void:
	var words: Array[String] = []
	var total := 0
	for i in KEYS.size():
		var word := _word_text(KEYS[i], FALLBACKS[i])
		words.append(word)
		total += word.length()
	var letter_index := 0
	for i in KEYS.size():
		var col := find_child(KEYS[i], true, false) as Control
		if col == null:
			continue
		var letters := col.find_child("Letters", true, false) as HBoxContainer
		if letters == null:
			continue
		var previous := letters.get_children()
		for child in previous:
			letters.remove_child(child)
			child.queue_free()
		var word: String = words[i]
		for j in word.length():
			var t := 0.0 if total <= 1 else float(letter_index) / float(total - 1)
			var glyph := Label.new()
			glyph.text = word.substr(j, 1)
			glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
			glyph.add_theme_font_override("font", _title_font())
			glyph.add_theme_font_size_override("font_size", letter_size)
			var color := _letter_color(t)
			glyph.add_theme_color_override("font_color", color)
			glyph.add_theme_constant_override("outline_size", 5)
			glyph.add_theme_color_override("font_outline_color", color)
			letters.add_child(glyph)
			letter_index += 1
