# res://autoload/HistoryManager.gd
extends Node

const HISTORY_PATH := "user://history.json"

signal stats_updated

var _historial: Array = []

# ================= STATS CACHÉ (públicas) =================
var stat_total_play_time_str: String = ""
var stat_matches_count_str: String = ""

var stat_letters_bought_by_difficulty_str: String = ""
var stat_hints_used_by_difficulty_str: String = ""
var stat_vowelsAE_bought_by_difficulty_str: String = ""
var stat_vowelsIOU_bought_by_difficulty_str: String = ""
var stat_swaps_made_by_difficulty_str: String = ""

# Por dificultad (1 Fácil, 2 Normal, 3 Difícil, 4 PRO)
var stat_letters_bought_facil_str: String = ""
var stat_letters_bought_normal_str: String = ""
var stat_letters_bought_dificil_str: String = ""

var stat_hints_used_facil_str: String = ""
var stat_hints_used_normal_str: String = ""
var stat_hints_used_dificil_str: String = ""

var stat_vowelsAE_bought_facil_str: String = ""
var stat_vowelsAE_bought_normal_str: String = ""
var stat_vowelsAE_bought_dificil_str: String = ""

var stat_vowelsIOU_bought_facil_str: String = ""
var stat_vowelsIOU_bought_normal_str: String = ""
var stat_vowelsIOU_bought_dificil_str: String = ""

var stat_swaps_made_facil_str: String = ""
var stat_swaps_made_normal_str: String = ""
var stat_swaps_made_dificil_str: String = ""

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
var stat_hints_used_pro_str: String = ""
var stat_vowelsAE_bought_pro_str: String = ""
var stat_vowelsIOU_bought_pro_str: String = ""
var stat_swaps_made_pro_str: String = ""

# Partidas por dificultad (añadimos Pro)
var stat_matches_pro_str: String = ""

# Tiempo medio por dificultad (añadimos Pro)
var stat_avg_time_pro_str: String = ""     # "HH:MM:SS"

# Tiempo por dificultad total (añadimos Pro)
var stat_time_pro_str: String = ""

func _ready() -> void:
	_historial = _load_history()
	_recompute_stats()


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

	var entry: Dictionary = {
		"id": GameManager.id_frase,
		"fecha": fecha,
		"jugador_nombre": GameManager.player_name,
		"categoria": GameManager.categoria_actual,
		"score": int(score),
		"tiempo_partida": int(GameManager.tiempo_partida), # segundos
		"dificultad": int(GameManager.dificultad_actual),   # 1,2,3,4
		"consonantes_compradas": GameManager.consonantes_compradas,
		"vocales_compradas_AE": GameManager.vocalesAE_compradas,
		"vocales_compradas_IOU": GameManager.vocalesIOU_compradas,
		"pistas_consumidas": GameManager.pistas_utilizadas,
		"cambios_hechos": GameManager.cambios_hechos,
	}
	_historial.append(entry)
	_save_history(_historial)
	_recompute_stats()

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
	var f := FileAccess.open(HISTORY_PATH, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir " + HISTORY_PATH)
		return []
	var txt := f.get_as_text()
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
			e["pistas_consumidas"] = int(e.get("pistas_consumidas", 0))
			e["cambios_hechos"] = int(e.get("cambios_hechos", 0))
			e["tiempo_partida"] = int(e.get("tiempo_partida", int(e.get("tiempo_partida_seg", 0))))
			e["score"] = int(e.get("score", 0))
			arr.append(e)
	return arr

func _save_history(data: Array) -> void:
	var f := FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	if f == null:
		push_error("No se pudo escribir " + HISTORY_PATH)
		return
	var json_text := JSON.stringify(data, "  ")
	f.store_string(json_text)
	f.close()

# Placeholder si no mandas breakdown (mejor sustituir con tus contadores reales)
func _derive_from_score(score: int) -> Dictionary:
	return {
		"dificultad": 0,
		"consonantes_compradas": 0,
		"vocales_compradas": 0,
		"pistas_consumidas": 0,
		"cambios_hechos": 0,
		"tiempo_partida_seg": 0
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
		# M:SS  (p. ej., 40:24)
		if m==0:
			return str("%02d" % s)
		elif m<10:

			return str("%1d" % m) + ":" + ("%02d" % s)
		else:
			return str(m) + ":" + ("%02d" % s)
	else:
		# H:MM:SS  (p. ej., 9:04:23 o 123:59:59)
		return str(h) + ":" + ("%02d:%02d" % [m, s])


# ------------------- RE-CÁLCULO CENTRAL -------------------

func _recompute_stats() -> void:
	# Arrays indexados 0..4 (usamos 1..4)
	var letters := [0, 0, 0, 0, 0]
	var hints   := [0, 0, 0, 0, 0]
	var vowelsAE := [0, 0, 0, 0, 0]
	var vowelsIOU := [0, 0, 0, 0, 0]
	var swaps   := [0, 0, 0, 0, 0]
	var matches := [0, 0, 0, 0, 0]
	var time_by_diff := [0, 0, 0, 0, 0]

	var total_play_sec := 0

	for e in _historial:
		var d := int(e.get("dificultad", 0))  # 1..4 (1=Fácil, 2=Normal, 3=Difícil, 4=Pro)
		if d < 1 or d > 4:
			continue

		matches[d] += 1
		letters[d] += int(e.get("consonantes_compradas", 0))
		hints[d]   += int(e.get("pistas_consumidas", 0))
		vowelsAE[d]  += int(e.get("vocales_compradas_AE", 0))
		vowelsIOU[d] += int(e.get("vocales_compradas_IOU", 0))
		swaps[d]   += int(e.get("cambios_hechos", 0))

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
	stat_letters_bought_by_difficulty_str = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [letters[1], letters[2], letters[3], letters[4]]
	stat_hints_used_by_difficulty_str     = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [hints[1],   hints[2],   hints[3],   hints[4]]
	stat_vowelsAE_bought_by_difficulty_str  = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [vowelsAE[1],  vowelsAE[2],  vowelsAE[3],  vowelsAE[4]]
	stat_vowelsIOU_bought_by_difficulty_str = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [vowelsIOU[1], vowelsIOU[2], vowelsIOU[3], vowelsIOU[4]]
	stat_swaps_made_by_difficulty_str     = "Facil: %d | Normal: %d | Dificil: %d | Pro: %d" % [swaps[1],   swaps[2],   swaps[3],   swaps[4]]

	# Strings simples por dificultad
	stat_letters_bought_facil_str  = str(letters[1])
	stat_letters_bought_normal_str = str(letters[2])
	stat_letters_bought_dificil_str= str(letters[3])
	stat_letters_bought_pro_str    = str(letters[4])

	stat_hints_used_facil_str      = str(hints[1])
	stat_hints_used_normal_str     = str(hints[2])
	stat_hints_used_dificil_str    = str(hints[3])
	stat_hints_used_pro_str        = str(hints[4])

	stat_vowelsAE_bought_facil_str   = str(vowelsAE[1])
	stat_vowelsAE_bought_normal_str  = str(vowelsAE[2])
	stat_vowelsAE_bought_dificil_str = str(vowelsAE[3])
	stat_vowelsAE_bought_pro_str     = str(vowelsAE[4])

	stat_vowelsIOU_bought_facil_str   = str(vowelsIOU[1])
	stat_vowelsIOU_bought_normal_str  = str(vowelsIOU[2])
	stat_vowelsIOU_bought_dificil_str = str(vowelsIOU[3])
	stat_vowelsIOU_bought_pro_str     = str(vowelsIOU[4])

	stat_swaps_made_facil_str      = str(swaps[1])
	stat_swaps_made_normal_str     = str(swaps[2])
	stat_swaps_made_dificil_str    = str(swaps[3])
	stat_swaps_made_pro_str        = str(swaps[4])

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

	# Paquete opcional (añadimos campos Pro)
	stat_pack = {
		"total_play_time": stat_total_play_time_str,
		"matches_count": stat_matches_count_str,

		"matches_by_diff": stat_matches_by_difficulty_str,
		"matches_facil": stat_matches_facil_str,
		"matches_normal": stat_matches_normal_str,
		"matches_dificil": stat_matches_dificil_str,
		"matches_pro": stat_matches_pro_str,

		"letters_by_diff": stat_letters_bought_by_difficulty_str,
		"hints_by_diff":   stat_hints_used_by_difficulty_str,
		"vowelsAE_by_diff":  stat_vowelsAE_bought_by_difficulty_str,
		"vowelsIOU_by_diff": stat_vowelsIOU_bought_by_difficulty_str,
		"swaps_by_diff":   stat_swaps_made_by_difficulty_str,

		"letters_facil":  stat_letters_bought_facil_str,
		"letters_normal": stat_letters_bought_normal_str,
		"letters_dificil":stat_letters_bought_dificil_str,
		"letters_pro":    stat_letters_bought_pro_str,

		"hints_facil":    stat_hints_used_facil_str,
		"hints_normal":   stat_hints_used_normal_str,
		"hints_dificil":  stat_hints_used_dificil_str,
		"hints_pro":      stat_hints_used_pro_str,

		"vowelsAE_facil":   stat_vowelsAE_bought_facil_str,
		"vowelsAE_normal":  stat_vowelsAE_bought_normal_str,
		"vowelsAE_dificil": stat_vowelsAE_bought_dificil_str,
		"vowelsAE_pro":     stat_vowelsAE_bought_pro_str,

		"vowelsIOU_facil":   stat_vowelsIOU_bought_facil_str,
		"vowelsIOU_normal":  stat_vowelsIOU_bought_normal_str,
		"vowelsIOU_dificil": stat_vowelsIOU_bought_dificil_str,
		"vowelsIOU_pro":     stat_vowelsIOU_bought_pro_str,

		"swaps_facil":    stat_swaps_made_facil_str,
		"swaps_normal":   stat_swaps_made_normal_str,
		"swaps_dificil":  stat_swaps_made_dificil_str,
		"swaps_pro":      stat_swaps_made_pro_str,

		"avg_time_facil":   stat_avg_time_facil_str,
		"avg_time_normal":  stat_avg_time_normal_str,
		"avg_time_dificil": stat_avg_time_dificil_str,
		"avg_time_pro":     stat_avg_time_pro_str,
		"avg_time_by_diff": stat_avg_time_by_difficulty_str,
	}

	emit_signal("stats_updated")
