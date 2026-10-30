extends Control
class_name Celda

@export var celda_mostrada: bool  = false
## Locked cells (initial gifts or verified-correct) cannot change letter; green cells can still receive color.
@export var bloqueada: bool = false
## Gifted at the start of the puzzle (grey). Turns green on reveal.
@export var es_regalo_inicial: bool = false
## Verified correct: green letter on white.
@export var revelada_verde: bool = false

# Letra que contiene la celda (puede estar vacía inicialmente)
@export var letra: String = ""
@export var letter_user: String = ""

@export var color_error: Color = Color(0.82, 0.12, 0.12, 1)
@export var color_font_default: Color = Color(0.169, 0.18, 0.188)

@export var font_size_inicial: int = 40
@export var font_size_asignada: int = 30

# Número asociado a la celda (1-27)
@export var numero: int = 0

# Número asociado a la celda dentro de todas las que son en la frase
@export var orden: int = 0

# ID del color asignado (0 = ninguno, 1–5 según lista_colores del GameManager)
@export var color_id: int = 0

# La celda ha de tener también los signos de ortografia: , " : ;... pueden hasta ser dos ".
@export  var punto_ortografia: String = ""
@onready var label_numero: Label = $Fondo/LabelNumero
@onready var label_letra: Label = $Fondo/LabelLetra

@onready var label_puntuacion_punto: Label = $Fondo/LabelPuntuacionPunto
@onready var label_puntuacion_coma: Label = $Fondo/LabelPuntuacionComa
@onready var label_puntuacion_punto_coma: Label = $Fondo/LabelPuntuacionPuntoComa
@onready var label_puntuacion_dos_puntos: Label = $Fondo/LabelPuntuacionDosPuntos
@onready var label_puntuacion_comillas_inicio: Label = $Fondo/LabelPuntuacionComillasInicio
@onready var label_puntuacion_comillas_fin: Label = $Fondo/LabelPuntuacionComillasFin
@onready var label_puntuacion_exclamación_inicio: Label = $Fondo/LabelPuntuacionExclamaciónInicio
@onready var label_puntuacion_exclamación_fin: Label = $Fondo/LabelPuntuacionExclamaciónFin
@onready var label_puntuacion_e_interrogacion_inicio: Label = $Fondo/LabelPuntuacionEInterrogacionInicio
@onready var label_puntuacion_e_interrogacion_fin: Label = $Fondo/LabelPuntuacionEInterrogacionFin
@onready var espacio_blanco: Panel = $Fondo/EspacioBlanco
@onready var panel_celda: Panel = $Fondo

@onready var celda_selected: Panel = $Fondo/CeldaSelected

@onready var tween := get_tree().create_tween()

@onready var color_init: Color = Color(0.975, 0.965, 0.945)
@onready var color_rellena: Color = Color(0.78, 0.76, 0.74)
@onready var color_fondo_blanco: Color = Color(1.0, 1.0, 1.0)
@onready var color_letra_correcta: Color = Color(0.22, 0.62, 0.28)
const COLOR_HINT_YELLOW := Color(1.0, 0.86, 0.18, 1.0)
const COLOR_SAME_NUMBER := Color(1.0, 0.94, 0.68, 1.0)
const COLOR_SELECTION := Color(0.769222, 0.769996, 0.302051, 1.0)

var _remaining_hint_tween: Tween
var _remaining_hint_active := false
var _same_number_highlight := false
var _tile_scaled := false
var _wide_tile_active := false
var _wide_layout_saved := false
var _label_backup: Array[Dictionary] = []
var _marco_backup: Array[Dictionary] = []

func _ready():
	add_to_group("Celda")
	_inicializar_puntuacion()
	_inicializar_letra()
	_inicializar_numero()
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not resized.is_connected(_sync_tile_scale):
		resized.connect(_sync_tile_scale)
	var button := get_node_or_null("Fondo/Button") as BaseButton
	if button:
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	SignalManager.update_size_celdas.connect(set_font_size)
	
func set_font_size() -> void:
	if _is_wide_board():
		_apply_wide_tile()
		return
	if _wide_tile_active:
		_restore_wide_tile()
	_sync_tile_scale()
	set_letter_font_size()
	set_number_font_size()
	
func _inicializar_puntuacion() -> void:
	label_puntuacion_punto.visible = false
	label_puntuacion_coma.visible = false
	label_puntuacion_punto_coma.visible = false
	label_puntuacion_dos_puntos.visible = false
	label_puntuacion_comillas_inicio.visible = false
	label_puntuacion_comillas_fin.visible = false
	label_puntuacion_exclamación_inicio.visible = false
	label_puntuacion_exclamación_fin.visible = false
	label_puntuacion_e_interrogacion_inicio.visible = false
	label_puntuacion_e_interrogacion_fin.visible = false
	espacio_blanco.visible = false
	
	celda_selected.visible = false
	
func set_letter_font_size() -> void:
	if _use_wide_letter_size():
		return
	var size := 85
	if GameManager.NUM_COLUMNAS == 8:
		size = 120
	elif GameManager.NUM_COLUMNAS == 9:
		size = 110
	elif GameManager.NUM_COLUMNAS == 10:
		size = 100
	elif GameManager.NUM_COLUMNAS == 11:
		size = 95
	elif GameManager.NUM_COLUMNAS == 12:
		size = 90
	if _displayed_board_letter() == "J":
		size = maxi(roundi(float(size) * 0.78), 1)
	size = maxi(roundi(float(size) * _board_font_scale()), 8)
	label_letra.add_theme_font_size_override("font_size", size)


func _displayed_board_letter() -> String:
	var shown := letter_user if letter_user != "" else letra
	return shown.strip_edges().to_upper() 
		
func set_number_font_size() -> void:
	if _use_wide_letter_size():
		return
	var size := maxi(roundi(float(font_size_inicial) * _board_font_scale()), 8)
	label_numero.add_theme_font_size_override("font_size", size)


func _sync_tile_scale() -> void:
	if _wide_tile_active:
		_layout_wide_tile()
		return
	if panel_celda == null or not is_inside_tree():
		return
	var canvas := get_tree().get_first_node_in_group("PuzzleCanvas")
	var fitting := canvas != null and bool(canvas.get("_fit_all_rows"))
	var source := Vector2.ZERO
	if canvas != null:
		source = canvas.get("fit_source_size")
	if not fitting or source.x < 2.0 or source.y < 2.0 or size.x < 2.0 or size.y < 2.0:
		if _tile_scaled:
			_restore_tile_scale()
		return
	panel_celda.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel_celda.position = Vector2.ZERO
	panel_celda.size = source
	panel_celda.pivot_offset = Vector2.ZERO
	panel_celda.scale = Vector2(size.x / source.x, size.y / source.y)
	_tile_scaled = true
	clip_contents = true


func _restore_tile_scale() -> void:
	if panel_celda == null:
		return
	panel_celda.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_celda.offset_left = 0.0
	panel_celda.offset_top = 0.0
	panel_celda.offset_right = 0.0
	panel_celda.offset_bottom = 0.0
	panel_celda.scale = Vector2.ONE
	panel_celda.pivot_offset = Vector2.ZERO
	_tile_scaled = false
	clip_contents = false


func _use_wide_letter_size() -> bool:
	if not (_wide_tile_active or _is_wide_board()):
		return false
	if _wide_tile_active:
		_layout_wide_tile()
	else:
		_apply_wide_tile()
	return true


func _is_wide_board() -> bool:
	if not is_inside_tree():
		return false
	var canvas := get_tree().get_first_node_in_group("PuzzleCanvas")
	return canvas != null and bool(canvas.get("_fit_all_rows"))


func _punctuation_labels() -> Array[Label]:
	return [
		label_puntuacion_punto,
		label_puntuacion_coma,
		label_puntuacion_punto_coma,
		label_puntuacion_dos_puntos,
		label_puntuacion_comillas_inicio,
		label_puntuacion_comillas_fin,
		label_puntuacion_exclamación_inicio,
		label_puntuacion_exclamación_fin,
		label_puntuacion_e_interrogacion_inicio,
		label_puntuacion_e_interrogacion_fin,
	]


func _apply_wide_tile() -> void:
	if panel_celda == null:
		return
	_restore_tile_scale()
	_remember_wide_layout()
	_wide_tile_active = true
	_layout_wide_tile()


func _layout_wide_tile() -> void:
	if label_numero == null or label_letra == null or size.x < 2.0:
		return
	_place_band(label_numero, 0.0, 0.30)
	label_numero.add_theme_font_size_override("font_size", maxi(8, int(size.x * 0.42)))
	_place_band(label_letra, 0.24, 1.0)
	var letter_size := maxi(10, int(minf(size.x * 0.82, size.y * 0.70)))
	label_letra.add_theme_font_size_override("font_size", letter_size)
	for mark in _punctuation_labels():
		if mark == null:
			continue
		_place_band(mark, 0.24, 1.0)
		mark.add_theme_font_size_override("font_size", letter_size)
	for marco_name in ["Marco1", "Marco2", "Marco3", "Marco4"]:
		var marco := panel_celda.get_node_or_null(marco_name) as Control
		if marco == null:
			continue
		if marco_name == "Marco1":
			marco.custom_minimum_size = Vector2(0, 1)
			marco.offset_top = 0.0
			marco.offset_bottom = 1.0
		elif marco_name == "Marco4":
			marco.anchor_top = 1.0
			marco.offset_top = -1.0
			marco.offset_bottom = 0.0
		elif marco_name == "Marco2":
			marco.custom_minimum_size = Vector2(1, 0)
			marco.offset_left = 0.0
			marco.offset_right = 1.0
		else:
			marco.custom_minimum_size = Vector2(1, 0)
			marco.offset_left = -1.0
			marco.offset_right = 0.0


func _place_band(label: Label, top: float, bottom: float) -> void:
	label.layout_mode = 1
	label.anchor_left = 0.0
	label.anchor_top = top
	label.anchor_right = 1.0
	label.anchor_bottom = bottom
	label.offset_left = 0.0
	label.offset_top = 0.0
	label.offset_right = 0.0
	label.offset_bottom = 0.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _remember_wide_layout() -> void:
	if _wide_layout_saved or panel_celda == null:
		return
	_label_backup.clear()
	for label in [label_numero, label_letra]:
		_label_backup.append(_control_snapshot(label))
	for mark in _punctuation_labels():
		_label_backup.append(_control_snapshot(mark))
	_marco_backup.clear()
	for marco_name in ["Marco1", "Marco2", "Marco3", "Marco4"]:
		_marco_backup.append(_control_snapshot(panel_celda.get_node_or_null(marco_name) as Control))
	_wide_layout_saved = true


func _control_snapshot(node: Control) -> Dictionary:
	if node == null:
		return {}
	return {
		"node": node,
		"layout_mode": node.layout_mode,
		"anchors": Rect2(node.anchor_left, node.anchor_top, node.anchor_right, node.anchor_bottom),
		"offsets": Rect2(node.offset_left, node.offset_top, node.offset_right, node.offset_bottom),
		"min_size": node.custom_minimum_size,
		"align_h": (node as Label).horizontal_alignment if node is Label else -1,
		"align_v": (node as Label).vertical_alignment if node is Label else -1,
	}


func _restore_wide_tile() -> void:
	_wide_tile_active = false
	for item in _label_backup:
		_restore_control_snapshot(item)
	for item in _marco_backup:
		_restore_control_snapshot(item)
	_wide_layout_saved = false
	_label_backup.clear()
	_marco_backup.clear()


func _restore_control_snapshot(item: Dictionary) -> void:
	if item.is_empty():
		return
	var node := item["node"] as Control
	if node == null:
		return
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
	node.custom_minimum_size = item["min_size"]
	if node is Label and int(item["align_h"]) >= 0:
		(node as Label).horizontal_alignment = int(item["align_h"]) as HorizontalAlignment
		(node as Label).vertical_alignment = int(item["align_v"]) as VerticalAlignment


func _board_font_scale() -> float:
	var canvas := get_tree().get_first_node_in_group("PuzzleCanvas") if is_inside_tree() else null
	if canvas != null and canvas.get("fit_font_scale") != null:
		return maxf(float(canvas.fit_font_scale), 0.12)
	return 1.0
		
		
func _inicializar_letra() -> void:
	label_letra.text = letra
	label_letra.visible = false
	
	set_letter_font_size()
		
	celda_mostrada = false
	bloqueada = false
	es_regalo_inicial = false
	revelada_verde = false
	label_numero.add_theme_font_size_override("font_size",font_size_inicial )
	if _is_blank_mark(letra):
		espacio_blanco.visible = true


func _is_blank_mark(character: String) -> bool:
	return character == " " or character == "\n" or character == "\t" \
		or character == "\u00a0" or character == "\u200b"


func _inicializar_numero() -> void:
	label_numero.text = str(numero)
	label_numero.visible = true
	label_numero.stop_blink()
	
	set_number_font_size()
	
	# Punctuation and other non-letters start solved: visible mark, no cipher number.
	if GameManager.is_excluded_character(letra):
		label_numero.visible = false
		label_numero.text = "101"
		numero = 101
		celda_mostrada = true
		bloqueada = true
		if _is_blank_mark(letra):
			espacio_blanco.visible = true
			label_letra.visible = false
		else:
			label_letra.visible = true
			label_letra.text = letra
			set_letter_font_size()
		

func _blink() -> void:
	start_remaining_hint()

func _blink_stop() -> void:
	stop_remaining_hint()


func start_remaining_hint() -> void:
	if _remaining_hint_active or panel_celda == null or numero >= 100:
		return
	_remaining_hint_active = true
	var style := _ensure_fondo_style()
	style.bg_color = color_fondo_blanco
	if is_instance_valid(_remaining_hint_tween):
		_remaining_hint_tween.kill()
	_remaining_hint_tween = create_tween()
	_remaining_hint_tween.set_loops()
	_remaining_hint_tween.tween_property(style, "bg_color", COLOR_HINT_YELLOW, 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_remaining_hint_tween.tween_property(style, "bg_color", color_fondo_blanco, 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func stop_remaining_hint() -> void:
	if not _remaining_hint_active:
		return
	_remaining_hint_active = false
	if is_instance_valid(_remaining_hint_tween):
		_remaining_hint_tween.kill()
	_remaining_hint_tween = null
	_refresh_fondo()


func _idle_fondo_color() -> Color:
	if color_id > 0 and color_id < GameManager.lista_tonos_colores.size():
		return GameManager.lista_tonos_colores[color_id]
	if es_regalo_inicial:
		return color_rellena
	if bloqueada and celda_mostrada:
		return color_fondo_blanco
	return color_init


func _exit_tree() -> void:
	if is_instance_valid(_remaining_hint_tween):
		_remaining_hint_tween.kill()

func configurar_celda(letra_config: String, numero_config: int, orden_config:int , color_id_config: int) -> void:
	color_id = color_id_config
	orden = orden_config
	letra = letra_config
	_inicializar_letra()
	numero = numero_config
	_inicializar_numero()
	_inicializar_puntuacion()
	
func set_number(number:int) -> void:
	numero = number
	
func set_letter(letter:String) -> void:
	letra = letter

func set_letter_user(letter:String) -> void:
	letter_user = letter
	
func set_order(order:int) -> void:
	orden = order
	
func asignar_letra(order:int) -> void:
	if _use_wide_letter_size():
		return
	var size := maxi(roundi(float(font_size_asignada) * _board_font_scale()), 8)
	label_numero.add_theme_font_size_override("font_size", size)

func _on_button_pressed() -> void:
	if _board_drag_blocks_selection():
		return
	if bloqueada and not revelada_verde:
		return
	if letra == " " or numero >= 100:
		return
	SoundManager.play("ClickCelda")
	SignalManager.puzzle_input.emit("cell", {
		"orden": orden,
		"numero": numero,
		"letter": letter_user,
	})
	GameManager.set_celda_seleccionada(orden, numero)
	if letter_user != "":
		GameManager.set_selected_letter_user(letter_user)
	else:
		GameManager.set_selected_letter_user("")
	
func cambia_color(color_a_cambiar: int) -> void:
	color_id = color_a_cambiar
	_same_number_highlight = false
	if celda_selected:
		celda_selected.visible = false
	if _remaining_hint_active:
		return
	_refresh_fondo()


func set_number_highlight(active: bool, is_primary: bool = false) -> void:
	_same_number_highlight = active
	if celda_selected:
		celda_selected.visible = is_primary
	if _remaining_hint_active:
		return
	_refresh_fondo()


func _refresh_fondo() -> void:
	if _same_number_highlight and color_id > 0:
		_set_fondo_color(COLOR_SELECTION)
	elif _same_number_highlight:
		_set_fondo_color(_idle_fondo_color().lerp(COLOR_SAME_NUMBER, 0.72))
	else:
		_set_fondo_color(_idle_fondo_color())


func _set_fondo_color(color: Color) -> void:
	if panel_celda == null:
		return
	var style := _ensure_fondo_style()
	style.bg_color = color


func _ensure_fondo_style() -> StyleBoxFlat:
	var current := panel_celda.get_theme_stylebox("panel")
	var style: StyleBoxFlat
	if current is StyleBoxFlat:
		style = current.duplicate() as StyleBoxFlat
	else:
		style = StyleBoxFlat.new()
	panel_celda.add_theme_stylebox_override("panel", style)
	return style

func deselect_all_cels() -> void:
	for celda:Celda in get_tree().get_nodes_in_group("Celda"):
		celda.deselect_cell()

func deselect_cell() -> void:
	set_number_highlight(false)


func release_pointer_press() -> void:
	var button := get_node_or_null("Fondo/Button") as BaseButton
	if button == null:
		return
	button.set_block_signals(true)
	button.disabled = true
	button.disabled = false
	button.set_block_signals(false)


func _board_drag_blocks_selection() -> bool:
	var node: Node = self
	while node != null:
		if node.has_method("is_suppressing_cell_selection"):
			return bool(node.call("is_suppressing_cell_selection"))
		node = node.get_parent()
	return false


func _gui_input(event: InputEvent) -> void:
	if not _board_drag_blocks_selection():
		return
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) \
			or event is InputEventScreenTouch \
			or event is InputEventScreenDrag:
		accept_event()

## Player assignment: visible letter, still editable.
func mostrar_letra_jugador() -> void:
	label_letra.text = letter_user
	set_letter_font_size()
	label_letra.visible = letter_user != ""
	label_letra.add_theme_color_override("font_color", color_font_default)
	celda_mostrada = letter_user != ""
	bloqueada = false
	es_regalo_inicial = false
	revelada_verde = false
	if celda_mostrada:
		stop_remaining_hint()

## Verified correct: white background, green letter, locked.
func mostrar_letra() -> void:
	stop_remaining_hint()
	label_letra.text = letter_user
	set_letter_font_size()
	label_letra.visible = true
	label_letra.add_theme_color_override("font_color", color_letra_correcta)
	color_id = 0
	celda_mostrada = true
	bloqueada = true
	revelada_verde = true
	_refresh_fondo()

func limpiar_letra_usuario() -> void:
	letter_user = ""
	label_letra.text = ""
	set_letter_font_size()
	label_letra.visible = false
	label_letra.add_theme_color_override("font_color", color_font_default)
	celda_mostrada = false
	bloqueada = false
	es_regalo_inicial = false
	revelada_verde = false

func mostrar_letra_errada() -> void:
	label_letra.text = letter_user
	set_letter_font_size()
	label_letra.add_theme_color_override("font_color", color_error)
	label_letra.visible = true
	celda_mostrada = false
	bloqueada = false
	revelada_verde = false

	
func mostrar_letra_especifica(letra_a_mostrar: String) -> void:
	#solo se usa para las letras que regalo al principio de la partida que así se diferencian de las del jugador
	letter_user = letra_a_mostrar
	label_letra.text = letra_a_mostrar
	set_letter_font_size()
	label_letra.visible = true
	label_letra.add_theme_color_override("font_color", color_font_default)
	celda_mostrada = true
	bloqueada = true
	es_regalo_inicial = true
	revelada_verde = false
	if color_id > 0:
		_refresh_fondo()
		return
	var style = StyleBoxFlat.new()
	style.bg_color = color_rellena
	panel_celda.add_theme_stylebox_override("panel", style)


func hide_letter_visual() -> void:
	if numero >= 100:
		return
	if label_letra:
		label_letra.visible = false


func apply_enter_letter_look(shown: String, orange: Color) -> void:
	letter_user = shown
	if label_letra == null:
		return
	label_letra.text = shown
	set_letter_font_size()
	label_letra.visible = true
	label_letra.add_theme_color_override("font_color", orange)
	celda_mostrada = true
	clip_contents = true
	if size.x > 1.0:
		pivot_offset = size * 0.5


func finish_enter_letter_look(as_gift: bool) -> void:
	clip_contents = false
	scale = Vector2.ONE
	if as_gift:
		mostrar_letra_especifica(letter_user if letter_user != "" else letra)
	elif label_letra:
		label_letra.add_theme_color_override("font_color", color_font_default)
