extends Node2D

@onready var dificultad: int
@onready var categoria: String

@onready var button_difficulty_1 = $Panel/ButtonDifficulty1
@onready var button_difficulty_2 = $Panel/ButtonDifficulty2
@onready var button_difficulty_3 = $Panel/ButtonDifficulty3

@onready var texture_rect_aviso: TextureRect = $TextureRectAviso

@onready var button_home = $ButtonHome

@onready var button_citas_celebres = $Panel/ButtonCitasCelebres
@onready var button_fragmentos_literarios = $Panel/ButtonFragmentosLiterarios
@onready var button_efemerides = $Panel/ButtonEfemerides
@onready var button_curiosidades = $Panel/ButtonCuriosidades

@onready var blanco_citas_celebres = $Panel/ButtonCitasCelebres/BlancoCitasCelebres
@onready var blanco_efemerides = $Panel/ButtonEfemerides/BlancoEfemerides
@onready var blanco_fragmentos_literarios: TextureRect = $Panel/ButtonFragmentosLiterarios/BlancoFragmentosLiterarios
@onready var blanco_curiosidades = $Panel/ButtonCuriosidades/BlancoCuriosidades

@onready var blanco_1 = $Panel/ButtonDifficulty1/Blanco1
@onready var blanco_2 = $Panel/ButtonDifficulty2/Blanco2
@onready var blanco_3 = $Panel/ButtonDifficulty3/Blanco3

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

#@onready var button_play = $ButtonPlay
@onready var button_play: TextureButton = $PlayButtonFx

@onready var category_selected: bool = false
@onready var difficulty_selected: bool = false

func _ready():
	dificultad = 0
	categoria = ""
	texture_rect_aviso.visible = true
	
	blanco_citas_celebres.visible = false
	blanco_fragmentos_literarios.visible = false
	blanco_efemerides.visible = false

	blanco_1.visible = false
	blanco_2.visible = false
	blanco_3.visible = false
	
	button_play.disabled = true
	
	category_selected = false
	difficulty_selected = false
	
	button_play.enable_sheen = false
	button_play.enable_scale = false
	button_play.enable_rotation = false


func _on_button_play_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)

	# Carga perezosa de la escena App
	if scene_app == null:
		scene_app = load(PATH_APP)
	get_tree().change_scene_to_packed(scene_app)


func _on_button_difficulty_1_pressed():
	dificultad = 1
	difficulty_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	button_difficulty_2.button_pressed = false
	button_difficulty_3.button_pressed = false
	blanco_1.visible = true
	blanco_2.visible = false
	blanco_3.visible = false
	GameManager.button_blink(button_difficulty_1)

func enableButtonPlay() -> void:
	button_play.enable_sheen = true
	button_play.enable_scale = true
	button_play.enable_rotation = true
	texture_rect_aviso.visible = false
	
	
func _on_button_difficulty_2_pressed():
	dificultad = 2
	difficulty_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	button_difficulty_1.button_pressed = false
	button_difficulty_3.button_pressed = false
	blanco_1.visible = false
	blanco_2.visible = true
	blanco_3.visible = false
	GameManager.button_blink(button_difficulty_2)

func _on_button_difficulty_3_pressed():
	dificultad = 3
	difficulty_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	button_difficulty_1.button_pressed = false
	button_difficulty_2.button_pressed = false
	blanco_1.visible = false
	blanco_2.visible = false
	blanco_3.visible = true
	GameManager.button_blink(button_difficulty_3)

func _on_button_citas_celebres_pressed():
	categoria = GameManager.CAT_CITA
	category_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	blanco_citas_celebres.visible = true
	blanco_fragmentos_literarios.visible = false
	blanco_efemerides.visible = false
	blanco_curiosidades.visible = false
	GameManager.button_blink(button_citas_celebres)
	SoundManager.play("ButtonClick")
	

func _on_button_fragmentos_literarios_pressed():
	categoria = GameManager.CAT_FRAGMENTO
	category_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	blanco_citas_celebres.visible = false
	blanco_fragmentos_literarios.visible = true
	blanco_efemerides.visible = false
	blanco_curiosidades.visible = false
	GameManager.button_blink(button_fragmentos_literarios)
	SoundManager.play("ButtonClick")


func _on_button_efemerides_pressed():
	categoria = GameManager.CAT_EFEMERIDE
	category_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	blanco_citas_celebres.visible = false
	blanco_fragmentos_literarios.visible = false
	blanco_efemerides.visible = true
	blanco_curiosidades.visible = false
	GameManager.button_blink(button_efemerides)
	SoundManager.play("ButtonClick")

func _on_button_curiosidades_pressed() -> void:
	categoria = GameManager.CAT_CURIOSIDADES
	category_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	blanco_citas_celebres.visible = false
	blanco_fragmentos_literarios.visible = false
	blanco_efemerides.visible = false
	blanco_curiosidades.visible = true	
	GameManager.button_blink(button_curiosidades)
	SoundManager.play("ButtonClick")


func _on_button_home_pressed():
	TransitionScreen.transition_to_black()
	GameManager.button_blink(button_home)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)

	# Carga perezosa de MenuMain
	if scene_menu_main == null:
		scene_menu_main = load(PATH_MENU_MAIN)
	get_tree().change_scene_to_packed(scene_menu_main)


func _on_play_button_fx_pressed():
	GameManager.set_categoria_actual(categoria)
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
