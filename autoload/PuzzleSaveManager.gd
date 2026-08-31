extends Node

const SAVE_PATH := "user://puzzle_states.json"
const SAVE_VERSION := 1

var _states: Dictionary = {}
var _save_queued := false
var _restoring := false


func _ready() -> void:
	_load_from_disk()
	var safety_timer := Timer.new()
	safety_timer.wait_time = 5.0
	safety_timer.autostart = true
	safety_timer.timeout.connect(save_current_now)
	add_child(safety_timer)


func begin_current_puzzle() -> void:
	var puzzle_id := int(GameManager.id_frase)
	if puzzle_id < 0:
		return
	var key := str(puzzle_id)
	if not _states.has(key):
		_states[key] = {
			"status": "in_progress",
			"resolution": {},
			"attempt": GameManager.export_attempt_state(),
			"cipher": GameManager.export_cipher_state(),
			"meta": _current_meta(),
		}
		_write_to_disk()


func prepare_current_puzzle_cipher() -> bool:
	var state := get_puzzle_state(int(GameManager.id_frase))
	if state.is_empty() or str(state.get("status", "")) != "in_progress":
		return false
	var cipher: Dictionary = state.get("cipher", {})
	if str(cipher.get("locale", GameManager.locale_code())) != GameManager.locale_code():
		return false
	return GameManager.import_cipher_state(cipher)


func restore_current_puzzle() -> void:
	var puzzle_id := int(GameManager.id_frase)
	var state := get_puzzle_state(puzzle_id)
	if state.is_empty() or str(state.get("status", "")) == "completed":
		begin_current_puzzle()
		return
	_restoring = true
	GameManager.import_attempt_state(state.get("attempt", {}))
	await get_tree().process_frame
	_apply_resolution(state.get("resolution", {}))
	await get_tree().process_frame
	var canvas := _find_canvas()
	if canvas != null and canvas.has_method("set_scroll_normalized"):
		canvas.call(
			"set_scroll_normalized",
			float(state.get("resolution", {}).get("scroll", 0.0))
		)
	GameManager.update_numero_letras_reveladas()
	SignalManager.update_puzzle_stars.emit(GameManager.puzzle_stars)
	_restoring = false


func request_autosave() -> void:
	if _restoring or _save_queued:
		return
	_save_queued = true
	call_deferred("_flush_autosave")


func _flush_autosave() -> void:
	await get_tree().process_frame
	_save_queued = false
	save_current_now()


func save_current_now() -> void:
	if _restoring or not _is_gameplay_active():
		return
	var puzzle_id := int(GameManager.id_frase)
	if puzzle_id < 0:
		return
	_states[str(puzzle_id)] = {
		"status": "in_progress",
		"resolution": _capture_resolution(),
		"attempt": GameManager.export_attempt_state(),
		"cipher": GameManager.export_cipher_state(),
		"meta": _current_meta(),
	}
	_write_to_disk()


func reset_resolution_keep_attempt() -> void:
	var puzzle_id := int(GameManager.id_frase)
	if puzzle_id < 0:
		return
	var key := str(puzzle_id)
	var state: Dictionary = get_puzzle_state(puzzle_id)
	state["status"] = "in_progress"
	state["resolution"] = {}
	state["attempt"] = GameManager.export_attempt_state()
	state["cipher"] = GameManager.export_cipher_state()
	var meta := _current_meta()
	meta["letters_filled"] = 0
	state["meta"] = meta
	_states[key] = state
	GameManager.clear_resolution_runtime_state()
	_write_to_disk()


func mark_completed(puzzle_id: int) -> void:
	if puzzle_id < 0:
		return
	var state: Dictionary = get_puzzle_state(puzzle_id)
	state["status"] = "completed"
	state["resolution"] = {}
	if not state.has("attempt"):
		state["attempt"] = GameManager.export_attempt_state()
	var meta: Dictionary = state.get("meta", {})
	meta["letters_filled"] = int(meta.get("letters_total", 0))
	state["meta"] = meta
	_states[str(puzzle_id)] = state
	_write_to_disk()


func get_puzzle_state(puzzle_id: int) -> Dictionary:
	var value: Variant = _states.get(str(puzzle_id), {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func get_puzzle_summary(puzzle_id: int) -> Dictionary:
	var state := get_puzzle_state(puzzle_id)
	if state.is_empty():
		return {
			"status": "new",
			"stars_remaining": 5,
			"letters_filled": 0,
			"letters_total": 0,
		}
	var attempt: Dictionary = state.get("attempt", {})
	var meta: Dictionary = state.get("meta", {})
	return {
		"status": str(state.get("status", "in_progress")),
		"stars_remaining": int(attempt.get("puzzle_stars", 5)),
		"letters_filled": int(meta.get("letters_filled", 0)),
		"letters_total": int(meta.get("letters_total", 0)),
	}


func _capture_resolution() -> Dictionary:
	var cells := {}
	for node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		var cell := node as Celda
		if cell.numero >= 100 or cells.has(str(cell.numero)):
			continue
		var visual_state := "empty"
		if cell.letter_user != "":
			if GameManager.letras_iniciales.to_upper().contains(cell.letter_user.to_upper()):
				visual_state = "initial"
			elif cell.bloqueada:
				visual_state = "correct"
			elif cell.celda_mostrada:
				visual_state = "player"
			else:
				visual_state = "wrong"
		cells[str(cell.numero)] = {
			"letter": cell.letter_user,
			"color_id": cell.color_id,
			"visual_state": visual_state,
		}
	var canvas := _find_canvas()
	var scroll := 0.0
	if canvas != null and canvas.has_method("get_scroll_normalized"):
		scroll = float(canvas.call("get_scroll_normalized"))
	return {
		"cells": cells,
		"selected_number": int(GameManager.celda_seleccionada_numero),
		"color_slots": [
			GameManager.number_1,
			GameManager.number_2,
			GameManager.number_3,
			GameManager.number_4,
			GameManager.number_5,
		],
		"scroll": scroll,
	}


func _apply_resolution(resolution: Dictionary) -> void:
	var saved_cells: Dictionary = resolution.get("cells", {})
	var assigned_letters := {}
	var correct_letters := {}
	for node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		var cell := node as Celda
		var saved_value: Variant = saved_cells.get(str(cell.numero), null)
		if not (saved_value is Dictionary):
			continue
		var saved: Dictionary = saved_value
		var visual_state := str(saved.get("visual_state", "empty"))
		if visual_state == "initial":
			continue
		var letter := str(saved.get("letter", ""))
		cell.set_letter_user(letter)
		match visual_state:
			"correct":
				cell.mostrar_letra()
				correct_letters[letter.to_upper()] = true
			"player":
				cell.mostrar_letra_jugador()
				assigned_letters[letter.to_upper()] = true
			"wrong":
				cell.mostrar_letra_errada()
			_:
				cell.limpiar_letra_usuario()
		var color_id := int(saved.get("color_id", 0))
		if color_id > 0 and color_id < GameManager.lista_tonos_colores.size():
			cell.cambia_color(color_id)

	for node in get_tree().get_nodes_in_group("Letra"):
		if not node is Letra:
			continue
		var keyboard_letter := node as Letra
		var key := keyboard_letter.letra.to_upper()
		if correct_letters.has(key):
			keyboard_letter.mark_as_correct()
		elif assigned_letters.has(key):
			keyboard_letter.restore_as_assigned()

	GameManager.celda_seleccionada_numero = int(
		resolution.get("selected_number", 0)
	)
	var color_slots: Array = resolution.get("color_slots", [])
	if color_slots.size() >= 5:
		GameManager.number_1 = int(color_slots[0])
		GameManager.number_2 = int(color_slots[1])
		GameManager.number_3 = int(color_slots[2])
		GameManager.number_4 = int(color_slots[3])
		GameManager.number_5 = int(color_slots[4])


func _current_meta() -> Dictionary:
	return {
		"category": GameManager.normalize_category(GameManager.categoria_actual),
		"mode": GameManager.game_mode_actual,
		"difficulty": int(GameManager.dificultad_actual),
		"locale": GameManager.locale_code(),
		"letters_filled": int(GameManager.numero_letras_reveladas),
		"letters_total": int(GameManager.numero_letras_a_revelar_originales),
		"updated_at": Time.get_unix_time_from_system(),
	}


func _find_canvas() -> Node:
	var nodes := get_tree().get_nodes_in_group("PuzzleCanvas")
	return nodes[0] if not nodes.is_empty() else null


func _is_gameplay_active() -> bool:
	return not get_tree().get_nodes_in_group("PuzzleCanvas").is_empty()


func _load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_states = (parsed as Dictionary).get("states", {})


func _write_to_disk() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"version": SAVE_VERSION,
		"states": _states,
	}))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_current_now()
