# res://autoload/HistoryManager.gd
extends Node

const HISTORY_PATH := "user://history.json"

signal stats_updated

@export var stat_games_won_str: String = ""          # Total ganadas (string)
@export var stat_games_won_facil_str: String = ""    # Facil (string)
@export var stat_games_won_normal_str: String = ""   # Normal (string)
@export var stat_games_won_dificil_str: String = ""  # Difícil (string)
@export var stat_games_won_pro_str: String = ""      # Pro (string)

var _historial: Array = []

# ================= STATS CACHÉ (públicas) =================
var stat_total_play_time_str: String = ""
var stat_matches_count_str: String = ""

var stat_letters_bought_by_difficulty_str: String = ""
var stat_hints1_used_by_difficulty_str: String = ""
var stat_vowelsAE_bought_by_difficulty_str: String = ""
var stat_vowelsIOU_bought_by_difficulty_str: String = ""
var stat_hints2_used_by_difficulty_str: String = ""

# Por dificultad (1 Fácil, 2 Normal, 3 Difícil, 4 PRO)
var stat_letters_bought_facil_str: String = ""
var stat_letters_bought_normal_str: String = ""
var stat_letters_bought_dificil_str: String = ""

var stat_hints1_used_facil_str: String = ""
var stat_hints1_used_normal_str: String = ""
var stat_hints1_used_dificil_str: String = ""
var stat_hints1_used_PRO_str: String = ""

var stat_vowelsAE_bought_facil_str: String = ""
var stat_vowelsAE_bought_normal_str: String = ""
var stat_vowelsAE_bought_dificil_str: String = ""

var stat_vowelsIOU_bought_facil_str: String = ""
var stat_vowelsIOU_bought_normal_str: String = ""
var stat_vowelsIOU_bought_dificil_str: String = ""

var stat_hints2_used_facil_str: String = ""
var stat_hints2_used_normal_str: String = ""
var stat_hints2_used_dificil_str: String = ""
var stat_hints2_used_PRO_str: String = ""

var stat_lives_lost_facil_str: String = ""
var stat_lives_lost_normal_str: String = ""
var stat_lives_lost_dificil_str: String = ""
var stat_lives_lost_PRO_str: String = ""

# Partidas por dificultad
var stat_matches_by_difficulty_str: String = ""   # "Facil: X | Normal: Y | Dificil: Z"
var stat_matches_facil_str: String = ""
var stat_matches_normal_str: String = ""
var stat_matches_dificil_str: String = ""

# Tiempo medio por dificultad
var stat_avg_time_facil_str: String = ""        # "HH:MM:SS"
var stat_avg_time_normal_str: String = ""       # "HH:MM:SS"
var stat_avg_time_dificil_str: String = ""      # "HH:MM:SS"
var stat_avg_time_by_difficulty_str: String = ""# "Facil: ... | Normal: ... | Dificil: ..."

# Tiempo por dificultad
var stat_time_facil_str: String = ""
var stat_time_normal_str: String = ""
var stat_time_dificil_str: String = ""

# Paquete opcional
var stat_pack: Dictionary = {}

# --- Pro: strings simples por dificultad ---
var stat_letters_bought_pro_str: String = ""
var stat_vowelsAE_bought_pro_str: String = ""
var stat_vowelsIOU_bought_pro_str: String = ""
var stat_hints2_used_pro_str: String = ""

# Partidas por dificultad (añadimos Pro)
var stat_matches_pro_str: String = ""

# Tiempo medio por dificultad (añadimos Pro)
var stat_avg_time_pro_str: String = ""     # "HH:MM:SS"

# Tiempo por dificultad total (añadimos Pro)
var stat_time_pro_str: String = ""

func _ready() -> void:
	_historial = _load_history()
	_recompute_stats()

# ================== GAMES WON: CÁLCULO ==================
func _recompute_games_won() -> void:
	var total: int = 0
	var won_facil: int = 0
	var won_normal: int = 0
	var won_dificil: int = 0
	var won_pro: int = 0

	for e in _historial:
		if not (e is Dictionary):
			continue
		var gano: bool = bool(e.get("partida_ganada", false))
		if gano:
			total += 1
			var d: int = int(e.get("dificultad", 0))
			if d == 1:
				won_facil += 1
			elif d == 2:
				won_normal += 1
			elif d == 3:
				won_dificil += 1
			elif d == 4:
				won_pro += 1
			# d fuera de 1..4: ignora

	# Publica como strings para UI
	stat_games_won_str = str(total)
	stat_games_won_facil_str = str(won_facil)
	stat_games_won_normal_str = str(won_normal)
	stat_games_won_dificil_str = str(won_dificil)
	stat_games_won_pro_str = str(won_pro)

	# Notifica si quieres refrescar UI inmediatamente
	emit_signal("stats_updated")

# ------------------- API PÚBLICA -------------------

func add_result(player_name: String, score: int, breakdown: Dictionary = {}) -> void:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	var fecha: Dictionary = {
		"dia": now["day"],
		"mes": now["month"],
		"anio": now["year"],
		"iso": "%04d-%02d-%02d" % [now["year"], now["month"], now["day"]]
	}

	var bd: Dictionary = breakdown
	if bd.is_empty():
		bd = _derive_from_score(score)

	var resultado: bool = score != 0

	var entry: Dictionary = {
		"id": GameManager.id_frase,
		"fecha": fecha,
		"jugador_nombre": GameManager.player_name,
		"categoria": GameManager.categoria_actual,
		"score": int(score),
		"partida_ganada": bool(resultado),
		"tiempo_partida": int(GameManager.tiempo_partida), # segundos
		"dificultad": int(GameManager.dificultad_actual),   # 1,2,3,4
		"consonantes_compradas": GameManager.consonantes_compradas,
		"vocales_compradas_AE": GameManager.vocalesAE_compradas,
		"vocales_compradas_IOU": GameManager.vocalesIOU_compradas,
		"pistas_consumidas_1": GameManager.pistas_utilizadas_1,
		"pistas_consumidas_2": GameManager.pistas_utilizadas_2,
		"vidas_perdidas": _calcula_vidas_perdidas()
	}
	_historial.append(entry)
	_save_history(_historial)
	_recompute_stats()

func _calcula_vidas_perdidas() -> int:
	if GameManager.dificultad_actual == 1:
		return 4 - GameManager.lives
	elif GameManager.dificultad_actual == 2:
		return 3 - GameManager.lives
	elif GameManager.dificultad_actual == 3:
		return 2 - GameManager.lives
	else:
		return 1 - GameManager.lives

func get_history() -> Array:
	return _historial.duplicate(true)

func clear_history() -> void:
	_historial.clear()
	_save_history(_historial)
	_recompute_stats()

# ------------------- CARGA / GUARDADO -------------------

func _load_history() -> Array:
	if not FileAccess.file_exists(HISTORY_PATH):
		return []
	var f: FileAccess = FileAccess.open(HISTORY_PATH, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir " + HISTORY_PATH)
		return []
	var txt: String = f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_ARRAY:
		return []

	# Normalización mínima de tipos esperados
	var arr: Array = []
	for v in parsed:
		if v is Dictionary:
			var e: Dictionary = v
			e["dificultad"] = int(e.get("dificultad", 0))
			e["consonantes_compradas"] = int(e.get("consonantes_compradas", 0))
			e["vocales_compradas_AE"] = int(e.get("vocales_compradas_AE", 0))
			e["vocales_compradas_IOU"] = int(e.get("vocales_compradas_IOU", 0))
			e["pistas_consumidas_1"] = int(e.get("pistas_consumidas_1", 0))
			e["pistas_consumidas_2"] = int(e.get("pistas_consumidas_2", 0))
			e["consonantes_compradas"] = int(e.get("consonantes_compradas", 0))
			e["tiempo_partida"] = int(e.get("tiempo_partida", int(e.get("tiempo_partida_seg", 0))))
			e["score"] = int(e.get("score", 0))
			e["partida_ganada"] = bool(e.get("partida_ganada"))
			e["vidas_perdidas"] = int(e.get("vidas_perdidas", 0))
			arr.append(e)
	return arr

func _save_history(data: Array) -> void:
	var f: FileAccess = FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	if f == null:
		push_error("No se pudo escribir " + HISTORY_PATH)
		return
	var json_text: String = JSON.stringify(data, "  ")
	f.store_string(json_text)
	f.close()

# Placeholder si no mandas breakdown (mejor sustituir con tus contadores reales)
func _derive_from_score(score: int) -> Dictionary:
	return {
		"dificultad": 0,
		"consonantes_compradas": 0,
		"vocales_compradas": 0,
		"pistas_consumidas_1": 0,
		"pistas_consumidas_2": 0,
		"tiempo_partida_seg": 0,
		"vidas_perdidas": 0
	}

# ------------------- FILTROS / RÁNKING -------------------

func get_results_filtered(category: String = "Todas", difficulty: int = -1) -> Array:
	var filtrados: Array = []
	for entry in _historial:
		if category != "Todas" and entry.get("categoria", "") != category:
			continue
		if difficulty != -1 and int(entry.get("dificultad", -1)) != difficulty:
			continue
		filtrados.append(entry)
	filtrados.sort_custom(func(a, b):
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	return filtrados

func partida_dentro_de_record(categoria: String, dificultad: int, score: int) -> bool:
	const TOP_LIMIT := 8
	var filtrados: Array = get_results_filtered(categoria, dificultad)
	var count_greater := 0
	for e in filtrados:
		if int(e.get("score", 0)) > score:
			count_greater += 1
			if count_greater >= TOP_LIMIT:
				return false
	return true

func numero_de_record_de_partida_dentro_de_record(categoria: String, dificultad: int, score: int) -> int:
	const TOP_LIMIT := 8
	var filtrados: Array = get_results_filtered(categoria, dificultad)
	var pos := 1
	var count_greater := 0
	for e in filtrados:
		var s := int(e.get("score", 0))
		if s > score:
			count_greater += 1
			pos += 1
			if count_greater >= TOP_LIMIT:
				return -1
		else:
			return pos
	return pos if count_greater < TOP_LIMIT else -1

# ------------------- HELPERS -------------------

func _format_time_hms(total_sec: int) -> String:
	total_sec = max(total_sec, 0)

	var h: int = int(total_sec / 3600)
	var m: int = int((total_sec % 3600) / 60)
	var s: int = int(total_sec % 60)

	if h == 0:
		if m == 0:
			return str("%02d" % s)
		elif m < 10:
			return str("%1d" % m) + ":" + ("%02d" % s)
		else:
			return str(m) + ":" + ("%02d" % s)
	else:
		return str(h) + ":" + ("%02d:%02d" % [m, s])

# ------------------- RE-CÁLCULO CENTRAL -------------------

func _recompute_stats() -> void:
	# Arrays indexados 0..4 (usamos 1..4)
	var letters := [0, 0, 0, 0, 0]
	var hints1   := [0, 0, 0, 0, 0]
	var hints2   := [0, 0, 0, 0, 0]
	var vowelsAE := [0, 0, 0, 0, 0]
	var vowelsIOU := [0, 0, 0, 0, 0]
	var matches := [0, 0, 0, 0, 0]
	var time_by_diff := [0, 0, 0, 0, 0]
	var lives_lost := [0, 0, 0, 0, 0]  # <-- NUEVO: vidas perdidas por dificultad

	var total_play_sec := 0

	for e in _historial:
		var d := int(e.get("dificultad", 0))  # 1..4 (1=Fácil, 2=Normal, 3=Difícil, 4=Pro)
		if d < 1 or d > 4:
			continue

		matches[d] += 1
		letters[d] += int(e.get("consonantes_compradas", 0))
		hints2[d]   += int(e.get("pistas_consumidas_2", 0))
		vowelsAE[d]  += int(e.get("vocales_compradas_AE", 0))
		vowelsIOU[d] += int(e.get("vocales_compradas_IOU", 0))
		hints1[d]   += int(e.get("pistas_consumidas_1", 0))
		lives_lost[d] += int(e.get("vidas_perdidas", 0))  # <-- NUEVO

		var secs := int(e.get("tiempo_partida", 0))
		time_by_diff[d] += secs
		total_play_sec += secs

	# Globales
	stat_total_play_time_str = _format_time_hms(total_play_sec)
	stat_matches_count_str = str(_historial.size())

	# Partidas por dificultad (incluye Pro)
	stat_matches_by_difficulty_str = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [matches[1], matches[2], matches[3], matches[4]]
	stat_matches_facil_str  = str(matches[1])
	stat_matches_normal_str = str(matches[2])
	stat_matches_dificil_str= str(matches[3])
	stat_matches_pro_str    = str(matches[4])

	# Agregados por dificultad (incluye Pro)
	stat_letters_bought_by_difficulty_str   = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [letters[1], letters[2], letters[3], letters[4]]
	stat_hints1_used_by_difficulty_str      = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [hints1[1],   hints1[2],   hints1[3],   hints1[4]]
	stat_vowelsAE_bought_by_difficulty_str  = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [vowelsAE[1],  vowelsAE[2],  vowelsAE[3],  vowelsAE[4]]
	stat_vowelsIOU_bought_by_difficulty_str = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [vowelsIOU[1], vowelsIOU[2], vowelsIOU[3], vowelsIOU[4]]
	stat_hints2_used_by_difficulty_str      = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [hints2[1],   hints2[2],   hints2[3],   hints2[4]]

	# Strings simples por dificultad
	stat_letters_bought_facil_str  = str(letters[1])
	stat_letters_bought_normal_str = str(letters[2])
	stat_letters_bought_dificil_str= str(letters[3])
	stat_letters_bought_pro_str    = str(letters[4])

	stat_hints1_used_facil_str      = str(hints1[1])
	stat_hints1_used_normal_str     = str(hints1[2])
	stat_hints1_used_dificil_str    = str(hints1[3])
	stat_hints1_used_PRO_str        = str(hints1[4])

	stat_hints2_used_facil_str      = str(hints2[1])
	stat_hints2_used_normal_str     = str(hints2[2])
	stat_hints2_used_dificil_str    = str(hints2[3])
	stat_hints2_used_PRO_str        = str(hints2[4])

	stat_vowelsAE_bought_facil_str   = str(vowelsAE[1])
	stat_vowelsAE_bought_normal_str  = str(vowelsAE[2])
	stat_vowelsAE_bought_dificil_str = str(vowelsAE[3])
	stat_vowelsAE_bought_pro_str     = str(vowelsAE[4])

	stat_vowelsIOU_bought_facil_str   = str(vowelsIOU[1])
	stat_vowelsIOU_bought_normal_str  = str(vowelsIOU[2])
	stat_vowelsIOU_bought_dificil_str = str(vowelsIOU[3])
	stat_vowelsIOU_bought_pro_str     = str(vowelsIOU[4])

	# NUEVO: Vidas perdidas por dificultad (strings)
	stat_lives_lost_facil_str  = str(lives_lost[1])
	stat_lives_lost_normal_str = str(lives_lost[2])
	stat_lives_lost_dificil_str= str(lives_lost[3])
	stat_lives_lost_PRO_str    = str(lives_lost[4])

	# Tiempo medio por dificultad (HH:MM:SS)
	var avg_f := int(time_by_diff[1] / matches[1]) if matches[1] > 0 else 0
	var avg_n := int(time_by_diff[2] / matches[2]) if matches[2] > 0 else 0
	var avg_d := int(time_by_diff[3] / matches[3]) if matches[3] > 0 else 0
	var avg_p := int(time_by_diff[4] / matches[4]) if matches[4] > 0 else 0

	stat_avg_time_facil_str   = _format_time_hms(avg_f)
	stat_avg_time_normal_str  = _format_time_hms(avg_n)
	stat_avg_time_dificil_str = _format_time_hms(avg_d)
	stat_avg_time_pro_str     = _format_time_hms(avg_p)

	stat_avg_time_by_difficulty_str = "Facil: %s | Normal: %s | Dificil: %s | Pro: %s" % [
		stat_avg_time_facil_str, stat_avg_time_normal_str, stat_avg_time_dificil_str, stat_avg_time_pro_str]

	# Tiempo total por dificultad
	stat_time_facil_str   = _format_time_hms(time_by_diff[1])
	stat_time_normal_str  = _format_time_hms(time_by_diff[2])
	stat_time_dificil_str = _format_time_hms(time_by_diff[3])
	stat_time_pro_str     = _format_time_hms(time_by_diff[4])

	# Paquete opcional (añadimos campos Pro y, si quieres, podrías añadir vidas aquí también)
	stat_pack = {
		"total_play_time": stat_total_play_time_str,
		"matches_count": stat_matches_count_str,

		"matches_by_diff": stat_matches_by_difficulty_str,
		"matches_facil": stat_matches_facil_str,
		"matches_normal": stat_matches_normal_str,
		"matches_dificil": stat_matches_dificil_str,
		"matches_pro": stat_matches_pro_str,

		"letters_by_diff": stat_letters_bought_by_difficulty_str,
		"hints1_by_diff":   stat_hints1_used_by_difficulty_str,
		"vowelsAE_by_diff":  stat_vowelsAE_bought_by_difficulty_str,
		"vowelsIOU_by_diff": stat_vowelsIOU_bought_by_difficulty_str,
		"hints2_by_diff":   stat_hints2_used_by_difficulty_str,

		"letters_facil":  stat_letters_bought_facil_str,
		"letters_normal": stat_letters_bought_normal_str,
		"letters_dificil":stat_letters_bought_dificil_str,
		"letters_pro":    stat_letters_bought_pro_str,

		"hints1_facil":    stat_hints1_used_facil_str,
		"hints1_normal":   stat_hints1_used_normal_str,
		"hints1_dificil":  stat_hints1_used_dificil_str,
		"hints1_pro":      stat_hints1_used_PRO_str,

		"vowelsAE_facil":   stat_vowelsAE_bought_facil_str,
		"vowelsAE_normal":  stat_vowelsAE_bought_normal_str,
		"vowelsAE_dificil": stat_vowelsAE_bought_dificil_str,
		"vowelsAE_pro":     stat_vowelsAE_bought_pro_str,

		"vowelsIOU_facil":   stat_vowelsIOU_bought_facil_str,
		"vowelsIOU_normal":  stat_vowelsIOU_bought_normal_str,
		"vowelsIOU_dificil": stat_vowelsIOU_bought_dificil_str,
		"vowelsIOU_pro":     stat_vowelsIOU_bought_pro_str,

		"hints2_facil":    stat_hints2_used_facil_str,
		"hints2_normal":   stat_hints2_used_normal_str,
		"hints2_dificil":  stat_hints2_used_dificil_str,
		"hints2_pro":      stat_hints2_used_PRO_str,

		"avg_time_facil":   stat_avg_time_facil_str,
		"avg_time_normal":  stat_avg_time_normal_str,
		"avg_time_dificil": stat_avg_time_dificil_str,
		"avg_time_pro":     stat_avg_time_pro_str,
		"avg_time_by_diff": stat_avg_time_by_difficulty_str,
	}

	# También recalculamos ganadas (usa _historial ya normalizado)
	_recompute_games_won()
	emit_signal("stats_updated")  # añade el cálculo de las vidas perdidas por dificultad (ya integrado arriba)




## res://autoload/HistoryManager.gd
#extends Node
#
#const HISTORY_PATH := "user://history.json"
#
#signal stats_updated
#
#@export var stat_games_won_str: String = ""         # Total ganadas (string)
#@export var stat_games_won_facil_str: String = ""  # Facil (string)
#@export var stat_games_won_normal_str: String = ""  # Normal (string)
#@export var stat_games_won_dificil_str: String = "" # Difícil (string)
#@export var stat_games_won_pro_str: String = ""     # Pro (string)
#
#var _historial: Array = []
#
## ================= STATS CACHÉ (públicas) =================
#var stat_total_play_time_str: String = ""
#var stat_matches_count_str: String = ""
#
#var stat_letters_bought_by_difficulty_str: String = ""
#var stat_hints1_used_by_difficulty_str: String = ""
#var stat_vowelsAE_bought_by_difficulty_str: String = ""
#var stat_vowelsIOU_bought_by_difficulty_str: String = ""
#var stat_hints2_used_by_difficulty_str: String = ""
#
## Por dificultad (1 Fácil, 2 Normal, 3 Difícil, 4 PRO)
#var stat_letters_bought_facil_str: String = ""
#var stat_letters_bought_normal_str: String = ""
#var stat_letters_bought_dificil_str: String = ""
#
#var stat_hints1_used_facil_str: String = ""
#var stat_hints1_used_normal_str: String = ""
#var stat_hints1_used_dificil_str: String = ""
#var stat_hints1_used_PRO_str: String = ""
#
#var stat_vowelsAE_bought_facil_str: String = ""
#var stat_vowelsAE_bought_normal_str: String = ""
#var stat_vowelsAE_bought_dificil_str: String = ""
#
#var stat_vowelsIOU_bought_facil_str: String = ""
#var stat_vowelsIOU_bought_normal_str: String = ""
#var stat_vowelsIOU_bought_dificil_str: String = ""
#
#var stat_hints2_used_facil_str: String = ""
#var stat_hints2_used_normal_str: String = ""
#var stat_hints2_used_dificil_str: String = ""
#var stat_hints2_used_PRO_str: String = ""
#
#var stat_lives_lost_facil_str: String = ""
#var stat_lives_lost_normal_str: String = ""
#var stat_lives_lost_dificil_str: String = ""
#var stat_lives_lost_PRO_str: String = ""
#
## Partidas por dificultad
#var stat_matches_by_difficulty_str: String = ""   # "Facil: X | Normal: Y | Dificil: Z"
#var stat_matches_facil_str: String = ""
#var stat_matches_normal_str: String = ""
#var stat_matches_dificil_str: String = ""
#
## Tiempo medio por dificultad
#var stat_avg_time_facil_str: String = ""        # "HH:MM:SS"
#var stat_avg_time_normal_str: String = ""       # "HH:MM:SS"
#var stat_avg_time_dificil_str: String = ""      # "HH:MM:SS"
#var stat_avg_time_by_difficulty_str: String = ""# "Facil: ... | Normal: ... | Dificil: ..."
#
## Tiempo por dificultad
#var stat_time_facil_str: String = ""
#var stat_time_normal_str: String = ""
#var stat_time_dificil_str: String = ""
#
## Paquete opcional
#var stat_pack: Dictionary = {}
#
## --- Pro: strings simples por dificultad ---
#var stat_letters_bought_pro_str: String = ""
##var stat_hints1_used_pro_str: String = ""
#var stat_vowelsAE_bought_pro_str: String = ""
#var stat_vowelsIOU_bought_pro_str: String = ""
#var stat_hints2_used_pro_str: String = ""
#
## Partidas por dificultad (añadimos Pro)
#var stat_matches_pro_str: String = ""
#
## Tiempo medio por dificultad (añadimos Pro)
#var stat_avg_time_pro_str: String = ""     # "HH:MM:SS"
#
## Tiempo por dificultad total (añadimos Pro)
#var stat_time_pro_str: String = ""
#
#func _ready() -> void:
	#_historial = _load_history()
	#_recompute_stats()
#
## ================== GAMES WON: CÁLCULO ==================
#func _recompute_games_won() -> void:
	#var total: int = 0
	#var won_normal: int = 0
	#var won_dificil: int = 0
	#var won_pro: int = 0
	#var won_facil: int = 0
#
	#for e in _historial:
		#if not (e is Dictionary):
			#continue
		#if e.partida_ganada :
			#total += 1
			#if (e.dificultad == 1):
				#won_facil +=1
			#elif (e.dificultad == 2):
				#won_normal += 1
			#elif (e.dificultad == 3):
				#won_dificil += 1
			#else:
				#won_pro += 1
#
	## Publica como strings para UI (alineado con tu convención *_str)
	#stat_games_won_str = str(total)
	#stat_games_won_facil_str = str(won_facil)
	#stat_games_won_normal_str = str(won_normal)
	#stat_games_won_dificil_str = str(won_dificil)
	#stat_games_won_pro_str = str(won_pro)
#
	## Si ya emites stats_updated en otro recompute global, no es obligatorio repetirlo aquí.
	## Si quieres notificar inmediatamente al UI:
	#emit_signal("stats_updated")
#
## ------------------- API PÚBLICA -------------------
#
#func add_result(player_name: String, score: int, breakdown: Dictionary = {}) -> void:
	#var now: Dictionary = Time.get_datetime_dict_from_system()
	#var fecha: Dictionary = {
		#"dia": now["day"],
		#"mes": now["month"],
		#"anio": now["year"],
		#"iso": "%04d-%02d-%02d" % [now["year"], now["month"], now["day"]]
	#}
#
	#var bd: Dictionary = breakdown
	#if bd.is_empty():
		#bd = _derive_from_score(score)
#
	#var resultado: bool
	#if score ==0:
		#resultado = false
	#else:
		#resultado = true
			#
#
	#var entry: Dictionary = {		
		#"id": GameManager.id_frase,
		#"fecha": fecha,
		#"jugador_nombre": GameManager.player_name,
		#"categoria": GameManager.categoria_actual,
		#"score": int(score),
		#"partida_ganada": bool(resultado),
		#"tiempo_partida": int(GameManager.tiempo_partida), # segundos
		#"dificultad": int(GameManager.dificultad_actual),   # 1,2,3,4
		#"consonantes_compradas": GameManager.consonantes_compradas,
		#"vocales_compradas_AE": GameManager.vocalesAE_compradas,
		#"vocales_compradas_IOU": GameManager.vocalesIOU_compradas,
		#"pistas_consumidas_1": GameManager.pistas_utilizadas_1,
		#"pistas_consumidas_2": GameManager.pistas_utilizadas_2,
		#"vidas_perdidas": _calcula_vidas_perdidas() 
		#
	#}
	#_historial.append(entry)
	#_save_history(_historial)
	#_recompute_stats()
#
#func _calcula_vidas_perdidas() -> int:
	#if GameManager.dificultad_actual == 1:
		#return 4 - GameManager.lives
	#elif GameManager.dificultad_actual == 2:
		#return 3 - GameManager.lives
	#elif GameManager.dificultad_actual == 3:
		#return 2 - GameManager.lives
	#else:
		#return 1 - GameManager.lives
#
#func get_history() -> Array:
	#return _historial.duplicate(true)
#
#func clear_history() -> void:
	#_historial.clear()
	#_save_history(_historial)
	#_recompute_stats()
#
## ------------------- CARGA / GUARDADO -------------------
#
#func _load_history() -> Array:
	#if not FileAccess.file_exists(HISTORY_PATH):
		#return []
	#var f := FileAccess.open(HISTORY_PATH, FileAccess.READ)
	#if f == null:
		#push_error("No se pudo abrir " + HISTORY_PATH)
		#return []
	#var txt := f.get_as_text()
	#f.close()
#
	#var parsed: Variant = JSON.parse_string(txt)
	#if typeof(parsed) != TYPE_ARRAY:
		#return []
#
	## Normalización mínima de tipos esperados
	#var arr: Array = []
	#for v in parsed:
		#if v is Dictionary:
			#var e: Dictionary = v
			#e["dificultad"] = int(e.get("dificultad", 0))
			#e["consonantes_compradas"] = int(e.get("consonantes_compradas", 0))
			#e["vocales_compradas_AE"] = int(e.get("vocales_compradas_AE", 0))
			#e["vocales_compradas_IOU"] = int(e.get("vocales_compradas_IOU", 0))
			#e["pistas_consumidas_1"] = int(e.get("pistas_consumidas_1", 0))
			#e["pistas_consumidas_2"] = int(e.get("pistas_consumidas_2", 0))
			#e["consonantes_compradas"] = int(e.get("consonantes_compradas", 0))
			#e["tiempo_partida"] = int(e.get("tiempo_partida", int(e.get("tiempo_partida_seg", 0))))
			#e["score"] = int(e.get("score", 0))
			#e["partida_ganada"] = bool(e.get("partida_ganada"))
			#e["vidas_perdidas"] = int(e.get("vidas_perdidas", 0))
			#
			#arr.append(e)
	#return arr
#
#func _save_history(data: Array) -> void:
	#var f := FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	#if f == null:
		#push_error("No se pudo escribir " + HISTORY_PATH)
		#return
	#var json_text := JSON.stringify(data, "  ")
	#f.store_string(json_text)
	#f.close()
#
## Placeholder si no mandas breakdown (mejor sustituir con tus contadores reales)
#func _derive_from_score(score: int) -> Dictionary:
	#return {
		#"dificultad": 0,
		#"consonantes_compradas": 0,
		#"vocales_compradas": 0,
		#"pistas_consumidas_1": 0,
		#"pistas_consumidas_2": 0,
		#"tiempo_partida_seg": 0,
		#"vidas_perdidas": 0
	#}
#
## ------------------- FILTROS / RÁNKING -------------------
#
#func get_results_filtered(category: String = "Todas", difficulty: int = -1) -> Array:
	#var filtrados: Array = []
	#for entry in _historial:
		#if category != "Todas" and entry.get("categoria", "") != category:
			#continue
		#if difficulty != -1 and int(entry.get("dificultad", -1)) != difficulty:
			#continue
		#filtrados.append(entry)
	#filtrados.sort_custom(func(a, b):
		#return int(a.get("score", 0)) > int(b.get("score", 0))
	#)
	#return filtrados
#
#func partida_dentro_de_record(categoria: String, dificultad: int, score: int) -> bool:
	#const TOP_LIMIT := 8
	#var filtrados: Array = get_results_filtered(categoria, dificultad)
	#var count_greater := 0
	#for e in filtrados:
		#if int(e.get("score", 0)) > score:
			#count_greater += 1
			#if count_greater >= TOP_LIMIT:
				#return false
	#return true
#
#func numero_de_record_de_partida_dentro_de_record(categoria: String, dificultad: int, score: int) -> int:
	#const TOP_LIMIT := 8
	#var filtrados: Array = get_results_filtered(categoria, dificultad)
	#var pos := 1
	#var count_greater := 0
	#for e in filtrados:
		#var s := int(e.get("score", 0))
		#if s > score:
			#count_greater += 1
			#pos += 1
			#if count_greater >= TOP_LIMIT:
				#return -1
		#else:
			#return pos
	#return pos if count_greater < TOP_LIMIT else -1
#
## ------------------- HELPERS -------------------
#
#func _format_time_hms(total_sec: int) -> String:
	#total_sec = max(total_sec, 0)
#
	#var h: int = int(total_sec / 3600)
	#var m: int = int((total_sec % 3600) / 60)
	#var s: int = int(total_sec % 60)
#
	#if h == 0:
		## M:SS  (p. ej., 40:24)
		#if m==0:
			#return str("%02d" % s)
		#elif m<10:
#
			#return str("%1d" % m) + ":" + ("%02d" % s)
		#else:
			#return str(m) + ":" + ("%02d" % s)
	#else:
		## H:MM:SS  (p. ej., 9:04:23 o 123:59:59)
		#return str(h) + ":" + ("%02d:%02d" % [m, s])
#
#
## ------------------- RE-CÁLCULO CENTRAL -------------------
#
#func _recompute_stats() -> void:
	## Arrays indexados 0..4 (usamos 1..4)
	#var letters := [0, 0, 0, 0, 0]
	#var hints1   := [0, 0, 0, 0, 0]
	#var hints2   := [0, 0, 0, 0, 0]
	#var vowelsAE := [0, 0, 0, 0, 0]
	#var vowelsIOU := [0, 0, 0, 0, 0]
	#var matches := [0, 0, 0, 0, 0]
	#var time_by_diff := [0, 0, 0, 0, 0]
#
	#var total_play_sec := 0
#
	#for e in _historial:
		#var d := int(e.get("dificultad", 0))  # 1..4 (1=Fácil, 2=Normal, 3=Difícil, 4=Pro)
		#if d < 1 or d > 4:
			#continue
#
		#matches[d] += 1
		#letters[d] += int(e.get("consonantes_compradas", 0))
		#hints2[d]   += int(e.get("pistas_consumidas_2", 0))
		#vowelsAE[d]  += int(e.get("vocales_compradas_AE", 0))
		#vowelsIOU[d] += int(e.get("vocales_compradas_IOU", 0))
		#hints1[d]   += int(e.get("pistas_consumidas_1", 0))
		#
		#var secs := int(e.get("tiempo_partida", 0))
		#time_by_diff[d] += secs
		#total_play_sec += secs
#
	## Globales
	#stat_total_play_time_str = _format_time_hms(total_play_sec)
	#stat_matches_count_str = str(_historial.size())
#
	## Partidas por dificultad (incluye Pro)
	#stat_matches_by_difficulty_str = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [matches[1], matches[2], matches[3], matches[4]]
	#stat_matches_facil_str  = str(matches[1])
	#stat_matches_normal_str = str(matches[2])
	#stat_matches_dificil_str= str(matches[3])
	#stat_matches_pro_str    = str(matches[4])
#
	## Agregados por dificultad (incluye Pro)
	#stat_letters_bought_by_difficulty_str = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [letters[1], letters[2], letters[3], letters[4]]
	#stat_hints1_used_by_difficulty_str     = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [hints1[1],   hints1[2],   hints1[3],   hints1[4]]
	#stat_vowelsAE_bought_by_difficulty_str  = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [vowelsAE[1],  vowelsAE[2],  vowelsAE[3],  vowelsAE[4]]
	#stat_vowelsIOU_bought_by_difficulty_str = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [vowelsIOU[1], vowelsIOU[2], vowelsIOU[3], vowelsIOU[4]]
	#stat_hints2_used_by_difficulty_str     = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [hints2[1],   hints2[2],   hints2[3],   hints2[4]]
#
	## Strings simples por dificultad
	#stat_letters_bought_facil_str  = str(letters[1])
	#stat_letters_bought_normal_str = str(letters[2])
	#stat_letters_bought_dificil_str= str(letters[3])
	#stat_letters_bought_pro_str    = str(letters[4])
#
	#stat_hints1_used_facil_str      = str(hints1[1])
	#stat_hints1_used_normal_str     = str(hints1[2])
	#stat_hints1_used_dificil_str    = str(hints1[3])
	#stat_hints1_used_PRO_str        = str(hints1[4])
	#
	#stat_hints2_used_facil_str      = str(hints2[1])
	#stat_hints2_used_normal_str     = str(hints2[2])
	#stat_hints2_used_dificil_str    = str(hints2[3])
	#stat_hints2_used_PRO_str        = str(hints2[4])
#
	#stat_vowelsAE_bought_facil_str   = str(vowelsAE[1])
	#stat_vowelsAE_bought_normal_str  = str(vowelsAE[2])
	#stat_vowelsAE_bought_dificil_str = str(vowelsAE[3])
	#stat_vowelsAE_bought_pro_str     = str(vowelsAE[4])
#
	#stat_vowelsIOU_bought_facil_str   = str(vowelsIOU[1])
	#stat_vowelsIOU_bought_normal_str  = str(vowelsIOU[2])
	#stat_vowelsIOU_bought_dificil_str = str(vowelsIOU[3])
	#stat_vowelsIOU_bought_pro_str     = str(vowelsIOU[4])
#
#
#
	## Tiempo medio por dificultad (HH:MM:SS)
	#var avg_f := int(time_by_diff[1] / matches[1]) if matches[1] > 0 else 0
	#var avg_n := int(time_by_diff[2] / matches[2]) if matches[2] > 0 else 0
	#var avg_d := int(time_by_diff[3] / matches[3]) if matches[3] > 0 else 0
	#var avg_p := int(time_by_diff[4] / matches[4]) if matches[4] > 0 else 0
#
	#stat_avg_time_facil_str   = _format_time_hms(avg_f)
	#stat_avg_time_normal_str  = _format_time_hms(avg_n)
	#stat_avg_time_dificil_str = _format_time_hms(avg_d)
	#stat_avg_time_pro_str     = _format_time_hms(avg_p)
#
	#stat_avg_time_by_difficulty_str = "Facil: %s | Normal: %s | Dificil: %s | Pro: %s" % [
		#stat_avg_time_facil_str, stat_avg_time_normal_str, stat_avg_time_dificil_str, stat_avg_time_pro_str]
#
	## Tiempo total por dificultad
	#stat_time_facil_str   = _format_time_hms(time_by_diff[1])
	#stat_time_normal_str  = _format_time_hms(time_by_diff[2])
	#stat_time_dificil_str = _format_time_hms(time_by_diff[3])
	#stat_time_pro_str     = _format_time_hms(time_by_diff[4])
#
	## Paquete opcional (añadimos campos Pro)
	#stat_pack = {
		#"total_play_time": stat_total_play_time_str,
		#"matches_count": stat_matches_count_str,
#
		#"matches_by_diff": stat_matches_by_difficulty_str,
		#"matches_facil": stat_matches_facil_str,
		#"matches_normal": stat_matches_normal_str,
		#"matches_dificil": stat_matches_dificil_str,
		#"matches_pro": stat_matches_pro_str,
#
		#"letters_by_diff": stat_letters_bought_by_difficulty_str,
		#"hints1_by_diff":   stat_hints1_used_by_difficulty_str,
		#"vowelsAE_by_diff":  stat_vowelsAE_bought_by_difficulty_str,
		#"vowelsIOU_by_diff": stat_vowelsIOU_bought_by_difficulty_str,
		#"hints2_by_diff":   stat_hints2_used_by_difficulty_str,
#
		#"letters_facil":  stat_letters_bought_facil_str,
		#"letters_normal": stat_letters_bought_normal_str,
		#"letters_dificil":stat_letters_bought_dificil_str,
		#"letters_pro":    stat_letters_bought_pro_str,
#
		#"hints1_facil":    stat_hints1_used_facil_str,
		#"hints1_normal":   stat_hints1_used_normal_str,
		#"hints1_dificil":  stat_hints1_used_dificil_str,
		#"hints1_pro":      stat_hints1_used_PRO_str,
#
		#"vowelsAE_facil":   stat_vowelsAE_bought_facil_str,
		#"vowelsAE_normal":  stat_vowelsAE_bought_normal_str,
		#"vowelsAE_dificil": stat_vowelsAE_bought_dificil_str,
		#"vowelsAE_pro":     stat_vowelsAE_bought_pro_str,
#
		#"vowelsIOU_facil":   stat_vowelsIOU_bought_facil_str,
		#"vowelsIOU_normal":  stat_vowelsIOU_bought_normal_str,
		#"vowelsIOU_dificil": stat_vowelsIOU_bought_dificil_str,
		#"vowelsIOU_pro":     stat_vowelsIOU_bought_pro_str,
#
		#"hints2_facil":    stat_hints2_used_facil_str,
		#"hints2_normal":   stat_hints2_used_normal_str,
		#"hints2_dificil":  stat_hints2_used_dificil_str,
		#"hints2_pro":      stat_hints2_used_PRO_str,
#
		#"avg_time_facil":   stat_avg_time_facil_str,
		#"avg_time_normal":  stat_avg_time_normal_str,
		#"avg_time_dificil": stat_avg_time_dificil_str,
		#"avg_time_pro":     stat_avg_time_pro_str,
		#"avg_time_by_diff": stat_avg_time_by_difficulty_str,
	#}
	#_recompute_games_won()
	#emit_signal("stats_updated")
