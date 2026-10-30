extends Node

signal loaded

const SAVE_PATH := "user://player_progress.json"
const CLOUD_KEY := "player_progress"
const VERSION := 1
const CLOUD_WAIT_MS := 4000
const PUZZLE_SCENE := "res://scenes/crazygames/CrazyGamesPuzzle.tscn"
const RUN_PUZZLES: Array[int] = [3098, 3065, 1009, 4027, 1022, 3109, 3102]

var total_stars := 0
var run: Dictionary = {}

var _loaded := false
var _has_record := false
var _saved_at := 0
var _last_finish_key := ""


func _ready() -> void:
	_load_local()
	if OS.has_feature("web") and Distribution.is_horizontal():
		_pull_cloud()
		return
	_finish_load()


func ensure_loaded() -> void:
	while not _loaded:
		await get_tree().process_frame


func has_run() -> bool:
	return int(run.get("number", 0)) > 0


func run_number() -> int:
	return int(run.get("number", 1)) if has_run() else 1


func begin_run(number: int = 1) -> void:
	if has_run():
		return
	run = {
		"number": maxi(number, 1),
		"puzzles_played": 0,
		"stars_earned": 0,
		"last_match": {},
	}
	_save()


func puzzle_to_open() -> int:
	var last_id := -1
	var last_status := ""
	if has_run():
		var last: Dictionary = run.get("last_match", {})
		last_id = int(last.get("puzzle_id", -1))
		last_status = str(last.get("status", ""))
	var start_at := 0
	var index := RUN_PUZZLES.find(last_id)
	if index >= 0:
		var retry := last_status == "in_progress" or last_status == "lost"
		if retry and not _local_completed_newer(last_id):
			return last_id
		if last_status == "completed" or (retry and _local_completed_newer(last_id)):
			start_at = index + 1
	for cursor in range(start_at, RUN_PUZZLES.size()):
		var puzzle_id := RUN_PUZZLES[cursor]
		if str(PuzzleSaveManager.get_puzzle_state(puzzle_id).get("status", "")) == "completed":
			continue
		return puzzle_id
	return RUN_PUZZLES[RUN_PUZZLES.size() - 1]


func has_pending_puzzle() -> bool:
	var puzzle_id := puzzle_to_open()
	if str(PuzzleSaveManager.get_puzzle_state(puzzle_id).get("status", "")) == "completed":
		return false
	if has_run():
		var last: Dictionary = run.get("last_match", {})
		if int(last.get("puzzle_id", -1)) == puzzle_id and str(last.get("status", "")) == "completed":
			return false
	return true


func open_current_puzzle() -> void:
	if not has_run():
		begin_run()
	var puzzle_id := puzzle_to_open()
	if puzzle_id == resume_puzzle_id():
		install_saved_match()
	GameManager.session_source = GameManager.SOURCE_NONE
	GameManager.allow_completed_replay = false
	GameManager.onboarding_stage = 0
	for raw in GameManager.frases_db:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = raw
		if int(item.get("index", -1)) != puzzle_id:
			continue
		GameManager.set_game_mode_actual(GameManager.level_game_mode(item))
		GameManager.set_dificultad_actual(int(item.get("difficulty", 1)))
		break
	GameManager.seleccionar_por_index(puzzle_id)
	PuzzleSaveManager.prepare_current_puzzle_cipher()
	GameManager.puzzle_enter_pending = true
	GameManager.set_go_to_game_disable()
	var tree := get_tree()
	if tree == null:
		return
	if tree.paused:
		tree.paused = false
	if typeof(StarCollectOverlay) != TYPE_NIL and StarCollectOverlay.is_covering():
		StarCollectOverlay.fade_white_cover(0.6)
	SignalManager.partida_iniciada.emit()
	tree.change_scene_to_file(PUZZLE_SCENE)


func _local_completed_newer(puzzle_id: int) -> bool:
	var existing := PuzzleSaveManager.get_puzzle_state(puzzle_id)
	if str(existing.get("status", "")) != "completed":
		return false
	var existing_meta: Dictionary = existing.get("meta", {})
	var last: Dictionary = run.get("last_match", {})
	var last_meta: Dictionary = last.get("meta", {})
	return int(existing_meta.get("updated_at", 0)) >= int(last_meta.get("updated_at", 0))


func resume_puzzle_id() -> int:
	if not has_run():
		return -1
	var last: Dictionary = run.get("last_match", {})
	if str(last.get("status", "")) != "in_progress":
		return -1
	var puzzle_id := int(last.get("puzzle_id", -1))
	if puzzle_id < 0:
		return -1
	var existing := PuzzleSaveManager.get_puzzle_state(puzzle_id)
	if str(existing.get("status", "")) == "completed":
		var existing_meta: Dictionary = existing.get("meta", {})
		var last_meta: Dictionary = last.get("meta", {})
		if int(existing_meta.get("updated_at", 0)) >= int(last_meta.get("updated_at", 0)):
			return -1
	return puzzle_id


func install_saved_match() -> void:
	if not has_run():
		return
	var last: Dictionary = run.get("last_match", {})
	var puzzle_id := int(last.get("puzzle_id", -1))
	if puzzle_id < 0 or str(last.get("status", "")) != "in_progress":
		return
	var existing := PuzzleSaveManager.get_puzzle_state(puzzle_id)
	var existing_meta: Dictionary = existing.get("meta", {})
	var last_meta: Dictionary = last.get("meta", {})
	if not existing.is_empty() and int(existing_meta.get("updated_at", 0)) >= int(last_meta.get("updated_at", 0)):
		return
	PuzzleSaveManager.import_external_state(puzzle_id, last)


func note_match_progress() -> void:
	if not has_run():
		return
	var snap := _capture("in_progress")
	if snap.is_empty():
		return
	var last: Dictionary = run.get("last_match", {})
	if int(last.get("puzzle_id", -2)) == int(snap.get("puzzle_id", -1)):
		var previous := str(last.get("status", ""))
		if previous == "completed" or previous == "lost":
			snap["status"] = previous
			var old_stats: Dictionary = last.get("stats", {})
			if bool(old_stats.get("completion_star", false)):
				var stats: Dictionary = snap.get("stats", {})
				stats["completion_star"] = true
				stats["stars"] = int(old_stats.get("stars", stats.get("stars", 0)))
				snap["stats"] = stats
	run["last_match"] = snap
	_save()


func note_match_finished(entry: Dictionary) -> void:
	var won := bool(entry.get("partida_ganada", false))
	var stars := maxi(int(entry.get("estrellas", 0)), 0) if won else 0
	var puzzle_id := int(entry.get("id", GameManager.id_frase))
	var status := "completed" if won else "lost"
	var key := "%d:%s:%d:%d" % [
		puzzle_id,
		status,
		int(entry.get("tiempo_partida", 0)),
		int(entry.get("completed_unix", 0)),
	]
	if key == _last_finish_key:
		return
	_last_finish_key = key
	total_stars += stars
	if has_run():
		run["puzzles_played"] = int(run.get("puzzles_played", 0)) + 1
		run["stars_earned"] = int(run.get("stars_earned", 0)) + stars
		var snap := _capture(status)
		if snap.is_empty():
			snap = _match_from_entry(entry, status, stars)
		else:
			var stats: Dictionary = snap.get("stats", {})
			stats["stars"] = stars
			stats["completion_star"] = false
			snap["stats"] = stats
		run["last_match"] = snap
	_save()


func note_completion_star() -> void:
	total_stars += 1
	if has_run():
		run["stars_earned"] = int(run.get("stars_earned", 0)) + 1
		var last: Dictionary = run.get("last_match", {})
		if not last.is_empty():
			var stats: Dictionary = last.get("stats", {})
			if not bool(stats.get("completion_star", false)):
				stats["completion_star"] = true
				stats["stars"] = int(stats.get("stars", 0)) + 1
				last["stats"] = stats
				run["last_match"] = last
	_save()


func _finish_load() -> void:
	if not _has_record:
		total_stars = _stars_from_history()
		_save()
	_loaded = true
	loaded.emit()


func _pull_cloud() -> void:
	var start := Time.get_ticks_msec()
	while not _cloud_ready():
		if Time.get_ticks_msec() - start >= CLOUD_WAIT_MS:
			break
		await get_tree().process_frame
	if _cloud_ready():
		var raw := _cloud_get()
		if raw != "":
			_apply_cloud(raw)
	_finish_load()


func _load_local() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_apply_data(parsed)


func _apply_data(data: Dictionary) -> void:
	total_stars = maxi(int(data.get("total_stars", 0)), 0)
	_saved_at = int(data.get("saved_at", 0))
	var saved_run: Variant = data.get("run", {})
	if saved_run is Dictionary and int((saved_run as Dictionary).get("number", 0)) > 0:
		run = (saved_run as Dictionary).duplicate(true)
	else:
		run = {}
	_has_record = true


func _apply_cloud(raw: String) -> void:
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed
	if _has_record and _saved_at > int(data.get("saved_at", 0)):
		_save()
		return
	_apply_data(data)
	_write_local()


func _save() -> void:
	_saved_at = int(Time.get_unix_time_from_system())
	var data := _payload()
	var text := JSON.stringify(data)
	if text == "":
		return
	_has_record = true
	_write_text(text)
	_push_cloud(text)


func _write_local() -> void:
	var text := JSON.stringify(_payload())
	if text != "":
		_write_text(text)


func _payload() -> Dictionary:
	var data := {
		"version": VERSION,
		"saved_at": _saved_at,
		"total_stars": total_stars,
	}
	if has_run():
		data["run"] = run.duplicate(true)
	return data


func _write_text(text: String) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)


func _capture(status: String) -> Dictionary:
	var bundle: Dictionary = PuzzleSaveManager.capture_active_bundle(status)
	if bundle.is_empty():
		return {}
	bundle["stats"] = _stats_from(bundle)
	return bundle


func _stats_from(bundle: Dictionary) -> Dictionary:
	var attempt: Dictionary = bundle.get("attempt", {})
	var meta: Dictionary = bundle.get("meta", {})
	var resolution: Dictionary = bundle.get("resolution", {})
	var placed := 0
	var cells: Dictionary = resolution.get("cells", {})
	for key in cells:
		var cell: Variant = cells[key]
		if not (cell is Dictionary):
			continue
		var row: Dictionary = cell
		if str(row.get("letter", "")) == "":
			continue
		if str(row.get("visual_state", "")) == "empty":
			continue
		placed += 1
	var lives_lost := 0
	if typeof(HistoryManager) != TYPE_NIL:
		lives_lost = HistoryManager._calcula_vidas_perdidas()
	return {
		"letters_placed": placed,
		"letters_total": int(meta.get("letters_total", 0)),
		"letters_erased": int(attempt.get("cambios_hechos", 0)),
		"letters_erased_list": attempt.get("letras_borradas", []),
		"errors": int(attempt.get("reveal_errors_count", 0)),
		"correct_reveals": int(attempt.get("reveal_success_count", 0)),
		"time_seconds": int(attempt.get("tiempo_partida", meta.get("tiempo_partida", 0))),
		"stars": int(attempt.get("puzzle_stars", 0)),
		"max_stars": int(attempt.get("puzzle_max_stars", 0)),
		"hints_used": int(attempt.get("pistas_utilizadas", 0)),
		"hints_word": int(attempt.get("pistas_utilizadas_1", 0)),
		"hints_letter": int(attempt.get("pistas_utilizadas_2", 0)),
		"consonants_bought": int(attempt.get("consonantes_compradas", 0)),
		"vowels_ae_bought": int(attempt.get("vocalesAE_compradas", 0)),
		"vowels_iou_bought": int(attempt.get("vocalesIOU_compradas", 0)),
		"lives": int(attempt.get("lives", 0)),
		"lives_lost": lives_lost,
		"score": int(attempt.get("score", 0)),
		"difficulty": int(meta.get("difficulty", 0)),
		"category": str(meta.get("category", "")),
		"mode": str(meta.get("mode", "")),
		"locale": str(meta.get("locale", "")),
		"completion_star": false,
	}


func _match_from_entry(entry: Dictionary, status: String, stars: int) -> Dictionary:
	return {
		"status": status,
		"puzzle_id": int(entry.get("id", -1)),
		"resolution": {},
		"attempt": {},
		"cipher": {},
		"meta": {},
		"stats": {
			"letters_placed": 0,
			"letters_erased": int(entry.get("gomas_utilizadas", 0)),
			"errors": int(entry.get("revelaciones_falladas", 0)),
			"correct_reveals": int(entry.get("revelaciones_correctas", 0)),
			"time_seconds": int(entry.get("tiempo_partida", 0)),
			"stars": stars,
			"difficulty": int(entry.get("dificultad", 1)),
			"category": str(entry.get("categoria", "")),
			"mode": str(entry.get("game_mode", "")),
			"score": int(entry.get("score", 0)),
			"lives_lost": int(entry.get("vidas_perdidas", 0)),
			"completion_star": false,
		},
	}


func _stars_from_history() -> int:
	if typeof(HistoryManager) == TYPE_NIL:
		return 0
	var total := 0
	for value in HistoryManager.get_history():
		if not (value is Dictionary):
			continue
		var row: Dictionary = value
		if not bool(row.get("partida_ganada", false)):
			continue
		total += maxi(int(row.get("estrellas", 0)), 0)
		if bool(row.get("completion_star", false)):
			total += 1
	return total


func _cloud_ready() -> bool:
	return (
		OS.has_feature("web")
		and typeof(CrazyGames) != TYPE_NIL
		and CrazyGames.is_initialised
		and typeof(CrazyGamesBridge) != TYPE_NIL
	)


func _cloud_get() -> String:
	var js := "window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.data ? window.CrazyGames.SDK.data.getItem(%s) : ''" % JSON.stringify(CLOUD_KEY)
	var value: Variant = JavaScriptBridge.eval(js)
	return value if typeof(value) == TYPE_STRING else ""


func _push_cloud(text: String) -> void:
	if not _cloud_ready() or text == "":
		return
	var js := "if (window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.data) window.CrazyGames.SDK.data.setItem(%s, %s);" % [JSON.stringify(CLOUD_KEY), JSON.stringify(text)]
	JavaScriptBridge.eval(js)
