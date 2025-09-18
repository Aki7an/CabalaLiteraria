extends Node2D

@onready var _1 = $"Label/Control/1"
@onready var _2 = $"Label/Control/2"
@onready var _3 = $"Label/Control/3"
@onready var _4 = $"Label/Control/4"
@onready var _5 = $"Label/Control/5"
@onready var _6 = $"Label/Control/6"
@onready var _7 = $"Label/Control/7"

@onready var button_1 = $Button1
@onready var button_2 = $Button2
@onready var button_3 = $Button3
@onready var button_4 = $Button4
@onready var button_5 = $Button5
@onready var button_6 = $Button6
@onready var button_7 = $Button7

#@onready var button_1: Button = $Button1
@onready var btn: = $Botton1   # ajusta la ruta si es distinta
# GameManager.gd (autoload)

@onready var check_box :CheckBox = $Label/Control/CheckBox

#@onready var button_back = $ButtonBack


func _on_button_back_pressed():
	if GameManager.go_to_game:
		SignalManager.partida_iniciada.emit()
		TransitionScreen.transition_to_black()
		await TransitionScreen._on_animation_finished("fade_to_black", 1)
		get_tree().change_scene_to_file("res://scenes/App.tscn")
		SoundManager.play("ButtonClick")

	else:
		TransitionScreen.transition_to_black()
		await TransitionScreen._on_animation_finished("fade_to_black", 1)
		get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")
		SoundManager.play("ButtonClick")

func _ready():
	
	#button_back.disabled = true
	
	if GameManager.mostrar_tuto_antes_partida:
		check_box.button_pressed = true
	else:
		check_box.button_pressed = false
	
	_1.visible = true
	_2.visible = false
	_3.visible = false
	_4.visible = false
	_5.visible = false
	_6.visible = false
	_7.visible = false
	
	# Espera 0.5 s desde que entra en escena
	await get_tree().create_timer(0.5).timeout
	await _simulate_click(btn, 0.12)


# Simula pulsación visual + señales (release)
func _simulate_click(node: Node, hold_time := 0.12) -> void:
	if not (node is BaseButton):
		push_error("El nodo no es un botón (BaseButton): %s" % node)
		return

	var b := node as BaseButton

	# --- Pulsar (estado visual) ---
	if b.toggle_mode:
		b.set_pressed_no_signal(true)
	else:
		b.button_pressed = true
	b.emit_signal("button_down")
	await get_tree().process_frame  # fuerza refresco de estilo "pressed"
	await get_tree().create_timer(hold_time).timeout

	# --- Soltar (release) ---
	if b.toggle_mode:
		b.set_pressed_no_signal(false)
	else:
		b.button_pressed = false
	b.emit_signal("button_up")
	b.emit_signal("pressed")  # ejecuta la lógica conectada al botón
	
	
	

func _on_button_1_pressed():
	_1.visible = true
	_2.visible = false
	_3.visible = false
	_4.visible = false
	_5.visible = false
	_6.visible = false
	_7.visible = false

	button_1.button_pressed = true
	button_2.button_pressed = false
	button_3.button_pressed = false
	button_4.button_pressed = false
	button_5.button_pressed = false
	button_6.button_pressed = false
	button_7.button_pressed = false

func _on_button_2_pressed():
	_1.visible = false
	_2.visible = true
	_3.visible = false
	_4.visible = false
	_5.visible = false
	_6.visible = false
	_7.visible = false
	
	button_1.button_pressed = true
	button_2.button_pressed = true
	button_3.button_pressed = false
	button_4.button_pressed = false
	button_5.button_pressed = false
	button_6.button_pressed = false
	button_7.button_pressed = false



func _on_button_3_pressed():
	_1.visible = false
	_2.visible = false
	_3.visible = true
	_4.visible = false
	_5.visible = false
	_6.visible = false
	_7.visible = false
	
	button_1.button_pressed = true
	button_2.button_pressed = true
	button_3.button_pressed = true
	button_4.button_pressed = false
	button_5.button_pressed = false
	button_6.button_pressed = false
	button_7.button_pressed = false


func _on_button_4_pressed():
	_1.visible = false
	_2.visible = false
	_3.visible = false
	_4.visible = true
	_5.visible = false
	_6.visible = false
	_7.visible = false

	button_1.button_pressed = true
	button_2.button_pressed = true
	button_3.button_pressed = true
	button_4.button_pressed = true
	button_5.button_pressed = false
	button_6.button_pressed = false
	button_7.button_pressed = false

func _on_button_5_pressed():
	_1.visible = false
	_2.visible = false
	_3.visible = false
	_4.visible = false
	_5.visible = true
	_6.visible = false
	_7.visible = false

	button_1.button_pressed = true
	button_2.button_pressed = true
	button_3.button_pressed = true
	button_4.button_pressed = true
	button_5.button_pressed = true
	button_6.button_pressed = false
	button_7.button_pressed = false


func _on_button_6_pressed():
	
	
	
	_1.visible = false
	_2.visible = false
	_3.visible = false
	_4.visible = false
	_5.visible = false
	_6.visible = true
	_7.visible = false

	button_1.button_pressed = true
	button_2.button_pressed = true
	button_3.button_pressed = true
	button_4.button_pressed = true
	button_5.button_pressed = true
	button_6.button_pressed = true
	button_7.button_pressed = false


func _on_button_7_pressed():
	#button_back.disabled = false
	
	_1.visible = false
	_2.visible = false
	_3.visible = false
	_4.visible = false
	_5.visible = false
	_6.visible = false
	_7.visible = true

	button_1.button_pressed = true
	button_2.button_pressed = true
	button_3.button_pressed = true
	button_4.button_pressed = true
	button_5.button_pressed = true
	button_6.button_pressed = true
	button_7.button_pressed = true


func _on_check_box_toggled(toggled_on):
	if toggled_on:
		print("Cambiado a ON")
		GameManager.set_mostrar_tuto_antes_partida_enable()
		PlayerPrefs.save_prefs()
	else:
		print("Cambiado a OFF")
		GameManager.set_mostrar_tuto_antes_partida_disable()
		PlayerPrefs.save_prefs()
