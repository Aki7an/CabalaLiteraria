extends Panel

const STAR_ON: Texture2D = preload("res://images/estrella_plano.png")
const STAR_OFF: Texture2D = preload("res://images/estrella_hueca.png")
const STAR_FILLED := Color(1, 0.78, 0.16, 1)
const STAR_EMPTY := Color(0.62, 0.56, 0.48, 0.9)
const DONE_TINT := Color(1, 1, 1, 0.72)

@onready var index_label: Label = $Index
@onready var art: TextureRect = $Art
@onready var stamp: CanvasItem = $Stamp
@onready var placeholder: CanvasItem = $Placeholder
@onready var hint: CanvasItem = $Placeholder/Hint
@onready var highlight: CanvasItem = $Highlight
@onready var star_icons: Array[TextureRect] = [
	$Stars/Star1,
	$Stars/Star2,
	$Stars/Star3,
]


func show_completed(step_text: String, texture: Texture2D, earned: int, maximum: int = 3) -> void:
	_apply_locale()
	index_label.text = step_text
	art.texture = texture
	art.visible = texture != null
	stamp.visible = true
	placeholder.visible = false
	highlight.visible = false
	modulate = DONE_TINT
	_paint_stars(maximum, earned)


func show_open(step_text: String, star_count: int, current: bool) -> void:
	_apply_locale()
	index_label.text = step_text
	art.visible = false
	stamp.visible = false
	placeholder.visible = true
	hint.visible = current
	highlight.visible = current
	modulate = Color.WHITE if current else Color(1, 1, 1, 0.8)
	_paint_stars(star_count, 0)


func _apply_locale() -> void:
	_plain(index_label, index_label.text)
	_plain($Placeholder/State, tr("RunSlotPending"))
	_plain($Placeholder/Hint, tr("RunSlotHint"))
	_plain($Stamp/Word, tr("RunSlotDone"))


func _plain(node: Label, value: String) -> void:
	if node == null:
		return
	node.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	node.text = value


func _paint_stars(count: int, filled_count: int) -> void:
	var shown := clampi(count, 0, star_icons.size())
	var filled := clampi(filled_count, 0, shown)
	for index in star_icons.size():
		var icon := star_icons[index]
		var is_filled := index < filled
		icon.visible = index < shown
		icon.texture = STAR_ON if is_filled else STAR_OFF
		icon.modulate = STAR_FILLED if is_filled else STAR_EMPTY
