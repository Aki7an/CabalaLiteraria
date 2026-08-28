@tool
extends Button

@export var enabled_color := Color("#13A8A7")
@export var disabled_color := Color("#C9C2AE")
@export var knob_color := Color("#FFF8E7")
@export var check_color := Color("#159A9A")


func _ready() -> void:
	toggle_mode = true
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggled.connect(_on_toggled)
	resized.connect(queue_redraw)
	queue_redraw()


func _on_toggled(_enabled: bool) -> void:
	queue_redraw()


func _draw() -> void:
	var height := size.y
	var radius := height * 0.5
	var background := StyleBoxFlat.new()
	background.bg_color = enabled_color if button_pressed else disabled_color
	background.corner_radius_top_left = int(radius)
	background.corner_radius_top_right = int(radius)
	background.corner_radius_bottom_left = int(radius)
	background.corner_radius_bottom_right = int(radius)
	background.shadow_color = Color(0.25, 0.16, 0.09, 0.16)
	background.shadow_size = 4
	background.shadow_offset = Vector2(0, 4)
	draw_style_box(background, Rect2(Vector2.ZERO, size))

	var knob_radius := height * 0.37
	var knob_x := size.x - radius if button_pressed else radius
	draw_circle(Vector2(knob_x, radius), knob_radius, knob_color, true, -1.0, true)

	if button_pressed:
		var center := Vector2(knob_x, radius)
		var stroke := maxf(3.0, height * 0.075)
		draw_line(
			center + Vector2(-knob_radius * 0.42, 0.02 * height),
			center + Vector2(-knob_radius * 0.10, knob_radius * 0.34),
			check_color,
			stroke,
			true
		)
		draw_line(
			center + Vector2(-knob_radius * 0.10, knob_radius * 0.34),
			center + Vector2(knob_radius * 0.50, -knob_radius * 0.38),
			check_color,
			stroke,
			true
		)
