extends Panel

#@onready var OverlaySceneFondoAvisoBorrado := preload("res://scenes/fondo_aviso_borrado.tscn")

@onready var button_0: Button = $HBoxContainer/Button0
@onready var button_1: Button = $HBoxContainer/Button1
@onready var button_2: Button = $HBoxContainer/Button2
@onready var button_3: Button = $HBoxContainer/Button3
@onready var button_4: Button = $HBoxContainer/Button4
@onready var button_5: Button = $HBoxContainer/Button5

@onready var color1_usado: bool = false
@onready var color2_usado: bool = false
@onready var color3_usado: bool = false
@onready var color4_usado: bool = false
@onready var color5_usado: bool = false

@onready var paginas_abajo = $HBoxContainer/ButtonDown/PaginasAbajo

func _ready() -> void:
	for i in GameManager.lista_colores.size():
		var style = StyleBoxFlat.new()
		style.bg_color = GameManager.lista_tonos_colores[i]

		var button = $HBoxContainer.get_node("Button" + str(i ))
		button.add_theme_stylebox_override("normal", style)

func _on_button_0_pressed():
	
		#primero borra la casilla anterior de este color
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,0)
		

	
func _on_button_1_pressed() -> void:
	if color1_usado:
		#primero borra la casilla anterior de este color
		GameManager.pinta_celdas(GameManager.number_1,0)
		
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,1)
	color1_usado = true
	GameManager.set_number1(GameManager.celda_seleccionada_numero)


func _on_button_2_pressed() -> void:
	if color2_usado:
		#primero borra la casilla anterior de este color
		GameManager.pinta_celdas(GameManager.number_2,0)
		
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,2)
	color2_usado = true
	GameManager.set_number2(GameManager.celda_seleccionada_numero)


func _on_button_3_pressed() -> void:
	if color3_usado:
		#primero borra la casilla anterior de este color
		GameManager.pinta_celdas(GameManager.number_3,0)
		
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,3)
	color3_usado = true
	GameManager.set_number3(GameManager.celda_seleccionada_numero)

	
func _on_button_4_pressed() -> void:
	if color4_usado:
		#primero borra la casilla anterior de este color
		GameManager.pinta_celdas(GameManager.number_4,0)
		
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,4)
	color4_usado = true
	GameManager.set_number4(GameManager.celda_seleccionada_numero)

func _on_button_5_pressed() -> void:
	if color5_usado:
		#primero borra la casilla anterior de este color
		GameManager.pinta_celdas(GameManager.number_5,0)
		
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,5)
	color5_usado = true
	GameManager.set_number5(GameManager.celda_seleccionada_numero)


func _on_btn_erase_pressed() -> void:
	print("ERASE PRESSED")
	if GameManager.celda_seleccionada_numero>=100 or GameManager.celda_seleccionada_numero == 0 or GameManager.selected_letra=="":
		print("no hay celda seleccionada, no hace nada")
	else:
		SignalManager.erase_letter_open_dialog.emit()
		print("hay celda seleccionada ", GameManager.selected_letra)



func _on_button_down_pressed():
	SignalManager.mueve_filas.emit(-4,.5)
	#paginas_abajo.text = boton_page_down()
