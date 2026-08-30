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
		"categoria": GameManager.normalize_category(GameManager.categoria_actual),
		"score": int(score),
		"partida_ganada": bool(resultado),
		"tiempo_partida": int(GameManager.tiempo_partida), # segundos
		"dificultad": int(GameManager.dificultad_actual),   # 1,2,3,4
		"game_mode": str(GameManager.game_mode_actual),
		"estrellas": int(GameManager.puzzle_stars),
		"star_system_version": 2,
		"consonantes_compradas": GameManager.consonantes_compradas,
		"vocales_compradas_AE": GameManager.vocalesAE_compradas,
		"vocales_compradas_IOU": GameManager.vocalesIOU_compradas,
		"pistas_consumidas_1": GameManager.pistas_utilizadas_1,
		"pistas_consumidas_2": GameManager.pistas_utilizadas_2,
		"revelaciones_falladas": int(GameManager.reveal_errors_count),
		"vidas_perdidas": _calcula_vidas_perdidas()
	}
	_historial.append(entry)
	_save_history(_historial)
	_recompute_stats()
	if resultado:
		PuzzleSaveManager.mark_completed(int(GameManager.id_frase))

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
	var filter_all := category.strip_edges() == "" or category == "Todas" or category.to_lower() == "all"
	var filter_id := GameManager.normalize_category(category)
	for entry in _historial:
		if not filter_all and not GameManager.categories_match(str(entry.get("categoria", "")), filter_id):
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


func _entry_game_mode(entry: Dictionary) -> String:
	var mode := str(entry.get("game_mode", "")).strip_edges().to_lower()
	if mode == GameManager.MODE_CRYPTOGRAM or mode == GameManager.MODE_QUICK:
		return mode
	var difficulty := int(entry.get("dificultad", 0))
	return GameManager.MODE_CRYPTOGRAM if difficulty >= 3 else GameManager.MODE_QUICK


func _format_duration_friendly(total_sec: int) -> String:
	total_sec = maxi(total_sec, 0)
	var hours := int(total_sec / 3600)
	var minutes := int((total_sec % 3600) / 60)
	var seconds := int(total_sec % 60)
	if hours > 0:
		if minutes == 0 and seconds == 0:
			return "%d h" % hours
		return "%d h %d min" % [hours, minutes]
	if minutes > 0:
		return "%d min %d s" % [minutes, seconds]
	return "%d s" % seconds


func _format_date_short(fecha: Dictionary) -> String:
	if fecha.is_empty():
		return "—"
	var day := int(fecha.get("dia", 0))
	var month := int(fecha.get("mes", 0))
	var year := int(fecha.get("anio", 0))
	if day <= 0 or month <= 0:
		var iso := str(fecha.get("iso", ""))
		return iso if iso != "" else "—"
	var months: Array[String] = ["", "ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]
	var month_name: String = months[month] if month < months.size() else str(month)
	if year > 0:
		return "%d %s %d" % [day, month_name, year]
	return "%d %s" % [day, month_name]


func _phrase_title_for_id(phrase_id: int) -> String:
	if typeof(GameManager) == TYPE_NIL:
		return "Nivel %d" % phrase_id
	for item in GameManager.frases_db:
		if int(item.get("index", -1)) != phrase_id:
			continue
		var init := str(item.get("description_init", "")).strip_edges()
		if init != "" and init.to_lower() != "frase final":
			return init
		var hint := str(item.get("hint_1", "")).strip_edges()
		if hint != "":
			return hint
		return "Nivel %d" % phrase_id
	return "Nivel %d" % phrase_id


func _count_levels_for(category_id: String, mode: String) -> int:
	var total := 0
	if typeof(GameManager) == TYPE_NIL:
		return 0
	for item in GameManager.frases_db:
		if not GameManager.categories_match(str(item.get("category", "")), category_id):
			continue
		var difficulty := int(item.get("difficulty", 1))
		var is_crypto := difficulty >= 3
		if mode == GameManager.MODE_CRYPTOGRAM and not is_crypto:
			continue
		if mode == GameManager.MODE_QUICK and is_crypto:
			continue
		total += 1
	return total


func get_stats_dashboard() -> Dictionary:
	var matches := _historial.size()
	var wins := 0
	var total_play_sec := 0
	var hints_used := 0
	var letters_revealed := 0
	var letters_failed := 0
	var searches := 0
	var best_entry: Dictionary = {}
	var best_stars := -1
	var best_score := -1
	var recent_times: Array[int] = []
	var completed_puzzles := {}
	var best_stars_by_puzzle := {}
	var time_by_mode := {
		GameManager.MODE_QUICK: 0,
		GameManager.MODE_CRYPTOGRAM: 0,
	}
	var matches_by_mode := {
		GameManager.MODE_QUICK: 0,
		GameManager.MODE_CRYPTOGRAM: 0,
	}
	var completed_by_mode: Dictionary = {
		GameManager.MODE_QUICK: {},
		GameManager.MODE_CRYPTOGRAM: {},
	}

	for category_id in GameManager.all_category_ids():
		completed_by_mode[GameManager.MODE_QUICK][category_id] = {}
		completed_by_mode[GameManager.MODE_CRYPTOGRAM][category_id] = {}

	for entry in _historial:
		if not (entry is Dictionary):
			continue
		var e: Dictionary = entry
		var won := bool(e.get("partida_ganada", false))
		if won:
			wins += 1
		var secs := int(e.get("tiempo_partida", 0))
		total_play_sec += secs
		recent_times.append(secs)
		var entry_mode := _entry_game_mode(e)
		if time_by_mode.has(entry_mode):
			time_by_mode[entry_mode] = int(time_by_mode[entry_mode]) + secs
			matches_by_mode[entry_mode] = int(matches_by_mode[entry_mode]) + 1

		hints_used += (
			int(e.get("pistas_consumidas_1", 0))
			+ int(e.get("pistas_consumidas_2", 0))
		)
		searches += int(e.get("pistas_consumidas_2", 0))
		letters_revealed += (
			int(e.get("consonantes_compradas", 0))
			+ int(e.get("vocales_compradas_AE", 0))
			+ int(e.get("vocales_compradas_IOU", 0))
		)
		letters_failed += int(e.get("revelaciones_falladas", 0))

		var stars := int(e.get("estrellas", -1))
		var score_val := int(e.get("score", 0))
		if stars > best_stars or (stars == best_stars and score_val > best_score):
			best_stars = stars
			best_score = score_val
			best_entry = e
		elif best_stars < 0 and score_val > best_score and won:
			best_score = score_val
			best_entry = e

		if won:
			var mode := _entry_game_mode(e)
			var category := GameManager.normalize_category(str(e.get("categoria", "")))
			var completed_id := int(e.get("id", -1))
			if completed_id >= 0:
				var completed_key := str(completed_id)
				completed_puzzles[completed_key] = true
				var result_stars := clampi(int(e.get("estrellas", 0)), 1, 5)
				best_stars_by_puzzle[completed_key] = maxi(
					int(best_stars_by_puzzle.get(completed_key, 0)),
					result_stars
				)
			if completed_by_mode.has(mode) and completed_by_mode[mode].has(category):
				var phrase_id := int(e.get("id", -1))
				if phrase_id >= 0:
					completed_by_mode[mode][category][phrase_id] = true

	var avg_sec := int(total_play_sec / matches) if matches > 0 else 0
	var win_rate := (100.0 * float(wins) / float(matches)) if matches > 0 else 0.0

	var series: Array[float] = []
	var series_source := recent_times
	if series_source.size() > 12:
		series_source = series_source.slice(series_source.size() - 12, series_source.size())
	for value in series_source:
		series.append(float(value) / 60.0)

	var progress := {}
	for mode in [GameManager.MODE_QUICK, GameManager.MODE_CRYPTOGRAM]:
		progress[mode] = []
		for category_id in [
			GameManager.CAT_CITA,
			GameManager.CAT_EFEMERIDE,
			GameManager.CAT_CURIOSIDADES,
			GameManager.CAT_FRAGMENTO,
		]:
			var record := get_competitive_record(category_id, mode)
			progress[mode].append({
				"category": category_id,
				"stars_earned": int(record.get("stars_earned", 0)),
				"stars_available": int(record.get("stars_available", 0)),
				"percent": int(round(float(record.get("percentage", 0.0)))),
			})

	var star_distribution := {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	for star_value in best_stars_by_puzzle.values():
		var star_count := clampi(int(star_value), 1, 5)
		star_distribution[star_count] = int(star_distribution[star_count]) + 1
	var global_record := get_competitive_record("global", "all")
	var completed_percent := 0.0
	if int(global_record.get("available_puzzles", 0)) > 0:
		completed_percent = (
			100.0
			* float(global_record.get("completed", 0))
			/ float(global_record.get("available_puzzles", 1))
		)
	var avg_quick_sec := 0
	var avg_crypto_sec := 0
	if int(matches_by_mode[GameManager.MODE_QUICK]) > 0:
		avg_quick_sec = int(
			int(time_by_mode[GameManager.MODE_QUICK])
			/ int(matches_by_mode[GameManager.MODE_QUICK])
		)
	if int(matches_by_mode[GameManager.MODE_CRYPTOGRAM]) > 0:
		avg_crypto_sec = int(
			int(time_by_mode[GameManager.MODE_CRYPTOGRAM])
			/ int(matches_by_mode[GameManager.MODE_CRYPTOGRAM])
		)

	var best := {
		"stars": maxi(best_stars, 0),
		"has_data": not best_entry.is_empty(),
		"title": "",
		"level": "",
		"date": "",
		"category": "",
	}
	if not best_entry.is_empty():
		var phrase_id := int(best_entry.get("id", -1))
		var category := GameManager.normalize_category(str(best_entry.get("categoria", "")))
		best["category"] = category
		best["title"] = _phrase_title_for_id(phrase_id)
		best["level"] = "Nivel %d" % phrase_id if phrase_id >= 0 else ""
		best["date"] = _format_date_short(best_entry.get("fecha", {}))
		if int(best_entry.get("estrellas", -1)) < 0:
			# Legacy entries without stars: estimate from score band.
			var score_est := int(best_entry.get("score", 0))
			if score_est >= 25000:
				best["stars"] = 5
			elif score_est >= 20000:
				best["stars"] = 4
			elif score_est >= 15000:
				best["stars"] = 3
			elif score_est >= 10000:
				best["stars"] = 2
			elif score_est > 0:
				best["stars"] = 1

	return {
		"matches": matches,
		"wins": wins,
		"completed_puzzles": int(global_record.get("completed", completed_puzzles.size())),
		"total_puzzles": int(global_record.get("available_puzzles", 0)),
		"completed_percent": completed_percent,
		"win_rate": win_rate,
		"total_play_sec": total_play_sec,
		"total_play_label": _format_duration_friendly(total_play_sec),
		"avg_play_sec": avg_sec,
		"avg_play_label": _format_duration_friendly(avg_sec),
		"avg_quick_label": _format_duration_friendly(avg_quick_sec),
		"avg_cryptogram_label": _format_duration_friendly(avg_crypto_sec),
		"hints_used": hints_used,
		"letters_revealed": letters_revealed,
		"letters_failed": letters_failed,
		"searches": searches,
		"avg_series_minutes": series,
		"progress": progress,
		"star_summary": {
			"earned": int(global_record.get("stars_earned", 0)),
			"available": int(global_record.get("stars_available", 0)),
			"percentage": float(global_record.get("percentage", 0.0)),
			"distribution": star_distribution,
		},
		"best": best,
	}


func get_competitive_record(
	category_filter: String = "global",
	mode_filter: String = "all"
) -> Dictionary:
	var normalized_category := category_filter.strip_edges().to_lower()
	var normalized_mode := mode_filter.strip_edges().to_lower()
	var filter_all_categories := normalized_category in ["", "global", "todas", "all"]
	var filter_all_modes := normalized_mode in ["", "todos", "all"]
	if not filter_all_categories:
		normalized_category = GameManager.normalize_category(normalized_category)

	var available_puzzles := {}
	for item_value in GameManager.frases_db:
		if not (item_value is Dictionary):
			continue
		var item: Dictionary = item_value
		var category := GameManager.normalize_category(str(item.get("category", "")))
		var difficulty := int(item.get("difficulty", 1))
		var mode := (
			GameManager.MODE_CRYPTOGRAM
			if difficulty >= 3
			else GameManager.MODE_QUICK
		)
		if not filter_all_categories and category != normalized_category:
			continue
		if not filter_all_modes and mode != normalized_mode:
			continue
		var phrase_id := int(item.get("index", -1))
		if phrase_id >= 0:
			available_puzzles["%s|%s|%d" % [category, mode, phrase_id]] = (
				GameManager.get_puzzle_difficulty_stars(difficulty)
			)

	var best_by_puzzle := {}
	for entry_value in _historial:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		if not bool(entry.get("partida_ganada", false)):
			continue
		var category := GameManager.normalize_category(str(entry.get("categoria", "")))
		var mode := _entry_game_mode(entry)
		if not filter_all_categories and category != normalized_category:
			continue
		if not filter_all_modes and mode != normalized_mode:
			continue
		var phrase_id := int(entry.get("id", -1))
		if phrase_id < 0:
			continue
		var key := "%s|%s|%d" % [category, mode, phrase_id]
		var difficulty := int(entry.get("dificultad", 1))
		var difficulty_stars := GameManager.get_puzzle_difficulty_stars(difficulty)
		var performance_stars := int(entry.get("estrellas", -1))
		if performance_stars < 0:
			var legacy_score := int(entry.get("score", 0))
			performance_stars = clampi(
				int(ceil(float(legacy_score) / 5000.0)),
				1,
				5
			)
		var stars := 0
		if int(entry.get("star_system_version", 1)) >= 2:
			stars = clampi(performance_stars, 0, difficulty_stars)
		else:
			stars = clampi(
				int(round(
					float(clampi(performance_stars, 0, 5))
					* float(difficulty_stars)
					/ 5.0
				)),
				0,
				difficulty_stars
			)
		var aids := _competitive_help_count(entry)
		var failed_letters := int(entry.get("revelaciones_falladas", 0))
		if not best_by_puzzle.has(key):
			best_by_puzzle[key] = {
				"stars": stars,
				"aids": aids,
				"failed_letters": failed_letters,
				"difficulty": difficulty,
			}
			continue
		var previous: Dictionary = best_by_puzzle[key]
		if stars > int(previous.get("stars", 0)) or (
			stars == int(previous.get("stars", 0))
			and (
				aids < int(previous.get("aids", 0))
				or (
					aids == int(previous.get("aids", 0))
					and failed_letters < int(previous.get("failed_letters", 0))
				)
			)
		):
			best_by_puzzle[key] = {
				"stars": stars,
				"aids": aids,
				"failed_letters": failed_letters,
				"difficulty": difficulty,
			}

	var stars_earned := 0
	var aids_used := 0
	var failed_letters := 0
	var hard_completed := 0
	for result_value in best_by_puzzle.values():
		var result: Dictionary = result_value
		stars_earned += int(result.get("stars", 0))
		aids_used += int(result.get("aids", 0))
		failed_letters += int(result.get("failed_letters", 0))
		if int(result.get("difficulty", 0)) >= 3:
			hard_completed += 1

	var completed := best_by_puzzle.size()
	var stars_available := 0
	for maximum_value in available_puzzles.values():
		stars_available += int(maximum_value)
	var percentage := 0.0
	if stars_available > 0:
		percentage = 100.0 * float(stars_earned) / float(stars_available)
	var stars_per_puzzle := 0.0
	if completed > 0:
		stars_per_puzzle = float(stars_earned) / float(completed)

	return {
		"category": "global" if filter_all_categories else normalized_category,
		"mode": "all" if filter_all_modes else normalized_mode,
		"stars_earned": stars_earned,
		"stars_available": stars_available,
		"percentage": percentage,
		"percentage_tenths": clampi(int(round(percentage * 10.0)), 0, 1000),
		"completed": completed,
		"hard_completed": hard_completed,
		"aids_used": aids_used,
		"failed_letters": failed_letters,
		"stars_per_puzzle": stars_per_puzzle,
		"available_puzzles": available_puzzles.size(),
		"stars_per_puzzle_hundredths": int(round(stars_per_puzzle * 100.0)),
		"stars_per_puzzle_tenths": int(round(stars_per_puzzle * 10.0)),
	}


func _competitive_help_count(entry: Dictionary) -> int:
	return (
		int(entry.get("pistas_consumidas_1", 0))
		+ int(entry.get("pistas_consumidas_2", 0))
		+ int(entry.get("consonantes_compradas", 0))
		+ int(entry.get("vocales_compradas_AE", 0))
		+ int(entry.get("vocales_compradas_IOU", 0))
	)


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
