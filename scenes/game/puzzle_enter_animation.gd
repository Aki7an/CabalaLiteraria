extends Node
class_name PuzzleEnterAnimation

const ORANGE := Color(0.96, 0.51, 0.01, 1)

var _layer: Node
var _rest: Dictionary = {}


static func should_play() -> bool:
	if Engine.has_meta("store_screenshot") and bool(Engine.get_meta("store_screenshot")):
		return false
	return true


func play(layer: CanvasLayer) -> void:
	_layer = layer
	if _layer == null:
		return
	var blocker := _make_blocker()
	_cache_and_hide()
	await get_tree().process_frame
	await get_tree().process_frame
	_hide_existing_letters()
	await _play_chrome()
	await _play_letters()
	_restore_all()
	await _play_finish_shake()
	if is_instance_valid(blocker):
		blocker.queue_free()
	GameManager.puzzle_enter_pending = false
	GameManager.update_numero_letras_reveladas()
	SignalManager.update_puzzle_stars.emit(GameManager.puzzle_stars)


func _make_blocker() -> ColorRect:
	var host := _layer.get_node_or_null("OverlayHost") as Control
	if host == null:
		return null
	var blocker := ColorRect.new()
	blocker.name = "EnterAnimBlocker"
	blocker.color = Color(1, 1, 1, 0)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.z_index = 50
	host.add_child(blocker)
	return blocker


func _node(path: String) -> Control:
	if _layer == null:
		return null
	return _layer.get_node_or_null(path) as Control


func _cache_and_hide() -> void:
	var header := _header()
	var reveal := _node("PanelUP/ButtonReveal")
	var hint := _node("PanelUP/ButtonHint")
	var theme := _node("PanelUP/ButtonTheme")
	var board := _node("BoardFrame")
	var colors := _node("PanelColors")
	var keys := _node("PanelLetras")
	for node in [header, reveal, hint, theme, board, colors, keys]:
		if node == null:
			continue
		_rest[node] = node.position
		node.visible = false
		node.modulate.a = 0.0


func _restore_all() -> void:
	for node in _rest.keys():
		if node == null or not is_instance_valid(node):
			continue
		node.visible = true
		node.modulate.a = 1.0
		node.position = _rest[node]


func _header() -> Control:
	var hud := _node("PanelUP")
	if hud == null:
		return null
	var header := hud.get_node_or_null("GameHeader") as Control
	if header:
		return header
	return hud


func _play_chrome() -> void:
	var board := _node("BoardFrame")
	var header := _header()
	var reveal := _node("PanelUP/ButtonReveal")
	var hint := _node("PanelUP/ButtonHint")
	var theme := _node("PanelUP/ButtonTheme")
	var colors := _node("PanelColors")
	var keys := _node("PanelLetras")
	SoundManager.play("IntroCifra")
	await _slide(board, Vector2(1100, 0), 0.42)
	SoundManager.play("Whoosh")
	await _slide(header, Vector2(0, -420), 0.30)
	SoundManager.play("IntroButtons")
	_slide(reveal, Vector2(-900, 0), 0.28)
	await get_tree().create_timer(0.08).timeout
	_slide(hint, Vector2(-900, 0), 0.28)
	await get_tree().create_timer(0.08).timeout
	await _slide(theme, Vector2(-900, 0), 0.28)
	SoundManager.play("Whoosh")
	await _slide(colors, Vector2(1100, 0), 0.30)
	SoundManager.play("Whoosh")
	await _slide(keys, Vector2(0, 700), 0.32)


func _slide(node: Control, from_offset: Vector2, duration: float) -> void:
	if node == null:
		return
	var dest: Vector2 = _rest.get(node, node.position)
	node.visible = true
	node.modulate.a = 1.0
	node.position = dest + from_offset
	var tw := node.create_tween()
	tw.tween_property(node, "position", dest, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	node.position = dest


func _hide_existing_letters() -> void:
	for node in get_tree().get_nodes_in_group("Celda"):
		if node is Celda:
			(node as Celda).hide_letter_visual()


func _play_letters() -> void:
	var letters := _letters_in_board_order()
	if letters.is_empty():
		return
	var per := clampf(1.7 / float(letters.size()), 0.12, 0.28)
	for letter in letters:
		await _reveal_letter_group(letter, per)


func _letters_in_board_order() -> Array[String]:
	var gift_set := {}
	var initials := GameManager.letras_iniciales.to_upper()
	for i in initials.length():
		var ch := GameManager._hint_letter_key(initials[i])
		if ch != "" and not GameManager.is_excluded_character(ch):
			gift_set[ch] = true
	var ordered: Array[String] = []
	var seen := {}
	var cells := _sorted_cells()
	for cell in cells:
		if cell.numero >= 100:
			continue
		var key := GameManager._hint_letter_key(str(cell.letra))
		var user := GameManager._hint_letter_key(str(cell.letter_user))
		var shown := user if user != "" else key
		var is_gift := gift_set.has(key)
		var is_filled := cell.celda_mostrada or user != ""
		if not is_gift and not is_filled:
			continue
		if shown == "" or seen.has(shown):
			continue
		seen[shown] = true
		ordered.append(shown)
	if ordered.is_empty():
		for key in gift_set.keys():
			ordered.append(str(key))
	return ordered


func _sorted_cells() -> Array[Celda]:
	var cells: Array[Celda] = []
	for node in get_tree().get_nodes_in_group("Celda"):
		if node is Celda:
			cells.append(node)
	cells.sort_custom(func(a: Celda, b: Celda) -> bool: return a.orden < b.orden)
	return cells


func _reveal_letter_group(letter: String, duration: float) -> void:
	var gift_set := {}
	var initials := GameManager.letras_iniciales.to_upper()
	for i in initials.length():
		var ch := GameManager._hint_letter_key(initials[i])
		if ch != "":
			gift_set[ch] = true
	var as_gift := gift_set.has(letter)
	var cells: Array[Celda] = []
	for cell in _sorted_cells():
		var key := GameManager._hint_letter_key(str(cell.letra))
		if key == letter:
			cells.append(cell)
	var key_node := _keyboard_key(letter)
	SoundManager.play("IntroLetra")
	StarCollectOverlay.play_chime()
	for cell in cells:
		cell.apply_enter_letter_look(letter, ORANGE)
	if key_node:
		key_node.apply_enter_letter_look(ORANGE)
	var blink := maxf(duration * 0.22, 0.05)
	await _blink_scale_twice(cells, key_node, blink)
	for cell in cells:
		cell.finish_enter_letter_look(as_gift)
	if key_node:
		key_node.finish_enter_letter_look()


func _keyboard_key(letter: String) -> Letra:
	for node in get_tree().get_nodes_in_group("Letra"):
		if node is Letra and GameManager._hint_letter_key((node as Letra).letra) == letter:
			return node
	return null


func _blink_scale_twice(cells: Array[Celda], key_node: Letra, step: float) -> void:
	var nodes: Array[Control] = []
	for cell in cells:
		nodes.append(cell)
	if key_node:
		nodes.append(key_node)
	for node in nodes:
		if node.size.x > 1.0:
			node.pivot_offset = node.size * 0.5
	for _i in 2:
		var up := create_tween()
		up.set_parallel(true)
		for node in nodes:
			var max_scale := 1.12 if node is Celda else 1.08
			up.tween_property(node, "scale", Vector2(max_scale, max_scale), step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await up.finished
		var down := create_tween()
		down.set_parallel(true)
		for node in nodes:
			down.tween_property(node, "scale", Vector2.ONE, step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await down.finished


func _play_finish_shake() -> void:
	var board := _node("BoardFrame")
	if board == null:
		return
	var origin: Vector2 = _rest.get(board, board.position)
	var amp := 9.0
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for _i in 2:
		tw.tween_property(board, "position", origin + Vector2(amp, amp * 0.4), 0.045)
		tw.tween_property(board, "position", origin + Vector2(-amp, -amp * 0.4), 0.07)
	tw.tween_property(board, "position", origin, 0.07)
	await tw.finished
	board.position = origin
