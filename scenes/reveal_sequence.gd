extends ColorRect

const FONT_LETTER: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FF_ICON: Texture2D = preload("res://images/ui_icon_fast_forward_white.svg")
const VHS_SHADER: Shader = preload("res://scenes/vhs_fast_forward.gdshader")
const DIM_COLOR := Color(1, 1, 0.98, 0.62)
const RED_DIM_COLOR := Color(1, 0.96, 0.96, 0.62)
const LETTER_GREEN := Color(0.22, 0.62, 0.28, 1)
const LETTER_RED := Color(0.82, 0.12, 0.12, 1)
const BLINK_DIM := 0.22
const BLINK_STEP := 0.11
const LETTER_SIZE := 300
const HALO_SCALE := 1.30
const HALO_FADE := 0.10
## Center of the letter + halo, as a fraction of screen height measured from the bottom.
const LETTER_FROM_BOTTOM := 0.66
const LETTER_BOX := 480.0
const FF_SPEED := 2.0
## Circle diameter. Doubled from the 177 px button.
const FF_BUTTON_DIAMETER := 354.0
## Gap between the button and the bottom edge of the number board.
const FF_BUTTON_BOARD_MARGIN := 28.0
const FF_BUTTON_FADE := 0.16
## Same orange as the menu button in the header.
const FF_FACE := Color(1, 0.56, 0.02, 1)
const FF_EDGE := Color(0.72, 0.32, 0.02, 1)
const FF_FACE_ON := Color(0.9, 0.4, 0.015, 1)
const FF_EDGE_ON := Color(0.65, 0.25, 0.01, 1)
const FF_SHADOW := Color(0.4, 0.2, 0.03, 0.25)
const FF_ICON_ON := Color(1, 0.98, 0.92, 1)
## Relative to this overlay (z 80); the raised keyboard sits at 90.
const VHS_Z := 15
const FF_BUTTON_Z := 20
const VHS_BLEED := 48.0
const VHS_FADE_IN := 0.14
const VHS_FADE_OUT := 0.2

var _dimmer: ColorRect
var _halo: Control
var _letter_label: Label
var _running := false
var _keyboard_panel: Control
var _keyboard_z := 0
var _ff_button: Button
var _ff_icon: TextureRect
var _vhs: ColorRect
var _vhs_tween: Tween
var _speed := 1.0
var _timeline: Array[Tween] = []


class WhiteHalo extends Control:
	func _draw() -> void:
		var radius := minf(size.x, size.y) * 0.5
		if radius <= 0.5:
			return
		draw_circle(size * 0.5, radius, Color.WHITE, true, -1.0, true)


func _ready() -> void:
	add_to_group("RevealSequence")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	color = Color(0, 0, 0, 0)
	z_index = 80
	_raise_keyboard()
	_build()
	_run_sequence()


func _exit_tree() -> void:
	_restore_keyboard()
	SoundManager.set_letter_fast_forward(false)


func _raise_keyboard() -> void:
	var nodes := get_tree().get_nodes_in_group("KeyboardPanel")
	if nodes.is_empty():
		return
	_keyboard_panel = nodes[0] as Control
	if _keyboard_panel == null:
		return
	_keyboard_z = _keyboard_panel.z_index
	_keyboard_panel.z_index = 90


func _restore_keyboard() -> void:
	if is_instance_valid(_keyboard_panel):
		_keyboard_panel.z_index = _keyboard_z
	_keyboard_panel = null


func _clip_above_keyboard() -> void:
	if _keyboard_panel == null or not is_instance_valid(_keyboard_panel):
		return
	var top := _keyboard_panel.global_position.y
	if top <= 1.0:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 0.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = top
	_layout_letter_stack()
	if _letter_label and _letter_label.text != "":
		_layout_halo(_letter_label.text)


func _build() -> void:
	_dimmer = ColorRect.new()
	_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dimmer.color = Color(1, 1, 1, 0)
	add_child(_dimmer)

	_halo = WhiteHalo.new()
	_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_halo.modulate.a = 0.0
	add_child(_halo)

	_letter_label = Label.new()
	_letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_letter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_letter_label.add_theme_font_override("font", FONT_LETTER)
	_letter_label.add_theme_font_size_override("font_size", LETTER_SIZE)
	_letter_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.03, 0.02, 0.55))
	_letter_label.add_theme_constant_override("shadow_offset_y", 10)
	_letter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letter_label.modulate.a = 0.0
	add_child(_letter_label)
	_build_vhs_filter()
	_build_ff_button()
	resized.connect(_on_resized)
	_layout_letter_stack()


func _build_vhs_filter() -> void:
	_vhs = ColorRect.new()
	_vhs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vhs.z_index = VHS_Z
	_vhs.visible = false
	var material := ShaderMaterial.new()
	material.shader = VHS_SHADER
	material.set_shader_parameter("intensity", 0.0)
	_vhs.material = material
	add_child(_vhs)
	_fit_vhs_to_screen()


func _fit_vhs_to_screen() -> void:
	if _vhs == null:
		return
	var bleed := Vector2(VHS_BLEED, VHS_BLEED)
	_vhs.position = -bleed
	_vhs.size = get_viewport_rect().size + bleed * 2.0


func _build_ff_button() -> void:
	_ff_button = Button.new()
	_ff_button.toggle_mode = true
	_ff_button.focus_mode = Control.FOCUS_NONE
	_ff_button.z_index = FF_BUTTON_Z
	_ff_button.visible = false
	var normal := _ff_style(FF_FACE, FF_EDGE, false)
	var pressed := _ff_style(FF_FACE_ON, FF_EDGE_ON, true)
	_ff_button.add_theme_stylebox_override("normal", normal)
	_ff_button.add_theme_stylebox_override("hover", normal)
	_ff_button.add_theme_stylebox_override("pressed", pressed)
	_ff_button.add_theme_stylebox_override("hover_pressed", pressed)
	_ff_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_ff_icon = TextureRect.new()
	_ff_icon.texture = FF_ICON
	_ff_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ff_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ff_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ff_button.add_child(_ff_icon)
	_layout_ff_icon(false)
	_ff_button.toggled.connect(_on_ff_toggled)
	add_child(_ff_button)


func _ff_style(face: Color, edge: Color, sunken: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = face
	style.border_color = edge
	style.set_border_width_all(5)
	if sunken:
		style.border_width_top = 9
	else:
		style.border_width_bottom = 9
		style.shadow_color = FF_SHADOW
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 8)
	style.set_corner_radius_all(int(FF_BUTTON_DIAMETER))
	return style


## The sunken style moves the face down by the border difference (9 - 4 px).
func _layout_ff_icon(sunken: bool) -> void:
	var shift := 4.0 if sunken else 0.0
	var pad := FF_BUTTON_DIAMETER * 0.24
	_ff_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ff_icon.offset_left = pad
	_ff_icon.offset_top = pad - 2.0 + shift
	_ff_icon.offset_right = -pad
	_ff_icon.offset_bottom = -pad - 4.0 + shift


func _run_sequence() -> void:
	if _running:
		return
	_running = true
	await get_tree().process_frame
	_clip_above_keyboard()
	var assignments := _player_assignments()
	var steps := _count_green_reveal_steps(assignments)
	SoundManager.begin_green_letter_sequence(steps)
	if steps > 0 or not assignments.is_empty():
		_show_ff_button()
	await _reveal_initial_letters()
	_log_reveal_result(assignments)
	for assignment in assignments:
		if assignment.get("correct", false):
			await _reveal_correct(assignment)
		else:
			await _reveal_wrong(assignment)
	await _close_fast_forward()
	GameManager.finish_reveal_sequence()
	queue_free()


func _show_ff_button() -> void:
	_ff_button.visible = true
	_ff_button.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_ff_button, "modulate:a", 1.0, FF_BUTTON_FADE)


func _close_fast_forward() -> void:
	if _ff_button == null or not _ff_button.visible:
		return
	_ff_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade := FF_BUTTON_FADE
	if _speed != 1.0:
		_ff_button.set_pressed_no_signal(false)
		_set_fast_forward(false)
		fade = maxf(fade, VHS_FADE_OUT)
	var tween := create_tween()
	tween.tween_property(_ff_button, "modulate:a", 0.0, fade)
	await tween.finished


func _on_ff_toggled(active: bool) -> void:
	SoundManager.play("ButtonClick")
	_set_fast_forward(active)


func _set_fast_forward(active: bool) -> void:
	_speed = FF_SPEED if active else 1.0
	for tween in _timeline:
		if tween.is_valid():
			tween.set_speed_scale(_speed)
	SoundManager.set_letter_fast_forward(active, FF_SPEED)
	_layout_ff_icon(active)
	_ff_icon.modulate = FF_ICON_ON if active else Color.WHITE
	_fade_vhs(active)


func _fade_vhs(active: bool) -> void:
	if _vhs_tween:
		_vhs_tween.kill()
	if active:
		_vhs.visible = true
	_vhs_tween = create_tween()
	_vhs_tween.tween_property(
		_vhs.material, "shader_parameter/intensity",
		1.0 if active else 0.0,
		VHS_FADE_IN if active else VHS_FADE_OUT
	)
	if not active:
		_vhs_tween.tween_callback(_vhs.hide)


## Tweens that drive the letter timeline; fast-forward rescales all of them.
func _sequence_tween() -> Tween:
	for i in range(_timeline.size() - 1, -1, -1):
		if not _timeline[i].is_valid():
			_timeline.remove_at(i)
	var tween := create_tween()
	tween.set_speed_scale(_speed)
	_timeline.append(tween)
	return tween


func _wait(sec: float) -> void:
	var tween := _sequence_tween()
	tween.tween_interval(sec)
	await tween.finished


func _count_green_reveal_steps(assignments: Array[Dictionary]) -> int:
	var steps := 0
	for cell in _all_cells():
		if cell.es_regalo_inicial and not cell.revelada_verde:
			steps = 1
			break
	for assignment in assignments:
		if assignment.get("correct", false):
			steps += 1
	return steps


func _reveal_initial_letters() -> void:
	var grey: Array[Celda] = []
	var already_green: Array[Celda] = []
	for cell in _all_cells():
		if not cell.es_regalo_inicial:
			continue
		if cell.revelada_verde:
			already_green.append(cell)
		else:
			grey.append(cell)
	if not already_green.is_empty():
		GameManager.apply_reveal_initials_green(already_green)
	if grey.is_empty():
		return
	await _blink_cells(grey)
	GameManager.apply_reveal_initials_green(grey)
	await _wait(0.12)


func _reveal_correct(assignment: Dictionary) -> void:
	var cells := _cells_from(assignment)
	var letter := str(assignment.get("letter", ""))
	_feedback_soft()
	SoundManager.play_green_letter_click(true)
	await _show_center_letter(letter, LETTER_GREEN, false)
	GameManager.apply_reveal_correct_number(int(assignment.get("numero", 0)))
	await _blink_cells(cells)
	await _hide_center_letter()


func _reveal_wrong(assignment: Dictionary) -> void:
	var cells := _cells_from(assignment)
	var letter := str(assignment.get("letter", ""))
	var number := int(assignment.get("numero", 0))
	_feedback_error()
	SoundManager.play_red_letter_click()
	await _show_center_letter(letter, LETTER_RED, true)
	GameManager.apply_reveal_wrong_number(number)
	await _blink_cells(cells)
	await _hide_center_letter()
	if GameManager.consume_reveal_error_star(number, letter):
		await _animate_star_loss()
		GameManager.subtract_puzzle_stars(1)


func _letter_anchor_y() -> float:
	return 1.0 - LETTER_FROM_BOTTOM


func _on_resized() -> void:
	_layout_letter_stack()
	_fit_vhs_to_screen()
	if _letter_label and _letter_label.text != "":
		_layout_halo(_letter_label.text)


func _layout_letter_stack() -> void:
	if _letter_label == null:
		return
	var ay := _letter_anchor_y()
	var half := LETTER_BOX * 0.5
	_letter_label.anchor_left = 0.5
	_letter_label.anchor_top = ay
	_letter_label.anchor_right = 0.5
	_letter_label.anchor_bottom = ay
	_letter_label.offset_left = -half
	_letter_label.offset_top = -half
	_letter_label.offset_right = half
	_letter_label.offset_bottom = half
	_letter_label.pivot_offset = Vector2(half, half)
	_layout_ff_button()


func _layout_ff_button() -> void:
	if _ff_button == null:
		return
	var place := _ff_button_rect()
	_ff_button.anchor_left = 0.0
	_ff_button.anchor_top = 0.0
	_ff_button.anchor_right = 0.0
	_ff_button.anchor_bottom = 0.0
	_ff_button.offset_left = place.position.x
	_ff_button.offset_top = place.position.y
	_ff_button.offset_right = place.position.x + place.size.x
	_ff_button.offset_bottom = place.position.y + place.size.y


func _ff_button_rect() -> Rect2:
	var diameter := FF_BUTTON_DIAMETER
	var board := _board_frame()
	var center_x := size.x * 0.5
	var bottom := size.y - FF_BUTTON_BOARD_MARGIN
	if board != null and board.size.x > 1.0:
		var origin := get_global_transform().affine_inverse() * board.global_position
		center_x = origin.x + board.size.x * 0.5
		bottom = origin.y + board.size.y - FF_BUTTON_BOARD_MARGIN
	return Rect2(center_x - diameter * 0.5, bottom - diameter, diameter, diameter)


func _board_frame() -> Control:
	var parent_node := get_parent()
	if parent_node == null:
		return null
	return parent_node.get_node_or_null("BoardFrame") as Control


func _layout_halo(letter: String) -> void:
	var box := FONT_LETTER.get_string_size(
		letter.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, LETTER_SIZE
	)
	var diameter := maxf(box.x, box.y) * HALO_SCALE
	var ay := _letter_anchor_y()
	_halo.anchor_left = 0.5
	_halo.anchor_top = ay
	_halo.anchor_right = 0.5
	_halo.anchor_bottom = ay
	_halo.offset_left = -diameter * 0.5
	_halo.offset_top = -diameter * 0.5
	_halo.offset_right = diameter * 0.5
	_halo.offset_bottom = diameter * 0.5
	_halo.pivot_offset = Vector2(diameter, diameter) * 0.5
	_halo.queue_redraw()


func _show_center_letter(letter: String, tint: Color, shake_letter: bool) -> void:
	_letter_label.text = letter.to_upper()
	_letter_label.add_theme_color_override("font_color", tint)
	_layout_letter_stack()
	_letter_label.scale = Vector2(0.18, 0.18)
	_letter_label.rotation_degrees = 0.0
	_letter_label.modulate.a = 0.0
	_layout_halo(letter)
	_halo.scale = Vector2(0.18, 0.18)
	_halo.modulate.a = 0.0
	var dim := RED_DIM_COLOR if shake_letter else DIM_COLOR
	var tween := _sequence_tween()
	tween.set_parallel(true)
	tween.tween_property(_dimmer, "color", dim, 0.18)
	tween.tween_property(_halo, "modulate:a", 1.0, HALO_FADE)
	tween.tween_property(_halo, "scale", Vector2.ONE, 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_letter_label, "modulate:a", 1.0, 0.16)
	tween.tween_property(_letter_label, "scale", Vector2.ONE, 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	if shake_letter:
		var punch := _sequence_tween()
		punch.tween_property(_letter_label, "rotation_degrees", -9.0, 0.06)
		punch.tween_property(_letter_label, "rotation_degrees", 9.0, 0.08)
		punch.tween_property(_letter_label, "rotation_degrees", 0.0, 0.07)
		await punch.finished


func _hide_center_letter() -> void:
	var tween := _sequence_tween()
	tween.set_parallel(true)
	tween.tween_property(_halo, "modulate:a", 0.0, HALO_FADE)
	tween.tween_property(_letter_label, "modulate:a", 0.0, 0.22)
	tween.tween_property(_letter_label, "scale", Vector2(1.12, 1.12), 0.22)
	tween.tween_property(_dimmer, "color", Color(1, 1, 1, 0), 0.22)
	await tween.finished
	_halo.scale = Vector2.ONE
	_letter_label.scale = Vector2.ONE
	_letter_label.rotation_degrees = 0.0


func _blink_cells(cells: Array[Celda]) -> void:
	if cells.is_empty():
		return
	var keys := _keyboard_keys_for(cells)
	for cell in cells:
		if is_instance_valid(cell):
			cell.modulate.a = 1.0
	for key in keys:
		if is_instance_valid(key):
			key.modulate.a = 1.0
	var tween := _sequence_tween()
	for _cycle in 2:
		tween.tween_callback(func() -> void:
			for cell in cells:
				if is_instance_valid(cell):
					cell.modulate.a = BLINK_DIM
			for key in keys:
				if is_instance_valid(key):
					key.modulate.a = BLINK_DIM
		)
		tween.tween_interval(BLINK_STEP)
		tween.tween_callback(func() -> void:
			for cell in cells:
				if is_instance_valid(cell):
					cell.modulate.a = 1.0
			for key in keys:
				if is_instance_valid(key):
					key.modulate.a = 1.0
		)
		tween.tween_interval(BLINK_STEP)
	await tween.finished
	for cell in cells:
		if is_instance_valid(cell):
			cell.modulate.a = 1.0
	for key in keys:
		if is_instance_valid(key):
			key.modulate.a = 1.0


func _keyboard_keys_for(cells: Array[Celda]) -> Array[Letra]:
	var wanted := {}
	for cell in cells:
		if not is_instance_valid(cell):
			continue
		var raw := cell.letter_user if cell.letter_user != "" else cell.letra
		var key := GameManager._hint_letter_key(raw)
		if key != "":
			wanted[key] = true
	var keys: Array[Letra] = []
	for node in get_tree().get_nodes_in_group("Letra"):
		if not node is Letra:
			continue
		var keyboard_letter := node as Letra
		if wanted.has(keyboard_letter.letra.to_upper()):
			keys.append(keyboard_letter)
	return keys


func _cells_from(assignment: Dictionary) -> Array[Celda]:
	var cells: Array[Celda] = []
	for item in assignment.get("cells", []):
		if item is Celda:
			cells.append(item)
	return cells


func _log_reveal_result(assignments: Array[Dictionary]) -> void:
	var correct: Array = []
	var wrong: Array = []
	for assignment in assignments:
		var item := {
			"letter": str(assignment.get("letter", "")),
			"numero": int(assignment.get("numero", 0)),
		}
		if assignment.get("correct", false):
			correct.append(item)
		else:
			wrong.append(item)
	SignalManager.puzzle_input.emit("reveal_result", {
		"correct": correct,
		"wrong": wrong,
	})


func _player_assignments() -> Array[Dictionary]:
	var by_number: Dictionary = {}
	for cell in _all_cells():
		if cell.numero >= 100 or cell.letter_user == "":
			continue
		if cell.es_regalo_inicial or cell.revelada_verde:
			continue
		if not GameManager.letra_corresponde_a_numero(cell.letter_user, cell.numero) \
				and GameManager.is_reveal_error_already_penalized(cell.numero, cell.letter_user):
			continue
		var number := cell.numero
		if not by_number.has(number):
			by_number[number] = {
				"letter": cell.letter_user.to_upper(),
				"numero": number,
				"orden": cell.orden,
				"correct": GameManager.letra_corresponde_a_numero(cell.letter_user, number),
				"cells": [],
			}
		var cells: Array = by_number[number]["cells"]
		cells.append(cell)
		by_number[number]["cells"] = cells
	var list: Array[Dictionary] = []
	for number in by_number:
		var bucket: Dictionary = by_number[number]
		var typed_cells: Array[Celda] = []
		for item in bucket["cells"]:
			if item is Celda:
				typed_cells.append(item)
		bucket["cells"] = typed_cells
		list.append(bucket)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("orden", 0)) < int(b.get("orden", 0))
	)
	return list


func _all_cells() -> Array[Celda]:
	var cells: Array[Celda] = []
	for node: Node in get_tree().get_nodes_in_group("Celda"):
		if node is Celda:
			cells.append(node as Celda)
	return cells


func _feedback_soft() -> void:
	var feedback := _error_feedback()
	if feedback != null and feedback.has_method("trigger_soft_shake"):
		feedback.trigger_soft_shake()


func _feedback_error() -> void:
	var feedback := _error_feedback()
	if feedback != null and feedback.has_method("trigger_reveal_error_shake"):
		feedback.trigger_reveal_error_shake()


func _error_feedback() -> Node:
	var parent := get_parent()
	if parent != null and parent.has_method("trigger_soft_shake"):
		return parent
	var nodes := get_tree().get_nodes_in_group("ErrorFeedback")
	return nodes[0] if not nodes.is_empty() else null


func _animate_star_loss() -> void:
	var hud_nodes := get_tree().get_nodes_in_group("GameHUD")
	if hud_nodes.is_empty() or not hud_nodes[0].has_method("animate_star_loss"):
		return
	await hud_nodes[0].animate_star_loss()
