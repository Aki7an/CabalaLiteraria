extends Panel
# Script final (Godot 4.4)

# Índices calculados de visibilidad
var first_full_visible_row: int = 0          # primera fila COMPLETA visible (0-based)
var first_partial_visible_row: int = 0       # primera fila al menos parcial
var last_partial_visible_row: int = 0        # última fila al menos parcial
var last_full_visible_row: int = 0           # última fila COMPLETA visible

@onready var color_rect_down = $ColorRectDown
@onready var color_rect_up = $ColorRectUp

# ------------------ Nodos ------------------
@onready var canvas_juego: Panel = $"."                 
@onready var grid_container: GridContainer = $GridContainer
var _input_blocker: Control = null

# Laterales
var _left_stripe: VBoxContainer
var _right_stripe: VBoxContainer

var _move_tween: Tween

# ------------------ Config ------------------
const DRAG_THRESHOLD := 8.0  # píxeles para considerar que es drag
const SCROLL_STEP := 80.0  # píxeles por “tic” de rueda (ajústalo a gusto)
const STRIPE_WIDTH := 80.0   # ancho de las columnas laterales

# ------------------ Estado input ------------------
var tocando: bool = false
var dragging: bool = false
var start_pos: Vector2 = Vector2.ZERO
var ultima_posicion: Vector2 = Vector2.ZERO


signal global_position_changed(new_global_pos: Vector2)

var _last_global_pos: Vector2

# ------------------ Escenas / datos ------------------
var escena_celda: PackedScene = preload("res://scenes/Celda/Celda.tscn")

# MoverCanvasJuego.gd  (adjunta este script al nodo que tenga como hijo a canvasJuego)

@onready var canvasJuego: = $"."  # ajusta la ruta si es distinta

# Parámetros por defecto
@export var from_y: float = 1420.0
@export var to_y: float = -440.0
@export var travel_time: float = 0.80

# Easing estándar de Tween
@export var trans_type: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT

# Si asignas una Curve aquí, se usará como curva de interpolación (0..1 → 0..1)
@export var curve_override: Curve

var _tween: Tween

## Mueve canvasJuego de X=inicio a X=fin en 'duration' segundos.
## Si 'start_from_current' es true, parte desde la X actual del nodo.
## Si pasas una Curve (o asignas curve_override en el Inspector), se usará como curva de easing personalizada.

# ----------------------------------------------------
#                       READY
# ----------------------------------------------------
func _ready() -> void:
	SignalManager.deselect_all_cells_in_canvas.connect(deselect_all_cels)
	SignalManager.insert_letter_in_number.connect(_insert_letter_in_number)
	SignalManager.move_canvas.connect(_move_canvas)
	SignalManager.añade_las_letras_iniciales.connect(_añade_las_letras_iniciales)
	SignalManager.mueve_filas.connect(pan_rows)
	
	_create_input_blocker()
	crear_linea_horizontal()
	reset_zoom_scale()
	reset_grid()

	# Crear columnas laterales
	_create_side_stripes()

	# Recalcular alturas cuando cambie el tamaño del grid y clamping
	grid_container.resized.connect(func ():
		_update_cell_min_heights()
		_rebuild_side_stripes()
		_rebuild_side_stripes()
		_clamp_canvas_y()
	)

# Activa las notificaciones de cambio de transform
	set_notify_transform(true)
	_last_global_pos = get_global_rect().position
	# (Opcional) emite al arrancar
	emit_signal("global_position_changed", _last_global_pos)
	
	# Si cambias columnas por señales externas:
	if SignalManager.has_signal("update_canvas_grid"):
		SignalManager.update_canvas_grid.connect(change_grid)

	await get_tree().process_frame
	_update_cell_min_heights()
	_rebuild_side_stripes()
	_clamp_canvas_y()
	position.y = GameManager.min_y_canvas
	update_position_botton_red_line()
	_añade_las_letras_iniciales()
	
	#move_canvas_juego(1420.0, -440.0, 0.9, Tween.TRANS_CUBIC, Tween.EASE_OUT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		# Para Control, usamos el rect global (incluye anclas, tamaños, etc.)
		var now := get_global_rect().position
		if now != _last_global_pos:
			_last_global_pos = now
			_on_canvas_global_moved(now)  # tu callback
			emit_signal("global_position_changed", now)

func _on_canvas_global_moved(new_pos: Vector2) -> void:
	# Aquí pones lo que quieras ejecutar cuando cambie la posición global
	# p.ej.: recalcular filas visibles, reconstruir laterales, etc.
	_update_visible_rows_info() # si usas la función que te pasé antes
	
func update_position_botton_red_line() ->void:
	color_rect_down.position.y = grid_bottom_in_parent(grid_container) + 6
	
	print("global position linea roja abajo: ", grid_bottom_global(grid_container) + 6)
	print("global position linea roja arriba: ", str(color_rect_up.position.y))
	
func grid_bottom_global(gc: GridContainer) -> float:
	# Si acabas de añadir hijos, espera 1 frame para que el layout se actualice:
	#await get_tree().process_frame
	return gc.global_position.y + gc.size.y
		
func grid_bottom_in_parent(gc: GridContainer) -> float:
	# Si acabas de añadir hijos, espera 1 frame para que el layout se actualice:
	#await get_tree().process_frame
	return gc.position.y + gc.size.y

func _create_side_stripes() -> void:
	# Crea contenedores laterales una única vez
	_left_stripe = VBoxContainer.new()
	_right_stripe = VBoxContainer.new()

	_left_stripe.name = "LeftStripe"
	_right_stripe.name = "RightStripe"

	# No queremos que capten el ratón (solo decoración)
	_left_stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right_stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Que ocupen exactamente su ancho
	_left_stripe.custom_minimum_size.x = STRIPE_WIDTH
	_right_stripe.custom_minimum_size.x = STRIPE_WIDTH

	# Asegura que estén en el mismo canvas del grid
	add_child(_left_stripe)
	add_child(_right_stripe)

	# Z opcional si quieres que queden por debajo/encima
	_left_stripe.z_index = grid_container.z_index
	_right_stripe.z_index = grid_container.z_index

func _rebuild_side_stripes() -> void:
	if _left_stripe == null or _right_stripe == null:
		return

	# Limpia contenido previo
	for c in _left_stripe.get_children():
		c.queue_free()
	for c in _right_stripe.get_children():
		c.queue_free()

	# Calcula alturas como en _update_cell_min_heights()
	var cols: int = max(1, grid_container.columns)
	var total_w: float = grid_container.size.x
	var hsep: int = _grid_hsep()
	var usable_w: float = total_w - float(hsep) * float(cols - 1)
	if usable_w <= 0.0:
		return
	var cell_w: float = usable_w / float(cols)
	var cell_h: float = cell_w * 2.0  # mismo ratio 1:2 que tus celdas

	# Número de filas actuales
	var filas: int = int(ceil(float(GameManager.TOTAL_CELDAS) / float(cols)))

	# Crea las tiras fila a fila, alternando color
	for i in range(filas):
		var color_even: Color  = Color(0.935, 0.852, 0.738)
		var color_odd: Color   = Color(0.617, 0.356, 0.275)
		var color_odd2: Color  = Color(0.277, 0.142, 0.1)

		# Secuencia: [odd, even, odd2, even] y repetir
		var cycle: Array[Color] = [color_odd, color_even, color_odd2, color_even]
		var col: Color = cycle[i % cycle.size()]

		var left_rect := ColorRect.new()
		left_rect.color = col
		left_rect.custom_minimum_size = Vector2(STRIPE_WIDTH, cell_h)
		left_rect.size_flags_horizontal = Control.SIZE_FILL
		left_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_left_stripe.add_child(left_rect)

		var right_rect := ColorRect.new()
		right_rect.color = col
		right_rect.custom_minimum_size = Vector2(STRIPE_WIDTH, cell_h)
		right_rect.size_flags_horizontal = Control.SIZE_FILL
		right_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_right_stripe.add_child(right_rect)

	# Posiciona las columnas pegadas al grid, a izquierda y derecha
	_left_stripe.position  = Vector2(grid_container.position.x - STRIPE_WIDTH, grid_container.position.y)
	_right_stripe.position = Vector2(grid_container.position.x + grid_container.size.x, grid_container.position.y)

	# Alto total igual al del grid (para evitar “sobresalir”)
	_left_stripe.custom_minimum_size.y = filas * cell_h + float(_grid_vsep()) * float(max(filas - 1, 0))
	_right_stripe.custom_minimum_size.y = _left_stripe.custom_minimum_size.y

func change_grid(step: int) -> void:
	grid_container.columns = max(1, grid_container.columns + step)
	_update_cell_min_heights()
	_rebuild_side_stripes()
	_clamp_canvas_y()
	var filas := int(ceil(GameManager.TOTAL_CELDAS / grid_container.columns))
	GameManager.set_columns_and_rows(grid_container.columns, filas)
	await get_tree().process_frame
	update_position_botton_red_line()
	GameManager.max_y_canvas = grid_container.position.y - grid_container.size.y + 40
	SignalManager.update_size_celdas.emit()

func reset_grid() -> void:
	grid_container.columns = max(1, GameManager.NUM_COLUMNAS)
	_update_cell_min_heights()
	_rebuild_side_stripes()
	_clamp_canvas_y()

func _update_cell_min_heights() -> void:
	var cols: int = max(1, grid_container.columns)
	var total_w: float = grid_container.size.x
	var hsep: int = _grid_hsep()
	var usable_w: float = total_w - float(hsep) * float(cols - 1)
	if usable_w <= 0.0:
		return
	var cell_w: float = usable_w / float(cols)
	var cell_h: float = cell_w * 2.0

	for child in grid_container.get_children():
		if child is AspectRatioContainer:
			var arc := child as AspectRatioContainer
			arc.custom_minimum_size = Vector2(cell_w, cell_h)
		elif child is Control:
			var c := child as Control
			c.custom_minimum_size.y = cell_h

	# reconstruye laterales con el nuevo alto de fila
	_rebuild_side_stripes()
	_clamp_canvas_y()

	
func _añade_las_letras_iniciales() -> void:
	#falta revisar las Letras y pintarlas en pantalla independientemente de si hay o no letras en la frase
		# Buscar todos los nodos que pertenezcan al grupo "Letra"
	var letras := get_tree().get_nodes_in_group("Letra")
	
	for letra in letras:
		for caracter in GameManager.letras_iniciales:
			if letra.letra == caracter:
				letra.muestra_letra()
				#print(caracter)
			
			
	
	# Asegúrate de tener celdas en el árbol
	var celdas := get_tree().get_nodes_in_group("Celda")
	if celdas.is_empty():
		# Reintenta en el siguiente frame (evita llamar en bucle si nunca se instancian)
		call_deferred("_añade_las_letras_iniciales")
		return

	# Nada que hacer si no hay letras iniciales
	if GameManager.letras_iniciales.strip_edges() == "":
		return

	# Normaliza y evita duplicados (por si "ATDBA" repite A)
	var letras_set := {}
	var s : String = GameManager.letras_iniciales.to_upper()
	for i in s.length():
		var ch := s[i]
		if not GameManager.EXCLUIR.has(ch):
			letras_set[ch] = true

	# Para cada letra inicial, calcula su número (mapeo dinámico actual)
	for letter in letras_set.keys():
		var num_objetivo := GameManager.letra_a_numero(letter) + 1  # tus celdas usan +1
		if num_objetivo <= 0:
			continue  # letra no encontrada en el alfabeto actual

		# Rellena todas las celdas cuyo número coincida
		for celda in celdas:
			# Saltar signos/espacios (tu convenio usa >=100 para no-jugables)
			#if not celda.has_variable("numero"):
				#continue
			if celda.numero >= 100:
				continue
			if celda.numero != num_objetivo:
				continue
			
			if (String(celda.letra) == letter):
				celda.mostrar_letra_especifica(letter)
				#print("LETRA:" , letter)
				#celda.set_user_letter(letter)
				
				
			elif celda.has_method("set_letter"):
				# Si tu set_letter está pensada para "cargar" la frase, úsala solo si en tu UI es correcto
				celda.set_letter(letter)
			else:
				# Fallback directo a la propiedad (asumiendo que el Label interno se actualiza al settear letra)
				celda.letra = letter

			# Cuenta esta revelación
			GameManager.update_numero_letras_reveladas()

# ----------------------------------------------------
#                     INPUT
# ----------------------------------------------------
func _input(event: InputEvent) -> void:
	var pos: Vector2 = _event_pos(event)
	

	# Desplazar solo si el puntero/gesto está sobre el canvas
	if event is InputEventMouseButton and _is_over_canvas(_event_pos(event)):
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			# rueda arriba -> mover contenido hacia arriba (Y menor)
			canvas_juego.position.y -= SCROLL_STEP
			_clamp_canvas_y()
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# rueda abajo -> mover contenido hacia abajo (Y mayor)
			canvas_juego.position.y += SCROLL_STEP
			_clamp_canvas_y()
			accept_event()

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _is_over_canvas(pos):
			tocando = true
			dragging = false
			start_pos = pos
			ultima_posicion = pos
			# No mostramos el blocker aquí; dejamos pasar el press a las celdas.
		elif not touch.pressed and tocando:
			# Fin del gesto
			if dragging:
				# Fue drag: ocultar y CONSUMIR el release (evita click fantasma)
				_input_blocker.hide()
				accept_event()
			else:
				# Fue tap: permitir selección normal
				_input_blocker.hide()
			tocando = false
			dragging = false

	elif event is InputEventScreenDrag and tocando:
		var drag := event as InputEventScreenDrag
		# Activar bloqueo cuando superamos el umbral
		if not dragging and (pos - start_pos).length() >= DRAG_THRESHOLD:
			dragging = true
			_input_blocker.show()

		if dragging:
			var delta: Vector2 = drag.position - ultima_posicion
			# Pan SOLO en eje Y
			canvas_juego.position.y += delta.y
			_clamp_canvas_y()
			ultima_posicion = drag.position

	elif event is InputEventMagnifyGesture and _is_over_canvas(pos):
		var mag := event as InputEventMagnifyGesture
		var nuevo_escala: Vector2 = canvas_juego.scale * mag.factor
		nuevo_escala = nuevo_escala.clamp(Vector2(0.5, 0.5), Vector2(3, 3))
		canvas_juego.scale = nuevo_escala
		_update_cell_min_heights() # por si el layout depende visualmente del zoom
		_rebuild_side_stripes()
		_clamp_canvas_y()


# ----------------------------------------------------
#                 LAYOUT / GRID UTILS
# ----------------------------------------------------
#func change_grid(step: int) -> void:
	#grid_container.columns = max(1, grid_container.columns + step)
	#_update_cell_min_heights()
	#_rebuild_side_stripes()
	#_clamp_canvas_y()
	#var filas := int(ceil(GameManager.TOTAL_CELDAS / grid_container.columns))
	#GameManager.set_columns_and_rows(grid_container.columns, filas)
	#await get_tree().process_frame
	#update_position_botton_red_line()
	##pan_to_y(GameManager.min_y_canvas, 0.5)
	#GameManager.max_y_canvas = grid_container.position.y - grid_container.size.y + 40
	##print("Nueva posicion: ", GameManager.max_y_canvas)
	#
#func reset_grid() -> void:
	#grid_container.columns = max(1, GameManager.NUM_COLUMNAS)
	#_update_cell_min_heights()
	#_rebuild_side_stripes()
	#_clamp_canvas_y()

func _grid_hsep() -> int:
	return grid_container.get_theme_constant("h_separation")

func _grid_vsep() -> int:
	return grid_container.get_theme_constant("v_separation")

# Ajusta el alto mínimo por fila para evitar solapes (ratio 1:2)
#func _update_cell_min_heights() -> void:
	#var cols: int = max(1, grid_container.columns)
	#var total_w: float = grid_container.size.x
	#var hsep: int = _grid_hsep()
	#var usable_w: float = total_w - float(hsep) * float(cols - 1)
	#if usable_w <= 0.0:
		#return
	#var cell_w: float = usable_w / float(cols)
	#var cell_h: float = cell_w * 2.0  # ratio 1:2 => alto = 2*ancho
#
	#for child in grid_container.get_children():
		#if child is AspectRatioContainer:
			#var arc := child as AspectRatioContainer
			#arc.custom_minimum_size = Vector2(cell_w, cell_h)
		#elif child is Control:
			#var c := child as Control
			#c.custom_minimum_size.y = cell_h
	#_clamp_canvas_y()

# Limita la posición Y del canvas para que:
#  - Primera fila quede arriba (y = 0)
#  - Última fila quede abajo (y = viewport_h - content_h), considerando zoom
func _clamp_canvas_y() -> void:
	var parent_ctrl := get_parent() as Control
	#print("Y:" + str(canvas_juego.position.y))
	#print("Y Global:" + str(canvas_juego.global_position.y))
	#print("Linea abajo Global:" + str(color_rect_down.global_position.y))
	#print("Grid Container Size:" + str(grid_container.size))
	
	#GameManager.calculate_max_y_canvas()
	
	if GameManager.max_y_canvas <= canvas_juego.position.y:
		#canvas_juego.position.y = clamp(canvas_juego.position.y, min_y, max_y)
		canvas_juego.position.y = clamp(canvas_juego.position.y, GameManager.max_y_canvas, GameManager.min_y_canvas)

		# Evita “temblores” por flotantes
		canvas_juego.position.y = round(canvas_juego.position.y)
		print("Position CanvasLJuego:" , canvas_juego.global_position.y)
	else:
		canvas_juego.position.y = GameManager.max_y_canvas


# ----------------------------------------------------
#               CREACIÓN DE CELDAS
# ----------------------------------------------------
func crear_linea_horizontal() -> void:
	for i in range(GameManager.lista_letras_frase_original.size()):
		var aspect_container := AspectRatioContainer.new()
		aspect_container.ratio = 0.5  # 1:2 (ancho:alto)
		aspect_container.stretch_mode = AspectRatioContainer.STRETCH_WIDTH_CONTROLS_HEIGHT
		aspect_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		aspect_container.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		# No fijamos min_size aquí; lo calculará _update_cell_min_heights()

		var celda := escena_celda.instantiate()
		celda.set_order(i)
		celda.set_letter(GameManager.lista_letras_frase_original[i])
		celda.set_number(GameManager.lista_numeros_frase_original[i])
		celda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		celda.size_flags_vertical   = Control.SIZE_EXPAND_FILL

		GameManager.añade_celda(celda)
		aspect_container.add_child(celda)
		grid_container.add_child(aspect_container)

# ----------------------------------------------------
#               GESTIÓN DE CELDAS
# ----------------------------------------------------

func _insert_letter_in_number(letter2: String, number: int) -> void:
	#CORREGIR, he de dar letra y numero y poner la letra que me da, no la que tiene realmente...
	#print("numero seleccionado a comprobar: " + str(number))
	for celda: Celda in get_tree().get_nodes_in_group("Celda"):
		if celda.numero == number:
			celda.set_letter(letter2)
			celda.set_letter_user(letter2)
			#print(" letter2: " + letter2)
			#print(" number: " + str(number))
			celda.mostrar_letra()
			if celda.letter_user != "":
				GameManager.update_numero_letras_reveladas()
			else:
				GameManager.disminuye_numero_letras_reveladas()
	# deselect Celda
	SignalManager.deselect_all_cells_in_canvas.emit()
	
	
# ----------------------------------------------------
#                 BLOQUEO DE INPUT
# ----------------------------------------------------
func _create_input_blocker() -> void:
	_input_blocker = Control.new()
	_input_blocker.name = "InputBlocker"
	_input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP  # captura todo
	_input_blocker.modulate.a = 0.0                          # invisible
	_input_blocker.z_index = 1000
	_input_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_input_blocker)  # por encima del grid
	_input_blocker.hide()

# ----------------------------------------------------
#                 HELPERS / VARIOS
# ----------------------------------------------------
func _is_over_canvas(pos: Vector2) -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered and (hovered == canvas_juego or canvas_juego.is_ancestor_of(hovered)):
		return true
	return canvas_juego.get_global_rect().has_point(pos)

func _event_pos(event: InputEvent) -> Vector2:
	if "position" in event:
		return event.position
	return get_viewport().get_mouse_position()

func reset_zoom_scale() -> void:
	canvas_juego.scale = Vector2.ONE

func deselect_all_cels() -> void:
	if get_tree() == null:
		return
	
	for c in get_tree().get_nodes_in_group("Celda"):
		if is_instance_valid(c) and c.has_node("CeldaSelected"):
			c.celda_selected.visible = false
	 
func _move_canvas(wide:int) -> void:
	var v:float = position.y - wide
	if v <= GameManager.min_y_canvas and v >= GameManager.max_y_canvas:
		#position.y = position.y - wide
		pan_to_y(position.y - wide, .5)
	else:
		if v >= GameManager.min_y_canvas:
			pan_to_y(GameManager.min_y_canvas, .5)
			#position.y = GameManager.min_y_canvas
		else:
			pan_to_y(GameManager.max_y_canvas, .5)
			#position.y = GameManager.max_y_canvas

func pan_to_y(target_y: float, duration: float = 0.5) -> void:
	# Asegúrate de que el Panel no está dentro de un VBox/HBox/Grid/… (si no, un Container pisará la posición)
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(self, "position:y", target_y, duration)

# --- Cálculo de alto de una fila (celda + separación vertical) ---
func _row_height() -> float:
	var cols: int = max(1, grid_container.columns)
	var total_w: float = grid_container.size.x
	var hsep: int = _grid_hsep()
	var usable_w: float = total_w - float(hsep) * float(cols - 1)
	if usable_w <= 0.0:
		return 0.0
	var cell_w: float = usable_w / float(cols)
	var cell_h: float = cell_w * 2.0  # mismo ratio 1:2 que usas en las celdas
	return cell_h + float(_grid_vsep())

# --- Mueve el canvas N filas (positivas hacia abajo, negativas hacia arriba) con tween ---
func pan_rows(delta_rows: int, duration: float = 0.35) -> void:
	#print(color_rect_down.global_position.y)
	if delta_rows<0 and color_rect_down.global_position.y <= 1420:
		return
	#if delta_rows < 0 and position.y <= (GameManager.max_y_canvas + .5) :
		#return
	
	var step_px: float = _row_height() * float(delta_rows)
	if step_px == 0.0:
		return
	var target_y: float = position.y + step_px
	# Limitar al rango válido del canvas
	target_y = clamp(target_y, GameManager.max_y_canvas, GameManager.min_y_canvas)
	pan_to_y(round(target_y), duration)
	
	
func move_canvas_juego(
		start_y: float = from_y,
		end_y: float = to_y,
		duration: float = travel_time,
		trans: Tween.TransitionType = trans_type,
		ease: Tween.EaseType = ease_type,
		curve: Curve = curve_override,
		start_from_current: bool = false
	) -> void:
	# Evita tweens solapados
	if is_instance_valid(_tween):
		_tween.kill()

	# Punto de partida tipado explícito (float)
	var s_y: float = (canvasJuego.position.y if start_from_current else start_y)
	canvasJuego.position.x = s_y

	var t: Tween = create_tween()
	_tween = t

	if curve != null:
		# Usamos MethodTweener tipado para evitar Variant
		var mt: MethodTweener = t.tween_method(
			func(alpha: float) -> void:
				var a: float = clamp(alpha, 0.0, 1.0)
				var eased: float = clamp(curve.sample(a), 0.0, 1.0)
				canvasJuego.position.y = lerp(s_y, end_y, eased),
			0.0, 1.0, duration
		)
		mt.set_trans(trans)
		mt.set_ease(ease)
	else:
		# Propiedad tipada a PropertyTweener
		var pt: PropertyTweener = t.tween_property(canvasJuego, "position:y", end_y, duration)
		pt.set_trans(trans)
		pt.set_ease(ease)

	# (Opcional) esperar fin:
	# await _tween.finished




















# Alto SOLO de la celda (sin separación)
func _cell_height_only() -> float:
	var cols: int = max(1, grid_container.columns)
	var total_w: float = grid_container.size.x
	var hsep: int = _grid_hsep()
	var usable_w: float = total_w - float(hsep) * float(cols - 1)
	if usable_w <= 0.0:
		return 0.0
	var cell_w: float = usable_w / float(cols)
	return cell_w * 2.0  # ratio 1:2 (ancho:alto) => alto = 2*ancho

# Rango de filas potenciales
func _rows_count() -> int:
	var cols :int= max(1, grid_container.columns)
	return int(ceil(float(GameManager.TOTAL_CELDAS) / float(cols)))

# Recalcula los índices de filas visibles (parcial y completa)
func _update_visible_rows_info() -> void:
	var parent_ctrl := get_parent() as Control
	if parent_ctrl == null:
		return

	var rh := _row_height()                    # celda + v_sep
	var ch := _cell_height_only()              # alto celda sin v_sep
	if rh <= 0.0 or ch <= 0.0:
		first_full_visible_row = 0
		first_partial_visible_row = 0
		last_partial_visible_row = 0
		last_full_visible_row = 0
		return

	# Ventana de visualización del padre (en coords del padre)
	var view_top    := 0.0
	var view_bottom := parent_ctrl.size.y

	# Y superior del grid dentro del padre (porque mueves self.position.y)
	var grid_top := position.y + grid_container.position.y

	# Primeras estimaciones por división
	var approx_first := int(floor((view_top - grid_top) / rh))
	approx_first = max(0, approx_first)

	var rows_total := _rows_count()
	var approx_last := int(floor((view_bottom - grid_top) / rh))
	approx_last = clamp(approx_last, 0, max(0, rows_total - 1))

	# Parcialmente visibles (cualquier intersección con la ventana)
	first_partial_visible_row = approx_first
	last_partial_visible_row  = approx_last

	# Ahora ajusta para COMPLETAMENTE visible
	var r := approx_first
	var top_y := grid_top + float(r) * rh
	var bottom_y := top_y + ch

	# Sube hasta que la fila esté totalmente dentro (si cabe)
	while r < rows_total and (top_y < view_top or bottom_y > view_bottom):
		r += 1
		top_y = grid_top + float(r) * rh
		bottom_y = top_y + ch

	# Si ninguna fila cabe completa (viewport más bajo que ch), marca -1
	if r >= rows_total or ch > (view_bottom - view_top):
		first_full_visible_row = -1
		last_full_visible_row = -1
	else:
		first_full_visible_row = r

		# Buscar la última COMPLETA visible a partir de r
		var last_full := r
		while last_full + 1 < rows_total:
			var next_top    := grid_top + float(last_full + 1) * rh
			var next_bottom := next_top + ch
			if next_bottom <= view_bottom:
				last_full += 1
			else:
				break
		last_full_visible_row = last_full
