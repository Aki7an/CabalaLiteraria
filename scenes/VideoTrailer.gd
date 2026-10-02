extends Node

const APP_SCENE := preload("res://scenes/App.tscn")
const HAND_TEXTURE := preload("res://images/tutorial/hand_pointer.png")
const PUZZLE_ID := 116
const HAND_SIZE := Vector2(300, 384)
const TIP_RATIO := Vector2(0.22, 0.04)

var _hand: TextureRect
var _locale := "es"


func _ready() -> void:
	_locale = _read_locale()
	Engine.set_meta("video_trailer", true)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_prepare_moon_puzzle()
	add_child(APP_SCENE.instantiate())
	_build_hand()
	_run_sequence()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Engine.has_meta("video_trailer"):
		Engine.remove_meta("video_trailer")


func _read_locale() -> String:
	var from_env := OS.get_environment("CIFRA_TRAILER_LANG").strip_edges().to_lower()
	if from_env != "":
		return from_env
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):
			return arg.trim_prefix("--lang=").strip_edges().to_lower()
	return "es"


func _prepare_moon_puzzle() -> void:
	TranslationServer.set_locale(_locale)
	if typeof(PlayerPrefs) != TYPE_NIL:
		PlayerPrefs.idioma = _locale
	GameManager.cargar_frases_desde_json()
	GameManager.session_source = GameManager.SOURCE_NONE
	GameManager.onboarding_stage = 0
	GameManager.allow_completed_replay = false
	GameManager.set_go_to_game_disable()
	PuzzleSaveManager.clear_puzzle_state(PUZZLE_ID)
	GameManager.seleccionar_por_index(PUZZLE_ID)
	GameManager.set_dificultad_actual(1)
	GameManager.set_game_mode_actual(GameManager.MODE_QUICK)


func _build_hand() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	_hand = TextureRect.new()
	_hand.name = "TrailerHand"
	_hand.texture = HAND_TEXTURE
	_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hand.custom_minimum_size = HAND_SIZE
	_hand.size = HAND_SIZE
	_hand.pivot_offset = HAND_SIZE * TIP_RATIO
	_hand.z_index = 20
	_hand.visible = false
	layer.add_child(_hand)
	var view := get_viewport().get_visible_rect().size
	_place_tip(Vector2(view.x * 0.72, view.y * 0.78))


func _run_sequence() -> void:
	while GameManager.puzzle_enter_pending:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	_hand.visible = true

	var theme := _find_button("ButtonTheme")
	if theme == null:
		push_error("VideoTrailer: no encuentro el botón TEMA.")
		return
	await _move_and_tap(theme, 0.92, 0.55)
	theme.pressed.emit()

	var preview := await _wait_for_group("PuzzleThemePreview")
	if preview == null:
		push_error("VideoTrailer: no se abrió la imagen del tema.")
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var image := preview.get_node_or_null("Card/ImageFrame/Image") as Control
	if image == null:
		push_error("VideoTrailer: la imagen del tema no está en el cuadro.")
		return
	await _tour_theme_image(image)
	var continue_button := preview.get_node_or_null("Card/ButtonStart") as BaseButton
	if continue_button == null:
		push_error("VideoTrailer: no encuentro el botón CONTINUAR.")
		return
	await _move_and_tap(continue_button)
	continue_button.pressed.emit()
	await _wait_until_group_empty("PuzzleThemePreview")
	await get_tree().create_timer(1.0).timeout
	print("TRAILER_LOCALE %s PHRASE %s" % [_locale, GameManager.frase_original])

	if _locale == "es":
		await _solve_spanish()
	else:
		await _solve_locale(_locale_plan(_locale))
	await _fill_remaining_letters()
	await _accelerate_green_carousel()


func _solve_spanish() -> void:
	var huella := _word_cells("HUELLA")
	var el := _word_cells("EL")
	var julio := _word_cells("JULIO")
	var apolo := _word_cells("APOLO")
	if huella.size() < 6 or el.size() < 2 or julio.size() < 5 or apolo.size() < 5:
		push_error("VideoTrailer: faltan HUELLA, EL, JULIO o APOLO. Frase: %s" % GameManager.frase_original)
		return

	var eles: Array[Celda] = [huella[3], huella[4]]
	await _circle_word(eles, 2.0)
	await _paint_cell(1, huella[5])
	await _paint_cell(2, huella[2])
	await get_tree().create_timer(1.0).timeout
	await _fill_word(huella)

	await _paint_cell(3, huella[1])
	await _fill_word(el)
	await _fill_word(julio)
	await _circle_word(apolo)
	await _fill_word(apolo)

	for word in ["DE", "SU", "EN", "DEJO", "LA", "LUNA"]:
		await _fill_word(_word_cells(word))


func _locale_plan(locale: String) -> Dictionary:
	match locale:
		"en":
			return {
				"focus": "FOOTPRINT",
				"pair": [1, 2],
				"colors": [["FOOTPRINT", 6], ["FOOTPRINT", 1]],
				"after": ["JULY", 1],
				"before_apollo": ["JULY"],
				"apollo": "APOLLO",
				"rest": ["LEFT", "ITS", "THE", "MOON", "ON"],
			}
		"it":
			return {
				"focus": "IMPRONTA",
				"colors": [["IMPRONTA", 7], ["IMPRONTA", 4]],
				"after": ["LUGLIO", 1],
				"before_apollo": ["IL", "LUGLIO"],
				"apollo": "APOLLO",
				"rest": ["LUNA", "SUA", "SULLA", "LASCIO", "LA"],
			}
		"fr":
			return {
				"focus": "EMPREINTE",
				"colors": [["EMPREINTE", 8], ["EMPREINTE", 5]],
				"after": ["JUILLET", 1],
				"before_apollo": ["LE", "JUILLET"],
				"apollo": "APOLLO",
				"rest": ["LUNE", "LAISSE", "SON", "SUR", "LA"],
			}
		"pt":
			return {
				"focus": "PEGADA",
				"colors": [["PEGADA", 5], ["PEGADA", 1]],
				"after": ["JULHO", 1],
				"before_apollo": ["EM", "JULHO"],
				"apollo": "APOLLO",
				"rest": ["DEIXOU", "SUA", "NA", "LUA", "DE"],
			}
		"de":
			return {
				"focus": "FUSSABDRUCK",
				"pair": [2, 3],
				"colors": [["FUSSABDRUCK", 4], ["FUSSABDRUCK", 1]],
				"after": ["JULI", 3],
				"before_apollo": ["AM", "JULI"],
				"apollo": "APOLLO",
				"rest": ["DEM", "MOND", "SEINEN", "HINTERLIESS", "AUF"],
			}
		"eu":
			return {
				"focus": "AZTARNA",
				"colors": [["AZTARNA", 6], ["UZTAILAREN", 8]],
				"after": ["UZTAILAREN", 0],
				"before_apollo": ["UZTAILAREN"],
				"apollo": "APOLLO",
				"rest": ["KO", "BERE", "ILARGIAN", "UTZI", "ZUEN", "AN"],
			}
		_:
			return {}


func _solve_locale(plan: Dictionary) -> void:
	if plan.is_empty():
		push_error("VideoTrailer: no hay un recorrido para el idioma %s." % _locale)
		return
	var focus := _word_cells(str(plan["focus"]))
	if focus.is_empty():
		push_error("VideoTrailer: no encuentro %s. Frase: %s" % [plan["focus"], GameManager.frase_original])
		return
	if plan.has("pair"):
		var pair: Array = plan["pair"]
		var doubled: Array[Celda] = []
		doubled.append(focus[int(pair[0])])
		doubled.append(focus[int(pair[1])])
		await _circle_word(doubled, 2.0)
	else:
		await _circle_word(focus, 2.0)
	var slot := 1
	for color in plan["colors"]:
		await _paint_cell(slot, _cell_at(str(color[0]), int(color[1])))
		slot += 1
	await get_tree().create_timer(1.0).timeout
	await _fill_word(focus)
	var after: Array = plan["after"]
	await _paint_cell(3, _cell_at(str(after[0]), int(after[1])))
	for word in plan["before_apollo"]:
		await _fill_word(_word_cells(str(word)))
	var apollo := _word_cells(str(plan["apollo"]))
	await _circle_word(apollo)
	await _fill_word(apollo)
	for word in plan["rest"]:
		await _fill_word(_word_cells(str(word)))


func _cell_at(word: String, index: int) -> Celda:
	var cells := _word_cells(word)
	if index < 0 or index >= cells.size():
		push_error("VideoTrailer: %s no tiene la letra %d. Frase: %s" % [word, index, GameManager.frase_original])
		return null
	return cells[index]


func _paint_cell(color_slot: int, cell: Celda) -> void:
	var color_button := _color_button(color_slot)
	if color_button == null or cell == null:
		push_error("VideoTrailer: no puedo pintar el color %d." % color_slot)
		return
	await _move_and_tap(color_button)
	SoundManager.play("ButtonClick")
	await _focus_cell(cell)
	await _move_and_tap(cell)
	_select_cell(cell)
	color_button.pressed.emit()


func _type_letter(cell: Celda, letter: String) -> void:
	var key := _keyboard_key(letter)
	if cell == null or key == null:
		push_error("VideoTrailer: no encuentro la letra %s." % letter)
		return
	await _focus_cell(cell)
	await _move_and_tap(cell)
	_select_cell(cell)
	await _press_key(letter)


func _select_cell(cell: Celda) -> void:
	if cell.bloqueada and not cell.revelada_verde:
		SoundManager.play("ClickCelda")
		GameManager.set_celda_seleccionada(cell.orden, cell.numero)
		return
	var button := cell.get_node_or_null("Fondo/Button") as BaseButton
	if button:
		button.pressed.emit()
	else:
		GameManager.set_celda_seleccionada(cell.orden, cell.numero)


func _focus_cell(cell: Celda) -> void:
	var board := get_tree().root.find_child("CanvasJuego", true, false)
	if board != null and board.has_method("pan_cell_into_view"):
		board.call("pan_cell_into_view", cell)
		await get_tree().process_frame


func _press_key(letter: String) -> void:
	var key := _keyboard_key(letter)
	if key == null:
		push_error("VideoTrailer: no encuentro la letra %s." % letter)
		return
	var key_button := key.get_node_or_null("PanelLetra/Button") as BaseButton
	if key_button == null:
		push_error("VideoTrailer: la tecla %s no tiene botón." % letter)
		return
	await _move_and_tap(key)
	key_button.pressed.emit()
	await get_tree().create_timer(0.8).timeout


func _fill_word(cells: Array[Celda]) -> void:
	var used := {}
	for cell in cells:
		if not _cell_needs_letter(cell):
			continue
		var key := GameManager._hint_letter_key(cell.letra)
		if key == "" or used.has(key) or _letter_already_used(key):
			continue
		used[key] = true
		await _type_letter(cell, key)


func _fill_remaining_letters() -> void:
	var cells: Array[Celda] = []
	for node in get_tree().get_nodes_in_group("Celda"):
		if node is Celda and _cell_needs_letter(node):
			cells.append(node)
	cells.sort_custom(func(a: Celda, b: Celda) -> bool: return a.orden < b.orden)
	var used := {}
	for cell in cells:
		var key := GameManager._hint_letter_key(cell.letra)
		if key == "" or used.has(key) or _letter_already_used(key) or not _cell_needs_letter(cell):
			continue
		used[key] = true
		await _type_letter(cell, key)


func _cell_needs_letter(cell: Celda) -> bool:
	if cell == null or cell.numero <= 0 or cell.numero >= 100:
		return false
	if cell.bloqueada or cell.revelada_verde or cell.celda_mostrada:
		return false
	return cell.letter_user.strip_edges() == ""


func _letter_already_used(letter: String) -> bool:
	var key := _keyboard_key(letter)
	return key != null and key.letra_mostrada


func _circle_word(cells: Array[Celda], turns: float = 3.0) -> void:
	var target := _circle_targets(cells)
	if target.is_empty():
		return
	await _focus_cell(target[0])
	await get_tree().process_frame
	var bounds := target[0].get_global_rect()
	for cell in target:
		bounds = bounds.merge(cell.get_global_rect())
	var center := bounds.get_center()
	var radius := bounds.size * 0.5 + Vector2(36, 28)
	radius.x = maxf(radius.x, 84.0)
	radius.y = maxf(radius.y, 62.0)
	var duration := 1.07 * turns
	var start_angle := -PI * 0.5
	await _move_tip_to(center + Vector2(cos(start_angle) * radius.x, sin(start_angle) * radius.y), 0.42)
	var elapsed := 0.0
	while elapsed < duration:
		elapsed += get_process_delta_time()
		var t := clampf(elapsed / duration, 0.0, 1.0)
		var angle := start_angle + t * TAU * turns
		_place_tip(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		await get_tree().process_frame


func _circle_targets(cells: Array[Celda]) -> Array[Celda]:
	if cells.is_empty():
		return []
	var ordered: Array[Celda] = cells.duplicate()
	ordered.sort_custom(func(a: Celda, b: Celda) -> bool:
		return a.get_global_rect().get_center().y < b.get_global_rect().get_center().y
	)
	var threshold := maxf(ordered[0].get_global_rect().size.y * 0.45, 8.0)
	var rows: Array = []
	var current: Array[Celda] = []
	var row_y := 0.0
	for cell in ordered:
		var y := cell.get_global_rect().get_center().y
		if current.is_empty() or absf(y - row_y) <= threshold:
			if current.is_empty():
				row_y = y
			current.append(cell)
		else:
			rows.append(current)
			current = [cell]
			row_y = y
	if not current.is_empty():
		rows.append(current)
	var best: Array[Celda] = []
	for row in rows:
		var row_cells: Array[Celda] = []
		for cell in row:
			row_cells.append(cell)
		if row_cells.size() > best.size():
			best = row_cells
	if best.is_empty():
		return cells
	var main := best[0].get_global_rect()
	for cell in best:
		main = main.merge(cell.get_global_rect())
	var merged: Array[Celda] = best.duplicate()
	for cell in cells:
		if merged.has(cell):
			continue
		var rect := cell.get_global_rect()
		var gap_x := 0.0
		if rect.position.x > main.end.x:
			gap_x = rect.position.x - main.end.x
		elif rect.end.x < main.position.x:
			gap_x = main.position.x - rect.end.x
		var gap_y := absf(rect.get_center().y - main.get_center().y)
		if gap_x <= rect.size.x * 1.4 and gap_y <= rect.size.y * 1.4:
			merged.append(cell)
	return merged


func _accelerate_green_carousel() -> void:
	var prompt := await _wait_for_group("BoardFillPrompt", 120)
	if prompt == null:
		push_error("VideoTrailer: no apareció el aviso de tablero completo.")
		return
	await get_tree().create_timer(0.55).timeout
	var finish := prompt.get_node_or_null("Card/ButtonFinish") as BaseButton
	if finish == null:
		push_error("VideoTrailer: no encuentro el botón de terminar.")
		return
	await _move_and_tap(finish)
	finish.pressed.emit()

	var reveal := await _wait_for_group("RevealSequence", 120)
	if reveal == null:
		push_error("VideoTrailer: no arrancó el carrusel de letras.")
		return
	await _wait_first_green_letter(reveal)
	var fast := _fast_forward_button(reveal)
	if fast != null:
		await _move_and_tap(fast)
		fast.button_pressed = true
	await _leave_screen()


func _wait_first_green_letter(overlay: Node) -> void:
	var label := _center_letter(overlay)
	if label == null:
		await get_tree().create_timer(1.4).timeout
		return
	var seen := false
	for _i in 900:
		var showing := label.text.strip_edges() != "" and label.modulate.a > 0.72
		if showing:
			seen = true
		elif seen and label.modulate.a < 0.2:
			return
		await get_tree().process_frame


func _center_letter(overlay: Node) -> Label:
	for child in overlay.get_children():
		if child is Label:
			return child
	return null


func _fast_forward_button(overlay: Node) -> Button:
	for child in overlay.get_children():
		if child is Button and (child as Button).toggle_mode:
			return child
	return null


func _leave_screen() -> void:
	var view := get_viewport().get_visible_rect().size
	await _move_tip_to(Vector2(view.x + 220.0, view.y * 0.78), 0.55)
	_hand.visible = false


func _tour_theme_image(image: Control) -> void:
	var rect := image.get_global_rect()
	await _circle_on_image(rect, Vector2(0.50, 0.80), Vector2(0.17, 0.075), 2.15)
	await _circle_on_image(rect, Vector2(0.18, 0.38), Vector2(0.16, 0.20), 2.15)


func _circle_on_image(rect: Rect2, center_ratio: Vector2, radius_ratio: Vector2, duration: float) -> void:
	var center := rect.position + Vector2(rect.size.x * center_ratio.x, rect.size.y * center_ratio.y)
	var radius := Vector2(rect.size.x * radius_ratio.x, rect.size.y * radius_ratio.y)
	var start_angle := -PI * 0.5
	await _move_tip_to(center + Vector2(cos(start_angle) * radius.x, sin(start_angle) * radius.y), 0.46)
	var elapsed := 0.0
	while elapsed < duration:
		elapsed += get_process_delta_time()
		var t := clampf(elapsed / duration, 0.0, 1.0)
		var angle := start_angle + t * TAU
		_place_tip(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		await get_tree().process_frame


func _move_and_tap(target: Control, move_time: float = 0.46, hold: float = 0.0) -> void:
	if target == null:
		return
	var rect := target.get_global_rect()
	await _move_tip_to(rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.42), move_time)
	if hold > 0.0:
		await get_tree().create_timer(hold).timeout
	await _tap()


func _move_tip_to(global_point: Vector2, duration: float) -> void:
	var dest := global_point - _tip_offset()
	var start := _hand.global_position
	if duration <= 0.0 or start.distance_to(dest) < 1.0:
		_hand.global_position = dest
		return
	var elapsed := 0.0
	while elapsed < duration:
		elapsed += get_process_delta_time()
		var t := clampf(elapsed / duration, 0.0, 1.0)
		var eased := t * t * (3.0 - 2.0 * t)
		_hand.global_position = start.lerp(dest, eased)
		await get_tree().process_frame


func _tap() -> void:
	var down := 0.08
	var up := 0.10
	var elapsed := 0.0
	while elapsed < down:
		elapsed += get_process_delta_time()
		var t := clampf(elapsed / down, 0.0, 1.0)
		_hand.scale = Vector2.ONE.lerp(Vector2(0.88, 0.88), t)
		await get_tree().process_frame
	elapsed = 0.0
	while elapsed < up:
		elapsed += get_process_delta_time()
		var t := clampf(elapsed / up, 0.0, 1.0)
		_hand.scale = Vector2(0.88, 0.88).lerp(Vector2.ONE, t)
		await get_tree().process_frame
	_hand.scale = Vector2.ONE


func _place_tip(global_point: Vector2) -> void:
	_hand.global_position = global_point - _tip_offset()


func _tip_offset() -> Vector2:
	var size := _hand.size if _hand.size.x > 1.0 else HAND_SIZE
	return size * TIP_RATIO


func _word_cells(word: String) -> Array[Celda]:
	var cells: Array[Celda] = []
	for node in get_tree().get_nodes_in_group("Celda"):
		if node is Celda and (node as Celda).numero > 0 and (node as Celda).numero < 100:
			cells.append(node)
	cells.sort_custom(func(a: Celda, b: Celda) -> bool: return a.orden < b.orden)
	var target := word.to_upper()
	if cells.size() < target.length():
		return []
	for start in cells.size() - target.length() + 1:
		var matched := true
		for offset in target.length():
			var key := GameManager._hint_letter_key(cells[start + offset].letra)
			if key != target[offset]:
				matched = false
				break
		if matched:
			var found: Array[Celda] = []
			for offset in target.length():
				found.append(cells[start + offset])
			return found
	return []


func _keyboard_key(letter: String) -> Letra:
	var wanted := letter.to_upper()
	for node in get_tree().get_nodes_in_group("Letra"):
		if node is Letra and GameManager._hint_letter_key((node as Letra).letra) == wanted:
			return node
	return null


func _color_button(slot: int) -> BaseButton:
	var panel := get_tree().root.find_child("PanelColors", true, false)
	if panel == null:
		return null
	return panel.get_node_or_null("HBoxContainer/Button%d" % slot) as BaseButton


func _find_button(node_name: String) -> BaseButton:
	return get_tree().root.find_child(node_name, true, false) as BaseButton


func _wait_for_group(group_name: String, frames: int = 40) -> Node:
	for _i in frames:
		var nodes := get_tree().get_nodes_in_group(group_name)
		if not nodes.is_empty():
			return nodes[0]
		await get_tree().process_frame
	return null


func _wait_until_group_empty(group_name: String, frames: int = 40) -> void:
	for _i in frames:
		if get_tree().get_nodes_in_group(group_name).is_empty():
			return
		await get_tree().process_frame
