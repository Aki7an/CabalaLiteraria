extends ColorRect

const FONT_LETTER: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
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

var _dimmer: ColorRect
var _halo: Control
var _letter_label: Label
var _running := false
var _keyboard_panel: Control
var _keyboard_z := 0


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
	resized.connect(_on_resized)
	_layout_letter_stack()


func _run_sequence() -> void:
	if _running:
		return
	_running = true
	await get_tree().process_frame
	_clip_above_keyboard()
	await _reveal_initial_letters()
	var assignments := _player_assignments()
	_log_reveal_result(assignments)
	for assignment in assignments:
		if assignment.get("correct", false):
			await _reveal_correct(assignment)
		else:
			await _reveal_wrong(assignment)
	GameManager.finish_reveal_sequence()
	queue_free()


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
	await get_tree().create_timer(0.12).timeout


func _reveal_correct(assignment: Dictionary) -> void:
	var cells := _cells_from(assignment)
	var letter := str(assignment.get("letter", ""))
	_feedback_soft()
	SoundManager.play("ClickLetra")
	await _show_center_letter(letter, LETTER_GREEN, false)
	GameManager.apply_reveal_correct_number(int(assignment.get("numero", 0)))
	await _blink_cells(cells)
	await _hide_center_letter()


func _reveal_wrong(assignment: Dictionary) -> void:
	var cells := _cells_from(assignment)
	var letter := str(assignment.get("letter", ""))
	var number := int(assignment.get("numero", 0))
	_feedback_error()
	SoundManager.play("LoseLive")
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
	var tween := create_tween()
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
		var punch := create_tween()
		punch.tween_property(_letter_label, "rotation_degrees", -9.0, 0.06)
		punch.tween_property(_letter_label, "rotation_degrees", 9.0, 0.08)
		punch.tween_property(_letter_label, "rotation_degrees", 0.0, 0.07)
		await punch.finished


func _hide_center_letter() -> void:
	var tween := create_tween()
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
	var tween := create_tween()
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
