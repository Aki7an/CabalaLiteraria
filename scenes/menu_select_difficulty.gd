extends Node2D

@onready var dificultad: int
@onready var categoria: String

@onready var button_home = $ButtonHome

# Rutas de escena (antes usabas preload de PackedScene)
const PATH_MENU_MAIN := "res://scenes/MenuMain.tscn"
const PATH_APP := "res://scenes/App.tscn"
const PATH_TUTORIAL := "res://scenes/MenuTutorial.tscn"
const PATH_SELECT_LEVEL := "res://scenes/MenuSelectLevelByID.tscn"

# Referencias a PackedScene que se cargarán bajo demanda
var scene_menu_main: PackedScene = null
var scene_app: PackedScene = null
var scene_tutorial: PackedScene = null
var scene_select_level: PackedScene = null

@onready var efemerides = $Panel/Efemerides
@onready var citas = $Panel/Citas
@onready var curiosidades = $Panel/Curiosidades
@onready var fragmentos = $Panel/Fragmentos

@onready var button_difficulty_2 = $Panel/ButtonDifficulty2
@onready var button_difficulty_3 = $Panel/ButtonDifficulty3
@onready var button_difficulty_4 = $Panel/ButtonDifficulty4


func _ready():
	efemerides.visible = false
	citas.visible = false
	curiosidades.visible = false
	fragmentos.visible = false
	
	dificultad = 0
	if GameManager.categoria_actual == "Efeméride":
		efemerides.visible = true
	elif GameManager.categoria_actual == "Cita":
		citas.visible = true
	elif GameManager.categoria_actual == "Curiosidades":
		curiosidades.visible = true
	else:
		fragmentos.visible = true
	
	if GameManager.level_normal_unlocked:
		button_difficulty_2.disabled = false
		button_difficulty_2.enable_intro_scale = true
		button_difficulty_2.enable_intro_rotation = true
	else:
		button_difficulty_2.disabled = true	
		button_difficulty_2.enable_intro_scale = false
		button_difficulty_2.enable_intro_rotation = false
	
	if GameManager.level_dificil_unlocked:
		button_difficulty_3.disabled = false
		button_difficulty_3.enable_intro_scale = true
		button_difficulty_3.enable_intro_rotation = true
	else:
		button_difficulty_3.disabled = true
		button_difficulty_3.enable_intro_scale = false
		button_difficulty_3.enable_intro_rotation = false
		
	if GameManager.level_pro_unlocked:
		button_difficulty_4.disabled = false
		button_difficulty_4.enable_intro_scale = true
		button_difficulty_4.enable_intro_rotation = true
	else:
		button_difficulty_4.disabled = true
		button_difficulty_4.enable_intro_scale = false
		button_difficulty_4.enable_intro_rotation = false
func _on_button_difficulty_1_pressed():
	dificultad = 1
	SoundManager.play("PlayAvailable")
	_play_game()

	
func _on_button_difficulty_2_pressed():
	dificultad = 2
	SoundManager.play("PlayAvailable")
	_play_game()


func _on_button_difficulty_3_pressed():
	dificultad = 3
	SoundManager.play("PlayAvailable")
	_play_game()


func _on_button_difficulty_4_pressed():
	dificultad = 4
	SoundManager.play("PlayAvailable")
	_play_game()


func _play_game():
	GameManager.set_dificultad_actual(dificultad)
	GameManager.set_go_to_game_enable()
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)

	# Carga perezosa de la pantalla de selección de nivel
	if scene_select_level == null:
		scene_select_level = load(PATH_SELECT_LEVEL)
	get_tree().change_scene_to_packed(scene_select_level)
	

func _on_button_exit_pressed():
	TransitionScreen.transition_to_black()
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)

	# Carga perezosa de MenuMain
	if scene_menu_main == null:
		scene_menu_main = load(PATH_MENU_MAIN)
	get_tree().change_scene_to_packed(scene_menu_main)
