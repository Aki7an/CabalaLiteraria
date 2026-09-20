extends Node

const SAVE_PATH := "user://puzzle_states.json"
const SAVE_VERSION := 1
const DEBUG_NEARLY_SOLVED_IDS: Array[int] = [3064, 3065, 3066, 3067]
const DEBUG_NEARLY_SOLVED_LETTER := "A"

var _states: Dictionary = {}
var _save_queued := false
var _restoring := false


func _ready() -> void:
	_load_from_disk()
	_reopen_debug_nearly_solved()
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
	var existing: Dictionary = get_puzzle_state(puzzle_id)
	var was_completed := str(existing.get("status", "")) == "completed"
	if was_completed and not GameManager.allow_completed_replay:
		if not _is_debug_nearly_solved(puzzle_id):
			return
	if GameManager.is_practice_session() and was_completed:
		return
	if existing.is_empty() or was_completed:
		_states[key] = {
			"status": "in_progress",
			"resolution": {},
			"attempt": GameManager.export_attempt_state(),
			"cipher": GameManager.export_cipher_state(),
			"meta": _current_meta(),
		}
		GameManager.allow_completed_replay = false
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
		_apply_debug_nearly_solved()
		GameManager.update_numero_letras_reveladas()
		SignalManager.update_puzzle_stars.emit(GameManager.puzzle_stars)
		request_autosave()
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
	_apply_debug_nearly_solved()
	GameManager.update_numero_letras_reveladas()
	SignalManager.update_puzzle_stars.emit(GameManager.puzzle_stars)
	_restoring = false
	request_autosave()


func _is_debug_nearly_solved(puzzle_id: int) -> bool:
	return OS.is_debug_build() and DEBUG_NEARLY_SOLVED_IDS.has(puzzle_id)


## Debug only: leave the debug puzzle with letter A unassigned so one tap solves it.
func _apply_debug_nearly_solved() -> void:
	if not _is_debug_nearly_solved(int(GameManager.id_frase)):
		return
	_reopen_debug_nearly_solved()
	var leave := GameManager._hint_letter_key(DEBUG_NEARLY_SOLVED_LETTER)
	var assigned_letters := {}
	var first_empty: Celda = null
	for node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		var cell := node as Celda
		if cell.numero >= 100:
			continue
		if GameManager.is_excluded_character(cell.letra):
			continue
		var key := GameManager._hint_letter_key(cell.letra)
		if key == leave:
			cell.limpiar_letra_usuario()
			if first_empty == null:
				first_empty = cell
			continue
		cell.set_letter_user(key)
		cell.mostrar_letra_jugador()
		assigned_letters[key] = true
	for node in get_tree().get_nodes_in_group("Letra"):
		if not node is Letra:
			continue
		var keyboard_letter := node as Letra
		var key := keyboard_letter.letra.to_upper()
		if assigned_letters.has(key):
			keyboard_letter.restore_as_assigned()
		elif key == leave:
			keyboard_letter.mark_as_unassigned()
	if first_empty != null:
		first_empty.deselect_all_cels()
		first_empty.celda_selected.visible = true
		GameManager.set_celda_seleccionada(first_empty.orden, first_empty.numero)
		GameManager.set_selected_letter_user("")


func _reopen_debug_nearly_solved() -> void:
	if not OS.is_debug_build():
		return
	for puzzle_id in DEBUG_NEARLY_SOLVED_IDS:
		_reopen_debug_nearly_solved_id(puzzle_id)
	_write_to_disk()


func _reopen_debug_nearly_solved_id(puzzle_id: int) -> void:
	var key := str(puzzle_id)
	var state: Dictionary = get_puzzle_state(puzzle_id)
	if state.is_empty():
		state = {
			"status": "in_progress",
			"resolution": {},
			"attempt": {},
			"cipher": {},
			"meta": {},
		}
	state["status"] = "in_progress"
	var attempt: Dictionary = state.get("attempt", {})
	if attempt is Dictionary:
		attempt["board_fill_prompt_shown"] = false
		state["attempt"] = attempt
	var meta: Dictionary = state.get("meta", {})
	if meta is Dictionary:
		meta.erase("completed_at")
		var leftover := _debug_letter_count(puzzle_id, DEBUG_NEARLY_SOLVED_LETTER)
		var total := int(meta.get("letters_total", 0))
		if total <= 0:
			total = _debug_playable_letter_count(puzzle_id)
		meta["letters_filled"] = maxi(total - leftover, 0)
		meta["letters_total"] = total
		state["meta"] = meta
	var resolution: Dictionary = state.get("resolution", {})
	if resolution is Dictionary:
		var cells: Dictionary = resolution.get("cells", {})
		var leave_number := _debug_cipher_number_for_letter(
			state.get("cipher", {}),
			DEBUG_NEARLY_SOLVED_LETTER
		)
		if leave_number > 0 and cells is Dictionary:
			cells[str(leave_number)] = {
				"letter": "",
				"color_id": 0,
				"visual_state": "empty",
			}
			resolution["cells"] = cells
			resolution["selected_number"] = leave_number
			state["resolution"] = resolution
	_states[key] = state


func _debug_playable_letter_count(puzzle_id: int) -> int:
	var text := str(GameManager.get_phrase_item(puzzle_id).get("text", ""))
	var count := 0
	for i in text.length():
		if not GameManager.is_excluded_character(text.substr(i, 1)):
			count += 1
	return count


func _debug_letter_count(puzzle_id: int, letter: String) -> int:
	var text := str(GameManager.get_phrase_item(puzzle_id).get("text", ""))
	var leave := GameManager._hint_letter_key(letter)
	var count := 0
	for i in text.length():
		var ch := text.substr(i, 1)
		if GameManager.is_excluded_character(ch):
			continue
		if GameManager._hint_letter_key(ch) == leave:
			count += 1
	return count


func _debug_cipher_number_for_letter(cipher: Variant, letter: String) -> int:
	if not (cipher is Dictionary):
		return 0
	var alphabet: Array = (cipher as Dictionary).get("alphabet", [])
	var numbers: Array = (cipher as Dictionary).get("numbers", [])
	var index := alphabet.find(letter)
	if index < 0 or index >= numbers.size():
		return 0
	return int(numbers[index]) + 1


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
	if GameManager.tutorial_board_active:
		return
	_sync_play_time_from_hud()
	var puzzle_id := int(GameManager.id_frase)
	if puzzle_id < 0:
		return
	var existing := get_puzzle_state(puzzle_id)
	if str(existing.get("status", "")) == "completed":
		if GameManager.is_practice_session() or not _is_debug_nearly_solved(puzzle_id):
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
	if GameManager.is_practice_session():
		return
	var state: Dictionary = get_puzzle_state(puzzle_id)
	state["status"] = "completed"
	state["resolution"] = {}
	if puzzle_id == int(GameManager.id_frase):
		state["attempt"] = GameManager.export_attempt_state()
	var meta: Dictionary = state.get("meta", {})
	if meta.is_empty():
		meta = _current_meta()
	meta["letters_filled"] = int(meta.get("letters_total", 0))
	meta["completed_at"] = int(Time.get_unix_time_from_system())
	if GameManager.session_source == GameManager.SOURCE_DAILY:
		meta["source"] = GameManager.SOURCE_DAILY
		meta["daily"] = true
	state["meta"] = meta
	_states[str(puzzle_id)] = state
	_write_to_disk()


func get_puzzle_state(puzzle_id: int) -> Dictionary:
	var value: Variant = _states.get(str(puzzle_id), {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func in_progress_ids() -> Dictionary:
	var result := {}
	for key in _states.keys():
		var state: Variant = _states[key]
		if state is Dictionary and str((state as Dictionary).get("status", "")) == "in_progress":
			result[int(str(key))] = true
	return result


func get_puzzle_summary(puzzle_id: int) -> Dictionary:
	var state := get_puzzle_state(puzzle_id)
	var maximum := _maximum_stars_for_puzzle(puzzle_id)
	var history := _history_completion(puzzle_id)
	if state.is_empty():
		if history.is_empty():
			return {
				"status": "new",
				"stars_remaining": maximum,
				"stars_max": maximum,
				"letters_filled": 0,
				"letters_total": 0,
				"tiempo_partida": 0,
				"completed_at": 0,
				"hours_since_completed": -1,
				"aids_used": 0,
				"failed_letters": 0,
				"is_perfect": false,
			}
		return _summary_from_history(puzzle_id, history, maximum)
	var attempt: Dictionary = state.get("attempt", {})
	var meta: Dictionary = state.get("meta", {})
	var status := str(state.get("status", "in_progress"))
	if status != "in_progress" and status != "completed" and not history.is_empty():
		return _summary_from_history(puzzle_id, history, maximum)
	var stars_remaining := clampi(
		int(attempt.get("puzzle_stars", maximum)),
		0,
		maximum
	)
	if not attempt.has("puzzle_stars") and not history.is_empty():
		stars_remaining = clampi(int(history.get("estrellas", maximum)), 0, maximum)
	var completed_at := completed_unix(puzzle_id)
	var completed := status == "completed"
	return {
		"status": status,
		"stars_remaining": stars_remaining,
		"stars_max": maximum,
		"letters_filled": int(meta.get("letters_filled", 0)),
		"letters_total": int(meta.get("letters_total", 0)),
		"tiempo_partida": int(attempt.get("tiempo_partida", meta.get("tiempo_partida", 0))),
		"completed_at": completed_at,
		"hours_since_completed": hours_since_completed(puzzle_id),
		"aids_used": _attempt_aids(attempt) if _attempt_aids(attempt) > 0 else _history_aids(history),
		"failed_letters": int(attempt.get("reveal_errors_count", history.get("revelaciones_falladas", 0))),
		"is_perfect": completed and stars_remaining >= maximum,
	}


func completed_unix(puzzle_id: int) -> int:
	var state := get_puzzle_state(puzzle_id)
	var stored := int(state.get("meta", {}).get("completed_at", 0))
	if stored > 0:
		return stored
	if typeof(HistoryManager) == TYPE_NIL:
		return 0
	var latest := 0
	for value in HistoryManager.get_history():
		if not (value is Dictionary):
			continue
		var entry: Dictionary = value
		if int(entry.get("id", -1)) != puzzle_id:
			continue
		if not bool(entry.get("partida_ganada", false)):
			continue
		var unix := int(entry.get("completed_unix", 0))
		if unix <= 0:
			unix = _unix_from_history_fecha(entry.get("fecha", {}))
		latest = maxi(latest, unix)
	return latest


func hours_since_completed(puzzle_id: int) -> int:
	var unix := completed_unix(puzzle_id)
	if unix > 0:
		var elapsed := int(Time.get_unix_time_from_system()) - unix
		return maxi(int(elapsed / 3600.0), 0)
	if str(get_puzzle_state(puzzle_id).get("status", "")) == "completed":
		return 48
	if not _history_completion(puzzle_id).is_empty():
		return 48
	return -1


func can_replay_completed(puzzle_id: int) -> bool:
	var summary := get_puzzle_summary(puzzle_id)
	if str(summary.get("status", "")) != "completed":
		return false
	return int(summary.get("hours_since_completed", -1)) >= 48


func _attempt_aids(attempt: Dictionary) -> int:
	return (
		int(attempt.get("pistas_utilizadas_1", 0))
		+ int(attempt.get("pistas_utilizadas_2", 0))
		+ int(attempt.get("consonantes_compradas", 0))
		+ int(attempt.get("vocalesAE_compradas", 0))
		+ int(attempt.get("vocalesIOU_compradas", 0))
	)


func _history_aids(entry: Dictionary) -> int:
	if entry.is_empty():
		return 0
	return (
		int(entry.get("pistas_consumidas_1", 0))
		+ int(entry.get("pistas_consumidas_2", 0))
		+ int(entry.get("consonantes_compradas", 0))
		+ int(entry.get("vocales_compradas_AE", 0))
		+ int(entry.get("vocales_compradas_IOU", 0))
	)


func _history_completion(puzzle_id: int) -> Dictionary:
	if typeof(HistoryManager) == TYPE_NIL:
		return {}
	var latest := {}
	var latest_unix := -1
	for value in HistoryManager.get_history():
		if not (value is Dictionary):
			continue
		var entry: Dictionary = value
		if int(entry.get("id", -1)) != puzzle_id:
			continue
		if not bool(entry.get("partida_ganada", false)):
			continue
		var unix := int(entry.get("completed_unix", 0))
		if unix <= 0:
			unix = _unix_from_history_fecha(entry.get("fecha", {}))
		if unix >= latest_unix:
			latest = entry
			latest_unix = unix
	return latest


func _summary_from_history(puzzle_id: int, history: Dictionary, maximum: int) -> Dictionary:
	var stars_remaining := clampi(int(history.get("estrellas", maximum)), 0, maximum)
	return {
		"status": "completed",
		"stars_remaining": stars_remaining,
		"stars_max": maximum,
		"letters_filled": 0,
		"letters_total": 0,
		"tiempo_partida": int(history.get("tiempo_partida", 0)),
		"completed_at": completed_unix(puzzle_id),
		"hours_since_completed": hours_since_completed(puzzle_id),
		"aids_used": _history_aids(history),
		"failed_letters": int(history.get("revelaciones_falladas", 0)),
		"is_perfect": stars_remaining >= maximum,
	}


func _unix_from_history_fecha(fecha: Variant) -> int:
	if not (fecha is Dictionary):
		return 0
	var date: Dictionary = fecha
	var year := int(date.get("anio", 0))
	var month := int(date.get("mes", 0))
	var day := int(date.get("dia", 0))
	if year <= 0 or month <= 0 or day <= 0:
		var iso := str(date.get("iso", ""))
		if iso.length() >= 10:
			year = int(iso.substr(0, 4))
			month = int(iso.substr(5, 2))
			day = int(iso.substr(8, 2))
	if year <= 0 or month <= 0 or day <= 0:
		return 0
	return int(Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": day,
		"hour": 12,
		"minute": 0,
		"second": 0,
	}))


func _maximum_stars_for_puzzle(puzzle_id: int) -> int:
	if puzzle_id == int(GameManager.id_frase):
		return GameManager.get_puzzle_difficulty_stars()
	for item_value in GameManager.frases_db:
		if item_value is Dictionary:
			var item: Dictionary = item_value
			if int(item.get("index", -1)) == puzzle_id:
				return GameManager.get_puzzle_difficulty_stars(
					int(item.get("difficulty", 1))
				)
	return 1


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
			var is_correct := GameManager.letra_corresponde_a_numero(
				cell.letter_user,
				cell.numero
			)
			if cell.revelada_verde or (cell.bloqueada and is_correct and not cell.es_regalo_inicial):
				visual_state = "correct"
			elif cell.es_regalo_inicial:
				visual_state = "initial"
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
			var saved_initial_letter := str(saved.get("letter", ""))
			if GameManager.letra_corresponde_a_numero(
				saved_initial_letter,
				cell.numero
			):
				cell.mostrar_letra_especifica(saved_initial_letter)
				continue
			# Repair saves created when an incorrect use of an initial letter
			# was mistakenly stored as a locked initial cell.
			visual_state = "wrong"
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
		"tiempo_partida": int(GameManager.tiempo_partida),
		"updated_at": Time.get_unix_time_from_system(),
		"source": str(GameManager.session_source),
	}


func _find_canvas() -> Node:
	var nodes := get_tree().get_nodes_in_group("PuzzleCanvas")
	return nodes[0] if not nodes.is_empty() else null


func _is_gameplay_active() -> bool:
	return not get_tree().get_nodes_in_group("PuzzleCanvas").is_empty()


func _sync_play_time_from_hud() -> void:
	for node in get_tree().get_nodes_in_group("GameHUD"):
		if node.has_method("sync_play_time"):
			node.call("sync_play_time")
			return


func _load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_states = (parsed as Dictionary).get("states", {})


func clear_all() -> void:
	_states.clear()
	_save_queued = false
	_write_to_disk()


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
