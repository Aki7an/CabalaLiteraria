extends Node
class_name EventLogger

const MAX_EVENTS := 4000
const PENDING_PATH := "user://logs/pending_trace.json"
const OUTCOME_COMPLETED := "COMPLETADA"
const OUTCOME_ABANDONED := "ABANDONADA"
const OUTCOME_UNFINISHED := "NO TERMINADA"

var session_id: String = ""
var events: Array = []
var started: bool = false
var finished: bool = false
var _start_ms: int = 0
var _pending_submit: bool = false
var _outcome: String = ""
var _flushing := false
var _boot_flush_done := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not SignalManager.puzzle_input.is_connected(_on_puzzle_input):
		SignalManager.puzzle_input.connect(_on_puzzle_input)
	_flush_pending()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		persist_unfinished()


func start_session() -> void:
	events.clear()
	session_id = _make_session_id()
	started = true
	finished = false
	_pending_submit = false
	_outcome = ""
	_start_ms = Time.get_ticks_msec()
	_log("session_start", {
		"puzzle_id": _puzzle_id(),
		"locale": TranslationServer.get_locale(),
	})


func finish_session(outcome: String = "") -> void:
	if not started or finished:
		if outcome != "":
			_outcome = outcome
		return
	finished = true
	if outcome != "":
		_outcome = outcome
	_log("session_end", {
		"puzzle_id": _puzzle_id(),
		"duration_sec": _game_sec(),
		"outcome": _current_outcome(),
	})


func discard_session() -> void:
	started = false
	finished = false
	_pending_submit = false
	_outcome = ""
	events.clear()
	session_id = ""


func log_action(action: String, meta: Dictionary = {}) -> void:
	if not started:
		start_session()
	_log(action, meta)


func persist_unfinished() -> void:
	if _flushing or not _should_share() or not started or finished:
		return
	if events.size() <= 1:
		return
	_write_pending(build_payload(OUTCOME_UNFINISHED))


func submit_if_consented(outcome: String = OUTCOME_COMPLETED) -> void:
	if not _should_share():
		discard_session()
		if _boot_flush_done:
			_clear_pending_if_session(session_id)
		return
	if not started and events.is_empty():
		return
	_outcome = outcome
	if not finished:
		finish_session(outcome)
	_pending_submit = true
	await _submit_async(outcome)


func build_payload(outcome: String = "") -> Dictionary:
	var resolved := outcome if outcome != "" else _current_outcome()
	return {
		"session_id": session_id,
		"puzzle_id": _puzzle_id(),
		"outcome": resolved,
		"player": GameManager.player_name if typeof(GameManager) != TYPE_NIL else "",
		"category": GameManager.categoria_actual if typeof(GameManager) != TYPE_NIL else "",
		"difficulty": GameManager.dificultad_actual if typeof(GameManager) != TYPE_NIL else 0,
		"game_mode": str(GameManager.game_mode_actual) if typeof(GameManager) != TYPE_NIL else "",
		"duration_sec": _game_sec(),
		"letters_shown": _letters_shown(),
		"board": _board_snapshot(),
		"locale": TranslationServer.get_locale(),
		"client_ver": str(ProjectSettings.get_setting("application/config/version", "")),
		"platform": OS.get_name(),
		"playfab_id": str(PlayFabTools.playfab_id) if typeof(PlayFabTools) != TYPE_NIL else "",
		"events": events.duplicate(true),
	}


func _on_puzzle_input(action: String, meta: Dictionary) -> void:
	log_action(action, meta)


func _log(action: String, meta: Dictionary) -> void:
	if not started:
		return
	var ev := {
		"id": events.size(),
		"action": action,
		"t_ms": _elapsed_ms(),
		"t_game_sec": _game_sec(),
	}
	for key in meta.keys():
		ev[key] = meta[key]
	events.append(ev)
	if events.size() > MAX_EVENTS:
		events.pop_front()


func _should_share() -> bool:
	if typeof(PlayerPrefs) == TYPE_NIL or not PlayerPrefs.share_solve_data:
		return false
	if typeof(GameManager) != TYPE_NIL and GameManager.skips_progress():
		return false
	return true


func _current_outcome() -> String:
	if _outcome != "":
		return _outcome
	return OUTCOME_COMPLETED if finished else OUTCOME_UNFINISHED


func _submit_async(outcome: String) -> void:
	var payload := build_payload(outcome)
	_write_local(payload)
	_write_pending(payload)
	var playfab_ok := await _send_payload(payload)
	print("PlayFab trace: ", playfab_ok, " outcome=", outcome)
	if playfab_ok:
		_clear_pending_if_session(str(payload.get("session_id", "")))
	discard_session()


func _flush_pending() -> void:
	if _flushing:
		return
	_flushing = true
	var payload := _read_pending()
	if payload.is_empty():
		_flushing = false
		_boot_flush_done = true
		return
	if typeof(PlayerPrefs) == TYPE_NIL or not PlayerPrefs.share_solve_data:
		_clear_pending()
		_flushing = false
		_boot_flush_done = true
		return
	if str(payload.get("outcome", "")).strip_edges() == "":
		payload["outcome"] = OUTCOME_UNFINISHED
	var playfab_ok := await _send_payload(payload)
	print("PlayFab pending trace: ", playfab_ok, " outcome=", payload.get("outcome", ""))
	if playfab_ok:
		_clear_pending()
	_flushing = false
	_boot_flush_done = true


func _send_payload(payload: Dictionary) -> bool:
	if typeof(PlayFabTools) == TYPE_NIL:
		return false
	if not PlayFabTools.is_logged_in():
		for _attempt in range(50):
			await get_tree().create_timer(0.1).timeout
			if PlayFabTools.is_logged_in():
				break
	if not PlayFabTools.is_logged_in():
		return false
	return await PlayFabTools.send_puzzle_trace(payload)


func _write_local(payload: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute("user://logs")
	var path := "user://logs/puzzle_%s_%s.json" % [
		str(payload.get("puzzle_id", _puzzle_id())),
		str(payload.get("session_id", session_id)),
	]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))
	file.close()


func _write_pending(payload: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute("user://logs")
	var file := FileAccess.open(PENDING_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))
	file.close()


func _read_pending() -> Dictionary:
	if not FileAccess.file_exists(PENDING_PATH):
		return {}
	var file := FileAccess.open(PENDING_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _clear_pending() -> void:
	if FileAccess.file_exists(PENDING_PATH):
		DirAccess.remove_absolute(PENDING_PATH)


func _clear_pending_if_session(sid: String) -> void:
	if sid == "":
		_clear_pending()
		return
	var pending := _read_pending()
	if pending.is_empty() or str(pending.get("session_id", "")) == sid:
		_clear_pending()


func _letters_shown() -> String:
	if typeof(GameManager) == TYPE_NIL or not is_inside_tree() or get_tree() == null:
		return ""
	if get_tree().get_nodes_in_group("Letra").is_empty():
		return ""
	return str(GameManager.recoger_letras_mostradas())


func _board_snapshot() -> Dictionary:
	if not is_inside_tree() or get_tree() == null:
		return {}
	var cells: Array = []
	for node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		var cell := node as Celda
		if cell.numero >= 100:
			continue
		var letter := str(cell.letter_user)
		if letter == "":
			continue
		cells.append({
			"orden": int(cell.orden),
			"numero": int(cell.numero),
			"letter": letter,
			"shown": bool(cell.celda_mostrada),
			"gift": bool(cell.es_regalo_inicial),
		})
	cells.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("orden", 0)) < int(b.get("orden", 0))
	)
	return {
		"assigned": cells,
		"assigned_count": cells.size(),
	}


func _elapsed_ms() -> int:
	return maxi(Time.get_ticks_msec() - _start_ms, 0)


func _game_sec() -> int:
	return GameManager.tiempo_partida if typeof(GameManager) != TYPE_NIL else 0


func _puzzle_id() -> int:
	return int(GameManager.id_frase) if typeof(GameManager) != TYPE_NIL else -1


func _make_session_id() -> String:
	return "%s_%d" % [
		Time.get_datetime_string_from_system().replace(":", "-"),
		randi()
	]
