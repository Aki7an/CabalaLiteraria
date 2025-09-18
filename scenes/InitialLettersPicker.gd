class_name InitialLettersPicker
extends Node

# ----------------------------------------------
# Parámetros de rendimiento/calibración
# ----------------------------------------------
const MAX_VOWEL_CANDIDATES: int = 5   # top-N vocales por frecuencia en la frase
const MAX_CONS_CANDIDATES: int  = 10  # top-N consonantes por frecuencia en la frase
const MAX_EVALS: int = 200            # freno de seguridad global

# Objetivos por nivel (0..100, según Analyzer.evaluar_dificultad)
const TARGET_BY_LEVEL := {1: 50.0, 2: 65.0, 3: 100.0}
# Reglas: (num_vowels, num_consonants)
const PICK_RULES := {1: Vector2i(2, 5), 2: Vector2i(1, 3), 3: Vector2i(0, 0)}
# Tolerancia relativa (±3%)
const TOL_PCT: float = 0.03

# Vocales
const VOWELS := {"A": true, "E": true, "I": true, "O": true, "U": true}

# -------------------------
# API principal
# -------------------------
## Devuelve un String con las letras iniciales (p.ej. "AEISNRL").
## Early-exit: en cuanto una combinación cae dentro de ±3% del objetivo, se devuelve.
static func pick_initials_for_level(frase: String, level: int) -> String:
	level = clampi(level, 1, 3)
	var rule: Vector2i = PICK_RULES[level]
	var need_v: int = rule.x
	var need_c: int = rule.y

	# Difícil (3): sin letras
	if need_v == 0 and need_c == 0:
		return ""

	# Preparar candidatos
	var norm_phrase: String = _norm(frase)
	var counts: Dictionary = _count_letters(norm_phrase)  # letra->frecuencia

	var vowels_all := PackedStringArray()
	var cons_all   := PackedStringArray()
	for k in counts.keys():
		var ch: String = String(k)
		if VOWELS.has(ch): vowels_all.append(ch)
		else: cons_all.append(ch)

	vowels_all = _sort_by_count_desc(vowels_all, counts)
	cons_all   = _sort_by_count_desc(cons_all, counts)

	if vowels_all.size() > MAX_VOWEL_CANDIDATES: vowels_all = vowels_all.slice(0, MAX_VOWEL_CANDIDATES)
	if cons_all.size()   > MAX_CONS_CANDIDATES:  cons_all   = cons_all.slice(0, MAX_CONS_CANDIDATES)

	if vowels_all.size() < need_v: vowels_all = _ensure_pool_vowels(vowels_all)
	if cons_all.size()   < need_c: cons_all   = _ensure_pool_cons(cons_all)

	var target: float = float(TARGET_BY_LEVEL[level])
	var tol_abs: float = max(1.0, target * TOL_PCT)  # mínimo 1 punto
	var evals: int = 0

	# --- Selección codiciosa de vocales ---
	var chosen := PackedStringArray()
	if need_v == 1:
		var best_v := _pick_best_single(frase, target, tol_abs, vowels_all, chosen, evals)
		evals = best_v.evals
		if best_v.hit: return _join_letters(best_v.chosen)
		chosen = best_v.chosen
	elif need_v == 2:
		# paso 1: mejor vocal
		var first := _pick_best_single(frase, target, tol_abs, vowels_all, chosen, evals)
		evals = first.evals
		if first.hit: return _join_letters(first.chosen)
		chosen = first.chosen
		# paso 2: segunda vocal (sobre las restantes)
		var remaining_v := _without(vowels_all, chosen)
		var second := _pick_best_single(frase, target, tol_abs, remaining_v, chosen, evals)
		evals = second.evals
		if second.hit: return _join_letters(second.chosen)
		chosen = second.chosen

	# --- Selección codiciosa de consonantes ---
	if need_c > 0:
		var picked := _pick_greedy_k(frase, target, tol_abs, cons_all, chosen, need_c, evals)
		# picked siempre devuelve algo; si dio hit ya salió antes desde dentro
		chosen = picked.chosen
		evals = picked.evals

	return _join_letters(chosen)

# -------------------------
# Greedy helpers (rápidos)
# -------------------------
# Elige UN candidato de "pool" (no incluido aún en "base") que acerque más al target.
# Early-exit si cae dentro de ±tol_abs. Devuelve {chosen: PackedStringArray, hit: bool, evals: int}
static func _pick_best_single(frase: String, target: float, tol_abs: float, pool: PackedStringArray, base: PackedStringArray, evals: int) -> Dictionary:
	var best_diff: float = 1e9
	var best_pick: String = ""
	var chosen := base.duplicate()
	for ch in pool:
		if evals >= MAX_EVALS: break
		var cand := base.duplicate(); cand.append(ch)
		var score: float = Analyzer.evaluar_dificultad(frase, _join_letters(cand))
		evals += 1
		var diff := absf(score - target)
		if diff <= tol_abs:
			chosen = cand
			return {"chosen": chosen, "hit": true, "evals": evals}
		if diff < best_diff:
			best_diff = diff
			best_pick = ch
	if best_pick != "":
		chosen.append(best_pick)
	return {"chosen": chosen, "hit": false, "evals": evals}

# Elige K elementos de "pool" añadiéndolos de uno en uno de forma greedy.
# Early-exit si en cualquier paso cae dentro de ±tol_abs.
static func _pick_greedy_k(frase: String, target: float, tol_abs: float, pool: PackedStringArray, base: PackedStringArray, k: int, evals: int) -> Dictionary:
	var chosen := base.duplicate()
	var remaining := _without(pool, chosen)
	for _i in k:
		if remaining.is_empty(): break
		var best_diff: float = 1e9
		var best_idx: int = -1
		for idx in remaining.size():
			if evals >= MAX_EVALS: break
			var cand := chosen.duplicate(); cand.append(remaining[idx])
			var score: float = Analyzer.evaluar_dificultad(frase, _join_letters(cand))
			evals += 1
			var diff := absf(score - target)
			if diff <= tol_abs:
				chosen = cand
				return {"chosen": chosen, "evals": evals}
			if diff < best_diff:
				best_diff = diff
				best_idx = idx
		if best_idx >= 0:
			chosen.append(remaining[best_idx])
			remaining.remove_at(best_idx)
		else:
			break
	return {"chosen": chosen, "evals": evals}

# -------------------------
# Helpers utilitarios
# -------------------------
static func _without(items: PackedStringArray, ban: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for ch in items:
		if ban.find(ch) == -1:
			out.append(ch)
	return out

static func _norm(s: String) -> String:
	var t := s.to_upper()
	t = t.replace("Á","A").replace("À","A").replace("Â","A").replace("Ã","A").replace("Ä","A")
	t = t.replace("É","E").replace("È","E").replace("Ê","E").replace("Ë","E")
	t = t.replace("Í","I").replace("Ì","I").replace("Î","I").replace("Ï","I")
	t = t.replace("Ó","O").replace("Ò","O").replace("Ô","O").replace("Õ","O").replace("Ö","O")
	t = t.replace("Ú","U").replace("Ù","U").replace("Û","U").replace("Ü","U")
	return t

static func _is_letter(ch: String) -> bool:
	var code := ch.unicode_at(0)
	return (code >= 65 and code <= 90) or ch == "Ñ"

static func _count_letters(s: String) -> Dictionary:
	var d := {}
	for i in s.length():
		var ch := s[i]
		if _is_letter(ch):
			d[ch] = int(d.get(ch, 0)) + 1
	return d

static func _sort_by_count_desc(arr: PackedStringArray, counts: Dictionary) -> PackedStringArray:
	var list: Array = []
	for ch in arr:
		list.append([String(ch), int(counts.get(ch, 0))])
	list.sort_custom(func(a, b):
		return (int(a[1]) > int(b[1])) if (a[1] != b[1]) else (String(a[0]) < String(b[0]))
	)
	var out := PackedStringArray()
	for row in list:
		out.append(String(row[0]))
	return out

static func _ensure_pool_vowels(pool: PackedStringArray) -> PackedStringArray:
	var all := PackedStringArray(["A","E","I","O","U"])
	for v in all:
		if pool.find(v) == -1:
			pool.append(v)
	return pool

static func _ensure_pool_cons(pool: PackedStringArray) -> PackedStringArray:
	var base := PackedStringArray(["B","C","D","F","G","H","J","K","L","M","N","Ñ","P","Q","R","S","T","V","W","X","Y","Z"])
	for c in base:
		if pool.find(c) == -1:
			pool.append(c)
	return pool

static func _join_letters(arr: PackedStringArray) -> String:
	# También valdría: return "".join(arr)
	var s: String = ""
	for ch in arr:
		s += String(ch)
	return s
