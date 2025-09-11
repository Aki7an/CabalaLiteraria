# res://addons/cifraletra/AnalizadorCL.gd
extends Node
## Analizador CifraLetra — Autoload (Godot 4.4.x)
## - Normaliza (MAYÚSCULAS, quita tildes, preserva Ñ)
## - Calcula frecuencias sobre texto FILTRADO (quitando descubiertas)
## - Estima dificultad (0–10) con: DL gaussiano, DR^2, DU = U/T y puerta G (si U<=1 ⇒ ~0)

# ====== Parámetros del modelo de dificultad ======
const ALFABETO_TOTAL := 27 # A-Z + Ñ
const LC := 125.0          # Longitud “cómoda” para el gaussiano
const SIGMA := 50.0
const W_L := 0.30
const W_R := 0.40
const W_U := 0.30

# ================== API ==================
## Llama a esta función desde tu juego:
##   var dif := AnalizadorCL.evaluar_dificultad("frase...", "AEIOUÑ...")
## Devuelve: dificultad (float 0..10). Imprime el resto en consola.
func evaluar_dificultad(frase_original: String, letras_descubiertas: String) -> float:
	# 1) Normalización
	var solo: String = _normalizar_solo_letras(frase_original)
	var desc: String = _normalizar_set(letras_descubiertas)

	# 2) Texto filtrado (quitando las letras ya descubiertas)
	var solo_filtrado := solo if desc.is_empty() else _remover_clase(solo, desc)

	# 3) Frecuencias (del texto filtrado)
	var freq := _contar_letras(solo_filtrado)
	var ordenado := _ordenar_frecuencias(freq)
	var total := solo_filtrado.length()

	# 4) Variables para dificultad
	var L: int = solo.length()                    # longitud total normalizada
	var D: int = desc.length()                    # letras descubiertas (únicas, ya normalizadas)
	var set_frase := _set_from_string(solo)       # conjunto de letras presentes
	var T: int = set_frase.size()                 # número de letras únicas en la frase
	var set_desc := _set_from_string(desc)
	var U: int = 0                                # letras únicas aún desconocidas
	for ch in set_frase.keys():
		if not set_desc.has(ch):
			U += 1

	# 5) Estimación
	var dif_data := _estimar_dificultad(L, ALFABETO_TOTAL, D, T, U)

	# 6) Logging en consola
	_log_header("Analizador CifraLetra")
	_log_kv("Frase (normalizada)", solo)
	_log_kv("Letras descubiertas (set ordenado)", (desc if not desc.is_empty() else "—"))
	_log_kv("Texto filtrado (para %)", solo_filtrado)
	_print_tabla_frecuencias(ordenado, total)

	# Variables y parciales
	print("--- Variables y parciales ---")
	_log_kv("L (longitud)", str(L))
	_log_kv("A (alfabeto total)", str(ALFABETO_TOTAL))
	_log_kv("D (descubiertas)", str(D))
	_log_kv("R (restantes en alfabeto)", str(dif_data.R))
	_log_kv("T (letras únicas en frase)", str(T))
	_log_kv("U (únicas por descubrir)", str(U))
	_log_kv("DL (gauss)", _f2(dif_data.DL, 4))
	_log_kv("DR^2", _f2(dif_data.DR, 4))
	_log_kv("DU = U/T", _f2(dif_data.DU, 4))
	_log_kv("G (puerta)", _f2(dif_data.G, 4))

	# Resultado final
	print("--- Resultado ---")
	_log_kv("Dificultad (0..10)", _f2(dif_data.dif, 2))
	print("")

	return dif_data.dif

# ================== Lógica ==================
func _quitar_tildes_vocales(s: String) -> String:
	s = s.to_upper()
	s = s.replace("Á","A").replace("À","A").replace("Â","A").replace("Ã","A").replace("Ä","A")
	s = s.replace("É","E").replace("È","E").replace("Ê","E").replace("Ë","E")
	s = s.replace("Í","I").replace("Ì","I").replace("Î","I").replace("Ï","I")
	s = s.replace("Ó","O").replace("Ò","O").replace("Ô","O").replace("Õ","O").replace("Ö","O")
	s = s.replace("Ú","U").replace("Ù","U").replace("Û","U").replace("Ü","U")
	return s

func _normalizar_solo_letras(s: String) -> String:
	s = _quitar_tildes_vocales(s)
	var out := PackedStringArray()
	for i in s.length():
		var ch := s[i]
		var code := ch.unicode_at(0)
		var is_AZ := (code >= 65 and code <= 90) # A..Z
		if is_AZ or ch == "Ñ":
			out.append(ch)
	return "".join(out)

func _normalizar_set(s: String) -> String:
	var norm := _normalizar_solo_letras(s)
	var setd := _set_from_string(norm) # Dictionary como conjunto
	var keys := PackedStringArray(setd.keys())
	keys.sort()
	return "".join(keys)

func _set_from_string(s: String) -> Dictionary:
	var st: Dictionary = {}
	for i in s.length():
		var ch := s[i]
		st[ch] = true
	return st

func _remover_clase(s: String, clase: String) -> String:
	var ban := _set_from_string(clase)
	var out := PackedStringArray()
	for i in s.length():
		var ch := s[i]
		if not ban.has(ch):
			out.append(ch)
	return "".join(out)

func _contar_letras(s: String) -> Dictionary:
	var d := {}
	for i in s.length():
		var ch := s[i]
		d[ch] = (d.get(ch, 0) as int) + 1
	return d

func _ordenar_frecuencias(freq: Dictionary) -> Array:
	var arr: Array = []
	for k in freq.keys():
		arr.append([k, freq[k]])
	# Comparador: primero por cuenta desc, luego por letra asc
	arr.sort_custom(func(a, b):
		if a[1] == b[1]:
			return String(a[0]) < String(b[0])  # asc por letra
		return int(a[1]) > int(b[1])           # desc por cuenta
	)
	return arr

# ------ Dificultad ------
func _estimar_dificultad(L: int, A: int, D: int, T: int, U: int) -> Dictionary:
	var DL := 1.0 - exp(-pow(float(L) - LC, 2.0) / (2.0 * pow(SIGMA, 2.0)))
	var R := maxi(1, A - D)
	var DR := pow(float(R - 1) / float(A - 1), 2.0)
	var DU := 0.0 if T == 0 else float(U) / float(T)
	var G := 0.0 if T <= 1 else _clamp01((float(U) - 1.0) / float(T - 1))
	var core := (W_L * DL + W_R * DR + W_U * DU) / (W_L + W_R + W_U)
	var dif := 10.0 * G * core
	return {
		"dif": dif,
		"DL": DL,
		"DR": DR,
		"DU": DU,
		"R": R,
		"G": G
	}

# ================== Utilidades de logging / formato ==================
func _print_tabla_frecuencias(ordenado: Array, total: int) -> void:
	print("--- Frecuencias (texto filtrado) ---")
	print("Letra   Cuenta     %")
	for row in ordenado:
		var letra: String = row[0]
		var cnt: int = row[1]
		var pct := (float(cnt) * 100.0 / float(total)) if total > 0 else 0.0
		print("%-6s  %-9d  %6.2f%%" % [letra, cnt, pct])

func _log_header(titulo: String) -> void:
	print("\n==================== %s ====================" % titulo)

func _log_kv(k: String, v: String) -> void:
	print("%s: %s" % [k, v])

func _clamp01(x: float) -> float:
	return clampf(x, 0.0, 1.0)

func _f2(x: float, n: int = 2) -> String:
	return String.num(x, n)
