extends Control

const PHONE_SIZE := Vector2(1206, 2622)
const VIDEO := Vector2(1920, 1080)
const FIT_SHIFT := Vector2(0, 22)
const BUTTONS_LOCAL_Y := 312.0
const BUTTONS_HEIGHT := 188.0
const PANEL_UP_HEIGHT := 548.0
const BOARD_HEIGHT := 1191.0
const KEY_HEIGHT := 582.0
const COLORS_HEIGHT := 286.0
const TOP_MARGIN := 80.0
const GAP_AFTER_BUTTONS := 20.0
const GAP_BEFORE_COLORS := 16.0
const GAP_BEFORE_KEYS := 12.0
const BOARD_TOP := TOP_MARGIN + BUTTONS_HEIGHT + GAP_AFTER_BUTTONS
const BOARD_RECT := Rect2(18, BOARD_TOP, 1170, BOARD_HEIGHT)
const RIGHT_MARGIN := 36.0


func _enter_tree() -> void:
	custom_minimum_size = PHONE_SIZE
	size = PHONE_SIZE
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	show_game_background()
	_layout_compact_chrome()
	hide_chrome()
	_freeze_board_canvas()
	pin_board_canvas()


func has_board_cells() -> bool:
	for node in get_tree().get_nodes_in_group("Celda"):
		if node is Celda and is_ancestor_of(node):
			return true
	return false


func _freeze_board_canvas() -> void:
	var canvas := get_node_or_null("BoardFrame/CanvasJuego") as Control
	if canvas == null:
		return
	for rect_name in ["ColorRectDown", "ColorRectUp"]:
		var rect := canvas.get_node_or_null(rect_name) as CanvasItem
		if rect == null:
			continue
		rect.visible = false
		rect.set_process(false)
		rect.process_mode = Node.PROCESS_MODE_DISABLED


func pin_board_canvas() -> void:
	var canvas := get_node_or_null("BoardFrame/CanvasJuego") as Control
	if canvas == null:
		return
	canvas.visible = true
	canvas.modulate.a = 1.0
	canvas.scale = Vector2.ONE
	if canvas.has_method("reset_zoom_scale"):
		canvas.reset_zoom_scale()
	var rest_y := canvas.offset_top
	if canvas.get("_rest_y") != null and not is_zero_approx(float(canvas._rest_y)):
		rest_y = float(canvas._rest_y)
	canvas.position.y = rest_y
	var board := get_node_or_null("BoardFrame") as CanvasItem
	if board:
		board.visible = true
		board.modulate.a = 1.0


func reload_board() -> void:
	var canvas := get_node_or_null("BoardFrame/CanvasJuego")
	if canvas != null and canvas.has_method("rebuild_puzzle_board"):
		await canvas.rebuild_puzzle_board()
	_freeze_board_canvas()
	pin_board_canvas()
	hide_chrome()
	show_board_numbers()


func show_board_phrase() -> void:
	for node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda or not is_ancestor_of(node):
			continue
		var cell := node as Celda
		var letter := str(cell.letra)
		if cell.label_letra:
			if cell.numero >= 100 or letter.strip_edges() == "":
				continue
			cell.label_letra.text = letter
			cell.label_letra.visible = true
		if cell.label_numero and cell.numero < 100:
			cell.label_numero.visible = true
			cell.label_numero.text = str(cell.numero)


func show_board_numbers() -> void:
	for node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		if not is_ancestor_of(node):
			continue
		var cell := node as Celda
		if cell.numero >= 100:
			continue
		if cell.label_numero:
			cell.label_numero.visible = true
			cell.label_numero.text = str(cell.numero)
		if cell.label_letra and not cell.es_regalo_inicial:
			cell.label_letra.visible = false


func show_game_background() -> void:
	var background := get_node_or_null("Background") as CanvasItem
	if background:
		background.visible = true
		background.modulate.a = 1.0
	clip_contents = true


func _layout_compact_chrome() -> void:
	var buttons_top := TOP_MARGIN
	var panel_up := get_node_or_null("PanelUP") as Control
	if panel_up:
		var panel_y := buttons_top - BUTTONS_LOCAL_Y
		panel_up.position = Vector2(panel_up.position.x, panel_y)
		panel_up.size.y = PANEL_UP_HEIGHT
	var board := get_node_or_null("BoardFrame") as Control
	if board:
		var board_y := buttons_top + BUTTONS_HEIGHT + GAP_AFTER_BUTTONS
		board.position = Vector2(board.position.x, board_y)
		board.size.y = BOARD_HEIGHT
	var after_board := (board.position.y + board.size.y) if board else (buttons_top + BUTTONS_HEIGHT + GAP_AFTER_BUTTONS + BOARD_HEIGHT)
	var colors := get_node_or_null("PanelColors") as Control
	if colors:
		colors.position = Vector2(colors.position.x, after_board + GAP_BEFORE_COLORS)
		colors.size.y = COLORS_HEIGHT
		colors.visible = false
		colors.modulate.a = 0.0
	var keys := get_node_or_null("PanelLetras") as Control
	if keys:
		var keys_y := after_board + GAP_BEFORE_COLORS + COLORS_HEIGHT + GAP_BEFORE_KEYS
		if colors:
			keys_y = colors.position.y + colors.size.y + GAP_BEFORE_KEYS
		keys.position = Vector2(keys.position.x, keys_y)
		keys.size.y = KEY_HEIGHT
	var header := get_node_or_null("PanelUP/GameHeader") as CanvasItem
	if header:
		header.visible = false
		header.modulate.a = 0.0


func show_play_chrome() -> void:
	for path in [
		"PanelUP/ButtonReveal",
		"PanelUP/ButtonHint",
		"PanelUP/ButtonTheme",
		"PanelColors",
		"PanelLetras",
		"BoardFrame",
	]:
		var node := get_node_or_null(path) as CanvasItem
		if node:
			node.visible = true
			node.modulate.a = 1.0
	var header := get_node_or_null("PanelUP/GameHeader") as CanvasItem
	if header:
		header.visible = false
		header.modulate.a = 0.0
	var rail := get_node_or_null("BoardFrame/ScrollRail") as CanvasItem
	if rail:
		rail.visible = false


func hide_chrome() -> void:
	for path in [
		"PanelUP/GameHeader",
		"PanelUP/ButtonReveal",
		"PanelUP/ButtonHint",
		"PanelUP/ButtonTheme",
		"PanelColors",
		"PanelLetras",
	]:
		var node := get_node_or_null(path) as CanvasItem
		if node:
			node.visible = false
			node.modulate.a = 0.0
	var board := get_node_or_null("BoardFrame") as CanvasItem
	if board:
		board.visible = true
		board.modulate.a = 1.0
	var rail := get_node_or_null("BoardFrame/ScrollRail") as CanvasItem
	if rail:
		rail.visible = false


func board_fill_xform() -> Dictionary:
	var scale := minf(VIDEO.x / BOARD_RECT.size.x, VIDEO.y / BOARD_RECT.size.y)
	var board_on_screen := BOARD_RECT.size * scale
	var pos := (VIDEO - board_on_screen) / 2.0 - BOARD_RECT.position * scale
	return {"scale": Vector2(scale, scale), "position": pos}


func phone_fit_xform() -> Dictionary:
	var scale := VIDEO.y / PHONE_SIZE.y
	var on_screen := PHONE_SIZE * scale
	var pos := (VIDEO - on_screen) / 2.0 + FIT_SHIFT
	return {"scale": Vector2(scale, scale), "position": pos}


func phone_right_xform() -> Dictionary:
	var scale := VIDEO.y / PHONE_SIZE.y
	var on_screen := PHONE_SIZE * scale
	var pos := Vector2(VIDEO.x - on_screen.x - RIGHT_MARGIN, (VIDEO.y - on_screen.y) / 2.0)
	return {"scale": Vector2(scale, scale), "position": pos}


func mira_phone_xform() -> Dictionary:
	var scale := VIDEO.y / PHONE_SIZE.y * 0.9
	var on_screen := PHONE_SIZE * scale
	var pos := Vector2(880.0, (VIDEO.y - on_screen.y) / 2.0)
	return {"scale": Vector2(scale, scale), "position": pos}


func board_play_xform() -> Dictionary:
	var scale := VIDEO.y / PHONE_SIZE.y
	var on_screen := PHONE_SIZE * scale
	var pos := Vector2(VIDEO.x - on_screen.x + 18.0, (VIDEO.y - on_screen.y) / 2.0)
	return {"scale": Vector2(scale, scale), "position": pos}


func hook_xform() -> Dictionary:
	var fill: Dictionary = board_fill_xform()
	var scale: Vector2 = fill["scale"] * 0.78
	var board_on := BOARD_RECT.size * scale.x
	var pos := (VIDEO - board_on) / 2.0 - BOARD_RECT.position * scale.x - Vector2(0.0, 72.0)
	return {"scale": scale, "position": pos}


func color_button(index: int) -> Control:
	return get_node_or_null("PanelColors/HBoxContainer/Button%d" % index) as Control


func show_hypothesis(real_letter: String, guessed: String, bg: Color) -> void:
	for cell in cells_for(real_letter):
		cell.letter_user = guessed
		if cell.label_letra:
			cell.label_letra.text = guessed
			cell.label_letra.visible = true
			cell.label_letra.add_theme_color_override("font_color", Color(0.18, 0.12, 0.08, 1))
		_paint_cell(cell, bg)


func clear_hypothesis(real_letter: String) -> void:
	for cell in cells_for(real_letter):
		cell.limpiar_letra_usuario()
		if cell.label_numero:
			cell.label_numero.visible = true
		if cell.label_letra:
			cell.label_letra.visible = false
		_paint_cell(cell, Color(0.97, 0.93, 0.86, 1))


func _paint_cell(cell: Celda, bg: Color) -> void:
	if cell == null or cell.panel_celda == null:
		return
	var style := StyleBoxFlat.new()
	var current := cell.panel_celda.get_theme_stylebox("panel")
	if current is StyleBoxFlat:
		style = (current as StyleBoxFlat).duplicate()
	style.bg_color = bg
	cell.panel_celda.add_theme_stylebox_override("panel", style)


func cells() -> Array[Celda]:
	var found: Array[Celda] = []
	for node in get_tree().get_nodes_in_group("Celda"):
		if node is Celda and is_ancestor_of(node):
			found.append(node)
	found.sort_custom(func(a: Celda, b: Celda) -> bool: return a.orden < b.orden)
	return found


func _cell_key(cell: Celda) -> String:
	if cell == null:
		return ""
	if GameManager:
		return GameManager._hint_letter_key(str(cell.letra))
	return str(cell.letra).strip_edges().to_upper()


func cells_for(letter: String) -> Array[Celda]:
	var key := letter.strip_edges().to_upper()
	if GameManager:
		key = GameManager._hint_letter_key(letter)
	var found: Array[Celda] = []
	for cell in cells():
		if cell.numero >= 100:
			continue
		if _cell_key(cell) == key:
			found.append(cell)
	return found


func first_cell(letter: String) -> Celda:
	var found := cells_for(letter)
	return found[0] if not found.is_empty() else null


func letter_is_shown(letter: String) -> bool:
	var cell := first_cell(letter)
	if cell == null or cell.label_letra == null:
		return false
	return cell.label_letra.visible and str(cell.letter_user).strip_edges() != ""


func letter_key(letter: String) -> Control:
	var keys := get_node_or_null("PanelLetras/GridContainer")
	if keys == null:
		return null
	var wanted := letter.strip_edges().to_upper()
	if GameManager:
		wanted = GameManager._hint_letter_key(letter)
	for child in keys.get_children():
		if child is Letra and str((child as Letra).letra).to_upper() == wanted:
			return child as Control
	return null


func cells_spelling(word: String) -> Array[Celda]:
	var compact: Array[Celda] = []
	var keys: PackedStringArray = PackedStringArray()
	for cell in cells():
		var raw := str(cell.letra)
		if raw.strip_edges() == "" or raw == " " or raw == "\n":
			continue
		var key := raw.to_upper()
		if GameManager and GameManager.is_playable_letter(raw):
			key = GameManager._hint_letter_key(raw)
		elif GameManager and GameManager.is_excluded_character(raw) and raw == ",":
			continue
		compact.append(cell)
		keys.append(key)
	var target := word.to_upper().replace(" ", "").replace(",", "")
	if target.is_empty() or compact.size() < target.length():
		return []
	for i in range(compact.size() - target.length() + 1):
		var matched := true
		for j in target.length():
			if keys[i + j] != target.substr(j, 1):
				matched = false
				break
		if matched:
			var found: Array[Celda] = []
			for j in target.length():
				found.append(compact[i + j])
			return found
	return []


func pulse_word(word: String, bg: Color) -> void:
	var found := cells_spelling(word)
	highlight_cells(found, bg)
	for cell in found:
		if cell == null or cell.size.x <= 1.0:
			continue
		cell.pivot_offset = cell.size * 0.5
		var tw := cell.create_tween()
		tw.tween_property(cell, "scale", Vector2(1.18, 1.18), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(cell, "scale", Vector2.ONE, 0.2)


func highlight_cells(found: Array[Celda], bg: Color) -> void:
	for cell in found:
		if cell == null or cell.panel_celda == null:
			continue
		var style := StyleBoxFlat.new()
		var current := cell.panel_celda.get_theme_stylebox("panel")
		if current is StyleBoxFlat:
			style = (current as StyleBoxFlat).duplicate()
		style.bg_color = bg
		cell.panel_celda.add_theme_stylebox_override("panel", style)
		if cell.size.x > 1.0:
			cell.pivot_offset = cell.size * 0.5
			var tw := cell.create_tween()
			tw.tween_property(cell, "scale", Vector2(1.12, 1.12), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(cell, "scale", Vector2.ONE, 0.18)


func clear_playable_letters() -> void:
	for cell in cells():
		if cell.numero >= 100:
			continue
		cell.limpiar_letra_usuario()
		if cell.label_numero:
			cell.label_numero.visible = true


func apply_gift_letters(letters: String) -> void:
	var gifts := {}
	for i in letters.length():
		var key := letters.substr(i, 1).to_upper()
		if GameManager:
			key = GameManager._hint_letter_key(letters.substr(i, 1))
		if key != "":
			gifts[key] = true
	for cell in cells():
		if cell.numero >= 100:
			continue
		var key := _cell_key(cell)
		if gifts.has(key):
			cell.mostrar_letra_especifica(key)


func reveal_letter(letter: String, color: Color, lock: bool = true) -> Array[Celda]:
	var found := cells_for(letter)
	var shown := letter.strip_edges().to_upper()
	if GameManager:
		shown = GameManager._hint_letter_key(letter)
	for cell in found:
		cell.letter_user = shown
		if cell.label_letra:
			cell.label_letra.text = shown
			cell.label_letra.visible = true
			cell.label_letra.add_theme_color_override("font_color", color)
		cell.celda_mostrada = true
		if lock:
			cell.bloqueada = true
		if cell.size.x > 1.0:
			cell.pivot_offset = cell.size * 0.5
			cell.scale = Vector2(1.14, 1.14)
			var tw := cell.create_tween()
			tw.tween_property(cell, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return found


func show_wrong_on(cell: Celda, letter: String) -> void:
	if cell == null:
		return
	cell.letter_user = letter
	cell.mostrar_letra_errada()


func paint_letters(letters: String, bg: Color) -> void:
	for i in letters.length():
		for cell in cells_for(letters.substr(i, 1)):
			if cell.panel_celda == null:
				continue
			var style := StyleBoxFlat.new()
			var current := cell.panel_celda.get_theme_stylebox("panel")
			if current is StyleBoxFlat:
				style = (current as StyleBoxFlat).duplicate()
			style.bg_color = bg
			cell.panel_celda.add_theme_stylebox_override("panel", style)


func reveal_all_remaining(color: Color) -> void:
	var seen := {}
	for cell in cells():
		if cell.numero >= 100:
			continue
		var key := _cell_key(cell)
		if key == "" or seen.has(key):
			continue
		if cell.label_letra and cell.label_letra.visible and str(cell.letter_user) != "":
			continue
		seen[key] = true
		reveal_letter(key, color, true)
