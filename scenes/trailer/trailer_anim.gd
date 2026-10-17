extends Object

const GREEN := Color(0.22, 0.62, 0.28, 1)
const RED := Color(0.81, 0.08, 0.08, 1)
const INK := Color(0.18, 0.12, 0.08, 1)
const HINT_Y := Color(1.0, 0.86, 0.18, 1)
const SAME_Y := Color(1.0, 0.94, 0.68, 1)
const FILL := Color(0.78, 0.76, 0.74, 1)
const VOWEL := Color(1.0, 0.8, 0.6, 1)
const CONS := Color(0.6, 0.8, 1.0, 1)
const HAND_SCALE := 0.155
const FULLHD := Vector2i(1920, 1080)


static func apply_fullhd(host: Node) -> void:
	if host == null:
		return
	var win := host.get_window()
	if win == null:
		return
	win.mode = Window.MODE_WINDOWED
	win.min_size = FULLHD
	win.size = FULLHD
	win.content_scale_size = FULLHD
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	if host is Control:
		(host as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func wait(host: Node, sec: float) -> void:
	if host == null or host.get_tree() == null or sec <= 0.0:
		return
	await host.get_tree().create_timer(sec, false).timeout


static func wait_remaining(host: Node, started_msec: int, duration: float) -> void:
	var elapsed := (Time.get_ticks_msec() - started_msec) / 1000.0
	await wait(host, duration - elapsed)


static func trailer_phone(host: Node) -> Control:
	if host == null:
		return null
	var blocks := host.get_parent()
	if blocks == null:
		return null
	var one := blocks.get_node_or_null("01_Pregunta")
	if one == null:
		return null
	if one.has_method("get_phone"):
		return one.get_phone()
	return one.get_node_or_null("Phone") as Control


static func trailer_theme_card(host: Node) -> Control:
	if host == null:
		return null
	var own := host.get_node_or_null("%ThemeCard") as Control
	if own:
		return own
	var blocks := host.get_parent()
	if blocks == null:
		return null
	var mira := blocks.get_node_or_null("03_Mira")
	if mira == null:
		return null
	return mira.get_node_or_null("%ThemeCard") as Control


static func phone_hand_tap_key(host: Control, phone: Node, letter: String) -> void:
	if phone == null or not phone.has_method("letter_key"):
		return
	var key: Control = phone.letter_key(letter)
	await hand_tap(host, key)


static func phone_highlight_word(host: Node, phone: Node, word: String, bg: Color = HINT_Y) -> void:
	if phone == null or not phone.has_method("cells_spelling"):
		return
	var found: Array = phone.cells_spelling(word)
	if phone.has_method("highlight_cells"):
		phone.highlight_cells(found, bg)
	await wait(host, 0.2)


static func banner_under_phone(host: Control, phone: Control, label: Label, gap: float = 16.0) -> Dictionary:
	var height := 220.0
	if label and label.size.y > 2.0:
		height = label.size.y
	var y := host.size.y * 0.68 if host else 740.0
	if phone:
		var board := phone.get_node_or_null("BoardFrame") as Control
		if board:
			y = board.get_global_rect().end.y - host.global_position.y + gap
	if host and y + height > host.size.y - 8.0:
		y = host.size.y - height - 8.0
	var width := host.size.x if host else 1920.0
	var start := Vector2(-width, y)
	var center := Vector2(0.0, y)
	var exit := Vector2(width, y)
	if label:
		label.size = Vector2(width, height)
		label.position = start
		label.visible = true
		label.modulate.a = 1.0
	return {"start": start, "center": center, "exit": exit}


static func fly_banner(host: Node, label: Control, start: Vector2, center: Vector2, exit: Vector2, in_sec: float, hold_sec: float, out_sec: float) -> void:
	if label == null:
		return
	label.position = start
	label.visible = true
	var fly := host.create_tween()
	fly.tween_property(label, "position", center, in_sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	fly.tween_interval(hold_sec)
	fly.tween_property(label, "position", exit, out_sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await fly.finished
	label.visible = false


static func fly_banner_in(host: Node, label: Control, start: Vector2, center: Vector2, in_sec: float) -> void:
	if label == null:
		return
	label.position = start
	label.visible = true
	label.modulate.a = 1.0
	var fly := host.create_tween()
	fly.tween_property(label, "position", center, in_sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await fly.finished


static func hide_legacy_stage(host: Node) -> void:
	if host == null:
		return
	for path in ["Backdrop", "BoardRig", "Dim", "Hud", "Board"]:
		var node := host.get_node_or_null(path) as CanvasItem
		if node:
			node.visible = false
	if host is Control:
		(host as Control).clip_contents = false
		(host as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


static func phone_hand_tap_letter(host: Control, phone: Node, letter: String) -> void:
	if phone == null or not phone.has_method("first_cell"):
		return
	var cell: Control = phone.first_cell(letter)
	await hand_tap(host, cell)


static func phone_reveal(host: Node, phone: Node, letter: String, color: Color = GREEN) -> void:
	if phone == null or not phone.has_method("reveal_letter"):
		return
	phone.reveal_letter(letter, color, true)
	sfx("ClickLetra")
	await wait(host, 0.18)


static func fly_banner_out(host: Node, label: Control, exit: Vector2, out_sec: float) -> void:
	if label == null:
		return
	var fly := host.create_tween()
	fly.tween_property(label, "position", exit, out_sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await fly.finished
	label.visible = false


static func reveal(host: Control, letter: String, color: Color = GREEN) -> void:
	var board: Node = host.get_node_or_null("%Board")
	if board == null:
		return
	var first := true
	var found: Array = board.call("cells_for", letter)
	for cell in found:
		cell.call("show_letter", letter, color, SAME_Y if first else FILL)
		cell.pivot_offset = cell.size * 0.5
		cell.scale = Vector2(1.16, 1.16)
		var tw := host.create_tween()
		tw.tween_property(cell, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if first:
			sfx("ClickLetra")
			first = false
	await wait(host, 0.2)
	found = board.call("cells_for", letter)
	for cell in found:
		cell.call("set_bg", FILL)


static func highlight_word(host: Control, word: String, bg: Color = HINT_Y) -> void:
	var board: Node = host.get_node_or_null("%Board")
	if board == null:
		return
	var found: Array = board.call("cells_spelling", word)
	for cell in found:
		cell.call("set_bg", bg)
		cell.pivot_offset = cell.size * 0.5
		var tw := host.create_tween()
		tw.tween_property(cell, "scale", Vector2(1.12, 1.12), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(cell, "scale", Vector2.ONE, 0.18)


static func paint(host: Control, letters: String, bg: Color) -> void:
	var board: Node = host.get_node_or_null("%Board")
	if board == null:
		return
	for i in letters.length():
		var found: Array = board.call("cells_for", letters.substr(i, 1))
		for cell in found:
			var letter_node: Node = cell.get_node_or_null("Letter")
			if letter_node is CanvasItem and (letter_node as CanvasItem).visible:
				cell.call("set_bg", bg)


static func hand_tap(host: Control, node: CanvasItem, move_sec: float = 0.32) -> void:
	var hand: Sprite2D = host.get_node_or_null("%Hand") as Sprite2D
	if hand == null or node == null:
		return
	hand.visible = true
	hand.modulate.a = 1.0
	var dest := Vector2.ZERO
	if node is Control:
		dest = (node as Control).get_global_rect().get_center() + Vector2(46, 78)
	else:
		dest = node.get_global_transform().origin + Vector2(46, 78)
	if hand.position.length() < 2.0:
		hand.position = dest + Vector2(240, 180)
	var tw := host.create_tween()
	tw.tween_property(hand, "position", dest, move_sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	var tap := host.create_tween()
	tap.tween_property(hand, "scale", Vector2(HAND_SCALE * 0.86, HAND_SCALE * 0.86), 0.06)
	tap.tween_property(hand, "scale", Vector2(HAND_SCALE, HAND_SCALE), 0.08)
	await tap.finished


static func hand_tap_letter(host: Control, letter: String) -> void:
	var board: Node = host.get_node_or_null("%Board")
	if board == null:
		return
	var cell: Control = board.call("first_cell", letter)
	await hand_tap(host, cell)


static func hide_hand(host: Control) -> void:
	var hand: Sprite2D = host.get_node_or_null("%Hand") as Sprite2D
	if hand == null:
		return
	var tw := host.create_tween()
	tw.tween_property(hand, "modulate:a", 0.0, 0.2)
	await tw.finished
	hand.visible = false


static func pulse(node: Control) -> void:
	if node == null:
		return
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	tw.set_loops(3)
	tw.tween_property(node, "scale", Vector2(1.08, 1.08), 0.28).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_SINE)


static func press(node: Control) -> void:
	if node == null:
		return
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(0.94, 0.94), 0.07)
	tw.tween_property(node, "scale", Vector2.ONE, 0.12)


static func fade_in(host: Node, node: CanvasItem, sec: float = 0.25) -> void:
	node.visible = true
	node.modulate.a = 0.0
	var tw := host.create_tween()
	tw.tween_property(node, "modulate:a", 1.0, sec)
	await tw.finished


static func fade_out(host: Node, node: CanvasItem, sec: float = 0.25) -> void:
	var tw := host.create_tween()
	tw.tween_property(node, "modulate:a", 0.0, sec)
	await tw.finished


static func cue(event_name: String) -> void:
	match event_name:
		"hook", "image", "link":
			sfx("ButtonClick")
		"letter":
			sfx("ClickLetra")
		"error":
			var tree := Engine.get_main_loop() as SceneTree
			var sm: Node = tree.root.get_node_or_null("SoundManager") if tree else null
			if sm and sm.has_method("play_red_letter_click"):
				sm.play_red_letter_click()
			else:
				sfx("ClickLetra")
		"correct", "huella", "discover":
			sfx("PlayAvailable")
		"categories", "logo":
			sfx("ButtonClick")
		_:
			pass


static func sfx(sfx_name: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var sm: Node = tree.root.get_node_or_null("SoundManager")
	if sm != null and sm.has_method("play"):
		sm.play(sfx_name)
