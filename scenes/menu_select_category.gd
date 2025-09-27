extends Node2D

@onready var categoria: String


@onready var button_citas_celebres = $Panel/ButtonCitasCelebres
@onready var button_fragmentos_literarios = $Panel/ButtonFragmentosLiterarios
@onready var button_efemerides = $Panel/ButtonEfemerides
@onready var button_curiosidades = $Panel/ButtonCuriosidades

# Rutas de escena (antes usabas preload de PackedScene)
const PATH_MENU_MAIN := "res://scenes/MenuMain.tscn"
const PATH_SELECT_DIFFICULTY := "res://scenes/MenuSelectDifficulty.tscn"

# Referencias a PackedScene que se cargarán bajo demanda
var scene_menu_main: PackedScene = null
var scene_select_difficulty: PackedScene = null


func _ready():

	categoria = ""


func _on_button_citas_celebres_pressed():
	categoria = "Cita"
	GameManager.button_blink(button_citas_celebres)
	SoundManager.play("ButtonClick")
	_go_to_select_difficulty()
	

func _on_button_fragmentos_literarios_pressed():
	categoria = "Fragmento"
	GameManager.button_blink(button_fragmentos_literarios)
	SoundManager.play("ButtonClick")
	_go_to_select_difficulty()


func _on_button_efemerides_pressed():
	categoria = "Efeméride"
	GameManager.button_blink(button_efemerides)
	SoundManager.play("ButtonClick")
	_go_to_select_difficulty()

func _on_button_curiosidades_pressed() -> void:
	categoria = "Curiosidades"
	GameManager.button_blink(button_curiosidades)
	SoundManager.play("ButtonClick")
	_go_to_select_difficulty()


func _on_button_exit_pressed():
	TransitionScreen.transition_to_black()
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)

	# Carga perezosa de MenuMain
	if scene_menu_main == null:
		scene_menu_main = load(PATH_MENU_MAIN)
	get_tree().change_scene_to_packed(scene_menu_main)
	
func _go_to_select_difficulty():
	GameManager.set_categoria_actual(categoria)
	GameManager.set_go_to_game_enable()
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if scene_select_difficulty == null:
		scene_select_difficulty = load(PATH_SELECT_DIFFICULTY)
	get_tree().change_scene_to_packed(scene_select_difficulty)
	
