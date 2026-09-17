extends Node
class_name EventLogger

const MAX_EVENTS := 4000

var session_id: String = ""
var events: Array = []
var started: bool = false
var finished: bool = false
var _start_ms: int = 0
var _pending_submit: bool = false


func _ready() -> void:
	if not SignalManager.puzzle_input.is_connected(_on_puzzle_input):
		SignalManager.puzzle_input.connect(_on_puzzle_input)


func start_session() -> void:
	events.clear()
	session_id = _make_session_id()
	started = true
	finished = false
	_pending_submit = false
	_start_ms = Time.get_ticks_msec()
	_log("session_start", {
		"puzzle_id": _puzzle_id(),
		"locale": TranslationServer.get_locale(),
	})


func finish_session() -> void:
	if not started or finished:
		return
	finished = true
	_log("session_end", {
		"puzzle_id": _puzzle_id(),
		"duration_sec": _game_sec(),
	})


func discard_session() -> void:
	started = false
	finished = false
	_pending_submit = false
	events.clear()
	session_id = ""


func log_action(action: String, meta: Dictionary = {}) -> void:
	if not started:
		start_session()
	_log(action, meta)


func submit_if_consented() -> void:
	if not PlayerPrefs.share_solve_data:
		discard_session()
		return
	if not started and events.is_empty():
		return
	if not finished:
		finish_session()
	_pending_submit = true
	await _submit_async()


func build_payload() -> Dictionary:
	return {
		"session_id": session_id,
		"puzzle_id": _puzzle_id(),
		"player": GameManager.player_name if typeof(GameManager) != TYPE_NIL else "",
		"category": GameManager.categoria_actual if typeof(GameManager) != TYPE_NIL else "",
		"difficulty": GameManager.dificultad_actual if typeof(GameManager) != TYPE_NIL else 0,
		"game_mode": str(GameManager.game_mode_actual) if typeof(GameManager) != TYPE_NIL else "",
		"duration_sec": _game_sec(),
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


func _submit_async() -> void:
	var payload := build_payload()
	_write_local(payload)
	if typeof(PlayFabTools) == TYPE_NIL:
		discard_session()
		return
	var sheets_ok := await PlayFabTools.export_trace_to_google_sheets(payload)
	print("Google Sheets export: ", sheets_ok)
	var playfab_ok := await PlayFabTools.send_puzzle_trace(payload)
	print("PlayFab trace: ", playfab_ok)
	discard_session()


func _write_local(payload: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute("user://logs")
	var path := "user://logs/puzzle_%s_%s.json" % [_puzzle_id(), session_id]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))
	file.close()


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
