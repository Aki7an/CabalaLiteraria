extends Node

## Opens the puzzle encoded in an incoming link.
## cifraletra://p/116, https://host/p/116, and ?puzzle=116 / ?id=116.

const THEME_PREVIEW := preload("res://scenes/game/PuzzleThemePreview.tscn")
const INBOX_NAME := "cifraletra_deeplink.url"
const GAME_SCENE := "res://scenes/App.tscn"
const _QUERY_KEYS: PackedStringArray = ["puzzle", "puzzle_id", "level", "id"]

var _pending_id := -1
var _launching := false
var _last_opened_id := -1
var _opened_msec := -10000
var _android_stamp := ""
var _cmdline_checked := false


func _ready() -> void:
	# El intent de Android no se lee aquí: hacerlo en el primer _ready
	# tumba el proceso mientras sigue visible la pantalla de Godot.
	_remember_stored_urls()
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(_capture_and_open)
	add_child(timer)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED:
		_capture_and_open()


func has_pending() -> bool:
	return _pending_id >= 0


func open_pending() -> bool:
	if _launching:
		return true
	var puzzle_id := _pending_id
	if puzzle_id < 0:
		return false
	_ensure_phrase_db()
	if not _puzzle_exists(puzzle_id):
		push_warning("DeepLink: no hay puzle con id %d. Se abre el menú." % puzzle_id)
		_pending_id = -1
		_go_home()
		return false
	if _recently_opened(puzzle_id) or _already_playing(puzzle_id):
		_pending_id = -1
		return false
	_pending_id = -1
	_launching = true
	_last_opened_id = puzzle_id
	_opened_msec = Time.get_ticks_msec()
	return _launch(puzzle_id)


static func puzzle_id_from_url(raw: String) -> int:
	var text := raw.strip_edges().trim_prefix("\"").trim_suffix("\"").trim_prefix("'").trim_suffix("'")
	if text.begins_with("--uri="):
		text = text.substr(6).strip_edges().trim_prefix("\"").trim_suffix("\"")
	if text.is_empty():
		return -1
	text = text.uri_decode()
	if not text.contains("://") and not text.begins_with("cifraletra:"):
		if text.is_valid_int():
			return _valid_id(int(text))
		return -1
	var hash := text.find("#")
	if hash >= 0:
		text = text.substr(0, hash)
	var query := ""
	var query_at := text.find("?")
	if query_at >= 0:
		query = text.substr(query_at + 1)
		text = text.substr(0, query_at)
	var from_query := _id_from_query(query)
	if from_query >= 0:
		return from_query
	var body := text
	var scheme := body.find("://")
	if scheme >= 0:
		body = body.substr(scheme + 3)
	elif body.begins_with("cifraletra:"):
		body = body.substr("cifraletra:".length())
	var parts := body.split("/", false)
	for index in range(parts.size() - 1, -1, -1):
		var part := str(parts[index]).strip_edges()
		if part.is_valid_int():
			return _valid_id(int(part))
	if body.is_valid_int():
		return _valid_id(int(body))
	return -1


static func _id_from_query(query: String) -> int:
	if query.is_empty():
		return -1
	var found := -1
	for pair in query.split("&", false):
		var eq := pair.find("=")
		if eq < 0:
			continue
		var key := pair.substr(0, eq).strip_edges().uri_decode().to_lower()
		var value := pair.substr(eq + 1).strip_edges().uri_decode()
		if _QUERY_KEYS.has(key) and value.is_valid_int():
			var parsed := _valid_id(int(value))
			if parsed >= 0:
				found = parsed
		elif key == "referrer" and found < 0:
			var nested := _id_from_query(value.replace(";", "&"))
			if nested >= 0:
				found = nested
	return found


static func _valid_id(puzzle_id: int) -> int:
	return puzzle_id if puzzle_id >= 0 else -1


func pull() -> void:
	_remember_urls()


func _capture_and_open() -> void:
	_remember_urls()
	if _pending_id < 0 or _launching:
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	open_pending()


func _remember_stored_urls() -> void:
	for url in [_read_inbox(), _cmdline_url()]:
		if url != "":
			_remember(url)


func _remember_urls() -> void:
	_remember_stored_urls()
	var android := _android_url()
	if android != "":
		_remember(android)


func _remember(url: String) -> void:
	var puzzle_id := puzzle_id_from_url(url)
	if puzzle_id < 0 or _recently_opened(puzzle_id) or _already_playing(puzzle_id):
		return
	if puzzle_id != _pending_id:
		print("[DeepLink] ", url, " -> ", puzzle_id)
		_pending_id = puzzle_id


func _recently_opened(puzzle_id: int) -> bool:
	return puzzle_id == _last_opened_id and Time.get_ticks_msec() - _opened_msec < 2000


func _ensure_phrase_db() -> void:
	if GameManager.frases_db.is_empty():
		GameManager.cargar_frases_desde_json()


func _puzzle_exists(puzzle_id: int) -> bool:
	return puzzle_id >= 0 and not GameManager.get_phrase_item(puzzle_id).is_empty()


func _go_home() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if tree.paused:
		tree.paused = false
	var scene := tree.current_scene
	if scene != null and scene.has_method("reveal_main_menu"):
		scene.call_deferred("reveal_main_menu")
		return
	tree.call_deferred("change_scene_to_file", Distribution.home_scene())


func _launch(puzzle_id: int) -> bool:
	_launching = false
	if not is_inside_tree():
		return false
	if not _puzzle_exists(puzzle_id) or _already_playing(puzzle_id):
		if not _puzzle_exists(puzzle_id):
			push_warning("DeepLink: no hay puzle con id %d. Se abre el menú." % puzzle_id)
			_go_home()
		return false
	var item := GameManager.get_phrase_item(puzzle_id)
	var summary := PuzzleSaveManager.get_puzzle_summary(puzzle_id)
	var completed := str(summary.get("status", "")) == "completed"
	GameManager.reset_game_paremeters()
	GameManager.resetear_partida_terminada()
	GameManager.reset_numero_letras_reveladas()
	if completed:
		GameManager.session_source = GameManager.SOURCE_PRACTICE
		GameManager.locked_record_stars = clampi(int(summary.get("stars_remaining", 0)), 0, 5)
		GameManager.allow_completed_replay = true
	else:
		GameManager.session_source = GameManager.SOURCE_NONE
		GameManager.locked_record_stars = -1
		GameManager.allow_completed_replay = false
	GameManager.id_frase = puzzle_id
	GameManager.set_game_mode_actual(GameManager.level_game_mode(item))
	GameManager.set_dificultad_actual(int(item.get("difficulty", 1)))
	GameManager.seleccionar_por_index(puzzle_id)
	if int(GameManager.id_frase) != puzzle_id or GameManager.frase_original_til.strip_edges().is_empty():
		push_warning("DeepLink: el puzle %d no se pudo preparar. Se abre el menú." % puzzle_id)
		_go_home()
		return false
	PuzzleSaveManager.prepare_current_puzzle_cipher()
	GameManager.set_go_to_game_disable()
	print("[DeepLink] puzzle start ", puzzle_id)
	_show_puzzle_start(item)
	return true


func _show_puzzle_start(item: Dictionary) -> void:
	var host := get_tree().current_scene if get_tree() != null else null
	if host == null:
		GameManager.launch_prepared_game()
		return
	if host.has_method("hide_for_puzzle_link"):
		host.call("hide_for_puzzle_link")
	var previous := host.get_node_or_null("DeepLinkPuzzleStart")
	if previous:
		previous.queue_free()
	var preview := THEME_PREVIEW.instantiate()
	preview.name = "DeepLinkPuzzleStart"
	preview.set("launch_game_on_start", true)
	preview.set("image_path", PuzzleThemePreview.find_image_path(
		int(item.get("image_number", GameManager.id_image)),
		int(item.get("index", GameManager.id_frase))
	))
	host.add_child(preview)
	if preview is Control:
		preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back := preview.get_node_or_null("Card/ButtonBack") as BaseButton
	if back:
		var built_in := Callable(preview, "_on_back_pressed")
		if back.pressed.is_connected(built_in):
			back.pressed.disconnect(built_in)
		if not back.pressed.is_connected(_reveal_menu_after_back):
			back.pressed.connect(_reveal_menu_after_back)


func _reveal_menu_after_back() -> void:
	SoundManager.play("ButtonClick")
	var scene := get_tree().current_scene if get_tree() != null else null
	if scene == null:
		return
	var preview := scene.get_node_or_null("DeepLinkPuzzleStart")
	if preview:
		preview.queue_free()
	if scene.has_method("reveal_main_menu"):
		scene.call_deferred("reveal_main_menu")


func _already_playing(puzzle_id: int) -> bool:
	if int(GameManager.id_frase) != puzzle_id:
		return false
	var scene := get_tree().current_scene if get_tree() != null else null
	return scene != null and scene.scene_file_path == GAME_SCENE


func _read_inbox() -> String:
	var found := ""
	for path in _inbox_paths():
		if not FileAccess.file_exists(path):
			continue
		if found == "":
			found = FileAccess.get_file_as_string(path).strip_edges()
		DirAccess.remove_absolute(path)
	return found


func _inbox_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	var dirs: PackedStringArray = [
		str(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)).strip_edges(),
		OS.get_user_data_dir(),
	]
	for dir in dirs:
		if dir.is_empty():
			continue
		var path := dir.path_join(INBOX_NAME)
		if not paths.has(path):
			paths.append(path)
	return paths


func _android_url() -> String:
	if OS.get_name() != "Android" or not Engine.has_singleton("AndroidRuntime"):
		return ""
	var runtime: Object = Engine.get_singleton("AndroidRuntime")
	var activity: Variant = runtime.getActivity()
	if activity == null or JavaClassWrapper.get_exception() != null:
		return ""
	var intent: Variant = activity.getIntent()
	if intent == null or JavaClassWrapper.get_exception() != null:
		return ""
	var action := str(intent.getAction())
	if JavaClassWrapper.get_exception() != null or action != "android.intent.action.VIEW":
		return ""
	var data: Variant = intent.getDataString()
	if JavaClassWrapper.get_exception() != null or data == null:
		_android_stamp = ""
		return ""
	var url := str(data).strip_edges()
	if url.is_empty() or url == "null" or url == "<null>":
		_android_stamp = ""
		return ""
	if url == _android_stamp:
		return ""
	_android_stamp = url
	# setData(null) cierra el proceso en Godot 4. Una cadena vacía sí es válida.
	intent.call("setAction", "android.intent.action.MAIN")
	_java_failed()
	return url


func _java_failed() -> bool:
	return JavaClassWrapper.get_exception() != null


func _cmdline_url() -> String:
	if _cmdline_checked:
		return ""
	_cmdline_checked = true
	var args := OS.get_cmdline_user_args()
	args.append_array(OS.get_cmdline_args())
	for arg in args:
		var text := str(arg).strip_edges()
		if puzzle_id_from_url(text) >= 0 and (text.contains("cifraletra:") or text.begins_with("--uri=") or text.contains("puzzle=")):
			return text
	return ""
