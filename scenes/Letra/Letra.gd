extends Control
class_name Letra

# Inicialmente la letra no tiene un numero asignado. Ni 0, es -1

@export var letra_mostrada: bool  = false
@export var verificada_correcta: bool = false

# Letra que contiene la celda (puede estar vacía inicialmente)
@export var letra: String = ""

@export var font_size_inicial: int = 40 #40
@export var font_size_asignada: int = 30

# Número asociado a la celda (1-27)0 es cuando no tiene nada asociado
@export var numero: int = 0

# Número asociado a la celda dentro de todas las que son en la frase. Orden en la frase
@export var orden: int = 0

# ID del color asignado (0 = ninguno, 1–5 según lista_colores del GameManager)
@export var color_id: int = 0

# La celda ha de tener también los signos de ortografia: , " : ;... pueden hasta ser dos ".
@export  var punto_ortografia: String = ""

#@onready var panel_celda: Panel = $PanelCelda
@onready var panel_letra: Panel = $PanelLetra


@onready var label_numero = $PanelLetra/LabelNumero
@onready var label_letra = $PanelLetra/LabelLetra

@onready var letra_selected = $PanelLetra/LetraSelected
@onready var button = $PanelLetra/Button

#@onready var tween := get_tree().create_tween()

@onready var color_normal: Color = Color(0.97, 0.91, 0.8)
@onready var color_selected: Color = Color(0.86, 0.78, 0.66)
@onready var color_selected_por_inicio: Color = Color(0.8, 0.72, 0.6)
@onready var color_correct: Color = Color(0.66, 0.84, 0.5)
@onready var color_error: Color = Color(0.96, 0.48, 0.42)

func _ready():
	SignalManager.erase_selected_letter.connect(_erase_letter)
	
	_inicializar_letra()
	_inicializar_numero()
	letra_selected.visible = false
	_apply_panel_color(color_normal)
	
func _inicializar_letra() -> void:
	label_letra.text = letra
	letra_mostrada = false
	verificada_correcta = false
	letra_selected.visible = false
	#label_numero.add_theme_font_size_override("font_size",font_size_inicial )


func _inicializar_numero() -> void:
	label_numero.text = str(numero)
	label_numero.visible = false


func configurar_letra(letra_config: String, numero_config: int, 
orden_config:int , color_id_config: int) -> void:
	color_id = color_id_config
	orden = orden_config
	letra = letra_config
	_inicializar_letra()
	numero = numero_config
	_inicializar_numero()

	
func set_number(number:int) -> void:
	numero = number
	
func set_letter(letter:String) -> void:
	letra = letter
	
func set_order(order:int) -> void:
	orden = order
	
func asignar_letra(order:int) -> void:
	label_numero.add_theme_font_size_override("font_size",font_size_asignada)

func hay_fondo_compra_letra() -> bool:
	return get_tree().get_nodes_in_group("FondoCompraLetra").size() > 0

func obtener_fondo_compra_letra() -> Node:
	var arr := get_tree().get_nodes_in_group("FondoCompraLetra")
	return arr[0] if arr.size() > 0 else null

func _on_button_pressed() -> void:
	if !hay_fondo_compra_letra() and (GameManager.celda_seleccionada_numero >= 100 or GameManager.celda_seleccionada_numero == 0):
		# avoid selection of Letters if no Cell is selected
		return

	if hay_fondo_compra_letra():
		SignalManager.letra_seleccionada_para_comprar.emit(letra)
		return

	# Verified green letters stay locked on the keyboard.
	if verificada_correcta:
		return

	# Letter already used elsewhere cannot be reused (unless freeing via replace below).
	if letra_mostrada:
		return

	# Selected cell must be editable (not verified / initial gift).
	if GameManager.seleccion_es_letra_verificada_correcta():
		return

	var previous_letter := GameManager.selected_letra.strip_edges()
	var target_number := GameManager.celda_seleccionada_numero

	# Changing an existing unverified assignment: free the old keyboard letter first.
	if previous_letter != "" and previous_letter.to_upper() != letra.to_upper():
		GameManager.liberar_letra_teclado(previous_letter)

	print("Tocada LETRA con letra:", letra)
	GameManager.set_selected_letter_user(letra)
	SoundManager.play("ClickLetra")
	_apply_panel_color(color_selected)
	letra_mostrada = true
	verificada_correcta = false
	SignalManager.insert_letter_in_number.emit(letra, target_number)
	print("Seleccionada Celda:", GameManager.selected_celda_number)
	GameManager.reset_cell_select()
	SignalManager.update_resting_characters.emit()
	if GameManager.hay_letra_que_borrar():
		SignalManager.update_rubber.emit()
	SignalManager.asignar_letra.emit(
		GameManager.tiempo_partida,
		GameManager.selected_letra
	)
	SignalManager.update_difficulty.emit(
		GameManager.frase_original,
		GameManager.recoger_letras_mostradas()
	)
	PuzzleSaveManager.request_autosave()


func _erase_letter() -> void:
	var selected := GameManager.selected_letra.strip_edges().to_upper()
	if selected == "" or letra.to_upper() != selected:
		return
	if verificada_correcta:
		return

	# Clear this letter from every editable cell on the board.
	GameManager.borrar_letra_en_tablero(selected)
	GameManager.reset_cell_select()
	SignalManager.update_resting_characters.emit()
	verificada_correcta = false
	letra_mostrada = false
	_inicializar_letra()
	_apply_panel_color(color_normal)
	SignalManager.update_difficulty.emit(
		GameManager.frase_original,
		GameManager.recoger_letras_mostradas()
	)
	SoundManager.play("LoseLive")
	SignalManager.update_cambios.emit()
	SignalManager.update_rubber.emit()
	PuzzleSaveManager.request_autosave()


func liberar_para_reuso() -> void:
	if verificada_correcta:
		return
	letra_mostrada = false
	verificada_correcta = false
	letra_selected.visible = false
	_apply_panel_color(color_normal)


func restore_as_assigned() -> void:
	letra_mostrada = true
	verificada_correcta = false
	letra_selected.visible = false
	_apply_panel_color(color_selected)


func cambia_color(color_a_cambiar: int) -> void:
	_apply_panel_color(GameManager.lista_tonos_colores[color_a_cambiar])
	
func deselect_all_letters() -> void:
	for letra_node in get_tree().get_nodes_in_group("Letra"):
		letra_node.letra_selected.visible = false

func muestra_letra() -> void:
	letra_mostrada = true
	letra_selected.visible = false
	_apply_panel_color(color_selected_por_inicio)


func mark_as_correct() -> void:
	letra_mostrada = true
	verificada_correcta = true
	letra_selected.visible = false
	_apply_panel_color(color_correct)


func mark_as_wrong_deselected() -> void:
	letra_mostrada = false
	verificada_correcta = false
	letra_selected.visible = false
	_apply_panel_color(color_error)


func mark_as_unassigned() -> void:
	letra_mostrada = false
	verificada_correcta = false
	letra_selected.visible = false
	_apply_panel_color(color_normal)


func _apply_panel_color(color: Color) -> void:
	var current := panel_letra.get_theme_stylebox("panel")
	var style: StyleBoxFlat
	if current is StyleBoxFlat:
		style = current.duplicate() as StyleBoxFlat
	else:
		style = StyleBoxFlat.new()
	style.bg_color = color
	panel_letra.add_theme_stylebox_override("panel", style)
