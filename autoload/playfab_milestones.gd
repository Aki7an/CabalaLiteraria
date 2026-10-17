extends Node

## Estado del jugador en PlayFab User Data (privado) y en estadísticas enteras.
## Las fechas se guardan en UTC. El exportado tools/export_playfab_milestones.py
## arma la tabla de todos los jugadores.

const LOCAL_PATH := "user://playfab_milestones.cfg"
const ACTIVITY_GAP_SEC := 60
const MAX_IDS_CHARS := 8000

const KEY_FIRST := "ms_first_access"
const KEY_TUTORIAL := "ms_tutorial_completed"
const KEY_FIRST_PUZZLE := "ms_first_puzzle"
const KEY_LAST_PUZZLE := "ms_last_puzzle"
const KEY_COUNT := "ms_puzzles_completed"
const KEY_ACTIVITY := "ms_last_activity"
const KEY_IDS := "ms_puzzle_ids"

const STAT_FIRST := "MsFirstAccess"
const STAT_TUTORIAL := "MsTutorialCompleted"
const STAT_FIRST_PUZZLE := "MsFirstPuzzle"
const STAT_LAST_PUZZLE := "MsLastPuzzle"
const STAT_COUNT := "MsPuzzlesCompleted"
const STAT_ACTIVITY := "MsLastActivity"

const DATA_KEYS: Array[String] = [
	KEY_FIRST,
	KEY_TUTORIAL,
	KEY_FIRST_PUZZLE,
	KEY_LAST_PUZZLE,
	KEY_COUNT,
	KEY_ACTIVITY,
	KEY_IDS,
]

var _tutorial_unix := 0
var _activity_unix := 0
var _stats_signature := ""
var _last_upload_unix := 0
var _tutorial_event := false
var _puzzle_event := false
var _event_puzzle_id := -1
var _sync_requested := false
var _sync_running := false
var _stat_warning_shown := false


func _ready() -> void:
	_load_local()
	var timer := Timer.new()
	timer.wait_time = 180.0
	timer.autostart = true
	timer.timeout.connect(note_player_activity)
	add_child(timer)


func note_tutorial_completed() -> void:
	_tutorial_event = true
	if _tutorial_unix <= 0:
		var from_history := _history_snapshot()
		_tutorial_unix = int(from_history.get("tutorial_unix", 0))
	if _tutorial_unix <= 0:
		_tutorial_unix = _now()
	_touch_activity()
	_save_local()
	request_sync()


func note_puzzle_completed() -> void:
	_puzzle_event = true
	_event_puzzle_id = int(GameManager.id_frase) if typeof(GameManager) != TYPE_NIL else -1
	_touch_activity()
	_save_local()
	request_sync()


func note_player_activity() -> void:
	_touch_activity()
	_save_local()
	if _tutorial_event or _puzzle_event:
		request_sync()
		return
	if _last_upload_unix > 0 and _activity_unix - _last_upload_unix < ACTIVITY_GAP_SEC:
		return
	request_sync()


func request_sync() -> void:
	_sync_requested = true
	if _sync_running:
		return
	_sync_running = true
	_run_sync_queue()


func _run_sync_queue() -> void:
	while _sync_requested:
		_sync_requested = false
		await _sync_once()
	_sync_running = false


func _sync_once() -> void:
	var waited := Time.get_ticks_msec()
	while not PlayFabTools.is_logged_in() and Time.get_ticks_msec() - waited < 20000:
		if PlayFabTools._login_finished:
			break
		await get_tree().process_frame
	if not PlayFabTools.is_logged_in():
		return

	var current := await _read_server_values()
	if not bool(current.get("_ok", false)):
		return
	current.erase("_ok")

	var now := _now()
	var first_access := _parse_iso(str(current.get(KEY_FIRST, "")))
	if first_access <= 0:
		first_access = await _account_first_access_unix()
	if first_access <= 0 and PlayFabTools.newly_created:
		first_access = now

	var puzzle_event := _puzzle_event
	var tutorial_event := _tutorial_event
	var event_puzzle_id := _event_puzzle_id
	_puzzle_event = false
	_tutorial_event = false
	_event_puzzle_id = -1

	var snapshot := _history_snapshot()
	var local_ids: Array = snapshot.get("puzzle_ids", [])
	var server_ids := _text_to_ids(str(current.get(KEY_IDS, "")))
	var puzzle_ids := _union_ids(server_ids, local_ids)
	var ids_text := _ids_to_text(puzzle_ids)
	var count := puzzle_ids.size()
	if ids_text.length() > MAX_IDS_CHARS:
		var server_count := int(str(current.get(KEY_COUNT, "0")))
		ids_text = _ids_to_text(server_ids)
		puzzle_ids = server_ids
		count = maxi(server_ids.size(), maxi(local_ids.size(), server_count))
		push_warning("PlayFab: la lista de puzles completados no cabe en el dato del jugador.")

	var tutorial := _earliest(
		_parse_iso(str(current.get(KEY_TUTORIAL, ""))),
		_earliest(int(snapshot.get("tutorial_unix", 0)), _tutorial_unix)
	)
	if tutorial <= 0 and tutorial_event:
		tutorial = now

	var first_puzzle := _earliest(
		_parse_iso(str(current.get(KEY_FIRST_PUZZLE, ""))),
		int(snapshot.get("first_unix", 0))
	)
	var last_puzzle := _latest(
		_parse_iso(str(current.get(KEY_LAST_PUZZLE, ""))),
		int(snapshot.get("last_unix", 0))
	)
	var previous_count := server_ids.size()
	var server_activity := _parse_iso(str(current.get(KEY_ACTIVITY, "")))
	var activity := _latest(_latest(server_activity, _activity_unix), now)

	var desired := {
		KEY_FIRST: _iso_utc(first_access),
		KEY_TUTORIAL: _iso_utc(tutorial),
		KEY_FIRST_PUZZLE: _iso_utc(first_puzzle),
		KEY_LAST_PUZZLE: _iso_utc(last_puzzle),
		KEY_COUNT: str(count),
		KEY_IDS: ids_text,
	}
	var updates := {}
	for key in desired.keys():
		var value := str(desired[key])
		if value == "":
			continue
		if key == KEY_IDS:
			if _ids_to_text(_text_to_ids(str(current.get(key, "")))) == value:
				continue
		elif key == KEY_COUNT:
			if str(current.get(key, "")) == value:
				continue
		elif _parse_iso(str(current.get(key, ""))) == _parse_iso(value):
			continue
		updates[key] = value

	var published_activity := server_activity
	var include_activity := server_activity <= 0 or activity - server_activity >= ACTIVITY_GAP_SEC
	if not updates.is_empty() and activity > server_activity:
		include_activity = true
	if include_activity and activity > server_activity:
		published_activity = activity
		updates[KEY_ACTIVITY] = _iso_utc(activity)

	var emit_first: bool = (
		bool(PlayFabTools.newly_created)
		and _parse_iso(str(current.get(KEY_FIRST, ""))) <= 0
		and first_access > 0
	)
	var emit_puzzle := puzzle_event and count > previous_count
	var emit_tutorial := tutorial_event and tutorial > 0
	var stats_pending := (
		_pending_stat_signature(first_access, tutorial, first_puzzle, last_puzzle, count, published_activity)
		!= _stats_signature
	)
	if _puzzle_event or _tutorial_event:
		_sync_requested = true

	if updates.is_empty() and not emit_first and not emit_puzzle and not emit_tutorial and not stats_pending:
		_last_upload_unix = now
		return

	if not updates.is_empty():
		var wrote: Dictionary = await PlayFabTools._client_post_json("UpdateUserData", {
			"Data": updates,
			"Permission": "Private",
		})
		if wrote.is_empty():
			_puzzle_event = _puzzle_event or puzzle_event
			_tutorial_event = _tutorial_event or tutorial_event
			if _event_puzzle_id < 0:
				_event_puzzle_id = event_puzzle_id
			push_warning("PlayFab: no se pudieron guardar los hitos del jugador.")
			return
		print("[PlayFab] hitos actualizados: ", _update_labels(updates))

	await _write_statistics(first_access, tutorial, first_puzzle, last_puzzle, count, published_activity)
	if emit_first:
		await PlayFabTools._write_player_event("milestone_first_access", {
			"at": _iso_utc(first_access),
		})
	if emit_tutorial:
		await PlayFabTools._write_player_event("milestone_tutorial_completed", {
			"at": _iso_utc(tutorial),
		})
	if emit_puzzle:
		await PlayFabTools._write_player_event("milestone_puzzle_completed", {
			"at": _iso_utc(last_puzzle if last_puzzle > 0 else now),
			"puzzle_id": event_puzzle_id,
			"puzzles_completed": count,
			"is_first": previous_count == 0 and count == 1,
		})
	if _puzzle_event or _tutorial_event:
		_sync_requested = true
	if tutorial > 0:
		_tutorial_unix = tutorial
	_activity_unix = activity
	_last_upload_unix = now
	_save_local()


func _write_statistics(
	first_access: int,
	tutorial: int,
	first_puzzle: int,
	last_puzzle: int,
	count: int,
	activity: int
) -> void:
	var statistics: Array[Dictionary] = []
	_append_stat(statistics, STAT_FIRST, first_access)
	_append_stat(statistics, STAT_TUTORIAL, tutorial)
	_append_stat(statistics, STAT_FIRST_PUZZLE, first_puzzle)
	_append_stat(statistics, STAT_LAST_PUZZLE, last_puzzle)
	_append_stat(statistics, STAT_COUNT, count)
	_append_stat(statistics, STAT_ACTIVITY, activity)
	if statistics.is_empty():
		return
	var signature := _stat_signature(statistics)
	if signature == _stats_signature:
		return
	var json: Dictionary = await PlayFabTools._client_post_json("UpdatePlayerStatistics", {
		"Statistics": statistics,
	})
	if json.is_empty():
		if not _stat_warning_shown:
			_stat_warning_shown = true
			push_warning(
				"PlayFab: no se pudieron actualizar las estadísticas de hitos. "
				+ "Ejecuta tools/export_playfab_milestones.py para crearlas en el título."
			)
		return
	_stats_signature = signature
	_save_local()


func _append_stat(statistics: Array[Dictionary], stat_name: String, value: int) -> void:
	if stat_name != STAT_COUNT and value <= 0:
		return
	statistics.append({
		"StatisticName": stat_name,
		"Value": clampi(value, 0, 2147483647),
	})


func _stat_signature(statistics: Array[Dictionary]) -> String:
	var text := ""
	for entry in statistics:
		text += "%s=%s;" % [str(entry.get("StatisticName", "")), str(entry.get("Value", 0))]
	return text


func _pending_stat_signature(
	first_access: int,
	tutorial: int,
	first_puzzle: int,
	last_puzzle: int,
	count: int,
	activity: int
) -> String:
	var statistics: Array[Dictionary] = []
	_append_stat(statistics, STAT_FIRST, first_access)
	_append_stat(statistics, STAT_TUTORIAL, tutorial)
	_append_stat(statistics, STAT_FIRST_PUZZLE, first_puzzle)
	_append_stat(statistics, STAT_LAST_PUZZLE, last_puzzle)
	_append_stat(statistics, STAT_COUNT, count)
	_append_stat(statistics, STAT_ACTIVITY, activity)
	return _stat_signature(statistics)


func _read_server_values() -> Dictionary:
	var keys: Array = []
	for key in DATA_KEYS:
		keys.append(key)
	var json: Dictionary = await PlayFabTools._client_post_json("GetUserData", {"Keys": keys})
	var values := {"_ok": false}
	if json.is_empty():
		return values
	values["_ok"] = true
	var data: Variant = json.get("data", {})
	if not (data is Dictionary):
		return values
	var records: Variant = (data as Dictionary).get("Data", {})
	if not (records is Dictionary):
		return values
	for key in (records as Dictionary).keys():
		var entry: Variant = records[key]
		if entry is Dictionary:
			values[str(key)] = str((entry as Dictionary).get("Value", ""))
		else:
			values[str(key)] = str(entry)
	return values


func _account_first_access_unix() -> int:
	var json: Dictionary = await PlayFabTools._client_post_json("GetAccountInfo", {})
	if json.is_empty():
		return 0
	var data: Variant = json.get("data", {})
	if not (data is Dictionary):
		return 0
	var info: Variant = (data as Dictionary).get("AccountInfo", {})
	if not (info is Dictionary):
		return 0
	var account: Dictionary = info
	var title: Variant = account.get("TitleInfo", {})
	var title_info: Dictionary = title if title is Dictionary else {}
	var unix := _parse_iso(str(title_info.get("FirstLogin", "")))
	if unix <= 0:
		unix = _parse_iso(str(title_info.get("Created", "")))
	if unix <= 0:
		unix = _parse_iso(str(account.get("Created", "")))
	return unix


func _history_snapshot() -> Dictionary:
	if typeof(HistoryManager) == TYPE_NIL or not HistoryManager.has_method("milestone_snapshot"):
		return {}
	return HistoryManager.milestone_snapshot()


func _update_labels(updates: Dictionary) -> String:
	var labels := {
		KEY_FIRST: "primer acceso",
		KEY_TUTORIAL: "tutorial",
		KEY_FIRST_PUZZLE: "primer puzle",
		KEY_LAST_PUZZLE: "último puzle",
		KEY_COUNT: "total puzles",
		KEY_ACTIVITY: "última actividad",
		KEY_IDS: "ids",
	}
	var text := ""
	for key in updates.keys():
		if text != "":
			text += ", "
		text += str(labels.get(key, key))
	return text


func _touch_activity() -> void:
	_activity_unix = _now()


func _now() -> int:
	return int(Time.get_unix_time_from_system())


func _earliest(a: int, b: int) -> int:
	if a <= 0:
		return b
	if b <= 0:
		return a
	return a if a < b else b


func _latest(a: int, b: int) -> int:
	return a if a > b else b


func _iso_utc(unix_time: int) -> String:
	if unix_time <= 0:
		return ""
	return Time.get_datetime_string_from_unix_time(unix_time, false) + "Z"


func _parse_iso(value: String) -> int:
	var text := value.strip_edges()
	if text.length() < 19:
		return 0
	text = text.substr(0, 19)
	return int(Time.get_unix_time_from_datetime_string(text))


func _text_to_ids(text: String) -> Array[int]:
	var ids: Array[int] = []
	var seen := {}
	for part in text.split(",", false):
		var token := part.strip_edges()
		if token == "":
			continue
		if not token.is_valid_int():
			continue
		var puzzle_id := int(token)
		if puzzle_id < 0 or seen.has(puzzle_id):
			continue
		seen[puzzle_id] = true
		ids.append(puzzle_id)
	ids.sort()
	return ids


func _union_ids(server_ids: Array, local_ids: Array) -> Array[int]:
	var merged: Array[int] = []
	var seen := {}
	for source in [server_ids, local_ids]:
		for value in source:
			var puzzle_id := int(value)
			if puzzle_id < 0 or seen.has(puzzle_id):
				continue
			seen[puzzle_id] = true
			merged.append(puzzle_id)
	merged.sort()
	return merged


func _ids_to_text(ids: Array) -> String:
	var text := ""
	for puzzle_id in ids:
		if text != "":
			text += ","
		text += str(int(puzzle_id))
	return text


func _load_local() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(LOCAL_PATH) != OK:
		return
	_tutorial_unix = int(cfg.get_value("milestones", "tutorial_unix", 0))
	_activity_unix = int(cfg.get_value("milestones", "last_activity_unix", 0))
	_stats_signature = str(cfg.get_value("milestones", "stats_signature", ""))
	_last_upload_unix = int(cfg.get_value("milestones", "last_upload_unix", 0))


func _save_local() -> void:
	var cfg := ConfigFile.new()
	cfg.load(LOCAL_PATH)
	cfg.set_value("milestones", "tutorial_unix", _tutorial_unix)
	cfg.set_value("milestones", "last_activity_unix", _activity_unix)
	cfg.set_value("milestones", "stats_signature", _stats_signature)
	cfg.set_value("milestones", "last_upload_unix", _last_upload_unix)
	cfg.save(LOCAL_PATH)
