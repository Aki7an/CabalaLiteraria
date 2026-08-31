extends Node2D
const scene_to_load_MenuMain = preload("res://scenes/MenuMain.tscn")
@onready var label_score = $Panel/LabelScore
@onready var nombre: LineEdit = $Panel/LabelNuevoRecord/Nombre
@onready var nombre_remarcar: Label = $Panel/LabelNuevoRecord/NombreRemarcar
@onready var advertencia_hecha: bool = false
@onready var partida_en_record: bool = false
@onready var texture_rect_record = $Panel/TextureRectRECORD
@onready var label_nuevo_record = $Panel/LabelNuevoRecord
#@onready var nombre = $Panel/LabelNuevoRecord/Nombre
@onready var button_back = $ButtonBack

func go_to_main_menu() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SoundManager.play("ButtonClick")
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")

func go_to_name_record_online() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SoundManager.play("ButtonClick")
	get_tree().change_scene_to_file("res://scenes/menu_player_name_record_online.tscn")

# Ejemplo 1: deshabilitar un botón concreto 3 s
func disable_for_3s(btn: BaseButton) -> void:
	btn.disabled = true
	await get_tree().create_timer(3.0).timeout
	btn.disabled = false

func _on_button_back_pressed():
	await disable_for_3s(button_back)
	#button_back.disabled = true
	if !partida_en_record:
		# if no record, go to MainMenu
		go_to_main_menu()
	
	# at least there is local redord
	# check name
	if nombre.text == "":
		if advertencia_hecha == false:
			# name empty first advice
			print("Name empty")
			nombre_remarcar.visible = true
			advertencia_hecha = true
			return
		else:
			# second advice. Name to ---
			#  Check if 
			GameManager.set_player_name("---")
			print("cambia el nombre...")
			HistoryManager.add_result(GameManager.player_name,GameManager.score)
			PlayFabTools.submit_competitive_rankings(GameManager.player_name)
			# check if record is number one to go to menu NAME for online record
			if HistoryManager.numero_de_record_de_partida_dentro_de_record(GameManager.categoria_actual, GameManager.dificultad_actual, GameManager.score) == 1:
				var ok : bool = await PlayFabTools.submit_player_score(GameManager.codifica_score(GameManager.score), GameManager.player_name, GameManager.playfab_table())
				if ok:
					print("✅ Score actualizado en 'Score'.")
				else:
					print("❌ No se pudo actualizar la puntuación.")
				go_to_name_record_online()
			else:
				go_to_main_menu()
				print("There should neve come to this point")
	else:			
		# name is not empty
		#redord and name
			
		GameManager.set_player_name(nombre.text)
		HistoryManager.add_result(GameManager.player_name,GameManager.score)
		PlayFabTools.submit_competitive_rankings(GameManager.player_name)
		# check if record is number one to go to menu NAME for online record
		if HistoryManager.numero_de_record_de_partida_dentro_de_record(GameManager.categoria_actual, GameManager.dificultad_actual, GameManager.score) == 1:
			var ok : bool = await PlayFabTools.submit_player_score(GameManager.codifica_score(GameManager.score), GameManager.player_name, GameManager.playfab_table())
			print("Score: ", GameManager.score)
			print ("score cofificado: " , str(GameManager.codifica_score(GameManager.score)))
			print ("Player Name: ", GameManager.player_name)
			print ("PlayFab Table: " , GameManager.playfab_table())
			
			if ok:
				print("✅ Score actualizado en 'Score'.")
			else:
				print("❌ No se pudo actualizar la puntuación.")
			
			go_to_name_record_online()
		else:
			go_to_main_menu()


func _ready() -> void:
	#GameManager.calcula_score()
	label_score.text =  GameManager.formatear_numero(GameManager.score)
	nombre_remarcar.visible = false
	advertencia_hecha = false
	
	if HistoryManager.partida_dentro_de_record(GameManager.categoria_actual, GameManager.dificultad_actual, GameManager.score):
		# Si local record
		texture_rect_record.visible = true
		label_nuevo_record.visible = true
		nombre.visible = true
		partida_en_record = true
	else:
		# No local record
		GameManager.set_player_name("BAD")
		texture_rect_record.visible = false
		label_nuevo_record.visible = false
		nombre.visible = false
		partida_en_record = false
	
	
	PlayFabTools.send_match_event(GameManager.tiempo_partida, GameManager.vocalesAE_compradas, GameManager.vocalesIOU_compradas, GameManager.consonantes_compradas, GameManager.pistas_utilizadas_1, GameManager.pistas_utilizadas_2, GameManager.dificultad_actual, GameManager.categoria_actual)
	
	
	focus_texto_y_teclado_android()	

func focus_texto_y_teclado_android() -> void:
 # Asegura que el control puede recibir foco
	# Asegura que puede recibir foco
	nombre.focus_mode = Control.FOCUS_ALL

	# Conecta para abrir/cerrar teclado al cambiar el foco
	nombre.focus_entered.connect(_on_nombre_focus_entered)
	nombre.focus_exited.connect(_on_nombre_focus_exited)

	# Pequeño delay para garantizar que está visible y en el árbol
	await get_tree().process_frame
	await get_tree().process_frame

	# Da foco y coloca el cursor al final
	nombre.grab_focus()
	nombre.caret_column = nombre.text.length()

	# Muestra teclado en móviles
	_show_virtual_keyboard()

func _on_nombre_focus_entered() -> void:
	_show_virtual_keyboard()

func _on_nombre_focus_exited() -> void:
	_hide_virtual_keyboard()

func _show_virtual_keyboard() -> void:
	if OS.has_feature("android") or OS.has_feature("ios"):
		await get_tree().create_timer(0.05).timeout
		DisplayServer.virtual_keyboard_show(nombre.text, Rect2(), 0, 0)

func _hide_virtual_keyboard() -> void:
	if OS.has_feature("android") or OS.has_feature("ios"):
		DisplayServer.virtual_keyboard_hide()


	
