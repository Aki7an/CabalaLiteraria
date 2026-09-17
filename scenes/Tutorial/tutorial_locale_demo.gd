extends Object

const VOWELS := ["A", "E", "I", "O", "U"]


static func demo_word() -> String:
	var loc := _locale()
	var raw := _tr("TutDemoWord", "")
	if raw.is_empty() or raw == "TutDemoWord":
		raw = _tr("CipherLetter", "")
	if raw.is_empty() or raw == "CipherLetter":
		raw = _demo_word_fallback(loc)
	var normalized := GameManager.normalizar_frase_idioma(raw, loc)
	var word := ""
	for i in normalized.length():
		var ch := normalized.substr(i, 1)
		if ch >= "A" and ch <= "Z":
			word += ch
		elif ch == "Ñ":
			word += ch
	return word if not word.is_empty() else _demo_word_fallback(loc)


static func whale_word() -> String:
	var loc := _locale()
	var raw := _tr("TutWhaleWord", "")
	if raw.is_empty() or raw == "TutWhaleWord":
		raw = _whale_fallback(loc)
	var normalized := GameManager.normalizar_frase_idioma(raw, loc)
	var word := ""
	for i in normalized.length():
		var ch := normalized.substr(i, 1)
		if ch >= "A" and ch <= "Z":
			word += ch
	return word if not word.is_empty() else _whale_fallback(loc)


static func alphabet() -> Array:
	return GameManager.get_letters_for_lang(_locale())


static func numbers_for(word: String) -> PackedStringArray:
	var map := {}
	var next_n := 1
	var out := PackedStringArray()
	for i in word.length():
		var ch := word.substr(i, 1)
		if not map.has(ch):
			map[ch] = str(next_n)
			next_n += 1
		out.append(str(map[ch]))
	return out


static func repeating_letters(word: String) -> PackedStringArray:
	var counts := {}
	for i in word.length():
		var ch := word.substr(i, 1)
		counts[ch] = int(counts.get(ch, 0)) + 1
	var vowels := PackedStringArray()
	var rest := PackedStringArray()
	for ch in counts.keys():
		if int(counts[ch]) < 2:
			continue
		if VOWELS.has(ch):
			vowels.append(str(ch))
		else:
			rest.append(str(ch))
	var out := PackedStringArray()
	out.append_array(vowels)
	out.append_array(rest)
	return out


static func tiles_with_letter(tiles: Array[VBoxContainer], letter: String) -> Array[VBoxContainer]:
	var out: Array[VBoxContainer] = []
	for tile in tiles:
		if _meta_letter(tile) == letter:
			out.append(tile)
	return out


static func collect_tiles(row: Node) -> Array[VBoxContainer]:
	var tiles: Array[VBoxContainer] = []
	if row == null:
		return tiles
	for child in row.get_children():
		if child is VBoxContainer and letter_label(child as VBoxContainer) != null:
			tiles.append(child as VBoxContainer)
	return tiles


static func fill_phrase(row: Node, word: String, empty_letter := "", show_all := true) -> Array[VBoxContainer]:
	var tiles := _ensure_tile_count(row, word.length())
	var nums := numbers_for(word)
	for i in tiles.size():
		var ch := word.substr(i, 1)
		var show := show_all and ch != empty_letter
		_set_tile(tiles[i], nums[i], ch, show)
		tiles[i].set_meta("demo_letter", ch)
		tiles[i].set_meta("demo_number", nums[i])
	return tiles


static func fill_whale(row: Node, word: String, normal: StyleBoxFlat, revealed_style: StyleBoxFlat) -> void:
	var tiles := _ensure_tile_count(row, word.length())
	var nums := numbers_for(word)
	var show := _whale_revealed(word)
	for i in tiles.size():
		var ch := word.substr(i, 1)
		_set_tile(tiles[i], nums[i], ch, show[i])
		var panel := tile_panel(tiles[i])
		if panel and normal and revealed_style:
			panel.add_theme_stylebox_override("panel", revealed_style if show[i] else normal)


static func wrong_letter(correct: String, word: String) -> String:
	var alpha := alphabet()
	var loc := _locale()
	if loc == "es" and alpha.has("Y") and correct != "Y":
		return "Y"
	var candidates := ["O", "B", "D", "G", "H", "M", "N", "S", "U", "P", "Y"]
	for ch in candidates:
		if ch == correct:
			continue
		if word.contains(ch):
			continue
		if alpha.has(ch):
			return ch
	for ch in alpha:
		if ch != correct:
			return str(ch)
	return "B"


static func find_key(keyboard: Node, letter: String) -> Panel:
	if keyboard == null or letter.is_empty():
		return null
	for node in keyboard.find_children("*", "Panel", true, false):
		var panel := node as Panel
		if panel == null:
			continue
		var lbl := panel.get_node_or_null("Letter") as Label
		if lbl and lbl.text.to_upper() == letter:
			return panel
	return null


static func sync_keyboard(keyboard: Node) -> void:
	if keyboard == null:
		return
	var alpha := alphabet()
	for node in keyboard.find_children("*", "Panel", true, false):
		var panel := node as Panel
		if panel == null:
			continue
		var lbl := panel.get_node_or_null("Letter") as Label
		if lbl == null:
			continue
		panel.visible = alpha.has(lbl.text.to_upper())


static func letter_label(tile: VBoxContainer) -> Label:
	if tile == null:
		return null
	var nested := tile.get_node_or_null("Panel/HBoxContainer/Letter")
	if nested is Label:
		return nested as Label
	var direct := tile.get_node_or_null("Panel/Letter")
	return direct as Label


static func number_label(tile: VBoxContainer) -> Label:
	if tile == null:
		return null
	var nested := tile.get_node_or_null("Panel/HBoxContainer/Number")
	if nested is Label:
		return nested as Label
	return tile.get_node_or_null("Panel/Number") as Label


static func tile_panel(tile: VBoxContainer) -> Panel:
	if tile == null:
		return null
	return tile.get_node_or_null("Panel") as Panel


static func _locale() -> String:
	return GameManager.locale_code()


static func _tr(key: String, fallback: String) -> String:
	var value := TranslationServer.translate(key)
	if value == key or value.is_empty():
		return fallback
	return value


static func _demo_word_fallback(loc: String) -> String:
	match loc:
		"en":
			return "CIPHERLETTER"
		"de":
			return "ZAHLBUCHSTABE"
		"fr":
			return "LETTRECHIFFREE"
		"eu":
			return "ZIFRATULETRA"
		"it":
			return "CIFRALETTERA"
		"pt":
			return "CIFRALETRA"
		_:
			return "CIFRALETRA"


static func _whale_fallback(loc: String) -> String:
	match loc:
		"en":
			return "WHALE"
		"de":
			return "WAL"
		"fr":
			return "BALEINE"
		"eu":
			return "BALEA"
		"it":
			return "BALENA"
		"pt":
			return "BALEIA"
		_:
			return "BALLENA"


static func _meta_letter(tile: VBoxContainer) -> String:
	if tile.has_meta("demo_letter"):
		return str(tile.get_meta("demo_letter"))
	var lbl := letter_label(tile)
	return lbl.text if lbl else ""


static func _set_tile(tile: VBoxContainer, number: String, letter: String, show_letter: bool) -> void:
	var num := number_label(tile)
	var lbl := letter_label(tile)
	if num:
		num.text = number
	if lbl:
		lbl.text = letter if show_letter else ""


static func _ensure_tile_count(row: Node, count: int) -> Array[VBoxContainer]:
	var tiles := collect_tiles(row)
	if row == null or count <= 0:
		return tiles
	if tiles.is_empty():
		return tiles
	var template := tiles[tiles.size() - 1]
	while tiles.size() < count:
		var extra := template.duplicate() as VBoxContainer
		extra.visible = true
		extra.unique_name_in_owner = false
		extra.name = "Tile%d" % tiles.size()
		row.add_child(extra)
		tiles.append(extra)
	for i in tiles.size():
		var on := i < count
		tiles[i].visible = on
		var after_i := tiles[i].get_index() + 1
		if after_i < row.get_child_count():
			var after := row.get_child(after_i)
			if after is Control and not (after is VBoxContainer):
				var gap := after as Control
				if gap.custom_minimum_size.x <= 12.0:
					gap.visible = on and i < count - 1
	var visible_tiles: Array[VBoxContainer] = []
	for i in mini(count, tiles.size()):
		visible_tiles.append(tiles[i])
	return visible_tiles


static func _whale_revealed(word: String) -> Array[bool]:
	var n := word.length()
	var hide_n := 3 if n >= 6 else (2 if n >= 3 else 0)
	hide_n = mini(hide_n, n - 1)
	var show: Array[bool] = []
	show.resize(n)
	for i in n:
		show[i] = VOWELS.has(word.substr(i, 1))
	var shown := 0
	for i in n:
		if show[i]:
			shown += 1
	var need := n - hide_n
	var i := n - 1
	while shown < need and i >= 0:
		if not show[i]:
			show[i] = true
			shown += 1
		i -= 1
	i = 0
	while shown > need and i < n:
		if show[i] and not VOWELS.has(word.substr(i, 1)):
			show[i] = false
			shown -= 1
		i += 1
	i = 0
	while shown > need and i < n - 1:
		if show[i]:
			show[i] = false
			shown -= 1
		i += 1
	return show
