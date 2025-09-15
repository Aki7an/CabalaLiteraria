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

@onready var blanco_citas_celebres = $Panel/ButtonCitasCelebres/BlancoCitasCelebres
@onready var blanco_efemerides = $Panel/ButtonEfemerides/BlancoEfemerides
@onready var blanco_fragmentos_literarios: TextureRect = $Panel/ButtonFragmentosLiterarios/BlancoFragmentosLiterarios


@onready var blanco_1 = $Panel/ButtonDifficulty1/Blanco1
@onready var blanco_2 = $Panel/ButtonDifficulty2/Blanco2
@onready var blanco_3 = $Panel/ButtonDifficulty3/Blanco3

const scene_to_load_MenuMain = preload("res://scenes/MenuMain.tscn")
const scene_to_load_App = preload("res://scenes/App.tscn")
const scene_to_tutorial = preload("res://scenes/MenuTutorial.tscn")

const scene_to_select_level = preload("res://scenes/MenuSelectLevelByID.tscn")

#@onready var button_play = $ButtonPlay
@onready var button_play: TextureButton = $PlayButtonFx

@onready var category_selected: bool = false
@onready var difficulty_selected: bool = false

func _ready():
	dificultad = 1
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
	get_tree().change_scene_to_packed(scene_to_load_App)


func _on_button_difficulty_1_pressed():
	dificultad = 1
	difficulty_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	GameManager.seleccionar_por_categoria_y_dificultad(categoria, dificultad)
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
	GameManager.seleccionar_por_categoria_y_dificultad(categoria, dificultad)
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
	GameManager.seleccionar_por_categoria_y_dificultad(categoria, dificultad)
	button_difficulty_1.button_pressed = false
	button_difficulty_2.button_pressed = false
	blanco_1.visible = false
	blanco_2.visible = false
	blanco_3.visible = true
	GameManager.button_blink(button_difficulty_3)

func _on_button_citas_celebres_pressed():
	categoria = "Cita célebre"
	category_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	blanco_citas_celebres.visible = true
	blanco_fragmentos_literarios.visible = false
	blanco_efemerides.visible = false
	GameManager.seleccionar_por_categoria_y_dificultad(categoria, dificultad)
	GameManager.button_blink(button_citas_celebres)
	SoundManager.play("ButtonClick")
	

func _on_button_fragmentos_literarios_pressed():
	categoria = "Fragmento"
	category_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	blanco_citas_celebres.visible = false
	blanco_fragmentos_literarios.visible = true
	blanco_efemerides.visible = false
	GameManager.seleccionar_por_categoria_y_dificultad(categoria, dificultad)
	GameManager.button_blink(button_fragmentos_literarios)
	SoundManager.play("ButtonClick")


func _on_button_efemerides_pressed():
	categoria = "Efeméride"
	category_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	blanco_citas_celebres.visible = false
	blanco_fragmentos_literarios.visible = false
	blanco_efemerides.visible = true
	GameManager.seleccionar_por_categoria_y_dificultad(categoria, dificultad)
	GameManager.button_blink(button_efemerides)
	SoundManager.play("ButtonClick")



func _on_button_home_pressed():
	TransitionScreen.transition_to_black()
	GameManager.button_blink(button_home)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(scene_to_load_MenuMain)


func _on_play_button_fx_pressed():
	GameManager.set_go_to_game_enable()
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(scene_to_select_level)
	


func _on_button_exit_pressed():
	TransitionScreen.transition_to_black()
	#GameManager.button_blink(button_home)
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(scene_to_load_MenuMain)


func _on_button_curiosidades_pressed() -> void:
	categoria = "Curiosidades"
	category_selected = true
	if difficulty_selected and category_selected:
		button_play.disabled = false
		enableButtonPlay()
		SoundManager.play("PlayAvailable")
	blanco_citas_celebres.visible = false
	blanco_fragmentos_literarios.visible = false
	blanco_efemerides.visible = true
	GameManager.seleccionar_por_categoria_y_dificultad(categoria, dificultad)
	GameManager.button_blink(button_efemerides)
	SoundManager.play("ButtonClick")
