extends Panel

var letra_scene: PackedScene = preload("res://scenes/Letra/Letra.tscn")

@export var COLUMNAS_POR_FILA: int = 10
@export var ALTO_CELDA: int = 100
@export var SEPARACION: int = 2

const LAYOUT_MODE_CONTAINER := 1

@onready var grid: GridContainer = $GridContainer

const WIDE_KEY_RATIO := 1.5
const WIDE_KEY_SEPARATION := 6

var _block_fit := false
var _wide_keys := false
var _lock_row := false
var _locked_row_h := -1
var _key_label_top := 16.0
var _key_font := 52
var _key_chrome_saved := false
var _grid_off_top := 8.0
var _grid_off_bottom := -4.0
var _grid_offsets_saved := false


func set_block_fit(blocked: bool) -> void:
	_block_fit = blocked


func restore_designed_key_heights() -> void:
	if grid == null:
		return
	_wide_keys = false
	_block_fit = true
	grid.columns = COLUMNAS_POR_FILA
	grid.add_theme_constant_override("h_separation", SEPARACION)
	grid.add_theme_constant_override("v_separation", SEPARACION)
	_reset_grid_frame()
	_grid_offsets_saved = false
	var row_h := _locked_row_h if _locked_row_h > 0 else ALTO_CELDA
	for child in grid.get_children():
		if child is Control:
			var control := child as Control
			control.custom_minimum_size = Vector2(0, row_h)
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			control.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_restore_key_letter(control)
	_key_chrome_saved = false
	_block_fit = false


func _reset_grid_frame() -> void:
	if grid == null:
		return
	grid.layout_mode = 1
	grid.anchor_left = 0.0
	grid.anchor_top = 0.0
	grid.anchor_right = 1.0
	grid.anchor_bottom = 1.0
	grid.offset_left = 10.0
	grid.offset_top = 8.0
	grid.offset_right = -10.0
	grid.offset_bottom = -4.0


func fit_wide_keys() -> void:
	if grid == null or grid.get_child_count() == 0 or size.x < 8.0 or size.y < 8.0:
		return
	_wide_keys = true
	_block_fit = true
	if not _grid_offsets_saved:
		_grid_off_top = grid.offset_top
		_grid_off_bottom = grid.offset_bottom
		_grid_offsets_saved = true
	var count := grid.get_child_count()
	var sep := float(WIDE_KEY_SEPARATION)
	var area_w := maxf(size.x - 20.0, 1.0)
	var area_h := maxf(size.y - 12.0, 1.0)
	var best_cols := 1
	var best_w := -1.0
	for cols in range(1, count + 1):
		var rows := int(ceil(float(count) / float(cols)))
		var max_w := (area_w - sep * float(cols - 1)) / float(cols)
		var max_h := (area_h - sep * float(rows - 1)) / float(rows)
		var key_w := minf(max_w, max_h / WIDE_KEY_RATIO)
		if key_w > best_w:
			best_w = key_w
			best_cols = cols
	var key_h := best_w * WIDE_KEY_RATIO
	var rows_used := int(ceil(float(count) / float(best_cols)))
	var used_h := key_h * float(rows_used) + sep * float(maxi(rows_used - 1, 0))
	var extra_y := maxf(area_h - used_h, 0.0) * 0.5
	grid.columns = best_cols
	grid.add_theme_constant_override("h_separation", WIDE_KEY_SEPARATION)
	grid.add_theme_constant_override("v_separation", WIDE_KEY_SEPARATION)
	grid.offset_top = 8.0 + extra_y
	grid.offset_bottom = -(4.0 + extra_y)
	var font_size := maxi(10, int(best_w * 0.62))
	var key_size := Vector2(floorf(best_w), floorf(key_h))
	for child in grid.get_children():
		if not (child is Control):
			continue
		var control := child as Control
		control.custom_minimum_size = key_size
		control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_fit_key_letter(control, font_size)
	grid.queue_sort()
	_block_fit = false


func _fit_key_letter(key: Control, font_size: int) -> void:
	var label := key.get_node_or_null("PanelLetra/LabelLetra") as Label
	if label == null:
		return
	if not _key_chrome_saved:
		_key_label_top = label.offset_top
		_key_font = label.get_theme_font_size("font_size")
		_key_chrome_saved = true
	label.offset_top = 0.0
	label.offset_bottom = 0.0
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)


func _restore_key_letter(key: Control) -> void:
	var label := key.get_node_or_null("PanelLetra/LabelLetra") as Label
	if label == null:
		return
	label.offset_top = _key_label_top
	label.offset_bottom = 0.0
	label.add_theme_font_size_override("font_size", _key_font)

func _ready() -> void:
	add_to_group("KeyboardPanel")
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	grid.columns = COLUMNAS_POR_FILA
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", SEPARACION)
	grid.add_theme_constant_override("v_separation", SEPARACION)
	_fill_keys()

	resized.connect(_fit_key_heights)
	grid.resized.connect(_fit_key_heights)
	call_deferred("_fit_key_heights")
	# Lock the row height once the panel has its real size. Later refits,
	# including the ones fired while the view toggle rewrites offsets, keep it.
	get_tree().process_frame.connect(_lock_initial_row, CONNECT_ONE_SHOT)


func rebuild_from_alphabet() -> void:
	if grid == null:
		return
	for child in grid.get_children():
		grid.remove_child(child)
		child.free()
	grid.columns = COLUMNAS_POR_FILA
	_fill_keys()
	_fit_key_heights()


func _fill_keys() -> void:
	for i in range(GameManager.letters_aphabet_array.size()):
		var celda_node := letra_scene.instantiate()
		if !(celda_node is Control):
			push_error("El root de Letra.tscn debe heredar de Control.")
			continue
		var celda := celda_node as Control
		celda.layout_mode = LAYOUT_MODE_CONTAINER
		celda.set_anchors_preset(Control.PRESET_TOP_LEFT)
		celda.offset_left = 0
		celda.offset_top = 0
		celda.offset_right = 0
		celda.offset_bottom = 0
		if celda.has_method("set_letter"):
			celda.call("set_letter", GameManager.letters_aphabet_array[i])
		celda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		celda.size_flags_vertical = Control.SIZE_EXPAND_FILL
		celda.custom_minimum_size = Vector2(0, ALTO_CELDA)
		grid.add_child(celda)


func _lock_initial_row() -> void:
	_fit_key_heights()
	if grid == null or grid.get_child_count() == 0:
		return
	var key := grid.get_child(0) as Control
	if key != null and key.custom_minimum_size.y > 1.0:
		_locked_row_h = int(key.custom_minimum_size.y)
		_lock_row = true


func _fit_key_heights() -> void:
	if _block_fit or _wide_keys or grid == null or grid.get_child_count() == 0:
		return
	var rows := int(ceil(float(grid.get_child_count()) / float(max(COLUMNAS_POR_FILA, 1))))
	if rows <= 0:
		return
	var row_h := _locked_row_h
	if not _lock_row or row_h < 1:
		# Use the panel height directly. GridContainer often reports only its
		# children height, which would leave a permanent gap at the bottom.
		var top_pad := absf(grid.offset_top)
		var bottom_pad := absf(grid.offset_bottom)
		var available := size.y - top_pad - bottom_pad - float(SEPARACION * max(rows - 1, 0))
		if available <= 1.0:
			return
		row_h = maxi(floori(available / float(rows)), 1)
	for child in grid.get_children():
		if child is Control:
			var control := child as Control
			control.custom_minimum_size = Vector2(0, row_h)
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			control.size_flags_vertical = Control.SIZE_EXPAND_FILL
