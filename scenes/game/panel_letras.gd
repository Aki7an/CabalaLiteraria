extends Panel

var letra_scene: PackedScene = preload("res://scenes/Letra/Letra.tscn")

@export var COLUMNAS_POR_FILA: int = 10
@export var ALTO_CELDA: int = 100
@export var SEPARACION: int = 2

@onready var contenedor_vertical: VBoxContainer = $VBoxContainer

const LAYOUT_MODE_CONTAINER := 1

@onready var grid: GridContainer = $GridContainer

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	grid.columns = COLUMNAS_POR_FILA
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", SEPARACION)
	grid.add_theme_constant_override("v_separation", SEPARACION)

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

	resized.connect(_fit_key_heights)
	grid.resized.connect(_fit_key_heights)
	call_deferred("_fit_key_heights")
	# Second pass after one frame so container sizes are final.
	get_tree().process_frame.connect(_fit_key_heights, CONNECT_ONE_SHOT)


func _fit_key_heights() -> void:
	if grid == null or grid.get_child_count() == 0:
		return
	var rows := int(ceil(float(grid.get_child_count()) / float(max(COLUMNAS_POR_FILA, 1))))
	if rows <= 0:
		return
	# Use the panel height directly. GridContainer often reports only its
	# children height, which would leave a permanent gap at the bottom.
	var top_pad := absf(grid.offset_top)
	var bottom_pad := absf(grid.offset_bottom)
	var available := size.y - top_pad - bottom_pad - float(SEPARACION * max(rows - 1, 0))
	if available <= 1.0:
		return
	var row_h := maxi(floori(available / float(rows)), 1)
	for child in grid.get_children():
		if child is Control:
			var control := child as Control
			control.custom_minimum_size = Vector2(0, row_h)
			control.size_flags_vertical = Control.SIZE_EXPAND_FILL
