extends Node

## Opens the puzzle encoded in an incoming link.
## cifraletra://p/3RS6LQ, https://host/p/3RS6LQ, and ?puzzle=3RS6LQ.
## The token is a 6-character code, not the puzzle id.

const THEME_PREVIEW := preload("res://scenes/game/PuzzleThemePreview.tscn")
const ShareConfig := preload("res://store/share_config.gd")
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const RemotePuzzles = preload("res://store/remote_puzzles.gd")
## Public read URL of the R2 bucket. The S3 API is not used.
const REMOTE_ROOTS: PackedStringArray = [
	"https://pub-1eba41b6ea9943db9fcab19d3f349f89.r2.dev/Puzles",
]
const INBOX_NAME := "cifraletra_deeplink.url"
const GAME_SCENE := "res://scenes/App.tscn"
const _QUERY_KEYS: PackedStringArray = ["puzzle", "puzzle_id", "level", "id"]

var _pending_id := -1
var _launching := false
var _last_opened_id := -1
var _opened_msec := -10000
var _android_stamp := ""
var _cmdline_checked := false
var _missing_notice := false
var _notice_retries := 0
var _fetching := false
var _remote_id := -1
var _remote_root := 0
var _remote_step := ""
var _remote_http: HTTPRequest


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
	if _launching or _fetching:
		return true
	var puzzle_id := _pending_id
	if puzzle_id < 0:
		return false
	_ensure_phrase_db()
	if not _puzzle_exists(puzzle_id):
		if RemotePuzzles.has_files(puzzle_id) and GameManager.install_saved_remote(puzzle_id):
			pass
		else:
			_begin_remote_download(puzzle_id)
			return true
	if not _puzzle_exists(puzzle_id):
		_reject_unavailable(puzzle_id)
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
		return _id_from_code(text)
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
		var parsed := _id_from_code(str(parts[index]))
		if parsed >= 0:
			return parsed
	return _id_from_code(body)


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
		if _QUERY_KEYS.has(key):
			var parsed := _id_from_code(value)
			if parsed >= 0:
				found = parsed
		elif key == "referrer" and found < 0:
			var nested := _id_from_query(value.replace(";", "&"))
			if nested >= 0:
				found = nested
	return found


static func _id_from_code(token: String) -> int:
	return ShareConfig.puzzle_id_from_code(token.strip_edges())


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
		if _missing_notice:
			call_deferred("_present_missing_notice")
		return
	if _missing_notice and not tree.scene_changed.is_connected(_on_home_ready_for_notice):
		tree.scene_changed.connect(_on_home_ready_for_notice, CONNECT_ONE_SHOT)
	tree.call_deferred("change_scene_to_file", Distribution.home_scene())


func _reject_unavailable(puzzle_id: int) -> void:
	push_warning("DeepLink: no hay puzle con id %d. Se abre el menú." % puzzle_id)
	_pending_id = -1
	_missing_notice = true
	_notice_retries = 0
	_go_home()


func _begin_remote_download(puzzle_id: int) -> void:
	_fetching = true
	_remote_id = puzzle_id
	_remote_root = 0
	_remote_step = ""
	_show_download_notice()
	_request_remote_json()


func _request_remote_json() -> void:
	if _remote_root >= REMOTE_ROOTS.size():
		_finish_remote(false)
		return
	_remote_step = "json"
	var url := _remote_object_url("json")
	if url.is_empty():
		_finish_remote(false)
		return
	_remote_get(url)


func _request_remote_image() -> void:
	_remote_step = "webp"
	var url := _remote_object_url("webp")
	if url.is_empty():
		_finish_remote(false)
		return
	_remote_get(url)


func _remote_object_url(extension: String) -> String:
	var code := ShareConfig.puzzle_code(_remote_id)
	if code.is_empty() or _remote_root < 0 or _remote_root >= REMOTE_ROOTS.size():
		return ""
	return "%s/%s.%s" % [REMOTE_ROOTS[_remote_root], code, extension]


func _remote_get(url: String) -> void:
	var http := _remote_request()
	if http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http.cancel_request()
	var error := http.request(url)
	if error != OK:
		print("[DeepLink] remote request failed ", error, " ", url)
		call_deferred("_advance_remote_root")


func _remote_request() -> HTTPRequest:
	if _remote_http != null and is_instance_valid(_remote_http):
		return _remote_http
	_remote_http = HTTPRequest.new()
	_remote_http.timeout = 20.0
	_remote_http.request_completed.connect(_on_remote_completed)
	add_child(_remote_http)
	return _remote_http


func _on_remote_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not _fetching:
		return
	var url := _remote_object_url("json" if _remote_step == "json" else "webp")
	print("[DeepLink] remote ", code, " ", url)
	var ok := result == HTTPRequest.RESULT_SUCCESS and code == 200
	if _remote_step == "json":
		if ok and RemotePuzzles.save_json(_remote_id, body.get_string_from_utf8()):
			call_deferred("_request_remote_image")
			return
		call_deferred("_advance_remote_root")
		return
	if ok and RemotePuzzles.save_webp(_remote_id, body) and GameManager.install_saved_remote(_remote_id):
		_finish_remote(true)
		return
	call_deferred("_advance_remote_root")


func _advance_remote_root() -> void:
	RemotePuzzles.discard(_remote_id)
	_remote_root += 1
	_request_remote_json()


func _finish_remote(ok: bool) -> void:
	var puzzle_id := _remote_id
	_fetching = false
	_hide_download_notice()
	if not ok:
		RemotePuzzles.discard(puzzle_id)
		_reject_unavailable(puzzle_id)
		return
	_pending_id = puzzle_id
	_launching = false
	open_pending()


func _show_download_notice() -> void:
	var host := _notice_host()
	if host == null or host.get_node_or_null("PuzzleDownloadDialog") != null:
		return
	var overlay := ColorRect.new()
	overlay.name = "PuzzleDownloadDialog"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.08, 0.04, 0.02, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 130
	host.add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(860, 0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 0.965, 0.86, 1)
	card_style.border_color = Color(0.62, 0.4, 0.16, 0.46)
	card_style.set_border_width_all(4)
	card_style.border_width_bottom = 9
	card_style.set_corner_radius_all(48)
	card_style.content_margin_left = 48
	card_style.content_margin_right = 48
	card_style.content_margin_top = 40
	card_style.content_margin_bottom = 40
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	card.add_child(_notice_label(_download_text(), 40, Color(0.24, 0.14, 0.08, 1)))


func _hide_download_notice() -> void:
	var host := _notice_host()
	if host == null:
		return
	var overlay := host.get_node_or_null("PuzzleDownloadDialog")
	if overlay != null:
		overlay.queue_free()


func _download_text() -> String:
	var lookup := "PuzzleDownloadBody"
	var translated := tr(lookup)
	if translated != lookup and not translated.is_empty():
		return translated
	var lang := TranslationServer.get_locale().substr(0, 2).to_lower()
	match lang:
		"es":
			return "Descargando el puzle…"
		"de":
			return "Rätsel wird geladen…"
		"fr":
			return "Téléchargement du puzzle…"
		"eu":
			return "Puzzlea deskargatzen…"
		"it":
			return "Download del puzzle…"
		"pt":
			return "A descarregar o puzzle…"
		_:
			return "Downloading the puzzle…"


func _on_home_ready_for_notice() -> void:
	call_deferred("_present_missing_notice")


func _present_missing_notice() -> void:
	if not _missing_notice:
		return
	var host := _notice_host()
	if host == null:
		if _notice_retries < 8:
			_notice_retries += 1
			call_deferred("_present_missing_notice")
		return
	_missing_notice = false
	_notice_retries = 0
	if host.get_node_or_null("PuzzleUnavailableDialog") != null:
		return
	var overlay := ColorRect.new()
	overlay.name = "PuzzleUnavailableDialog"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.08, 0.04, 0.02, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 130
	host.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(980, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 0.965, 0.86, 1)
	card_style.border_color = Color(0.62, 0.4, 0.16, 0.46)
	card_style.set_border_width_all(4)
	card_style.border_width_bottom = 9
	card_style.set_corner_radius_all(48)
	card_style.shadow_color = Color(0.14, 0.08, 0.03, 0.34)
	card_style.shadow_size = 24
	card_style.shadow_offset = Vector2(0, 17)
	card_style.content_margin_left = 48
	card_style.content_margin_right = 48
	card_style.content_margin_top = 40
	card_style.content_margin_bottom = 36
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 22)
	card.add_child(inner)
	inner.add_child(_notice_label(_notice_text("title"), 46, Color(0.24, 0.14, 0.08, 1)))
	inner.add_child(_notice_label(_notice_text("body"), 34, Color(0.28, 0.17, 0.1, 1)))
	var button := _notice_button(_notice_text("ok"))
	button.pressed.connect(_dismiss_missing_notice)
	inner.add_child(button)


func _notice_host() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var scene := tree.current_scene
	if scene == null or not scene.is_inside_tree():
		return null
	return scene


func _dismiss_missing_notice() -> void:
	SoundManager.play("ButtonClick")
	var host := _notice_host()
	if host == null:
		return
	var overlay := host.get_node_or_null("PuzzleUnavailableDialog")
	if overlay != null:
		overlay.queue_free()


func _notice_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _notice_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 120)
	button.add_theme_font_override("font", FONT_UI)
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.65, 0.46, 1)
	style.border_color = Color(0.1, 0.42, 0.3, 1)
	style.set_border_width_all(3)
	style.border_width_bottom = 8
	style.set_corner_radius_all(30)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	return button


func _notice_text(key: String) -> String:
	var lookup := "PuzzleUnavailable" + key.capitalize()
	var translated := tr(lookup)
	if translated != lookup and not translated.is_empty():
		return translated
	var lang := TranslationServer.get_locale().substr(0, 2).to_lower()
	var table: Dictionary = _NOTICE.get(lang, _NOTICE["en"])
	return str(table.get(key, _NOTICE["en"][key]))


func _launch(puzzle_id: int) -> bool:
	_launching = false
	if not is_inside_tree():
		return false
	if not _puzzle_exists(puzzle_id) or _already_playing(puzzle_id):
		if not _puzzle_exists(puzzle_id):
			_reject_unavailable(puzzle_id)
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
		_reject_unavailable(puzzle_id)
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


const _NOTICE := {
	"es": {
		"title": "Puzle no disponible",
		"body": "El puzle de este enlace no está en el juego.",
		"ok": "Entendido",
	},
	"en": {
		"title": "Puzzle unavailable",
		"body": "The puzzle in this link is not in the game.",
		"ok": "Got it",
	},
	"de": {
		"title": "Rätsel nicht verfügbar",
		"body": "Das Rätsel aus diesem Link ist nicht im Spiel.",
		"ok": "Verstanden",
	},
	"fr": {
		"title": "Puzzle indisponible",
		"body": "Le puzzle de ce lien n'est pas dans le jeu.",
		"ok": "Compris",
	},
	"eu": {
		"title": "Puzzlea ez dago eskuragarri",
		"body": "Esteka honetako puzzlea ez dago jokoan.",
		"ok": "Ulertuta",
	},
	"it": {
		"title": "Puzzle non disponibile",
		"body": "Il puzzle di questo link non è nel gioco.",
		"ok": "Capito",
	},
	"pt": {
		"title": "Puzzle indisponível",
		"body": "O puzzle deste link não está no jogo.",
		"ok": "Entendido",
	},
}
