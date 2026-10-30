@tool
extends Control

const _ADOPT := [
	["TopCard/Usuario", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/CgLevelBar/UserLabel"],
	["TopCard/Nivel", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/CgLevelBar/LevelLabel"],
	["TopCard/CambioDeVista", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/CgLevelBar/ViewButton"],
	["TopCard/EstrellasTitulo", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/Top/StarsBlock/StarsTitle"],
	["TopCard/Estrellas", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/Top/StarsBlock/Stars"],
	["TopCard/Musica", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/Top/ButtonMusic"],
	["TopCard/Opciones", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/Top/ButtonPause"],
	["TopCard/Ilustres", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/Top/CategoryWrap"],
	["TopCard/Modo", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/Top/StarsBlock/ModeRow"],
	["TopCard/Reloj", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/Top/TimerColumn/TimeIcon"],
	["TopCard/Tiempo", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/Top/TimerColumn/TimeLine"],
	["TopCard/BarraLetras", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/Bottom/LettersProgress"],
	["TopCard/TextoLetras", "Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/Bottom/LettersFilled"],
	["Tema", "Game/CanvasLayer/PanelUP/ButtonTheme"],
	["Pista", "Game/CanvasLayer/PanelUP/ButtonHint"],
	["Comprobar", "Game/CanvasLayer/PanelUP/ButtonReveal"],
	["Colores", "Game/CanvasLayer/PanelColors"],
	["Teclado", "Game/CanvasLayer/PanelLetras"],
]

var _stash: Array[Dictionary] = []
var _adopted := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	visible = false
	for preview in find_children("Preview", "CanvasItem", true, false):
		preview.visible = false


func adopt(host: Node) -> void:
	if _adopted:
		return
	_stash.clear()
	var jobs: Array[Dictionary] = []
	for entry in _ADOPT:
		var slot := get_node_or_null(entry[0]) as Control
		var node := host.get_node_or_null(entry[1]) as Control
		if slot == null or node == null:
			continue
		jobs.append({
			"slot": slot,
			"node": node,
			"snap": _capture(node),
			"visual_scale": _visual_scale(node),
		})
	for job in jobs:
		var slot := job["slot"] as Control
		var node := job["node"] as Control
		_stash.append(job["snap"])
		node.reparent(slot)
		if slot.name == "Colores" and node.has_method("apply_wide_colors"):
			node.call("apply_wide_colors", true)
		if slot.name == "Teclado":
			if node.has_method("set_block_fit"):
				node.call("set_block_fit", true)
			node.layout_mode = 0
			node.anchor_left = 0.0
			node.anchor_top = 0.0
			node.anchor_right = 0.0
			node.anchor_bottom = 0.0
			node.position = Vector2.ZERO
			node.scale = Vector2.ONE
			node.size = _slot_size(slot)
			node.custom_minimum_size = Vector2.ZERO
			if node.has_method("set_block_fit"):
				node.call("set_block_fit", false)
			_seat_keyboard(node)
			if node.has_method("fit_wide_keys"):
				node.call("fit_wide_keys")
			continue
		if slot.name == "Colores":
			var native := Vector2(1170, 170)
			node.layout_mode = 0
			node.anchor_left = 0.0
			node.anchor_top = 0.0
			node.anchor_right = 0.0
			node.anchor_bottom = 0.0
			node.position = Vector2.ZERO
			node.offset_right = native.x
			node.offset_bottom = native.y
			node.custom_minimum_size = Vector2.ZERO
			var room := _slot_size(slot)
			var fitted := minf(room.x / native.x, room.y / native.y)
			node.scale = Vector2(fitted, fitted)
			continue
		if slot.name == "Musica" or slot.name == "Opciones":
			_place_same_size(node, job["visual_scale"], job["snap"])
			continue
		if (slot.name == "Nivel" or slot.name == "Usuario") and node is Label:
			_place_level_label(node as Label, slot, job["visual_scale"])
			continue
		_fit_in_slot(node, slot)
	var panel := host.get_node_or_null("Game/CanvasLayer/PanelUP") as CanvasItem
	if panel != null:
		panel.visible = false
	visible = true
	_adopted = true


func release() -> void:
	if not _adopted:
		return
	var colors := get_node_or_null("Colores")
	if colors != null:
		for child in colors.get_children():
			if child.has_method("apply_wide_colors"):
				child.call("apply_wide_colors", false)
	for item in _stash:
		_restore(item)
	_stash.clear()
	var host := get_parent()
	if host != null:
		var panel := host.get_node_or_null("PanelUP") as CanvasItem
		if panel != null:
			panel.visible = true
	visible = false
	_adopted = false


func _capture(node: Control) -> Dictionary:
	return {
		"node": node,
		"parent": node.get_parent(),
		"index": node.get_index(),
		"layout_mode": node.layout_mode,
		"anchors": Rect2(node.anchor_left, node.anchor_top, node.anchor_right, node.anchor_bottom),
		"offsets": Rect2(node.offset_left, node.offset_top, node.offset_right, node.offset_bottom),
		"scale": node.scale,
		"min_size": node.custom_minimum_size,
		"flags_h": node.size_flags_horizontal,
		"flags_v": node.size_flags_vertical,
		"align": (node as Label).horizontal_alignment if node is Label else -1,
		"size": node.size,
	}


func _seat_keyboard(panel: Control) -> void:
	panel.clip_contents = true
	var grid := panel.get_node_or_null("GridContainer") as Control
	if grid == null:
		return
	for child in grid.get_children():
		if child is Control:
			(child as Control).update_minimum_size()
	grid.custom_minimum_size = Vector2.ZERO
	grid.update_minimum_size()
	grid.layout_mode = 1
	grid.anchor_left = 0.0
	grid.anchor_top = 0.0
	grid.anchor_right = 1.0
	grid.anchor_bottom = 1.0
	grid.offset_left = 10.0
	grid.offset_top = 8.0
	grid.offset_right = -10.0
	grid.offset_bottom = -4.0
	grid.position = Vector2(10.0, 8.0)
	grid.size = Vector2(maxf(panel.size.x - 20.0, 1.0), maxf(panel.size.y - 12.0, 1.0))
	grid.queue_sort()


func _slot_size(slot: Control) -> Vector2:
	var box := Vector2(slot.offset_right - slot.offset_left, slot.offset_bottom - slot.offset_top)
	if box.x > 2.0 and box.y > 2.0:
		return box * slot.scale
	if slot.size.x > 2.0 and slot.size.y > 2.0:
		return slot.size
	return Vector2(80, 40)


func _place_level_label(label: Label, slot: Control, visual: Vector2) -> void:
	# The header stretches this label across the free width. Fitting that rect
	# into the slot shrinks the glyphs. Keep the stacked view's visual scale
	# and size the control to the text itself.
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var content := _label_content_size(label)
	label.layout_mode = 0
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 0.0
	label.anchor_bottom = 0.0
	label.custom_minimum_size = content
	label.pivot_offset = Vector2.ZERO
	label.scale = visual
	var drawn_h := content.y * visual.y
	var room := _slot_size(slot)
	var top := (room.y - drawn_h) * 0.5
	label.offset_left = 0.0
	label.offset_top = top
	label.offset_right = content.x
	label.offset_bottom = top + content.y


func _label_content_size(label: Label) -> Vector2:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	if font == null or font_size <= 0:
		var fallback := label.get_minimum_size()
		if fallback.x > 2.0 and fallback.y > 2.0:
			return fallback
		return Vector2(220, 66)
	var text_size := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	return Vector2(maxf(ceil(text_size.x) + 4.0, 2.0), maxf(ceil(text_size.y), float(font_size)))


func _place_same_size(node: Control, visual: Vector2, snap: Dictionary) -> void:
	var natural: Vector2 = snap.get("size", node.size)
	if natural.x < 2.0 or natural.y < 2.0:
		natural = snap.get("min_size", node.custom_minimum_size)
	if natural.x < 2.0 or natural.y < 2.0:
		natural = Vector2(122, 133)
	node.layout_mode = 0
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0
	node.position = Vector2.ZERO
	node.offset_right = natural.x
	node.offset_bottom = natural.y
	node.custom_minimum_size = natural
	node.scale = visual


func _visual_scale(node: Control) -> Vector2:
	var source := node.get_global_transform().get_scale()
	var dest := get_global_transform().get_scale()
	if absf(dest.x) < 0.001 or absf(dest.y) < 0.001:
		return source
	return Vector2(source.x / dest.x, source.y / dest.y)


func _fit_in_slot(node: Control, slot: Control) -> void:
	var natural := node.size
	if natural.x < 2.0 or natural.y < 2.0:
		natural = node.custom_minimum_size
	if natural.x < 2.0 or natural.y < 2.0:
		natural = Vector2(80, 40)
	node.layout_mode = 0
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0
	node.custom_minimum_size = Vector2.ZERO
	var room := _slot_size(slot)
	var fitted := minf(room.x / natural.x, room.y / natural.y)
	# The hourglass recenters its pivot whenever it resizes. Keep that center
	# for the flip, and shift the control so the drawing stays inside the slot.
	node.pivot_offset = natural * 0.5
	node.scale = Vector2(fitted, fitted)
	var pos := -node.pivot_offset * (1.0 - fitted)
	node.offset_left = pos.x
	node.offset_top = pos.y
	node.offset_right = pos.x + natural.x
	node.offset_bottom = pos.y + natural.y
	node.pivot_offset = natural * 0.5


func _restore(item: Dictionary) -> void:
	var node := item["node"] as Control
	var parent := item["parent"] as Node
	if node == null or parent == null:
		return
	if node.get_parent() != parent:
		node.reparent(parent)
		parent.move_child(node, clampi(int(item["index"]), 0, parent.get_child_count() - 1))
	var anchors: Rect2 = item["anchors"]
	var offsets: Rect2 = item["offsets"]
	node.layout_mode = int(item["layout_mode"])
	node.anchor_left = anchors.position.x
	node.anchor_top = anchors.position.y
	node.anchor_right = anchors.size.x
	node.anchor_bottom = anchors.size.y
	node.offset_left = offsets.position.x
	node.offset_top = offsets.position.y
	node.offset_right = offsets.size.x
	node.offset_bottom = offsets.size.y
	node.scale = item["scale"]
	node.custom_minimum_size = item["min_size"]
	node.size_flags_horizontal = int(item["flags_h"])
	node.size_flags_vertical = int(item["flags_v"])
	if node is Label and int(item["align"]) >= 0:
		(node as Label).horizontal_alignment = int(item["align"]) as HorizontalAlignment
