extends Control
class_name Letra

# Inicialmente la letra no tiene un numero asignado. Ni 0, es -1

@export var letra_mostrada: bool  = false

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

@onready var color_normal: Color = Color(0.985, 0.91, 0.73)
@onready var color_selected: Color = Color(0.91, 0.72, 0.42)
@onready var color_selected_por_inicio: Color = Color(0.69, 0.65, 0.56)
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

## Devuelve true si en el árbol (desde 'from') hay un nodo instanciado
## desde la escena indicada por 'scene_path' (p.ej. "res://ui/HintsPanel.tscn").
#func has_scene_instance(scene_path: String, from: Node = self) -> bool:
	#print("intenta detectar")
	#if from.scene_file_path == scene_path:
		#return true
	#for c in from.get_children():
		#if has_scene_instance(scene_path, c):
			#return true
	#return false
#
## Ejemplo
func hay_fondo_compra_letra() -> bool:
	return get_tree().get_nodes_in_group("FondoCompraLetra").size() > 0

func obtener_fondo_compra_letra() -> Node:
	var arr := get_tree().get_nodes_in_group("FondoCompraLetra")
	return arr[0] if arr.size() > 0 else null

func _on_button_pressed() -> void:

	if !hay_fondo_compra_letra() and (GameManager.celda_seleccionada_numero>=100 or GameManager.celda_seleccionada_numero == 0):
		# avoid selection of Letters if no Cell is selected

		return
		
	if letra_mostrada == true:
			return
	else:
		#letter not showed, but dont know if CELL has letter or not
		#print("paso por aqui inicial")
		#if GameManager.selected_letra == "":
		# not letter in CELL
		# mira si no estoy en la pantalla de comprar letras
		if hay_fondo_compra_letra():
			#estoy
			var nodo := obtener_fondo_compra_letra()
			#print("Encontrado:", nodo)
			SignalManager.letra_seleccionada_para_comprar.emit(letra)
		else:
		# not in buy screen
			print("Tocada LETRA con letra:", letra)
			GameManager.set_selected_letter_user(letra)
			SoundManager.play("ClickLetra")
			_apply_panel_color(color_selected)
			letra_mostrada = true
			SignalManager.insert_letter_in_number.emit(
				letra,
				GameManager.celda_seleccionada_numero
			)
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
	
func _erase_letter() -> void:
	#ERASE selection and enable letter again
	
	SignalManager.insert_letter_in_number.emit("",GameManager.celda_seleccionada_numero)

	GameManager.reset_cell_select()
	SignalManager.update_resting_characters.emit()
	letra_mostrada = false
	_inicializar_letra()
	SignalManager.update_difficulty.emit(GameManager.frase_original, GameManager.recoger_letras_mostradas()) 
	# change color of the CELL
	_apply_panel_color(color_normal)
	
	SoundManager.play("LoseLive")
	
	SignalManager.update_cambios.emit()
			
			
func cambia_color(color_a_cambiar: int) -> void:
	_apply_panel_color(GameManager.lista_tonos_colores[color_a_cambiar])
	
func deselect_all_letters() -> void:
	for letra in get_tree().get_nodes_in_group("Letra"):
		letra.letra_selected.visible = false

func muestra_letra() -> void:
	letra_mostrada = true
	letra_selected.visible = false
	_apply_panel_color(color_selected_por_inicio)


func mark_as_correct() -> void:
	letra_mostrada = true
	letra_selected.visible = false
	_apply_panel_color(color_correct)


func mark_as_wrong_deselected() -> void:
	letra_mostrada = false
	letra_selected.visible = false
	_apply_panel_color(color_error)


func mark_as_unassigned() -> void:
	letra_mostrada = false
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
