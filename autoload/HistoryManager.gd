extends Node

const HISTORY_PATH := "user://history.json"

var _historial: Array = []

func _ready() -> void:
	_historial = _load_history()
	#print(_historial)

# ---------- API PÚBLICA ----------

## Registra el resultado de una partida.
## - player_name: String
## - category: String
## - score: int
## - tiempo_partida: int
## - breakdown (opcional): Dictionary con:
##   dificultad:int, letras_compradas:int, vocales_compradas:int,
##   pistas_consumidas:int, cambios_hechos:int, tiempo_partida_seg:int

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
		"score": score,
		"tiempo_partida": GameManager.tiempo_partida,
		"dificultad": GameManager.dificultad_actual,
		"letras_compradas": int(bd.get("letras_compradas", 0)),
		"vocales_compradas": int(bd.get("vocales_compradas", 0)),
		"pistas_consumidas": int(bd.get("pistas_consumidas", 0)),
		"cambios_hechos": int(bd.get("cambios_hechos", 0)),
		#"tiempo_partida_seg": int(bd.get("tiempo_partida_seg", 0))
	}

	_historial.append(entry)
	_save_history(_historial)


## Devuelve todo el historial (puedes filtrar por categoría, jugador, etc. fuera)
func get_history() -> Array:
	return _historial.duplicate(true)

## Limpia el historial (opcional)
func clear_history() -> void:
	_historial.clear()
	_save_history(_historial)

# ---------- INTERNOS ----------

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
	if typeof(parsed) == TYPE_ARRAY:
		return parsed as Array
	return []


func _save_history(data: Array) -> void:
	var f := FileAccess.open(HISTORY_PATH, FileAccess.WRITE)
	if f == null:
		push_error("No se pudo escribir " + HISTORY_PATH)
		return
	var json_text := JSON.stringify(data, "  ")  # con indentado
	f.store_string(json_text)
	f.close()

# Si tu sistema de puntuación codifica los datos, define aquí la lógica.
# De momento devuelve ceros (para que todo compile).
func _derive_from_score(score: int) -> Dictionary:
	# TODO: sustituir por tu fórmula real de decodificación del score
	return {
		"dificultad": 0,
		"letras_compradas": 0,
		"vocales_compradas": 0,
		"pistas_consumidas": 0,
		"cambios_hechos": 0,
		"tiempo_partida_seg": 0
	}

## Devuelve resultados filtrados por categoría y dificultad,
## ordenados por score descendente.
## - category: String ("Todas" para no filtrar)
## - difficulty: int (-1 para no filtrar)
func get_results_filtered(category: String = "Todas", difficulty: int = -1) -> Array:
	var filtrados: Array = []

	for entry in _historial:
		# Filtrar por categoría
		if category != "Todas" and entry.get("categoria", "") != category:
			continue
		# Filtrar por dificultad
		if difficulty != -1 and int(entry.get("dificultad", -1)) != difficulty:
			continue

		filtrados.append(entry)

	# Ordenar de mayor a menor score
	filtrados.sort_custom(func(a, b):
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	#print("CATEGORIA: ", category)
	#print("DIFICULTAD: ", difficulty)
	#print(filtrados)
	return filtrados

## Devuelve true si el score entra en el TOP 8 de la categoría+dificultad.
## Criterio: hay menos de 8 partidas con puntuación estrictamente mayor.
func partida_dentro_de_record(categoria: String, dificultad: int, score: int) -> bool:
	const TOP_LIMIT := 8
	var filtrados: Array = get_results_filtered(categoria, dificultad)  # ya viene ordenado DESC
	var count_greater: int = 0

	for e in filtrados:
		var s: int = int(e.get("score", 0))
		if s > score:
			count_greater += 1
			if count_greater >= TOP_LIMIT:
				return false

	# Si hay menos de 8 con score estrictamente mayor, entra (incluye empates).
	return true

func numero_de_record_de_partida_dentro_de_record(categoria: String, dificultad: int, score: int) -> int:
	const TOP_LIMIT := 8
	var filtrados: Array = get_results_filtered(categoria, dificultad)  # ya viene ordenado DESC
	var count_greater: int = 0
	var pos:int = 1
	
	for e in filtrados:
		
		var s: int = int(e.get("score", 0))
		if s > score:
			count_greater += 1
			pos += 1
			if count_greater >= TOP_LIMIT:
				return false
		else:
			return pos

	# Si hay menos de 8 con score estrictamente mayor, entra (incluye empates).
	return pos
