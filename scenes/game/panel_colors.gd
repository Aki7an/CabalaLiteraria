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
	if not SignalManager.rubber_feedback.is_connected(_on_rubber_feedback):
		SignalManager.rubber_feedback.connect(_on_rubber_feedback)
	var erase_label := get_node_or_null("HBoxContainer/Button0/Content/Label") as Label
	if erase_label:
		erase_label.text = tr("TutEraseButton")
	var instruction := get_node_or_null("Instruction") as Label
	if instruction:
		instruction.text = tr("TutCaption2")
	for i in range(1, GameManager.lista_colores.size()):
		var button: Button = $HBoxContainer.get_node("Button" + str(i))
		var current := button.get_theme_stylebox("normal")
		var style: StyleBoxFlat
		if current is StyleBoxFlat:
			style = current.duplicate() as StyleBoxFlat
		else:
			style = StyleBoxFlat.new()
		style.bg_color = GameManager.lista_tonos_colores[i]
		button.add_theme_stylebox_override("normal", style)
	_apply_onboarding_color_lock()


func _apply_onboarding_color_lock() -> void:
	if not GameManager.is_onboarding_session() or GameManager.onboarding_stage != 1:
		return
	var box := get_node_or_null("HBoxContainer")
	if box == null:
		return
	for i in range(1, 6):
		var button := box.get_node_or_null("Button%d" % i) as CanvasItem
		if button:
			button.modulate = Color(1, 1, 1, 0.42)


func _block_onboarding_colors() -> bool:
	if not GameManager.is_onboarding_session() or GameManager.onboarding_stage != 1:
		return false
	var guide := get_tree().get_first_node_in_group("OnboardingGuide")
	if guide and guide.has_method("show_later_tools_message"):
		guide.show_later_tools_message()
		return true
	return false

func _on_rubber_feedback() -> void:
	if is_instance_valid(button_0) and button_0.is_in_group("EraseButton"):
		GameManager.button_blink_repeat(button_0, 2)


func _on_button_0_pressed():
	
		#primero borra la casilla anterior de este color
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,0)
		

	
func _on_button_1_pressed() -> void:
	if _block_onboarding_colors():
		return
	if color1_usado or GameManager.number_1 != 0:
		#primero borra la casilla anterior de este color
		GameManager.pinta_celdas(GameManager.number_1,0)
		
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,1)
	color1_usado = true
	GameManager.set_number1(GameManager.celda_seleccionada_numero)
	_log_color(1)


func _on_button_2_pressed() -> void:
	if _block_onboarding_colors():
		return
	if color2_usado or GameManager.number_2 != 0:
		#primero borra la casilla anterior de este color
		GameManager.pinta_celdas(GameManager.number_2,0)
		
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,2)
	color2_usado = true
	GameManager.set_number2(GameManager.celda_seleccionada_numero)
	_log_color(2)


func _on_button_3_pressed() -> void:
	if _block_onboarding_colors():
		return
	if color3_usado or GameManager.number_3 != 0:
		#primero borra la casilla anterior de este color
		GameManager.pinta_celdas(GameManager.number_3,0)
		
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,3)
	color3_usado = true
	GameManager.set_number3(GameManager.celda_seleccionada_numero)
	_log_color(3)

	
func _on_button_4_pressed() -> void:
	if _block_onboarding_colors():
		return
	if color4_usado or GameManager.number_4 != 0:
		#primero borra la casilla anterior de este color
		GameManager.pinta_celdas(GameManager.number_4,0)
		
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,4)
	color4_usado = true
	GameManager.set_number4(GameManager.celda_seleccionada_numero)
	_log_color(4)

func _on_button_5_pressed() -> void:
	if _block_onboarding_colors():
		return
	if color5_usado or GameManager.number_5 != 0:
		#primero borra la casilla anterior de este color
		GameManager.pinta_celdas(GameManager.number_5,0)
		
	GameManager.pinta_celdas(GameManager.celda_seleccionada_numero,5)
	color5_usado = true
	GameManager.set_number5(GameManager.celda_seleccionada_numero)
	_log_color(5)


func _on_btn_erase_pressed() -> void:
	if GameManager.celda_seleccionada_numero >= 100 \
			or GameManager.celda_seleccionada_numero == 0:
		return

	# A colored cell uses the eraser to remove that annotation first.
	# The color is shared by cipher number, so all matching cells are cleared.
	if GameManager.borrar_color_de_numero(GameManager.celda_seleccionada_numero):
		color1_usado = GameManager.number_1 != 0
		color2_usado = GameManager.number_2 != 0
		color3_usado = GameManager.number_3 != 0
		color4_usado = GameManager.number_4 != 0
		color5_usado = GameManager.number_5 != 0
		SignalManager.puzzle_input.emit("erase", {
			"kind": "color",
			"numero": GameManager.celda_seleccionada_numero,
		})
		SoundManager.play("Erase")
		SignalManager.update_rubber.emit()
		return

	if GameManager.selected_letra == "":
		return
	if GameManager.seleccion_es_letra_verificada_correcta():
		# Verified green letters cannot be erased.
		return

	var letra := GameManager.selected_letra
	var celda := GameManager.selected_celda_number
	SignalManager.puzzle_input.emit("erase", {
		"kind": "letter",
		"letter": letra,
		"numero": celda,
	})
	GameManager.cambios_increase()
	SignalManager.erase_letter.emit(letra)
	SignalManager.update_rubber.emit()
	SignalManager.update_cambios.emit()
	SignalManager.añade_las_letras_iniciales.emit()
	SignalManager.borrar_letra.emit(GameManager.tiempo_partida, celda, letra)


func _log_color(slot: int) -> void:
	SignalManager.puzzle_input.emit("color_%d" % slot, {
		"slot": slot,
		"numero": GameManager.celda_seleccionada_numero,
	})


func _on_button_down_pressed():
	SignalManager.mueve_filas.emit(-4,.5)
	#paginas_abajo.text = boton_page_down()
