class_name UtilsCLDifficulty
extends Node

# ----------------- Config calibrable -----------------
const VOWELS_MAX_REDUCTION := 0.60     # 0.60 → con AEIOU, M_vowels = 0.40
const PROGRESS_MAX_REDUCTION := 0.70   # reducción máxima por progreso
const PROGRESS_EXP := 1.50             # curva no lineal (acelera al final)
const MIN_FLOOR_WHEN_LEFT := 0.05      # suelo si aún quedan >1 letras únicas
const NEAR_SOLVED_LEFT := 1            # si quedan 0–1 letras únicas → casi 0

# Conjunto de vocales
const VOW: Dictionary = {"A":true,"E":true,"I":true,"O":true,"U":true}
# Letras “diagnósticas” en palabras cortas
const SHORT_HINT: Dictionary = {"Y":true,"S":true,"L":true,"D":true}
# Dígrafos vecinos
const DIGR_OK: Dictionary = {"LL":true,"RR":true,"CC":true}

# Prior (frecuencias) — español aprox
const FREQ: Dictionary = {
	"E":0.1372,"A":0.1172,"O":0.0844,"S":0.0720,"N":0.0683,"R":0.0641,"I":0.0528,"L":0.0524,"D":0.0467,"T":0.0460,
	"U":0.0455,"C":0.0387,"M":0.0308,"P":0.0289,"B":0.0149,"H":0.0118,"Q":0.0111,"Y":0.0109,"V":0.0105,"G":0.0100,
	"F":0.0069,"J":0.0052,"Z":0.0047,"Ñ":0.0017,"X":0.0014,"K":0.0011,"W":0.0004
}

# -----------------------------------------------------
# API principal (devuelve 0..100)
# -----------------------------------------------------
static func evaluar_dificultad(frase_original: String, letras_descubiertas: String, alpha: float = 1.0) -> float:
	var norm: String = _norm_text(letras_descubiertas)
	var disc_arr: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}

	for ch_char in norm:
		var s: String = String(ch_char)
		if _is_letter(s) and not seen.has(s):
			seen[s] = true
			disc_arr.append(s)

	var res: Dictionary = next_letter_difficulty(frase_original, disc_arr, alpha, 3)
	if not res.has("difficulty"):
		return 0.0
	return float(res["difficulty"]) * 100.0

# ----------------- Helpers de normalización -----------------
static func _norm_text(s: String) -> String:
	var t: String = s.to_upper()
	t = t.replace("Á","A").replace("É","E").replace("Í","I").replace("Ó","O").replace("Ú","U").replace("Ü","U")
	return t

static func _is_letter(ch: String) -> bool:
	return FREQ.has(ch)

# Devuelve [tokens:Array, letters:Array[String]]
static func _tokens_with_indices(text: String) -> Array:
	var letters: Array[String] = []
	for ch_char in text:
		var s: String = _norm_text(String(ch_char))
		if _is_letter(s):
			letters.append(s)

	var idx_letters: int = 0
	var tokens: Array = []                   # [TIPO] mantenemos genérico, pero contenido conocido
	var current: Array[int] = []             # [TIPO]
	for ch2 in text:
		var ss: String = _norm_text(String(ch2))
		if _is_letter(ss):
			current.append(idx_letters)
			idx_letters += 1
		else:
			if current.size() > 0:
				tokens.append(current.duplicate())
				current.clear()
	if current.size() > 0:
		tokens.append(current)
	return [tokens, letters]

# ----------------- Núcleo con ajustes de dificultad -----------------
static func next_letter_difficulty(phrase: String, discovered: PackedStringArray, alpha: float = 1.0, k_top: int = 3) -> Dictionary:
	var text: String = _norm_text(phrase)

	# Descubiertas como conjunto
	var disc: Dictionary = {}
	for d in discovered:
		disc[_norm_text(d)] = true

	# [TIPO] tipa explícito lo que sale del “tuple” Array
	var tk: Array = _tokens_with_indices(text)
	var tokens: Array = (tk[0] as Array)             # [TIPO]
	var letters: Array = (tk[1] as Array)            # [TIPO] realmente Array[String]
	if letters.is_empty():
		return {"difficulty": 0.0, "top": [], "probs": {}}

	# Conjunto de letras únicas presentes
	var set_phrase: Dictionary = {}
	for ch in letters:
		var chs: String = String(ch)                 # [TIPO] asegura String
		set_phrase[chs] = true
	var total_unique: int = set_phrase.size()

	# Descubiertas únicas
	var discovered_unique: int = 0
	for k in set_phrase.keys():
		var key_str: String = String(k)              # [TIPO]
		if disc.has(key_str):
			discovered_unique += 1

	# Cobertura de vocales
	var vowels_found: int = 0
	for v in VOW.keys():
		var vstr: String = String(v)                 # [TIPO]
		if disc.has(vstr):
			vowels_found += 1
	var vowel_coverage: float = float(vowels_found) / 5.0

	# Mapa de conocidas por índice
	var known: Array[bool] = []                      # [TIPO]
	for ch2 in letters:
		var s2: String = String(ch2)                 # [TIPO]
		known.append(disc.has(s2))

	# --- Brechas vocálicas ---
	var gaps: Array[int] = []                        # [TIPO]
	var cur: int = 0
	for i in range(letters.size()):
		var ch3: String = String(letters[i])         # [TIPO] ← corrige tu línea 119
		if known[i] and VOW.has(ch3):
			if cur > 0:
				gaps.append(cur)
				cur = 0
		else:
			cur += 1
	if cur > 0:
		gaps.append(cur)
	var max_gap: int = 0                             # [TIPO] evita ternario Variant
	if gaps.size() > 0:
		max_gap = int(gaps.max())

	# --- S(l) acumulado ---
	var S: Dictionary = {}
	for l in FREQ.keys():
		var lk: String = String(l)                   # [TIPO]
		S[lk] = 0.0

	for token_any in tokens:
		var token: Array = token_any as Array
		var L: int = token.size()
		if L == 0:
			continue
		var w_len: float = 1.0 / pow(float(L), max(alpha, 0.01))

		for pos_any in token:
			var pos: int = int(pos_any)
			if known[pos]:
				continue

			var left: String = ""
			if (pos - 1) >= 0:
				left = String(letters[pos - 1])      # [TIPO]

			var right: String = ""
			if (pos + 1) < letters.size():
				right = String(letters[pos + 1])     # [TIPO]

			# Candidatos C_i
			var C: Dictionary = {}

			if L == 1:
				C["A"] = true; C["Y"] = true; C["O"] = true; C["E"] = true
			elif L == 2:
				var mate: int = (int(token[1]) if int(token[0]) == pos else int(token[0]))
				var mate_known: bool = known[mate]
				var mate_is_vowel: bool = false
				if mate_known:
					mate_is_vowel = VOW.has(String(letters[mate]))
				if mate_known and not mate_is_vowel:
					for chv in VOW.keys():
						C[String(chv)] = true
				else:
					for chf in FREQ.keys():
						C[String(chf)] = true
			elif L == 3:
				var k_known: int = 0
				var cons: int = 0
				for p_any in token:
					var p: int = int(p_any)
					if known[p]:
						k_known += 1
						if not VOW.has(String(letters[p])):
							cons += 1
				if k_known >= 2 and cons >= 2:
					for chv2 in VOW.keys():
						C[String(chv2)] = true
				else:
					for chf2 in FREQ.keys():
						C[String(chf2)] = true
			else:
				for chf3 in FREQ.keys():
					C[String(chf3)] = true

			# Bonos contextuales
			var dig_bonus: Dictionary = {}
			var pairL: String = ""
			if left != "" and _is_letter(left):
				pairL = left + String(letters[pos])

			var pairR: String = ""
			if right != "" and _is_letter(right):
				pairR = String(letters[pos]) + right

			var near_digraph: bool = DIGR_OK.has(pairL) or DIGR_OK.has(pairR)

			for ch4 in FREQ.keys():
				var c4: String = String(ch4)          # [TIPO]
				dig_bonus[c4] = 1.0
				if near_digraph and VOW.has(c4):
					dig_bonus[c4] = 1.25

			var gap_bonus: Dictionary = {}
			for ch5 in FREQ.keys():
				var c5: String = String(ch5)          # [TIPO]
				gap_bonus[c5] = 1.0
				if max_gap >= 4 and VOW.has(c5):
					gap_bonus[c5] = 1.15

			var short_bonus: Dictionary = {}
			for ch6 in FREQ.keys():
				var c6: String = String(ch6)          # [TIPO]
				short_bonus[c6] = 1.0
				if (L == 2 or L == 3) and SHORT_HINT.has(c6):
					short_bonus[c6] = 1.10

			for ch7 in FREQ.keys():
				var c7: String = String(ch7)          # [TIPO]
				if not C.has(c7):
					continue
				var prior: float = float(FREQ[c7])
				var mult: float = w_len * prior * float(dig_bonus[c7]) * float(gap_bonus[c7]) * float(short_bonus[c7])
				S[c7] = float(S[c7]) + mult

	# No proponer ya descubiertas
	for ch8 in FREQ.keys():
		var c8: String = String(ch8)                 # [TIPO]
		if disc.has(c8):
			S[c8] = 0.0

	# P(l)
	var denom: float = 0.0                           # [TIPO] ← corrige tu línea 227
	for ch9 in S.keys():
		denom += float(S[String(ch9)])

	var P: Dictionary = {}
	if denom <= 0.0:
		for ch10 in FREQ.keys():
			var c10: String = String(ch10)           # [TIPO]
			P[c10] = float(FREQ[c10])
	else:
		for ch11 in S.keys():
			var c11: String = String(ch11)           # [TIPO]
			P[c11] = float(S[c11]) / denom

	# Entropía normalizada (base 27)
	var H: float = 0.0                                # [TIPO] ← corrige warnings 237+
	for ch12 in P.keys():
		var c12: String = String(ch12)                # [TIPO]
		var p: float = float(P[c12])
		if p > 0.0:
			H -= p * (log(p) / log(2.0))
	H /= (log(27.0) / log(2.0))
	var base_difficulty: float = clamp(H, 0.0, 1.0)    # [TIPO]

	# -------- NUEVOS MULTIPLICADORES --------
	var M_vowels: float = 1.0 - VOWELS_MAX_REDUCTION * vowel_coverage

	var coverage: float = 0.0
	if total_unique > 0:
		coverage = float(discovered_unique) / float(total_unique)
	var M_progress: float = 1.0 - PROGRESS_MAX_REDUCTION * pow(coverage, PROGRESS_EXP)

	var uniques_left: int = max(0, total_unique - discovered_unique)
	var floor_mult: float = MIN_FLOOR_WHEN_LEFT
	if uniques_left <= NEAR_SOLVED_LEFT:
		floor_mult = 0.0

	var combo: float = base_difficulty * M_vowels * M_progress
	var final01: float = maxf(floor_mult, combo)       # [TIPO] maxf para float
	var difficulty: float = clamp(final01, 0.0, 1.0)

	# Top-k sugerencias
	var pairs: Array = []
	for ch13 in P.keys():
		var c13: String = String(ch13)                # [TIPO]
		pairs.append([c13, float(P[c13])])

	pairs.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	var top: Array = []
	var limit: int = mini(k_top, pairs.size())        # [TIPO] mini para int
	for i in limit:
		top.append([String(pairs[i][0]), float(pairs[i][1])])

	return {"difficulty": difficulty, "top": top, "probs": P}










#class_name UtilsCLDifficulty
#extends Node
#
#
#
## UtilsCLDifficulty.gd — Godot 4.4.x
## Modelo "context-first" para calcular:
##   - P(l): probabilidad de que la próxima letra acertada sea l
##   - H: entropía normalizada de P(l)  → dificultad = H
## Fórmula por posición i:
##   S_i(l) = w_len * π(l) * 1[l ∈ C_i] * B_dígrafo(i,l) * B_brechaVocal(i,l) * B_corta(i,l)
## Donde:
##   π(l)           = prior por frecuencia del español (FREQ)
##   C_i            = conjunto de candidatos permitido por máscara y contexto local
##   w_len          = 1 / len(token)^α  (prioriza palabras cortas)
##   B_dígrafo      = bonus si i está junto a LL/RR/CC y l es vocal
##   B_brechaVocal  = bonus si una vocal en i rompe una brecha larga sin vocal
##   B_corta        = bonus a {Y,S,L,D} en tokens de 2–3 letras
##   S(l)           = ∑_i S_i(l)
##   P(l)           = S(l) / ∑_x S(x)
##   H              = entropía(P) / log2(27)  ∈ [0,1]
##   dificultad     = H
#
#
## --- Conjuntos y frecuencias --------------------------------------------------
#
## Conjunto de vocales (núcleo silábico)
#const VOW: Dictionary = {"A":true,"E":true,"I":true,"O":true,"U":true}
#
## Letras “diagnósticas” en palabras cortas (para B_corta)
#const SHORT_HINT: Dictionary = {"Y":true,"S":true,"L":true,"D":true}
#
## Dígrafos de vecindad (para B_dígrafo)
#const DIGR_OK: Dictionary = {"LL":true,"RR":true,"CC":true}
#
## π(l) — Prior por frecuencia de letras en español (aprox. normalizado)
#const FREQ: Dictionary = {
	#"E":0.1372,"A":0.1172,"O":0.0844,"S":0.0720,"N":0.0683,"R":0.0641,"I":0.0528,"L":0.0524,"D":0.0467,"T":0.0460,
	#"U":0.0455,"C":0.0387,"M":0.0308,"P":0.0289,"B":0.0149,"H":0.0118,"Q":0.0111,"Y":0.0109,"V":0.0105,"G":0.0100,
	#"F":0.0069,"J":0.0052,"Z":0.0047,"Ñ":0.0017,"X":0.0014,"K":0.0011,"W":0.0004
#}
#
## -------------------------------------------------------------------
## Evalúa la dificultad (entropía normalizada) dada una frase y
## un string de letras descubiertas. El string puede venir separado
## por comas, espacios o sin separadores (p.ej. "aeiou" o "a,e,i,o,u").
##
## Ejemplos:
##   evaluar_dificultad("LA CASA ROJA", "ae")      -> 0.23  (p.ej.)
##   evaluar_dificultad("EL RÍO GRANDE", "a,e,i")  -> 0.xx
## -------------------------------------------------------------------
#static func evaluar_dificultad(frase_original: String, letras_descubiertas: String, alpha: float = 1.0) -> float:
	## 1) Normaliza el string y lo parsea a un conjunto de letras válidas
	#var norm: String = _norm_text(letras_descubiertas)
	#var disc_arr: PackedStringArray = PackedStringArray()
	#var seen: Dictionary = {}
#
	## Acepta formatos: "A,E,I", "A E I", "AEI", "A|E|I"
	## Recorremos carácter a carácter y recogemos solo letras del alfabeto modelado.
	#for ch_char in norm:
		#var s: String = String(ch_char)
		#if _is_letter(s) and not seen.has(s):
			#seen[s] = true
			#disc_arr.append(s)
#
	## 2) Llama a la función principal con las letras descubiertas ya normalizadas
	#var res: Dictionary = next_letter_difficulty(frase_original, disc_arr, alpha, 3)
	#if not res.has("difficulty"):
		#return 0.0
	#return float(res["difficulty"]) * 100
	#
## --- Helpers estáticos --------------------------------------------------------
#
## Normaliza texto: mayúsculas y diacríticos a base (Á→A, etc.)
#static func _norm_text(s: String) -> String:
	#var t: String = s.to_upper()
	#t = t.replace("Á","A").replace("É","E").replace("Í","I").replace("Ó","O").replace("Ú","U").replace("Ü","U")
	#return t
#
## ¿Es letra del alfabeto modelado (según FREQ)?
#static func _is_letter(ch: String) -> bool:
	#return FREQ.has(ch)
#
## Tokeniza manteniendo índices al stream de letras:
## Devuelve [tokens, letters]
##   - letters: Array[String] solo con letras válidas (A..Z/Ñ)
##   - tokens:  Array[Array[int]]; cada token contiene índices a 'letters'
#static func _tokens_with_indices(text: String) -> Array:
	#var letters: Array[String] = []
	#for ch_char in text:
		#var s: String = String(ch_char)
		#s = _norm_text(s)
		#if _is_letter(s):
			#letters.append(s)
#
	#var idx_letters: int = 0
	#var tokens: Array = []       # Array[Array[int]] (no genérico estricto por sintaxis)
	#var current: Array[int] = []
	#for ch2 in text:
		#var ss: String = _norm_text(String(ch2))
		#if _is_letter(ss):
			#current.append(idx_letters)
			#idx_letters += 1
		#else:
			#if current.size() > 0:
				#tokens.append(current.duplicate())
				#current.clear()
	#if current.size() > 0:
		#tokens.append(current)
	#return [tokens, letters]  # [Array[Array[int]], Array[String]]
#
## --- Función principal con comentarios de variables de la fórmula -------------
#
#static func next_letter_difficulty(phrase: String, discovered: PackedStringArray, alpha: float = 1.0, k_top: int = 3) -> Dictionary:
	## text: frase normalizada (mayúsculas y sin diacríticos)
	#var text: String = _norm_text(phrase)
#
	## disc: {letra:true} → letras ya descubiertas (impacta en S(l)=0 para esas letras)
	#var disc: Dictionary = {}
	#for d in discovered:
		#disc[_norm_text(d)] = true
#
	## tokens / letters: ver helper; letters es el stream limpio, tokens apunta a posiciones de ese stream
	#var tk: Array = _tokens_with_indices(text)
	#var tokens: Array = tk[0]
	#var letters: Array = tk[1]
#
	## Caso trivial
	#if letters.is_empty():
		#return {"difficulty": 0.0, "top": [], "probs": {}}
#
	## known[i]: true si letters[i] ya fue descubierta
	#var known: Array[bool] = []
	#for ch in letters:
		#known.append(disc.has(ch))
#
	## --- Brechas vocálicas (para B_brechaVocal) ---
	#var gaps: Array[int] = []
	#var cur: int = 0
	#for i in range(letters.size()):
		#var ch2: String = letters[i]
		#if known[i] and VOW.has(ch2):
			#if cur > 0:
				#gaps.append(cur)
				#cur = 0
		#else:
			#cur += 1
	#if cur > 0:
		#gaps.append(cur)
	## max_gap: si es grande, proponer vocal sube puntuación vía B_brechaVocal(i,l)
	#var max_gap: int = (int(gaps.max()) if gaps.size() > 0 else 0)
#
	## S(l): acumulador global de puntuación (S(l) = ∑_i S_i(l))
	#var S: Dictionary = {}
	#for l in FREQ.keys():
		#S[l] = 0.0
#
	## Recorre cada token/palabra para construir C_i y multiplicadores de contexto
	#for token in tokens:
		#var L: int = int((token as Array).size())  # L = len(token)
		#if L == 0:
			#continue
#
		## w_len = 1 / L^α → prioriza palabras cortas (término de la fórmula)
		#var w_len: float = 1.0 / pow(float(L), max(alpha, 0.01))
#
		## Posiciones desconocidas (i)
		#for pos_any in token:
			#var pos: int = int(pos_any)
			#if known[pos]:
				#continue
#
			## left/right: vecinos inmediatos (para B_dígrafo)
			#var left: String  = (letters[pos - 1] if (pos - 1) >= 0 else "")
			#var right: String = (letters[pos + 1] if (pos + 1) < letters.size() else "")
#
			## --- C_i: conjunto de candidatos permitidos → implementa 1[l ∈ C_i] ---
			#var C: Dictionary = {}
			#if L == 1:
				#for ch3 in ["A", "Y", "O", "E"]:
					#C[ch3] = true
			#elif L == 2:
				#var mate: int = (int(token[1]) if int(token[0]) == pos else int(token[0]))
				#var mate_known: bool = known[mate]
				#var mate_is_vowel: bool = mate_known and VOW.has(letters[mate])
				#if mate_known and not mate_is_vowel:
					## compañero = consonante conocida → forzamos vocal
					#for chv in VOW.keys():
						#C[chv] = true
				#else:
					#for chf in FREQ.keys():
						#C[chf] = true
			#elif L == 3:
				#var k: int = 0      # nº posiciones conocidas
				#var cons: int = 0   # nº de consonantes conocidas
				#for p_any in token:
					#var p: int = int(p_any)
					#if known[p]:
						#k += 1
						#if not VOW.has(letters[p]):
							#cons += 1
				#if k >= 2 and cons >= 2:
					#for chv2 in VOW.keys():
						#C[chv2] = true
				#else:
					#for chf2 in FREQ.keys():
						#C[chf2] = true
			#else:
				#for chf3 in FREQ.keys():
					#C[chf3] = true
#
			## --- B_dígrafo(i,l): bonus si hay LL/RR/CC pegado y l es vocal ---
			#var dig_bonus: Dictionary = {}
			#var pairL: String = (left + String(letters[pos])) if (left != "" and _is_letter(left)) else ""
			#var pairR: String = (String(letters[pos]) + right) if (right != "" and _is_letter(right)) else ""
			#var near_digraph: bool = DIGR_OK.has(pairL) or DIGR_OK.has(pairR)
			#for ch4 in FREQ.keys():
				#dig_bonus[ch4] = 1.0
				#if near_digraph and VOW.has(ch4):
					#dig_bonus[ch4] = 1.25
#
			## --- B_brechaVocal(i,l): bonus si hay brecha larga sin vocal (p.ej. max_gap ≥ 4) ---
			#var gap_bonus: Dictionary = {}
			#for ch5 in FREQ.keys():
				#gap_bonus[ch5] = 1.0
				#if max_gap >= 4 and VOW.has(ch5):
					#gap_bonus[ch5] = 1.15
#
			## --- B_corta(i,l): bonus a {Y,S,L,D} en tokens de 2–3 letras ---
			#var short_bonus: Dictionary = {}
			#for ch6 in FREQ.keys():
				#short_bonus[ch6] = 1.0
				#if (L == 2 or L == 3) and SHORT_HINT.has(ch6):
					#short_bonus[ch6] = 1.10
#
			## --- S_i(l): contribución posicional → se suma a S(l) ---
			#for ch7 in FREQ.keys():
				#if not C.has(ch7):
					#continue
				#var prior: float = float(FREQ[ch7])  # π(l)
				#var mult: float = w_len * prior * float(dig_bonus[ch7]) * float(gap_bonus[ch7]) * float(short_bonus[ch7])
				#S[ch7] = float(S[ch7]) + mult  # S(l) = ∑_i S_i(l)
#
	## No proponemos letras ya descubiertas → S(l)=0
	#for ch8 in FREQ.keys():
		#if disc.has(ch8):
			#S[ch8] = 0.0
#
	## P(l) = S(l) / ∑_x S(x)
	#var denom: float = 0.0
	#for ch9 in S.keys():
		#denom += float(S[ch9])
	#var P: Dictionary = {}
	#if denom <= 0.0:
		## Sin evidencia contextual: fallback al prior π(l)
		#for ch10 in FREQ.keys():
			#P[ch10] = float(FREQ[ch10])
	#else:
		#for ch11 in S.keys():
			#P[ch11] = float(S[ch11]) / denom
#
	## H = -∑ P(l) log2 P(l), normalizado por log2(27)
	#var H: float = 0.0
	#for ch12 in P.keys():
		#var p: float = float(P[ch12])
		#if p > 0.0:
			#H -= p * (log(p) / log(2.0))
	#H /= (log(27.0) / log(2.0))
	#var difficulty: float = clamp(H, 0.0, 1.0)  # dificultad = H
#
	## Top-k sugerencias
	#var pairs: Array = []
	#for ch13 in P.keys():
		#pairs.append([ch13, float(P[ch13])])
	#pairs.sort_custom(func(a, b): return a[1] > b[1])
	#var top: Array = []
	#var limit: int = min(k_top, pairs.size())
	#for i in limit:
		#top.append([pairs[i][0], float(pairs[i][1])])
#
	#return {"difficulty": difficulty, "top": top, "probs": P}








## res://addons/cifraletra/AnalizadorCL.gd
#extends Node
### Analizador CifraLetra — Autoload (Godot 4.4.x)
### - Normaliza (MAYÚSCULAS, quita tildes, preserva Ñ)
### - Calcula frecuencias sobre texto FILTRADO (quitando descubiertas)
### - Estima dificultad (0–10) con: DL gaussiano, DR^2, DU = U/T y puerta G (si U<=1 ⇒ ~0)
#
## ====== Parámetros del modelo de dificultad ======
#const ALFABETO_TOTAL := 27 # A-Z + Ñ
#const LC := 125.0          # Longitud “cómoda” para el gaussiano
#const SIGMA := 50.0
#const W_L := 0.30
#const W_R := 0.40
#const W_U := 0.30
#
## ================== API ==================
### Llama a esta función desde tu juego:
###   var dif := AnalizadorCL.evaluar_dificultad("frase...", "AEIOUÑ...")
### Devuelve: dificultad (float 0..10). Imprime el resto en consola.
#func evaluar_dificultad(frase_original: String, letras_descubiertas: String) -> float:
	## 1) Normalización
	#var solo: String = _normalizar_solo_letras(frase_original)
	#var desc: String = _normalizar_set(letras_descubiertas)
#
	## 2) Texto filtrado (quitando las letras ya descubiertas)
	#var solo_filtrado := solo if desc.is_empty() else _remover_clase(solo, desc)
#
	## 3) Frecuencias (del texto filtrado)
	#var freq := _contar_letras(solo_filtrado)
	#var ordenado := _ordenar_frecuencias(freq)
	#var total := solo_filtrado.length()
#
	## 4) Variables para dificultad
	#var L: int = solo.length()                    # longitud total normalizada
	#var D: int = desc.length()                    # letras descubiertas (únicas, ya normalizadas)
	#var set_frase := _set_from_string(solo)       # conjunto de letras presentes
	#var T: int = set_frase.size()                 # número de letras únicas en la frase
	#var set_desc := _set_from_string(desc)
	#var U: int = 0                                # letras únicas aún desconocidas
	#for ch in set_frase.keys():
		#if not set_desc.has(ch):
			#U += 1
#
	## 5) Estimación
	#var dif_data := _estimar_dificultad(L, ALFABETO_TOTAL, D, T, U)
#
	## 6) Logging en consola
	#_log_header("Analizador CifraLetra")
	#_log_kv("Frase (normalizada)", solo)
	#_log_kv("Letras descubiertas (set ordenado)", (desc if not desc.is_empty() else "—"))
	#_log_kv("Texto filtrado (para %)", solo_filtrado)
	#_print_tabla_frecuencias(ordenado, total)
#
	## Variables y parciales
	#print("--- Variables y parciales ---")
	#_log_kv("L (longitud)", str(L))
	#_log_kv("A (alfabeto total)", str(ALFABETO_TOTAL))
	#_log_kv("D (descubiertas)", str(D))
	#_log_kv("R (restantes en alfabeto)", str(dif_data.R))
	#_log_kv("T (letras únicas en frase)", str(T))
	#_log_kv("U (únicas por descubrir)", str(U))
	#_log_kv("DL (gauss)", _f2(dif_data.DL, 4))
	#_log_kv("DR^2", _f2(dif_data.DR, 4))
	#_log_kv("DU = U/T", _f2(dif_data.DU, 4))
	#_log_kv("G (puerta)", _f2(dif_data.G, 4))
#
	## Resultado final
	#print("--- Resultado ---")
	#_log_kv("Dificultad (0..10)", _f2(dif_data.dif, 2))
	#print("")
#
	#return dif_data.dif
#
## ================== Lógica ==================
#func _quitar_tildes_vocales(s: String) -> String:
	#s = s.to_upper()
	#s = s.replace("Á","A").replace("À","A").replace("Â","A").replace("Ã","A").replace("Ä","A")
	#s = s.replace("É","E").replace("È","E").replace("Ê","E").replace("Ë","E")
	#s = s.replace("Í","I").replace("Ì","I").replace("Î","I").replace("Ï","I")
	#s = s.replace("Ó","O").replace("Ò","O").replace("Ô","O").replace("Õ","O").replace("Ö","O")
	#s = s.replace("Ú","U").replace("Ù","U").replace("Û","U").replace("Ü","U")
	#return s
#
#func _normalizar_solo_letras(s: String) -> String:
	#s = _quitar_tildes_vocales(s)
	#var out := PackedStringArray()
	#for i in s.length():
		#var ch := s[i]
		#var code := ch.unicode_at(0)
		#var is_AZ := (code >= 65 and code <= 90) # A..Z
		#if is_AZ or ch == "Ñ":
			#out.append(ch)
	#return "".join(out)
#
#func _normalizar_set(s: String) -> String:
	#var norm := _normalizar_solo_letras(s)
	#var setd := _set_from_string(norm) # Dictionary como conjunto
	#var keys := PackedStringArray(setd.keys())
	#keys.sort()
	#return "".join(keys)
#
#func _set_from_string(s: String) -> Dictionary:
	#var st: Dictionary = {}
	#for i in s.length():
		#var ch := s[i]
		#st[ch] = true
	#return st
#
#func _remover_clase(s: String, clase: String) -> String:
	#var ban := _set_from_string(clase)
	#var out := PackedStringArray()
	#for i in s.length():
		#var ch := s[i]
		#if not ban.has(ch):
			#out.append(ch)
	#return "".join(out)
#
#func _contar_letras(s: String) -> Dictionary:
	#var d := {}
	#for i in s.length():
		#var ch := s[i]
		#d[ch] = (d.get(ch, 0) as int) + 1
	#return d
#
#func _ordenar_frecuencias(freq: Dictionary) -> Array:
	#var arr: Array = []
	#for k in freq.keys():
		#arr.append([k, freq[k]])
	## Comparador: primero por cuenta desc, luego por letra asc
	#arr.sort_custom(func(a, b):
		#if a[1] == b[1]:
			#return String(a[0]) < String(b[0])  # asc por letra
		#return int(a[1]) > int(b[1])           # desc por cuenta
	#)
	#return arr
#
## ------ Dificultad ------
#func _estimar_dificultad(L: int, A: int, D: int, T: int, U: int) -> Dictionary:
	#var DL := 1.0 - exp(-pow(float(L) - LC, 2.0) / (2.0 * pow(SIGMA, 2.0)))
	#var R := maxi(1, A - D)
	#var DR := pow(float(R - 1) / float(A - 1), 2.0)
	#var DU := 0.0 if T == 0 else float(U) / float(T)
	#var G := 0.0 if T <= 1 else _clamp01((float(U) - 1.0) / float(T - 1))
	#var core := (W_L * DL + W_R * DR + W_U * DU) / (W_L + W_R + W_U)
	#var dif := 10.0 * G * core
	#return {
		#"dif": dif,
		#"DL": DL,
		#"DR": DR,
		#"DU": DU,
		#"R": R,
		#"G": G
	#}
#
## ================== Utilidades de logging / formato ==================
#func _print_tabla_frecuencias(ordenado: Array, total: int) -> void:
	#print("--- Frecuencias (texto filtrado) ---")
	#print("Letra   Cuenta     %")
	#for row in ordenado:
		#var letra: String = row[0]
		#var cnt: int = row[1]
		#var pct := (float(cnt) * 100.0 / float(total)) if total > 0 else 0.0
		#print("%-6s  %-9d  %6.2f%%" % [letra, cnt, pct])
#
#func _log_header(titulo: String) -> void:
	#print("\n==================== %s ====================" % titulo)
#
#func _log_kv(k: String, v: String) -> void:
	#print("%s: %s" % [k, v])
#
#func _clamp01(x: float) -> float:
	#return clampf(x, 0.0, 1.0)
#
#func _f2(x: float, n: int = 2) -> String:
	#return String.num(x, n)
