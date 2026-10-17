extends Panel

const TIP_KEYS: PackedStringArray = [
	"TipShort",
	"TipDeduce",
	"TipLongTexts",
	"TipColors",
]

@export var interval_seconds := 8.0
@export var fade_time := 0.22

@onready var tip_title: Label = %TipTitle
@onready var tip_text: RichTextLabel = %TipText
@onready var dots: HBoxContainer = %Dots
@onready var pause_play_button: Button = %PausePlay
@onready var progress: ProgressBar = %Progress
@onready var timer: Timer = %Timer

var _idx := 0
var _advancing := false
var _is_paused := false
var _progress_tween: Tween
var _dot_nodes: Array[Panel] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tip_title.text = tr("Consejo").to_upper()
	tip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not pause_play_button.pressed.is_connected(_on_pause_play_pressed):
		pause_play_button.pressed.connect(_on_pause_play_pressed)
	_build_dots()
	_show_tip(_idx, false)
	timer.wait_time = interval_seconds
	timer.one_shot = true
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
	_restart_progress()
	timer.start()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			_advance()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			accept_event()
			_advance()

func _on_timer_timeout() -> void:
	_advance()

func _advance() -> void:
	if _advancing or TIP_KEYS.is_empty():
		return
	_advancing = true
	timer.stop()
	var next_idx := (_idx + 1) % TIP_KEYS.size()
	await _show_tip(next_idx, true)
	_idx = next_idx
	_restart_progress()
	timer.start()
	_advancing = false

func _show_tip(index: int, animate: bool) -> void:
	_idx = index
	_refresh_dots()
	var translated := tr(TIP_KEYS[index])
	if not animate:
		tip_text.modulate.a = 1.0
		tip_text.text = translated
		return
	var fade := create_tween()
	fade.tween_property(tip_text, "modulate:a", 0.0, fade_time)
	await fade.finished
	tip_text.text = translated
	var fade_in := create_tween()
	fade_in.tween_property(tip_text, "modulate:a", 1.0, fade_time)
	await fade_in.finished

func _restart_progress() -> void:
	progress.min_value = 0
	progress.max_value = 100
	progress.value = 0
	if is_instance_valid(_progress_tween):
		_progress_tween.kill()
	_progress_tween = create_tween()
	_progress_tween.set_trans(Tween.TRANS_LINEAR)
	_progress_tween.tween_property(progress, "value", 100.0, interval_seconds)
	if _is_paused:
		_progress_tween.pause()

func _build_dots() -> void:
	for child in dots.get_children():
		if child == pause_play_button:
			continue
		dots.remove_child(child)
		child.queue_free()
	_dot_nodes.clear()
	for i in TIP_KEYS.size():
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(11, 11)
		dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots.add_child(dot)
		dots.move_child(dot, pause_play_button.get_index())
		_dot_nodes.append(dot)
	_refresh_dots()

func _on_pause_play_pressed() -> void:
	_is_paused = not _is_paused
	timer.paused = _is_paused
	if is_instance_valid(_progress_tween):
		if _is_paused:
			_progress_tween.pause()
		else:
			_progress_tween.play()
	pause_play_button.text = "▶" if _is_paused else "Ⅱ"
	pause_play_button.tooltip_text = tr("ResumeTips") if _is_paused else tr("PauseTips")

func _refresh_dots() -> void:
	var active := Color(0.364706, 0.25098, 0.215686, 1)
	var idle := Color(0.364706, 0.25098, 0.215686, 0.25)
	for i in _dot_nodes.size():
		_dot_nodes[i].add_theme_stylebox_override(
			"panel",
			_make_dot_style(active if i == _idx else idle)
		)

func _make_dot_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.anti_aliasing = true
	style.anti_aliasing_size = 0.5
	return style
