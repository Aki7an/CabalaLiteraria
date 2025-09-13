extends Panel
@onready var difficulty: Label = $Difficulty

@onready var OverlaySceneFondoSalir := preload("res://scenes/fondo_salir.tscn")
@onready var OverlaySceneMenuResults := preload("res://scenes/MenuResults.tscn")
@onready var OverlaySceneMenuGameOver := preload("res://scenes/menu_game_over.tscn")
@onready var OverlaySceneFondoAvisoBorrado := preload("res://scenes/fondo_aviso_borrado.tscn")
@onready var OverlaySceneCuadroHints := preload("res://scenes/Cuadro_Hints.tscn")
@onready var OverlaySceneCuadroComprarLetra := preload("res://scenes/fondo_comprar_letra.tscn")
@onready var OverlaySceneSettingsGame := preload("res://scenes/MenuSettingsGame.tscn")

#@onready var rich_text_frase = $MenuGameOver/GameOver/RichTextFrase
@onready var score = %Score2

@export var lista_imagenes: Array[Texture2D] = []
#@onready var fondo_salir = $FondoSalir
@onready var cuadro_salir = $FondoSalir/CuadroSalir
#@onready var fondo_aviso_borrado: ColorRect = $FondoAvisoBorrado
#@onready var fondo_player_name_record = $FondoPlayerNameRecord

const scene_to_load_MenuResults = preload("res://scenes/MenuResults.tscn")


@onready var game_letters: Label = $Completado/ProgressBar/GameLetters

#@onready var menu_game_over = $MenuGameOver


@onready var id = $ID
	
@onready var restante_2 = %Restante2
@onready var progress_bar = %ProgressBar


@onready var label_tiempo: Label = %Tiempo2

var start_ms: int
@onready var categoria = %Categoria2

@onready var cuadro_tips_0: Label = $CuadroTips0
@onready var cuadro_tips_1: Label = $CuadroTips1
@onready var cuadro_tips_2: Label = $CuadroTips2
@onready var cuadro_tips_3: Label = $CuadroTips3

@onready var rich_text_frase: RichTextLabel = $MenuGameOver/GameOver/ButtonFx/RichTextFrase

@onready var button_pista:Button = $ButtonPista
@onready var button_pista_2:Button = %ButtonPista2
@onready var button_pista_3:Button = %ButtonPista3

@onready var rich_text_label_0: RichTextLabel = $CuadroTips0/RichTextLabel0
@onready var rich_text_label_1: RichTextLabel = $CuadroTips1/RichTextLabel1
@onready var rich_text_label_2: RichTextLabel = $CuadroTips2/RichTextLabel2
@onready var rich_text_label_3: RichTextLabel = $CuadroTips3/RichTextLabel3

@onready var pistas = $VBoxContainer/HBoxContainer/Pistas/Pistas

@onready var cambios = %Cambios2

@onready var imagen_viñeta = $CuadroTips0/ImagenViñeta
@onready var game_over = $MenuGameOver/GameOver
@onready var coins = $Coins/Coins


func _ready() -> void:
	start_ms = Time.get_ticks_msec()
	SignalManager.update_resting_characters.connect(_update_resting_characters)
	SignalManager.update_cambios.connect(_update_cambios)
	SignalManager.game_finished.connect(_game_finished_to_results)
	SignalManager.update_score.connect(_update_score)
	SignalManager.erase_letter.connect(_erase_letter)
	SignalManager.erase_letter_open_dialog.connect(_erase_letter_open_dialog)
	SignalManager.update_coins.connect(update_coins)
	
	_update_resting_characters()
	_update_categoria()
	_update_dificultad()
	
	update_coins()
	
	_silueta_o_texto()
	rich_text_label_1.clear()
	rich_text_label_2.clear()
	rich_text_label_3.clear()
	
	rich_text_label_1.text = GameManager.hint_1
	rich_text_label_2.text = GameManager.hint_2
	rich_text_label_3.text = GameManager.hint_3
	
	#rich_text_frase.text = GameManager.frase_original_til
	
	#fondo_salir.visible = false
	#menu_game_over.visible = false
	#fondo_aviso_borrado.visible = false
	#fondo_player_name_record.visible = false
	
	#button_pista_2.disabled = true
	#button_pista_3.disabled = true
	GameManager.set_hints_based_on_difficulty()
	
	GameManager.reset_numero_letras_reveladas()
	
	_update_cambios()
	
	id.text = "ID " + str(GameManager.id_frase)
	
	cuadro_tips_0.visible = false
	cuadro_tips_1.visible = false
	cuadro_tips_2.visible = false
	cuadro_tips_3.visible = false
	#await get_tree().create_timer(0.5).timeout
	#GameManager.play_pop_animation(cuadro_tips_0)
	
	#start with Hint opened
	var overlay := OverlaySceneCuadroHints.instantiate()
	add_child(overlay)                             # no cierra lo de abajo
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # bloquea clicks al fondo
	
	SignalManager.update_difficulty.connect(_update_difficulty_label)
	SignalManager.update_difficulty.emit(GameManager.frase_original, GameManager.recoger_letras_mostradas)
	#print("frase: ", GameManager.frase_original)
	#print("Letras mostradas: ", GameManager.recoger_letras_mostradas())
	
func _update_difficulty_label(frase: String, revelada: String) -> void:
	difficulty.text = "Dificultad: " + String.num(Analyzer.evaluar_dificultad(frase, revelada),2)
		
func _update_score() -> void:
	GameManager.calcula_score()
	score.text = GameManager.formatear_numero(GameManager.score)
	
func _silueta_o_texto() -> void:
	if GameManager.descripcion_actual == "IMAGEN":
		imagen_viñeta.visible = true
		imagen_viñeta.texture = lista_imagenes[GameManager.id_frase]
		rich_text_label_0.text = ""
	else:
		rich_text_label_0.text = str(GameManager.descripcion_actual)
		imagen_viñeta.visible = false

func update_coins() -> void:
	coins.text = str(GameManager.coins)
	
func _update_cambios() -> void:
	cambios.text = str(GameManager.cambios)

func _update_categoria() -> void:
	categoria.text = GameManager.categoria_actual
	
func _update_dificultad() -> void:
	GameManager.dificultad_actual
	
func _process(_delta: float) -> void:
	var elapsed_s := float(Time.get_ticks_msec() - start_ms) / 1000.0
	label_tiempo.text = format_time_mm_ss(elapsed_s)
	GameManager.set_tiempo_partida(elapsed_s)

func format_time_mm_ss(t_sec: float) -> String:
	var total := int(t_sec)
	var m := total / 60
	var s := total % 60
	if m==0:
		if s<=9:
			return "%2d" % [s]
		else:
			return "%02d" % [s]
	else:
		return "%d:%02d" % [m, s]


func _update_resting_characters() -> void:
	game_letters.text = str(GameManager.numero_letras_reveladas) + "/" + str(GameManager.numero_letras_a_revelar_originales)
	
	if GameManager.numero_letras_a_revelar_originales == 0:
		progress_bar.value = 0
	else:
		progress_bar.value = 100 * GameManager.numero_letras_reveladas / GameManager.numero_letras_a_revelar_originales

func calcula_pistas_utilizadas() -> int:
	if GameManager.pista_1 and GameManager.pista_2 and GameManager.pista_3:
		GameManager.set_pistas_utilizadas(3)
	elif GameManager.pista_1 and GameManager.pista_2:
		GameManager.set_pistas_utilizadas(2)
	elif GameManager.pista_1:
		GameManager.set_pistas_utilizadas(1)
	return 0


func _on_button_pista_0_pressed():
	
	#if cuadro_tips_0.visible:
		#cuadro_tips_0.visible = false
	#else:
		#cuadro_tips_0.visible = true
	#SoundManager.play("Tip1")
	#GameManager.play_pop_animation(cuadro_tips_0)
	var overlay := OverlaySceneCuadroHints.instantiate()
	add_child(overlay)                             # no cierra lo de abajo
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # bloquea clicks al fondo


#func _on_button_pista_pressed():
	#GameManager.set_pista1()
	#calcula_pistas_utilizadas()
	#pistas.text = str(GameManager.pistas_utilizadas)
	#button_pista_2.disabled = false
	#if cuadro_tips_1.visible:
		#cuadro_tips_1.visible = false
	#else:
		#cuadro_tips_1.visible = true
	#SoundManager.play("Tip1")
	#GameManager.play_pop_animation(cuadro_tips_1)

#func _on_button_pista_2_pressed():
	#GameManager.set_pista2()
	#calcula_pistas_utilizadas()
	#pistas.text = str(GameManager.pistas_utilizadas)
	#button_pista_3.disabled = false
	#if cuadro_tips_2.visible:
		#cuadro_tips_2.visible = false
	#else:
		#cuadro_tips_2.visible = true
	#SoundManager.play("Tip2")
	#GameManager.play_pop_animation(cuadro_tips_2)
#
#func _on_button_pista_3_pressed():
	#GameManager.set_pista3()
	#calcula_pistas_utilizadas()
	#pistas.text = str(GameManager.pistas_utilizadas)
	#if cuadro_tips_3.visible:
		#cuadro_tips_3.visible = false
	#else:
		#cuadro_tips_3.visible = true
	#SoundManager.play("Tip3")
	#GameManager.play_pop_animation(cuadro_tips_3)

#func _on_button_pista_close_0_pressed():
	#SoundManager.play("ButtonClick")
	##cuadro_tips_0.visible = false
	#GameManager.play_pop_close_animation(cuadro_tips_0)
	

#func _on_button_pista_close_1_pressed():
	#SoundManager.play("ButtonClick")
	#GameManager.play_pop_close_animation(cuadro_tips_1)
	##cuadro_tips_1.visible = false
#
#func _on_button_pista_close_2_pressed():
	#SoundManager.play("ButtonClick")
	##cuadro_tips_2.visible = false
	#GameManager.play_pop_close_animation(cuadro_tips_2)
#
#func _on_button_pista_close_3_pressed():
	#SoundManager.play("ButtonClick")
	##cuadro_tips_3.visible = false
	#GameManager.play_pop_close_animation(cuadro_tips_3)

#func _game_finished_to_results() -> void:
	#SoundManager.play("ButtonClick")
	##menu_game_over.visible = true
	#GameManager.calcula_score()
	#
	#menu_game_over.visible = true
	#GameManager.play_pop_animation(game_over)

func _on_button_game_over_pressed():
	TransitionScreen.transition_to_black()
	SoundManager.play("ButtonClick")
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	
	get_tree().change_scene_to_packed(scene_to_load_MenuResults)


#func _on_button_home_pressed():
	#fondo_salir.visible = true
	#GameManager.play_pop_animation(cuadro_salir)


#func _on_button_seguir_pressed():
	#
	#GameManager.play_pop_close_animation(fondo_salir)
	#await get_tree().create_timer(0.3).timeout
	#fondo_salir.visible = false

#func _on_button_salir_pressed():
	#TransitionScreen.transition_to_black()
	#await TransitionScreen._on_animation_finished("fade_to_black", 1)
	#get_tree().change_scene_to_packed(scene_to_load_MainMenu)
	#SoundManager.play("ButtonClick")


func _on_button_exit_pressed():
	#fondo_salir.visible = true
	#GameManager.play_pop_animation(fondo_salir)
	var overlay := OverlaySceneFondoSalir.instantiate()
	add_child(overlay)                             # no cierra lo de abajo
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # bloquea clicks al fondo
	# overlay.modulate = Color(1,1,1,0.98)        # si quieres atenuar



	
func _erase_letter(letra: String) -> void:
	#var overlay := OverlaySceneFondoAvisoBorrado.instantiate()
	#add_child(overlay) 
	##GameManager.play_pop_animation(fondo_aviso_borrado)
	#print("letra enviada: ",letra)
	
	#meter la rutina borrada de eliminar letra
	print ("Borrado")
	SignalManager.erase_selected_letter.emit()
	
func _game_finished_to_results() -> void:
	print("GAME END SIGNAL DONE")
	SoundManager.play("ButtonClick")
	#menu_game_over.visible = true
	GameManager.calcula_score()

	#var overlay := OverlaySceneMenuResults.instantiate()
	var overlay :=OverlaySceneMenuGameOver.instantiate()
	add_child(overlay)                             # no cierra lo de abajo
	#overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	#overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # bloquea clicks al fondo
	# overlay.modulate = Color(1,1,1,0.98)        # si quieres atenuar

func _erase_letter_open_dialog() -> void:
		var overlay := OverlaySceneFondoAvisoBorrado.instantiate()
		add_child(overlay) 


func _on_button_letters_pressed():
	var overlay := OverlaySceneCuadroComprarLetra.instantiate()
	add_child(overlay)                             # no cierra lo de abajo
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # bloquea clicks al fondo


func _on_button_settings_pressed():
	var overlay := OverlaySceneSettingsGame.instantiate()
	add_child(overlay)                             # no cierra lo de abajo
	#overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	#overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # bloquea clicks al fondo
