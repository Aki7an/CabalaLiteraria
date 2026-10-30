extends Control

const DESIGN := Vector2(1280, 720)
const BOARD_SHARE := 0.70

var _wide := false
var _toggle_serial := 0
var _saved: Array[Dictionary] = []
var _level_label: Label
var _user_label: Label
var _view_button: Button


func _enter_tree() -> void:
	_fit_to_window()


func _ready() -> void:
	_fit_to_window()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_fit_to_window):
		viewport.size_changed.connect(_fit_to_window)
	_saved = _capture($Game/CanvasLayer)
	_level_label = get_node_or_null("Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/CgLevelBar/LevelLabel") as Label
	_user_label = get_node_or_null("Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/CgLevelBar/UserLabel") as Label
	_view_button = get_node_or_null("Game/CanvasLayer/PanelUP/GameHeader/Margin/Main/CgLevelBar/ViewButton") as Button
	_refresh_level_label()
	if _view_button != null and not _view_button.pressed.is_connected(_on_view_toggle_pressed):
		_view_button.pressed.connect(_on_view_toggle_pressed)


func _fit_to_window() -> void:
	var view := get_viewport_rect().size
	if view.x < 2.0 or view.y < 2.0:
		return
	var fitted := minf(view.x / DESIGN.x, view.y / DESIGN.y)
	scale = Vector2(fitted, fitted)
	pivot_offset = Vector2.ZERO
	position = (view - DESIGN * fitted) * 0.5


func _on_view_toggle_pressed() -> void:
	_toggle_serial += 1
	var serial := _toggle_serial
	_wide = not _wide
	_refresh_level_label()
	if _wide:
		_apply_wide(serial)
	else:
		_restore_saved(serial)


func _refresh_level_label() -> void:
	if _level_label != null:
		_level_label.text = "%s: %d" % [tr("LevelShort"), _run_level()]
	if _user_label != null:
		_user_label.text = _crazygames_display_name()
	if _view_button != null:
		_view_button.text = tr("ChangeView")


func _crazygames_display_name() -> String:
	var name := ""
	if typeof(GameManager) != TYPE_NIL:
		name = str(GameManager.crazygames_username).strip_edges()
	if name == "":
		var guest := tr("CgGuest")
		return "Invitado" if guest == "" or guest == "CgGuest" else guest
	if name.length() > 16:
		return name.substr(0, 15) + "…"
	return name


func _run_level() -> int:
	if typeof(PlayerProgress) != TYPE_NIL:
		return PlayerProgress.run_number()
	return 1


func _apply_wide(serial: int) -> void:
	var column := get_node_or_null("Game/CanvasLayer/WidePlayColumn")
	if column != null and column.has_method("adopt"):
		column.call("adopt", self)
	var board := $Game/CanvasLayer/BoardFrame as Control
	var margin := 8.0
	var split := DESIGN.x * BOARD_SHARE
	var board_size := Vector2(split - margin * 2.0, DESIGN.y - margin * 2.0)
	_set_box(board, Rect2(margin, margin, board_size.x, board_size.y), Vector2.ONE)
	var canvas := board.get_node("CanvasJuego") as Control
	var rail := board.get_node("ScrollRail") as Control
	var inset := 12.0
	_set_box(canvas, Rect2(inset, inset, board_size.x - inset * 2.0, board_size.y - inset * 2.0), Vector2.ONE)
	if rail != null:
		rail.visible = false
	_show_panel(board)
	await get_tree().process_frame
	if serial != _toggle_serial or not _wide:
		return
	_set_box(canvas, Rect2(inset, inset, board_size.x - inset * 2.0, board_size.y - inset * 2.0), Vector2.ONE)
	if canvas.has_method("note_layout_rest"):
		canvas.call("note_layout_rest")
	if canvas.has_method("set_fit_all_rows"):
		canvas.call("set_fit_all_rows", true)
	if rail != null:
		rail.visible = false



func _restore_saved(serial: int) -> void:
	var letters := get_node_or_null("Game/CanvasLayer/WidePlayColumn/Teclado/PanelLetras")
	if letters == null:
		letters = get_node_or_null("Game/CanvasLayer/PanelLetras")
	if letters != null and letters.has_method("set_block_fit"):
		letters.call("set_block_fit", true)
	var column := get_node_or_null("Game/CanvasLayer/WidePlayColumn")
	if column != null and column.has_method("release"):
		column.call("release")
	for item in _saved:
		var node := item["node"] as Control
		if node == null:
			continue
		_set_box(node, item["rect"], item["scale"])
		if str(node.name) != "ScrollRail":
			_show_panel(node)
	await get_tree().process_frame
	if serial != _toggle_serial or _wide:
		return
	var canvas := get_node_or_null("Game/CanvasLayer/BoardFrame/CanvasJuego")
	if canvas != null and canvas.has_method("note_layout_rest"):
		canvas.call("note_layout_rest")
	if canvas != null and canvas.has_method("set_fit_all_rows"):
		canvas.call("set_fit_all_rows", false)
	if letters != null and letters.has_method("restore_designed_key_heights"):
		letters.call("restore_designed_key_heights")
		(letters as CanvasItem).clip_contents = false
		letters.call("set_block_fit", true)
	await get_tree().process_frame
	if serial != _toggle_serial or _wide:
		return
	_force_saved_rect("PanelLetras")
	if letters != null and letters.has_method("_fit_key_heights"):
		letters.call("set_block_fit", false)
		letters.call("_fit_key_heights")
	_force_saved_rect("PanelLetras")
	if canvas != null and canvas.has_method("_update_scroll_bounds"):
		canvas.call("_update_scroll_bounds")


func _capture(root: Node) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for path in ["BoardFrame", "BoardFrame/CanvasJuego", "BoardFrame/ScrollRail", "PanelUP", "PanelColors", "PanelLetras"]:
		var node := root.get_node_or_null(path) as Control
		if node == null:
			continue
		found.append({
			"node": node,
			"rect": Rect2(node.position, node.size),
			"scale": node.scale,
		})
	return found


func _force_saved_rect(node_name: String) -> void:
	for item in _saved:
		var node := item["node"] as Control
		if node == null or str(node.name) != node_name:
			continue
		node.custom_minimum_size = Vector2.ZERO
		_set_box(node, item["rect"], item["scale"])
		return


func _box_size(node: Control) -> Vector2:
	return node.size


func _show_panel(node: Control) -> void:
	node.visible = true
	node.modulate.a = 1.0


func _set_box(node: Control, rect: Rect2, node_scale: Vector2) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0
	node.offset_left = rect.position.x
	node.offset_top = rect.position.y
	node.offset_right = rect.end.x
	node.offset_bottom = rect.end.y
	node.scale = node_scale
