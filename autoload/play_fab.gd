# PlayFabTools.gd — Godot 4.4.x
extends Node

signal login_succeeded(playfab_id: String, newly_created: bool)
signal login_failed(error_message: String, http_code: int)

@export var COUNT_PER_TABLE: int = 30
@export var SLEEP_BETWEEN_CALLS_SEC: float = 0.15  # evita throttling

var _seed_run_nonce: String = ""  # identificador único de esta ejecución

const LEADERBOARD_NAME: String = "Score"  # nombre de la estadística
const TRACE_CHUNK_CHARS := 8500

## Ajusta tu TitleId aquí o desde fuera (set_title_id)
@export var TITLE_ID: String = "1BC2FD"

## Resultado de login reutilizable durante la sesión
@export var session_ticket: String = ""
@export var playfab_id: String = _get_device_custom_id()

var newly_created: bool = false

@onready var http: HTTPRequest = HTTPRequest.new()

func _ready() -> void:
	add_child(http)
	http.timeout = 30
	#login_with_custom_id(playfab_id,true)
	print("playfabid: " , playfab_id)
	var ok: bool = await PlayFabTools.login_with_custom_id(playfab_id, true)
	if ok:
		print("Listo. Ticket:", PlayFabTools.session_ticket, "ID:", PlayFabTools.playfab_id)
		if typeof(GameManager) != TYPE_NIL:
			GameManager.ensure_online_identity()
			await _update_player_display_name(GameManager.player_name)
			sync_player_language(GameManager.locale_code())
	else:
		print("No se pudo iniciar sesión en PlayFab.")
	


	#randomize()
	#await seed_all()
	#print("✅ Seeding terminado.")
	
	
	
## (Opcional) Cambiar TitleId en runtime
func set_title_id(id: String) -> void:
	TITLE_ID = id

## Login con CustomId (p_create=true para crear cuenta si no existe)
## Devuelve true si el login fue correcto y rellena session_ticket / playfab_id
func login_with_custom_id(custom_id: String, p_create: bool = true) -> bool:
	if TITLE_ID.strip_edges() == "":
		push_error("PlayFab TITLE_ID vacío. Configúralo antes de hacer login.")
		return false

	var url: String = "https://%s.playfabapi.com/Client/LoginWithCustomID" % TITLE_ID
	var body: Dictionary = {
		"TitleId": TITLE_ID,
		"CustomId": custom_id,
		"CreateAccount": p_create
	}
	# X-ReportErrorAsSuccess hace que PlayFab responda 200 y ponga 'code' en el JSON
	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Accept-Encoding: identity",
		"X-ReportErrorAsSuccess: true"
	])

	var err: int = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		var msg := "HTTPRequest error al loguear: %s" % err
		push_warning(msg)
		print("❌ ", msg)
		emit_signal("login_failed", msg, -1)
		return false

	# ✅ Forma correcta: recoger el array de la señal y tipar cada elemento
	var r: Array = await http.request_completed
	var result: int = r[0]
	var response_code: int = r[1]
	var resp_headers: PackedStringArray = r[2]
	var body_bytes: PackedByteArray = r[3]

	var text: String = body_bytes.get_string_from_utf8()

	# Parseo JSON tipado
	var parsed: Variant = JSON.parse_string(text)
	if !(parsed is Dictionary):
		var msg2 := "Respuesta JSON inválida en login."
		push_warning(msg2)
		print("❌ ", msg2)
		emit_signal("login_failed", msg2, response_code)
		return false

	var json: Dictionary = parsed
	# Si usamos X-ReportErrorAsSuccess, PlayFab mete su código en json['code'].
	var pf_code: int = int(json.get("code", response_code))
	if pf_code != 200:
		var err_msg := str(json.get("errorMessage", "Error desconocido"))
		push_warning("PlayFab LoginWithCustomID falló: %s" % err_msg)
		print("❌ PlayFab login FAILED: %s (http=%d pf_code=%d)" % [err_msg, response_code, pf_code])
		emit_signal("login_failed", err_msg, response_code)
		return false

	var data_any: Variant = json.get("data", {})
	var data: Dictionary = (data_any as Dictionary) if (data_any is Dictionary) else {}
	if !data.has("SessionTicket"):
		var msg3 := "Login sin SessionTicket en respuesta."
		push_warning(msg3)
		print("❌ ", msg3)
		emit_signal("login_failed", msg3, response_code)
		return false

	# Guardar credenciales de sesión
	session_ticket = str(data["SessionTicket"])
	playfab_id = str(data.get("PlayFabId", ""))
	newly_created = bool(data.get("NewlyCreated", false))

	# --- Debug/Estado en consola ---
	print("✅ PlayFab login OK — PlayFabId=%s | NewlyCreated=%s" % [playfab_id, str(newly_created)])

	emit_signal("login_succeeded", playfab_id, newly_created)
	return true

## Utilidad: ¿estamos autenticados?
func is_logged_in() -> bool:
	return session_ticket != ""


func sync_player_display_name(player_name: String = "") -> void:
	var name := player_name.strip_edges()
	if name == "" and typeof(GameManager) != TYPE_NIL:
		name = str(GameManager.player_name).strip_edges()
	if name == "":
		return
	_update_player_display_name(name)


const LANGUAGE_STAT_NAME := "PlayerLanguage"
const LANGUAGE_DATA_KEY := "Language"


func language_code_from_locale(code: String = "") -> String:
	var raw := code.strip_edges().to_lower().replace("-", "_")
	if raw.is_empty() and typeof(GameManager) != TYPE_NIL:
		raw = GameManager.locale_code()
	var base := String(raw.split("_")[0])
	match base:
		"es", "en", "eu", "de", "pt", "it", "fr":
			return base
		_:
			return ""


func language_stat_value(code: String = "") -> int:
	match language_code_from_locale(code):
		"es":
			return 1
		"en":
			return 2
		"eu":
			return 3
		"de":
			return 4
		"pt":
			return 5
		"it":
			return 6
		"fr":
			return 7
		_:
			return 0


func language_from_stat_value(value: int) -> String:
	match value:
		1:
			return "es"
		2:
			return "en"
		3:
			return "eu"
		4:
			return "de"
		5:
			return "pt"
		6:
			return "it"
		7:
			return "fr"
		_:
			return ""


func sync_player_language(code: String = "") -> void:
	if not is_logged_in():
		return
	var lang := language_code_from_locale(code)
	if lang == "":
		return
	await _update_public_user_data({LANGUAGE_DATA_KEY: lang})


func fetch_player_languages(playfab_ids: Array) -> Dictionary:
	var languages := {}
	var unique: Array[String] = []
	for id_value in playfab_ids:
		var id := str(id_value).strip_edges()
		if id == "" or unique.has(id):
			continue
		unique.append(id)
	for id in unique:
		languages[id] = await _fetch_one_player_language(id)
	return languages


func _fetch_one_player_language(target_id: String) -> String:
	var json := await _client_post_json("GetPlayerCombinedInfo", {
		"PlayFabId": target_id,
		"InfoRequestParameters": {
			"GetUserData": true,
			"UserDataKeys": [LANGUAGE_DATA_KEY],
			"GetPlayerStatistics": true,
			"PlayerStatisticNames": [LANGUAGE_STAT_NAME],
		},
	})
	if json.is_empty():
		return ""
	var data: Variant = json.get("data", {})
	if not (data is Dictionary):
		return ""
	var payload: Variant = data.get("InfoResultPayload", {})
	if not (payload is Dictionary):
		return ""
	var from_data := language_from_user_data_payload(payload)
	if from_data != "":
		return from_data
	var stats_value: Variant = payload.get("PlayerStatistics", [])
	if stats_value is Array:
		for stat_value in stats_value:
			if not (stat_value is Dictionary):
				continue
			var stat: Dictionary = stat_value
			if str(stat.get("StatisticName", "")) != LANGUAGE_STAT_NAME:
				continue
			return language_from_stat_value(int(stat.get("Value", 0)))
	return ""


func language_from_user_data_payload(payload: Dictionary) -> String:
	var user_data: Variant = payload.get("UserData", {})
	if not (user_data is Dictionary) or not user_data.has(LANGUAGE_DATA_KEY):
		return ""
	var entry: Variant = user_data[LANGUAGE_DATA_KEY]
	if entry is Dictionary:
		return language_code_from_locale(str(entry.get("Value", "")))
	return language_code_from_locale(str(entry))

## Imprime el estado actual del login en consola (con el ID si existe)
func print_login_status() -> void:
	if is_logged_in():
		print("🔐 Logeado en PlayFab como PlayFabId=%s" % playfab_id)
	else:
		print("🔓 No estás logeado en PlayFab.")

## (Opcional) limpiar sesión (memoria)
func logout() -> void:
	session_ticket = ""
	playfab_id = ""
	newly_created = false
	print("🔄 Sesión PlayFab limpiada.")


func _get_device_custom_id() -> String:
	var platform: String = OS.get_name()  # "Android", "iOS", "Windows", "Linux", "macOS", "Web", etc.

	# --- iOS / Android: usar el identificador único del SO si es válido ---
	if platform == "Android" or platform == "iOS":
		var dev_id: String = OS.get_unique_id()
		# Filtramos valores inútiles que algunas plataformas/devices devuelven
		var invalid: bool = (dev_id == "" or dev_id.to_lower() == "unknown" or dev_id.to_lower() == "android_id")
		if not invalid:
			var prefix: String = ("AND_" if platform == "Android" else "IOS_")
			return prefix + dev_id
		# Si no hay ID válido, caemos a persistido por instalación

	# --- PC (Windows/Linux/macOS) o fallback: ID persistido por instalación ---
	return _load_or_create_persisted_custom_id(platform)


# Guarda en user:// un CustomId estable por instalación (sirve para PC y fallback móvil).
func _load_or_create_persisted_custom_id(platform: String) -> String:
	const CFG_PATH := "user://playfab_auth.cfg"
	const CFG_SECTION := "auth"
	const CFG_KEY := "custom_id"

	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		var saved_any: Variant = cfg.get_value(CFG_SECTION, CFG_KEY, "")
		var saved: String = str(saved_any)
		if saved != "":
			return saved

	# Generar uno nuevo (aleatorio + timestamp + plataforma) y guardarlo
	var seed: String = "%s|%s|%s|%s" % [platform, Time.get_unix_time_from_system(), randi(), OS.get_unique_id()]
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(seed.to_utf8_buffer())
	var custom_id: String = "CL_" + hc.finish().hex_encode().substr(0, 32)  # 32 hex

	cfg.set_value(CFG_SECTION, CFG_KEY, custom_id)
	cfg.save(CFG_PATH)
	print("CUSTOM ID Creado: " , custom_id)
	return custom_id


# -------------------------------------------------------------------
# Envía la puntuación del jugador a la estadística "Score".
# Devuelve true si PlayFab respondió OK, false si hubo error.
# -------------------------------------------------------------------
# Envía puntuación y (opcional) fija el nombre del jugador para que
# aparezca en el leaderboard como DisplayName.
# Requiere estar logeado con PlayFabTools (autoload).
func submit_player_score(score: int, player_name: String = "", stat_name: String = "Score") -> bool:
	# 1) Comprobar sesión
	if typeof(PlayFabTools) == TYPE_NIL or not PlayFabTools.is_logged_in():
		push_warning("No hay sesión PlayFab. Inicia sesión antes de enviar puntuación/nombre.")
		return false

	# 2) Si viene nombre, intentar guardarlo como DisplayName (no falla la puntuación si esto falla)
	if player_name.strip_edges() != "":
		var ok_name := await _update_player_display_name(player_name)
		if not ok_name:
			push_warning("No se pudo actualizar el DisplayName. Continuo con el envío de puntuación…")

	# 3) Enviar puntuación a la estadística (Score por defecto)
	var url_stats: String = "https://%s.playfabapi.com/Client/UpdatePlayerStatistics" % PlayFabTools.TITLE_ID
	var body_stats: Dictionary = {
		"Statistics": [
			{
				"StatisticName": stat_name,  # "Score"
				"Value": score
			}
		]
	}
	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Accept-Encoding: identity",
		"X-Authorization: " + PlayFabTools.session_ticket,
		"X-ReportErrorAsSuccess: true"
	])

	var req := HTTPRequest.new()
	add_child(req)
	req.timeout = 30
	var err := req.request(url_stats, headers, HTTPClient.METHOD_POST, JSON.stringify(body_stats))
	if err != OK:
		push_warning("HTTPRequest error al enviar puntuación: %s" % err)
		req.queue_free()
		return false

	var r: Array = await req.request_completed
	var http_code: int = r[1]
	var body_bytes: PackedByteArray = r[3]
	var text: String = body_bytes.get_string_from_utf8()
	req.queue_free()

	var parsed: Variant = JSON.parse_string(text)
	if !(parsed is Dictionary):
		push_warning("Respuesta no válida de PlayFab al enviar puntuación.")
		return false

	var json: Dictionary = parsed
	var pf_code: int = int(json.get("code", http_code))
	if pf_code != 200:
		var err_msg := str(json.get("errorMessage", "Error desconocido"))
		push_warning("UpdatePlayerStatistics falló: %s" % err_msg)
		return false

	return true


## Packed ranking for PlayFab int32:
## stars * 1_000_000 + (99 - puzzles) * 10_000 + (99 - aids) * 100 + (99 - failed)
const COMPETITIVE_STAR_PLACE := 1_000_000
const COMPETITIVE_PUZZLE_PLACE := 10_000
const COMPETITIVE_AID_PLACE := 100
const COMPETITIVE_COUNT_MAX := 99
const COMPETITIVE_STAR_MAX := 2047


func competitive_stat_name(category_filter: String, mode_filter: String) -> String:
	var category := category_filter.strip_edges().to_lower()
	if category in ["", "global", "all", "todas"]:
		category = "Global"
	else:
		category = GameManager.normalize_category(category).capitalize()
	var mode := mode_filter.strip_edges().to_lower()
	match mode:
		GameManager.MODE_QUICK:
			mode = "Quick"
		GameManager.MODE_CRYPTOGRAM:
			mode = "Cryptogram"
		_:
			mode = "All"
	return "CompetitiveV2_%s_%s" % [category, mode]


func encode_competitive_record(record: Dictionary) -> int:
	var stars := clampi(int(record.get("stars_earned", 0)), 0, COMPETITIVE_STAR_MAX)
	var puzzles := clampi(int(record.get("completed", 0)), 0, COMPETITIVE_COUNT_MAX)
	var aids := clampi(int(record.get("aids_used", 0)), 0, COMPETITIVE_COUNT_MAX)
	var failed := clampi(int(record.get("failed_letters", 0)), 0, COMPETITIVE_COUNT_MAX)
	return (
		stars * COMPETITIVE_STAR_PLACE
		+ (COMPETITIVE_COUNT_MAX - puzzles) * COMPETITIVE_PUZZLE_PLACE
		+ (COMPETITIVE_COUNT_MAX - aids) * COMPETITIVE_AID_PLACE
		+ (COMPETITIVE_COUNT_MAX - failed)
	)


func decode_competitive_value(value: int) -> Dictionary:
	var remaining := maxi(value, 0)
	var failed := COMPETITIVE_COUNT_MAX - (remaining % COMPETITIVE_AID_PLACE)
	remaining = int(remaining / COMPETITIVE_AID_PLACE)
	var aids := COMPETITIVE_COUNT_MAX - (remaining % COMPETITIVE_AID_PLACE)
	remaining = int(remaining / COMPETITIVE_AID_PLACE)
	var puzzles := COMPETITIVE_COUNT_MAX - (remaining % COMPETITIVE_AID_PLACE)
	var stars := int(remaining / COMPETITIVE_AID_PLACE)
	var hundredths := 0
	if puzzles > 0:
		hundredths = int(round(float(stars) * 100.0 / float(puzzles)))
	return {
		"stars_earned": stars,
		"stars_per_puzzle_hundredths": hundredths,
		"completed": puzzles,
		"aids_used": aids,
		"failed_letters": failed,
	}


func submit_competitive_rankings(player_name: String = "") -> bool:
	if not is_logged_in():
		for _attempt in range(50):
			await get_tree().create_timer(0.1).timeout
			if is_logged_in():
				break
		if not is_logged_in():
			push_warning("No se pudo enviar la clasificación: PlayFab no inició sesión.")
			return false
	if player_name.strip_edges() != "":
		await _update_player_display_name(player_name)
	var language := language_code_from_locale()
	await sync_player_language(language)

	var categories := [
		"global",
		GameManager.CAT_CITA,
		GameManager.CAT_EFEMERIDE,
		GameManager.CAT_CURIOSIDADES,
		GameManager.CAT_FRAGMENTO,
	]
	var modes := ["all", GameManager.MODE_QUICK, GameManager.MODE_CRYPTOGRAM]
	var statistics: Array[Dictionary] = []
	for category in categories:
		for mode in modes:
			var record: Dictionary = HistoryManager.get_competitive_record(category, mode)
			statistics.append({
				"StatisticName": competitive_stat_name(category, mode),
				"Value": encode_competitive_record(record),
			})
	var language_value := language_stat_value(language)
	if language_value > 0:
		statistics.append({
			"StatisticName": LANGUAGE_STAT_NAME,
			"Value": language_value,
		})

	var request := HTTPRequest.new()
	add_child(request)
	request.timeout = 30
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Accept-Encoding: identity",
		"X-Authorization: " + session_ticket,
		"X-ReportErrorAsSuccess: true",
	])
	var url := "https://%s.playfabapi.com/Client/UpdatePlayerStatistics" % TITLE_ID
	var error := request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify({"Statistics": statistics})
	)
	if error != OK:
		request.queue_free()
		return false
	var response: Array = await request.request_completed
	var http_code := int(response[1])
	var response_text := (response[3] as PackedByteArray).get_string_from_utf8()
	request.queue_free()
	var parsed: Variant = JSON.parse_string(response_text)
	if not (parsed is Dictionary):
		return false
	return int((parsed as Dictionary).get("code", http_code)) == 200


# ----- Helper: fija el DisplayName del jugador en este título -----
func _update_player_display_name(player_name: String) -> bool:
	if typeof(PlayFabTools) == TYPE_NIL or not PlayFabTools.is_logged_in():
		return false

	# PlayFab suele limitar a 3..25 caracteres (evita nombres vacíos o muy largos)
	var name := player_name.strip_edges()
	if name == "":
		return false
	if name.length() > 25:
		name = name.substr(0, 25)

	var url_name: String = "https://%s.playfabapi.com/Client/UpdateUserTitleDisplayName" % PlayFabTools.TITLE_ID
	var body_name: Dictionary = { "DisplayName": name }
	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Accept-Encoding: identity",
		"X-Authorization: " + PlayFabTools.session_ticket,
		"X-ReportErrorAsSuccess: true"
	])

	var req := HTTPRequest.new()
	add_child(req)
	req.timeout = 30
	var err := req.request(url_name, headers, HTTPClient.METHOD_POST, JSON.stringify(body_name))
	if err != OK:
		req.queue_free()
		return false

	var r: Array = await req.request_completed
	var http_code: int = r[1]
	var body_bytes: PackedByteArray = r[3]
	var text: String = body_bytes.get_string_from_utf8()
	req.queue_free()

	var parsed: Variant = JSON.parse_string(text)
	if !(parsed is Dictionary):
		return false

	var json: Dictionary = parsed
	var pf_code: int = int(json.get("code", http_code))
	return pf_code == 200


func _update_public_user_data(data: Dictionary) -> bool:
	var json := await _client_post_json("UpdateUserData", {
		"Data": data,
		"Permission": "Public",
	})
	return not json.is_empty()


func _client_post(endpoint: String, body: Dictionary) -> bool:
	var json := await _client_post_json(endpoint, body)
	return not json.is_empty()


func _client_post_json(endpoint: String, body: Dictionary) -> Dictionary:
	if not is_logged_in():
		return {}
	var request := HTTPRequest.new()
	add_child(request)
	request.timeout = 20
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Accept-Encoding: identity",
		"X-Authorization: " + session_ticket,
		"X-ReportErrorAsSuccess: true",
	])
	var url := "https://%s.playfabapi.com/Client/%s" % [TITLE_ID, endpoint]
	if request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body)) != OK:
		request.queue_free()
		return {}
	var response: Array = await request.request_completed
	var http_code := int(response[1])
	var text := (response[3] as PackedByteArray).get_string_from_utf8()
	request.queue_free()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}
	var json: Dictionary = parsed
	if int(json.get("code", http_code)) != 200:
		push_warning(
			"PlayFab %s falló: %s" % [
				endpoint,
				str(json.get("errorMessage", json.get("error", http_code))),
			]
		)
		return {}
	return json

func send_match_event(duration_sec: int, vowelsAE: int, vowelsIOU:int, letras: int, pistas1: int, pistas2: int, dificultad: int, categoria: String) -> bool:
	if typeof(PlayFabTools) == TYPE_NIL or not PlayFabTools.is_logged_in():
		return false

	var url := "https://%s.playfabapi.com/Client/WritePlayerEvent" % PlayFabTools.TITLE_ID
	var body := {
		"EventName": "match_finished",
		"Body": {
			"duration_sec": duration_sec,
			"vowelsAE_bought": vowelsAE,
			"vowelsIOU_bought": vowelsIOU,
			"lettersAE_bought": letras,
			"hints1_used": pistas1,
			"hints2_used": pistas2,
			"difficulty": dificultad,
			"category": categoria
		}
	}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"X-Authorization: " + PlayFabTools.session_ticket, # SessionTicket del login
		"X-ReportErrorAsSuccess: true"
	])

	var req := HTTPRequest.new(); add_child(req); req.timeout = 30
	var err := req.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK: req.queue_free(); return false
	var r: Array = await req.request_completed
	req.queue_free()

	var http_code: int = r[1]
	var parsed: Variant = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	return (parsed is Dictionary) and (int((parsed as Dictionary).get("code", http_code)) == 200)


func send_puzzle_trace(payload: Dictionary) -> bool:
	if typeof(PlayFabTools) == TYPE_NIL or not PlayFabTools.is_logged_in():
		push_warning("No hay sesión PlayFab para enviar la traza del puzle.")
		return false
	var events: Array = payload.get("events", [])
	var header := payload.duplicate(true)
	header.erase("events")
	header["event_count"] = events.size()
	var chunks := _chunk_trace_events(events)
	header["chunk_count"] = chunks.size()
	var ok := await _write_player_event("puzzle_solve_trace", header)
	if ok:
		await _client_post_json("UpdateUserData", {
			"Data": {"LastPuzzleTrace": JSON.stringify(header)},
			"Permission": "Private",
		})
	if not ok:
		return false
	for i in chunks.size():
		var sent := await _write_player_event("puzzle_solve_trace_chunk", {
			"session_id": str(payload.get("session_id", "")),
			"puzzle_id": int(payload.get("puzzle_id", -1)),
			"chunk_index": i,
			"chunk_count": chunks.size(),
			"events": chunks[i],
		})
		if not sent:
			ok = false
	return ok


func _chunk_trace_events(events: Array) -> Array:
	var chunks: Array = []
	var current: Array = []
	for ev in events:
		current.append(ev)
		if JSON.stringify(current).length() >= TRACE_CHUNK_CHARS:
			current.pop_back()
			if current.is_empty():
				chunks.append([ev])
				current = []
			else:
				chunks.append(current)
				current = [ev]
	if not current.is_empty() or chunks.is_empty():
		chunks.append(current)
	return chunks


func _write_player_event(event_name: String, body: Dictionary) -> bool:
	if not is_logged_in():
		return false
	var json := await _client_post_json("WritePlayerEvent", {
		"EventName": event_name,
		"Body": body,
	})
	return not json.is_empty()

# Devuelve la posición (1-based) del jugador en "Score_Facil".
# Requiere estar logeado (PlayFabLogin.is_logged_in()).
# Retorna -1 si falla o si no hay entrada.

func get_player_rank_in_current_difficulty() -> int:
	# 0) Comprobar sesión
	if typeof(PlayFabTools) == TYPE_NIL or not PlayFabTools.is_logged_in():
		push_warning("No hay sesión PlayFab.")
		return -1

	# 1) Leer dificultad actual del GameManager (acepta 'dificultad_actual' o 'dificultad_acutal')
	var diff_code: int = 0
	if typeof(GameManager) != TYPE_NIL:
		var v :int= GameManager.get("dificultad_actual")
		if v == null:
			v = GameManager.get("dificultad_acutal") # por si está con typo
		if v != null:
			diff_code = int(v)

	# 2) Mapear a nombre de estadística
	const STAT_BY_DIFF := {1: "Score_Facil", 2: "Score_Normal", 3: "Score_Dificil"}
	var stat_name: String = STAT_BY_DIFF.get(diff_code, "Score_Facil")

	# 3) Petición a PlayFab
	var url := "https://%s.playfabapi.com/Client/GetLeaderboardAroundPlayer" % PlayFabTools.TITLE_ID
	var body := {
		"StatisticName": stat_name,
		"MaxResultsCount": 1
	}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Accept-Encoding: identity",
		"X-Authorization: " + PlayFabTools.session_ticket,
		"X-ReportErrorAsSuccess: true"
	])

	var req := HTTPRequest.new(); add_child(req); req.timeout = 30
	var err := req.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		req.queue_free()
		return -1

	var r: Array = await req.request_completed
	var http_code: int = r[1]
	var text := (r[3] as PackedByteArray).get_string_from_utf8()
	req.queue_free()

	var parsed: Variant = JSON.parse_string(text)
	if !(parsed is Dictionary):
		return -1
	var json: Dictionary = parsed
	if int(json.get("code", http_code)) != 200:
		return -1

	var data := (json.get("data", {}) as Dictionary)
	var lb  := (data.get("Leaderboard", []) as Array)
	if lb.is_empty() or !(lb[0] is Dictionary):
		return -1

	var entry := lb[0] as Dictionary
	var zero_based_pos: int = int(entry.get("Position", -1))
	return zero_based_pos + 1 if zero_based_pos >= 0 else -1

# PlayFabSeeder.gd — Godot 4.4
# Crea 90 cuentas de test (CustomID), fija DisplayName y escribe stats en:
#   Score_Facil, Score_Normal, Score_Dificil (30 jugadores cada una).





# -------------------- ENTRY POINT --------------------

# -------------------- CORE --------------------

# -------------------- HELPERS PLAYFAB --------------------
func _login_with_custom_id(custom_id: String, create: bool) -> Dictionary:
	var url := "https://%s.playfabapi.com/Client/LoginWithCustomID" % TITLE_ID
	var body := {
		"TitleId": TITLE_ID,
		"CustomId": custom_id,
		"CreateAccount": create
	}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Accept-Encoding: identity",
		"X-ReportErrorAsSuccess: true"
	])
	var text := await _post(url, headers, body)
	var parsed: Variant = JSON.parse_string(text)
	var json: Dictionary = (parsed as Dictionary) if (parsed is Dictionary) else {}
	if int(json.get("code", 400)) != 200:
		return {"success": false}
	var data := (json.get("data", {}) as Dictionary)
	return {
		"success": data.has("SessionTicket"),
		"session_ticket": str(data.get("SessionTicket", "")),
		"playfab_id": str(data.get("PlayFabId", "")),
		"newly_created": bool(data.get("NewlyCreated", false))
	}

func _parse_retry_after(headers: PackedStringArray) -> float:
	for h in headers:
		var hl := h.to_lower()
		if hl.begins_with("retry-after:"):
			var parts := h.split(":", false, 2)
			if parts.size() >= 2:
				var s := parts[1].strip_edges()
				if s.is_valid_float():
					return float(s)
	return -1.0

func _update_display_name(session_ticket: String, display_name: String) -> Dictionary:
	var name := display_name.strip_edges()
	if name.length() > 25:
		name = name.substr(0, 25)

	var url := "https://%s.playfabapi.com/Client/UpdateUserTitleDisplayName" % TITLE_ID
	var body := { "DisplayName": name }
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Accept-Encoding: identity",
		"X-Authorization: " + session_ticket,
		"X-ReportErrorAsSuccess: true"
	])

	var req := HTTPRequest.new(); add_child(req); req.timeout = 30
	var err := req.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		req.queue_free()
		return {"ok": false, "http": 0, "pf": -1, "msg": "HTTPRequest error: %s" % err}

	var r: Array = await req.request_completed
	var http_code: int = r[1]
	var resp_headers: PackedStringArray = r[2]
	var text := (r[3] as PackedByteArray).get_string_from_utf8()
	req.queue_free()

	var retry_after := _parse_retry_after(resp_headers)

	var parsed: Variant = JSON.parse_string(text)
	if !(parsed is Dictionary):
		print("⚠ display name: JSON inválido. http=", http_code)
		return {"ok": false, "http": http_code, "pf": -1, "msg": "invalid json", "retry_after": retry_after}

	var json: Dictionary = parsed
	var pf_code: int = int(json.get("code", http_code))
	if pf_code != 200:
		var msg := str(json.get("errorMessage", ""))
		var err_name := str(json.get("error", ""))
		print("✖ display name FAIL → http=", http_code, " pf=", pf_code, " err=", err_name, " msg=", msg, " retry_after=", retry_after)
		return {
			"ok": false, "http": http_code, "pf": pf_code, "msg": msg,
			"error": err_name, "retry_after": retry_after, "json": json
		}

	print("✓ display name OK → ", name)
	return {"ok": true, "http": http_code, "pf": pf_code, "display_name": name}


func _update_stat(session_ticket: String, stat_name: String, value: int) -> bool:
	var url := "https://%s.playfabapi.com/Client/UpdatePlayerStatistics" % TITLE_ID
	var body := {
		"Statistics": [
			{"StatisticName": stat_name, "Value": value}
		]
	}
	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"X-Authorization: " + session_ticket,
		"X-ReportErrorAsSuccess: true"
	])

	var text := await _post(url, headers, body)
	var parsed: Variant = JSON.parse_string(text)
	var json: Dictionary = (parsed as Dictionary) if (parsed is Dictionary) else {}
	return int(json.get("code", 400)) == 200

# -------------------- NET WRAPPER --------------------
func _post(url: String, headers: PackedStringArray, body: Dictionary) -> String:
	var req := HTTPRequest.new()
	add_child(req)
	req.timeout = 30
	var err := req.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		req.queue_free()
		return "{}"
	var r: Array = await req.request_completed
	var text := (r[3] as PackedByteArray).get_string_from_utf8()
	req.queue_free()
	return text

# -------------------- UTILS --------------------
#func _make_custom_id(tag: String) -> String:
	## CustomId estable y único (no importa que sea legible)
	#var stamp := Time.get_unix_time_from_system()
	#return "SEED_%s_%d_%d" % [tag, stamp, randi()]

#func _make_display_name(tag: String, idx: int) -> String:
	#var pool: PackedStringArray = PackedStringArray([
		#"Alex","Blair","Casey","Drew","Elliot","Fran","Gale","Harper","Indigo","Jules",
		#"Kai","Logan","Morgan","Noa","Owen","Parker","Quinn","Riley","Sage","Taylor",
		#"Uma","Vega","Winter","Xen","Yael","Zane","Ari","Benn","Cris"
	#])
	#var base: String = pool[(idx - 1) % pool.size()]
	#return "%s_%s_%02d" % [tag, base, idx]
	#

func _sleep(sec: float) -> Signal:
	return get_tree().create_timer(max(sec, 0.01)).timeout



func seed_all() -> void:
	# Nonce único por ejecución (para IDs únicos)
	_seed_run_nonce = _make_nonce()

	# Ritmo y reintentos (para evitar throttling)
	var MAX_RETRIES: int = 4
	var BASE_BACKOFF: float = 1.0
	var PAUSE: float = max(SLEEP_BETWEEN_CALLS_SEC, 0.35)

	# Tablas a sembrar + rangos pedidos
	var SPECS: Array = [
		{"name":"Score_Facil",   "min":0,           "max":199_999_999, "tag":"FACIL"},
		{"name":"Score_Normal",  "min":200_000_000, "max":299_999_999, "tag":"NORMAL"},
		{"name":"Score_Dificil", "min":300_000_000, "max":399_999_999, "tag":"DIFICIL"}
	]

	var seeded_by_table := {
		"Score_Facil": 0,
		"Score_Normal": 0,
		"Score_Dificil": 0
	}

	print("== SEED RUN START :: nonce=", _seed_run_nonce, " :: count_per_table=", COUNT_PER_TABLE, " ==")
	for i in COUNT_PER_TABLE:
		for spec in SPECS:
			var stat_name: String = spec["name"]
			var min_val: int      = spec["min"]
			var max_val: int      = spec["max"]
			var tag: String       = spec["tag"]

			var custom_id := _make_custom_id(tag, i + 1)  # usa firma (tag, idx)
			var display   := _make_display_name(tag, i + 1)
			var score     := randi_range(min_val, max_val)

			print("\n>>> [", i + 1, "/", COUNT_PER_TABLE, "] [", stat_name, "]")
			print("    custom_id=", custom_id, "  display=", display, "  score=", score)

			# -------------------- LOGIN (con backoff) --------------------
			var login := {}
			var ok_login := false
			var attempt := 0
			var backoff := BASE_BACKOFF
			while attempt <= MAX_RETRIES:
				login = await _login_with_custom_id(custom_id, true)
				if login.has("success") and login.success:
					ok_login = true
					print("    login OK  pfid=", login.playfab_id, "  newly_created=", login.newly_created)
					break
				print("    login FAIL (attempt ", attempt + 1, "/", MAX_RETRIES + 1, ") — retry in ", backoff, " s")
				await get_tree().create_timer(backoff).timeout
				backoff = min(backoff * 2.0, 8.0)
				attempt += 1
			if not ok_login:
				push_warning("    ABORT — no login: " + custom_id)
				await get_tree().create_timer(PAUSE).timeout
				continue

			# -------------------- DISPLAY NAME (con backoff) -------------
# -------------------- DISPLAY NAME (con diagnóstico y Retry-After) -------------
				attempt = 0
				backoff = BASE_BACKOFF
				var ok_name := false
				var current_name := display

				while attempt <= MAX_RETRIES:
					var dn: Dictionary = await _update_display_name(login.session_ticket, current_name)
					if dn.has("ok") and bool(dn.ok):
						ok_name = true
						print("    display name OK → ", current_name)
						break

					# Lee Retry-After si lo devolvió el servidor; si no, usa backoff local
					var wait_s := backoff
					if dn.has("retry_after"):
						var ra := float(dn.retry_after)
						if ra > 0.0:
							wait_s = ra

					# Si el nombre está ocupado (NameNotAvailable = 1058), genera variante y reintenta
					if dn.has("pf") and int(dn.pf) == 1058:
						var suffix := str(randi() % 10000)
						var base := current_name
						var room := 25 - (suffix.length() + 1)  # máximo 25 chars
						if room < 3:
							room = 3
						base = base.substr(0, room)
						current_name = base + "_" + suffix
						print("    name taken; retry with: ", current_name)
						# reintento rápido para colisión de nombre
						if wait_s > 0.5:
							wait_s = 0.5

					print("    display name FAIL (attempt ", attempt + 1, "/", MAX_RETRIES + 1, ") — wait=", wait_s, "s")
					await get_tree().create_timer(wait_s).timeout
					backoff = min(backoff * 2.0, 8.0)
					attempt += 1

				if not ok_name:
					push_warning("    (continúo) sin poder fijar DisplayName")


			# -------------------- UPDATE STAT (con backoff) --------------
			attempt = 0
			backoff = BASE_BACKOFF
			var ok_stat := false
			while attempt <= MAX_RETRIES:
				ok_stat = await _update_stat(login.session_ticket, stat_name, score)
				if ok_stat:
					print("    UPDATE STAT OK → ", stat_name, " = ", score)
					seeded_by_table[stat_name] = int(seeded_by_table[stat_name]) + 1
					break
				print("    UPDATE STAT FAIL (attempt ", attempt + 1, "/", MAX_RETRIES + 1, ") — retry in ", backoff, " s")
				await get_tree().create_timer(backoff).timeout
				backoff = min(backoff * 2.0, 8.0)
				attempt += 1

			if not ok_stat:
				push_warning("    ✖ no se pudo escribir stat para " + display + " en " + stat_name)

			# Pausa entre operaciones para no golpear el límite
			await get_tree().create_timer(PAUSE).timeout

		# Cede un frame por iteración para mantener UI responsiva
		await get_tree().process_frame

	print("\n== SEED RUN END ==")
	print("Resumen → Facil=", seeded_by_table["Score_Facil"],
		"  Normal=", seeded_by_table["Score_Normal"],
		"  Dificil=", seeded_by_table["Score_Dificil"])




func seed_leaderboard(stat_name: String, min_val: int, max_val: int, name_tag: String) -> void:
	print("== Sembrando ", stat_name, " ==")
	for i in COUNT_PER_TABLE:
		# 1) CustomId SIEMPRE ÚNICO
		var custom_id := _make_custom_id(name_tag, i + 1)
		var display   := _make_display_name(name_tag, i + 1)

		# 2) Login/Create con ese CustomId → si no existe, crea jugador nuevo
		var login := await _login_with_custom_id(custom_id, true)
		if not login.success:
			push_warning("Login failed para %s" % custom_id)
			await _sleep(SLEEP_BETWEEN_CALLS_SEC)
			continue

		# 3) Fijar nombre visible
		var ok_name := await _update_display_name(login.session_ticket, display)
		if not ok_name:
			push_warning("No pude poner DisplayName=%s" % display)

		# 4) Score aleatorio en el rango pedido
		var score := randi_range(min_val, max_val)

		# 5) Escribir estadística en la tabla (stat) correspondiente
		var ok_stat := await _update_stat(login.session_ticket, stat_name, score)
		if ok_stat:
			print("  → OK ", display, "  ", stat_name, " = ", score, "  (PFID=", login.playfab_id, ")")
		else:
			push_warning("Falló UpdatePlayerStatistics para %s" % display)

		await _sleep(SLEEP_BETWEEN_CALLS_SEC)

# ---------- Helpers de ID únicos ----------
func _make_nonce() -> String:
	var seed_text := "%s|%s|%s|%s" % [
		Time.get_unix_time_from_system(),
		OS.get_unique_id(),
		randi(),
		randi()
	]
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(seed_text.to_utf8_buffer())
	return hc.finish().hex_encode().substr(0, 10)  # 10 hex = 40 bits

func _make_custom_id(tag: String, idx: int) -> String:
	# Example: SEED_FACIL_ab12cd34ef_07_39281746
	return "SEED_%s_%s_%02d_%d" % [tag, _seed_run_nonce, idx, randi()]

func _make_display_name(tag: String, idx: int) -> String:
	var pool: PackedStringArray = PackedStringArray([
		"Alex","Blair","Casey","Drew","Elliot","Fran","Gale","Harper","Indigo","Jules",
		"Kai","Logan","Morgan","Noa","Owen","Parker","Quinn","Riley","Sage","Taylor",
		"Uma","Vega","Winter","Xen","Yael","Zane","Ari","Benn","Cris","Mika","Nico","Oli","Pau","Rae","Sam"
	])
	var base: String = pool[(idx - 1) % pool.size()]
	return "%s_%s_%02d" % [tag, base, idx]














# Ejecuta CloudScript submitPhraseFeedback
# Requiere sesión PlayFab ya abierta (session_ticket disponible).


func send_phrase_feedback(
		phrase_id: int,
		ratings: Dictionary,
		comment: String,
		give_coin_if_first: bool = true
	) -> Dictionary:
	# 0) Sesión PlayFab
	if typeof(PlayFabTools) == TYPE_NIL or not PlayFabTools.is_logged_in():
		return {"ok": false, "error": "no_session"}

	# 1) URL y cabeceras
	var url: String = "https://%s.playfabapi.com/Client/ExecuteCloudScript" % PlayFabTools.TITLE_ID
	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"X-Authorization: " + PlayFabTools.session_ticket,
		"X-ReportErrorAsSuccess: true"
	])

	# 2) Payload (añadimos give_coin_if_first)
	var payload: Dictionary = {
		"FunctionName": "submitPhraseFeedback",
		"FunctionParameter": {
			"phrase_id": phrase_id,
			"rating_global": int(ratings.get("global", 0)),
			"rating_difficulty": int(ratings.get("difficulty", 0)),
			"rating_duration": int(ratings.get("duration", 0)),
			"rating_hint1": int(ratings.get("hint1", 0)),
			"rating_hint2": int(ratings.get("hint2", 0)),
			"rating_hint3": int(ratings.get("hint3", 0)),
			"rating_interest": int(ratings.get("interest", 0)),
			"rating_init_letters": int(ratings.get("init_letters", 0)),
			"difficulty_issue": str(ratings.get("difficulty_issue", "")),
			"duration_issue": str(ratings.get("duration_issue", "")),
			"comment": comment,
			"client_ver": str(ProjectSettings.get_setting("application/config/version", "")),
			"locale": OS.get_locale(),
			"platform": OS.get_name(),
			"give_coin_if_first": give_coin_if_first
		},
		"GeneratePlayStreamEvent": true
	}

	# 3) Petición HTTP
	var req := HTTPRequest.new()
	add_child(req)
	req.timeout = 30
	var err: int = req.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		req.queue_free()
		return {"ok": false, "error": "http_request_failed"}

	var r: Array = await req.request_completed
	req.queue_free()

	# 4) Parseo seguro (tipado explícito)
	var http_code: int = int(r[1])
	var text: String = (r[3] as PackedByteArray).get_string_from_utf8()

	var parsed: Variant = JSON.parse_string(text)
	if !(parsed is Dictionary):
		return {"ok": false, "error": "bad_json", "http": http_code}

	var json: Dictionary = parsed as Dictionary
	if int(json.get("code", http_code)) != 200:
		return {"ok": false, "error": str(json.get("errorMessage", "cloud_err")), "http": http_code}

	var data_any: Variant = json.get("data", {})
	var data: Dictionary = (data_any as Dictionary) if (data_any is Dictionary) else {}

	var func_any: Variant = data.get("FunctionResult", {})
	var res: Dictionary = (func_any as Dictionary) if (func_any is Dictionary) else {}

	if res.is_empty():
		return {"ok": false, "error": "no_func_result", "http": http_code}

	# éxito
	res["ok"] = true
	return res
