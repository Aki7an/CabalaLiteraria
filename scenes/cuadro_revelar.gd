extends ColorRect

const FONT_TITLE: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const COLOR_RED := Color("8B1E1E")
const COLOR_INK := Color("3D2B1F")
const COLOR_CHECK_ON := Color(0.93, 0.84, 0.68, 1)
const COLOR_CHECK_OFF := Color(1, 0.98, 0.93, 1)

@onready var card: PanelContainer = $Center/Card
@onready var letters_label: RichTextLabel = %Letters
@onready var skip_button: Button = %SkipRow
@onready var skip_mark: Label = %SkipMark
@onready var skip_box: Panel = %SkipBox


func _ready() -> void:
	add_to_group("RevealOverlay")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_letters()
	gui_input.connect(_on_background_input)


func _update_letters() -> void:
	var pending := _letters_to_check()
	if pending.is_empty():
		letters_label.add_theme_color_override("default_color", COLOR_RED)
		letters_label.add_theme_font_override("normal_font", FONT_TITLE)
		letters_label.text = "NINGUNA LETRA NUEVA A COMPROBAR"
		return
	var prefix := "Letra a comprobar:" if pending.size() == 1 else "Letras a comprobar:"
	letters_label.add_theme_color_override("default_color", COLOR_INK)
	letters_label.text = "%s [b][font_size=56]%s[/font_size][/b]" % [
		prefix,
		", ".join(pending)
	]


func _letters_to_check() -> PackedStringArray:
	var seen: Dictionary = {}
	var cells: Array[Celda] = []
	for node: Node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		var cell := node as Celda
		if cell.numero >= 100 or cell.letter_user == "" or cell.bloqueada:
			continue
		var letter := cell.letter_user.to_upper()
		if seen.has(letter):
			continue
		seen[letter] = true
		cells.append(cell)
	cells.sort_custom(func(a: Celda, b: Celda) -> bool:
		return a.orden < b.orden
	)
	var letters: PackedStringArray = []
	for cell in cells:
		letters.append(cell.letter_user.to_upper())
	return letters


func _on_background_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if card.get_global_rect().has_point((event as InputEventMouseButton).global_position):
		return
	SoundManager.play("ButtonClick")
	queue_free()


func _on_skip_pressed(_pressed: bool) -> void:
	SoundManager.play("ButtonClick")
	var checked := skip_button.button_pressed
	skip_mark.text = "✓" if checked else ""
	var style := skip_box.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style != null:
		style.bg_color = COLOR_CHECK_ON if checked else COLOR_CHECK_OFF
		skip_box.add_theme_stylebox_override("panel", style)


func _on_cancel_pressed() -> void:
	SoundManager.play("ButtonClick")
	queue_free()


func _on_reveal_pressed() -> void:
	SoundManager.play("ButtonClick")
	if skip_button.button_pressed:
		PlayerPrefs.skip_reveal_dialog = true
		PlayerPrefs.save_prefs()
	queue_free()
	GameManager.reveal_assignment_errors()
