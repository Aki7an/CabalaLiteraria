extends Panel

signal chosen(puzzle_id: int)

const STAR_ON: Texture2D = preload("res://images/estrella_plano.png")

const PULSE_SCALE := Vector2(1.12, 1.12)

var puzzle_id := -1
var _pulse: Tween

@onready var art: TextureRect = $ArtFrame/Art
@onready var play: Button = $Play
@onready var star_icons: Array[TextureRect] = [
	$Stars/Star1,
	$Stars/Star2,
	$Stars/Star3,
]


func _ready() -> void:
	_sync_pulse()


func present(next_puzzle_id: int, texture: Texture2D, star_count: int, accent: Color, enabled: bool = true) -> void:
	puzzle_id = next_puzzle_id
	visible = true
	modulate = Color(1, 1, 1, 1) if enabled else Color(1, 1, 1, 0.42)
	if art != null:
		art.texture = texture
	_paint_frame(accent)
	_paint_play(accent)
	if play != null:
		play.disabled = not enabled
		play.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
		_sync_pulse()
	var shown := clampi(star_count, 0, star_icons.size())
	for index in star_icons.size():
		var icon := star_icons[index]
		icon.visible = index < shown
		icon.texture = STAR_ON
		icon.modulate = accent


func _on_play_pressed() -> void:
	if puzzle_id <= 0 or play == null or play.disabled:
		return
	chosen.emit(puzzle_id)


func _sync_pulse() -> void:
	if play == null:
		return
	play.pivot_offset = Vector2(
		play.offset_right - play.offset_left,
		play.offset_bottom - play.offset_top
	) * 0.5
	var can_pulse := visible and not play.disabled
	if not can_pulse:
		_stop_pulse()
		return
	if _pulse != null and _pulse.is_valid():
		return
	play.scale = Vector2.ONE
	_pulse = create_tween()
	_pulse.set_loops()
	_pulse.set_trans(Tween.TRANS_SINE)
	_pulse.set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(play, "scale", PULSE_SCALE, 0.42)
	_pulse.tween_property(play, "scale", Vector2.ONE, 0.42)


func _stop_pulse() -> void:
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	_pulse = null
	if play != null:
		play.scale = Vector2.ONE


func _paint_frame(accent: Color) -> void:
	var style := get_theme_stylebox("panel")
	if style == null:
		return
	var copy := style.duplicate() as StyleBoxFlat
	if copy == null:
		return
	copy.border_color = accent
	add_theme_stylebox_override("panel", copy)


func _paint_play(accent: Color) -> void:
	if play == null:
		return
	var style := play.get_theme_stylebox("normal")
	if style == null:
		return
	var copy := style.duplicate() as StyleBoxFlat
	if copy == null:
		return
	copy.bg_color = accent
	copy.border_color = accent.darkened(0.22)
	var pressed := copy.duplicate() as StyleBoxFlat
	pressed.bg_color = accent.darkened(0.12)
	play.add_theme_stylebox_override("normal", copy)
	play.add_theme_stylebox_override("hover", copy)
	play.add_theme_stylebox_override("pressed", pressed)
	play.add_theme_stylebox_override("focus", copy)
