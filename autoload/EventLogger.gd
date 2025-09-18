extends Node
class_name EventLogger

enum EventType {
	COMPRA_VOCAL_AE,
	COMPRA_VOCAL_IOU,
	COMPRA_CONSONANTE,
	COMPRA_PISTA_2,
	COMPRA_PISTA_3,
	BORRAR_LETRA,
	ASIGNAR_LETRA,
	PARTIDA_INICIADA,
	PARTIDA_FINALIZADA
}

var session_id: String = ""
var events: Array = []
var started: bool = false

# Opcional: límites de seguridad
@export var max_events: int = 5000

func _ready() -> void:
	# Conexiones a SignalManager
	SignalManager.compra_vocal_ae.connect(func(t:int): _log(EventType.COMPRA_VOCAL_AE, {"coste": _coins_diff()}, t))
	SignalManager.compra_vocal_iou.connect(func(t:int): _log(EventType.COMPRA_VOCAL_IOU, {"coste": _coins_diff()}, t))
	SignalManager.compra_consonante.connect(func(t:int): _log(EventType.COMPRA_CONSONANTE, {"coste": _coins_diff()}, t))
	SignalManager.compra_pista_2.connect(func(t:int): _log(EventType.COMPRA_PISTA_2, {"coste": _coins_diff()}, t))
	SignalManager.compra_pista_3.connect(func(t:int): _log(EventType.COMPRA_PISTA_3, {"coste": _coins_diff()}, t))
	SignalManager.borrar_letra.connect(
		func(t:int, celda:int, letra:String):
			_log(EventType.BORRAR_LETRA, {"celda": celda, "letra": letra}, t)
	)
	SignalManager.asignar_letra.connect(
		func(t:int, celda:int, letra:String):
			_log(EventType.ASIGNAR_LETRA, {"celda": celda, "letra": letra}, t)
	)
	SignalManager.partida_iniciada.connect(func(): start_session())
	SignalManager.partida_finalizada.connect(func(resultado:String): _log(EventType.PARTIDA_FINALIZADA, {"resultado": resultado}, _t_game()); end_session_and_export())

func start_session() -> void:
	events.clear()
	session_id = _make_session_id()
	started = true
	_log(EventType.PARTIDA_INICIADA, {}, _t_game())

func _log(t:EventType, meta:Dictionary, t_game_ms:int) -> void:
	if not started:
		start_session()
	var ev := {
		"id": events.size(),
		"type": t,
		"t_game_ms": t_game_ms,
		"t_wall_ms": Time.get_ticks_msec(),
		"meta": meta
	}
	events.append(ev)
	# Cap seguridad
	if events.size() > max_events:
		events.pop_front()

# ---- Exportar & PlayFab ----
func end_session_and_export() -> void:
	if not started: return
	started = false
	var payload := {
		"session_id": session_id,
		"phrase_ID": GameManager.id_frase,
		"player": GameManager.player_name if typeof(GameManager) != TYPE_NIL else "unknown",
		"category": GameManager.categoria_actual if typeof(GameManager) != TYPE_NIL else "",
		"difficulty": GameManager.dificultad_actual if typeof(GameManager) != TYPE_NIL else 0,
		"score": GameManager.score if typeof(GameManager) != TYPE_NIL else 0,
		"locale": TranslationServer.get_locale(),
		"events": events
	}

	# 1) Persistir local (backup / reintento)
	var path := "user://logs/%s.json" % session_id
	DirAccess.make_dir_recursive_absolute("user://logs")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()

	# 2) Enviar a PlayFab (telemetría / event write)
	_send_to_playfab_async(payload)

# --- PlayFab (ejemplo básico con HTTPRequest) ---
func _send_to_playfab_async(payload:Dictionary) -> void:
	# Nota: Para producción usa el SDK oficial de PlayFab (GDScript o REST).
	# Aquí va un ejemplo REST “genérico” para WritePlayerEvent.
	var http := HTTPRequest.new()
	add_child(http)

	# Rellena con tus credenciales PlayFab:
	var title_id := "XXXX"  # tu Title ID
	var entity_type := "title_player_account"
	var entity_id := _playfab_entity_id() # guárdalo antes al autenticar
	var secret_key := "" # NUNCA en cliente; en cliente usa Entity Token, no secret key

	var url := "https://%s.playfabapi.com/Event/WriteEvents" % title_id
	var headers := [
		"Content-Type: application/json",
		"X-EntityToken: %s" % _playfab_entity_token()  # obtenido tras login
	]

	var events_pf: Array = []
	for ev in events:
		events_pf.append({
			"EventName": "game_action",
			# “Body” puede ser tu ev completo, o solo meta
			"Payload": ev,
			"Timestamp": Time.get_datetime_string_from_system()
		})

	var body := {
		"Events": events_pf,
		"Entity": {"Type": entity_type, "Id": entity_id}
	}

	http.request_completed.connect(func(_result:int, _code:int, _headers:PackedStringArray, _body:PackedByteArray):
		http.queue_free()
	)

	var err := http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		push_warning("PlayFab request error: %s" % str(err))

# ---- Helpers ----
func _make_session_id() -> String:
	return "%s_%s" % [Time.get_datetime_string_from_system().replace(":","-"), str(randi())]

func _t_game() -> int:
	return GameManager.tiempo_partida if typeof(GameManager) != TYPE_NIL else 0

func _coins_diff() -> Dictionary:
	# Si quieres guardar economía antes/después, puedes capturar aquí:
	return {"coins": GameManager.coins} if typeof(GameManager) != TYPE_NIL else {}

func _playfab_entity_token() -> String:
	# Implementa según tu login
	return ProjectSettings.get_setting("playfab/entity_token", "")

func _playfab_entity_id() -> String:
	# Implementa según tu login
	return ProjectSettings.get_setting("playfab/entity_id", "")
