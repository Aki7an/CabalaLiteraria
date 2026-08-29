extends Node

@export var lives: int

@export var level_normal_unlocked: bool = false
@export var level_dificil_unlocked: bool = false
@export var level_pro_unlocked: bool = false

@export var go_to_game :bool = false

@export var vocalesAE_compradas: int = 0
@export var vocalesIOU_compradas: int = 0
@export var consonantes_compradas: int = 0

#@export var letras_compradas: int = 0
@export var vocales_compradas: int = 0
@export var cambios_hechos: int = 0

@export var pistas_utilizadas_1: int = 0 
@export var pistas_utilizadas_2: int = 0 
@export var pistas_utilizadas: int = 0 
@export var pistas: int = 0 
@export var puzzle_stars: int = 5

var _penalized_reveal_errors: Dictionary = {}
var _penalized_hints: Dictionary = {}
var reveal_errors_count: int = 0

@export var player_name: String = "Aki"
@export var score: int
@export var score_init: int = 30000

@export var coins: int = 15

@export var frases_json_path: String = "res://data/frases.json"
@export var frases_json_path_es: String = "res://data/frases_es.json"
@export var frases_json_path_en: String = "res://data/frases_en.json"
@export var frases_json_path_eu: String = "res://data/frases_eu.json"
@export var frases_json_path_fr: String = "res://data/frases_fr.json"
@export var frases_json_path_de: String = "res://data/frases_de.json"
@export var frases_json_path_it: String = "res://data/frases_it.json"
@export var frases_json_path_pt: String = "res://data/frases_pt.json"


@export var score_ultima_partida: int
@export var categoria_ultima_partida: String
@export var dificultad_ultima_partida: int

@export 	var frase_original_til: String

@export var partida_terminada: bool = false

var frases_db: Array = []

# Campos extra de la frase activa
var frase_index_actual: int = -1
var idioma_actual: String = ""
var categoria_actual: String = ""
var dificultad_actual: int = 1
var game_mode_actual: String = "quick"
#var descripcion_actual: String = ""
var descripcion_final: String = ""
var letras_iniciales: String = ""
var pistas_actuales: Array[String] = []
@export var descripcion_final_actual: String = ""


@export var pista_1: bool = false
@export var pista_2: bool = false
@export var pista_3: bool = false


@export var canvas_wide:int = 1000

@export var max_y_canvas:int = -8940
@export var min_y_canvas:int = 440

@export var tiempo_partida: int = 0

# List of letters. May change deppending on the language 226-27
@export var letters_aphabet_array := [
	"A","B","C","D","E","F","G","H","I","J","K","L","M",
	"N","Ñ","O","P","Q","R","S","T","U","V","W","X","Y","Z"
] # 27 letters

@export var EXCLUIR: Array = [
	"1", "2", "3","4", "5", "6", "7", "8", "9","0",",", ".", ";", ":", "-", "-", " ", "?", "¿", "¡", "!", "#", "@",
	"$", "%", "&", "/", "(", ")", "=", "+", "*", "}", "{", "<",
	">", "_", "\\", "º", "`", "´", "^", "«", "»"]
	
@export var game_scale:Vector2 = Vector2(1,1)

# ¿?
@export var number_1: int = 0
@export var number_2: int = 0
@export var number_3: int = 0
@export var number_4: int = 0
@export var number_5: int = 0

# number of the SELECTED CELDA in the sentence string. If none:0
@export var selected_celda_number :int =100
@export var selected_letra :String = ""

# the number that CELDA contains. If none: 0
@export var celda_seleccionada_numero :int =100

# PlayCanvas size
@export var NUM_COLUMNAS : int	= 10
@export var NUM_FILAS :int = 13
@export var TOTAL_CELDAS : int = NUM_COLUMNAS * NUM_FILAS

# Colors available, description
@export var lista_colores := ["Blanco","Rojo", "Azul", "Verde", "Naranja", "Rosa"]

# Pastel Colors
@export var lista_tonos_colores := [  
	Color(1.0, 1.0, 1.0),   # Rojo blanco  
	Color(1.0, 0.6, 0.6),   # Rojo pastel  
	Color(0.6, 0.8, 1.0),   # Azul pastel  
	Color(0.6, 1.0, 0.6),   # Verde pastel  
	Color(1.0, 0.8, 0.6),   # Naranja pastel  
	Color(1.0, 0.6, 0.8)    # Rosa pastel  
]

@export var mostrar_tuto_antes_partida :bool

# Not used
@export var lista_comentarios_colores := ["-", "-", "-", "-", "-" ]

# List of random numbers from 1 to 27 assigned to the LETTERS
@export var lista_numeros := [] # [1..27] ramdomized

# Colors assigned to the LETTERS (0 = none, 1-5 colors)
@export var lista_colores_asignados := [] # colors assigned to the CELDAs in the sentence  ¿?

# -- Lista de celdas del canvas --
@export var lista_celdas := [Celda] # objetos tipo Celda

@export var id_frase : int = 0
@export var id_image : int = 0

@export var hint_1 : String = ""
@export var hint_2 : String = ""
@export var hint_3 : String = ""

@export var lista_letras_frase_original := [] # Sentence LETTERs
@export var lista_letras_frase_original_sin_espacios_ni_puntuacion :=[]

@export var numero_letras_a_revelar_originales :int =0
@export var numero_letras_reveladas :int =0
var board_fill_prompt_shown: bool = false

# SENTENCE
@export var frase_original :String = ""

# Original numbers to the original sentence, not randomized
@export var lista_numeros_frase_original := []

# Choices that user has made. May be wrong.
@export var lista_letras_frase_usuario := []
@export var frase_usuario: String
#export var letras_reveladas: String = ""

const CAT_EFEMERIDE := "efemeride"
const CAT_CITA := "cita"
const CAT_CURIOSIDADES := "curiosidades"
const CAT_FRAGMENTO := "fragmento"
const MODE_QUICK := "quick"
const MODE_CRYPTOGRAM := "cryptogram"

func locale_code() -> String:
	var loc := TranslationServer.get_locale().strip_edges()
	if loc.is_empty():
		return "es"
	var base := loc.replace("-", "_")
	var parts := base.split("_")
	return String(parts[0]).to_lower()

func apply_language(code: String) -> void:
	var locale := code.strip_edges()
	if locale.is_empty():
		locale = "es"
	TranslationServer.set_locale(locale)
	if typeof(PlayerPrefs) != TYPE_NIL:
		PlayerPrefs.idioma = locale
		PlayerPrefs.save_prefs()
	change_letters_aphabet_array()
	cargar_frases_desde_json()
	SignalManager.fit_text.emit()

func normalize_category(raw: String) -> String:
	var key := raw.strip_edges().to_lower()
	key = key.replace("á", "a").replace("é", "e").replace("è", "e").replace("ë", "e")
	match key:
		"efemeride", "efemerides", "event", "events", "ereignis", "gertaera", "evenement", "evento":
			return CAT_EFEMERIDE
		"cita", "citas", "appointment":
			return CAT_CITA
		"curiosidades", "curiosities":
			return CAT_CURIOSIDADES
		"fragmento", "fragment", "fragmentos":
			return CAT_FRAGMENTO
		_:
			return key

func categories_match(a: String, b: String) -> bool:
	return normalize_category(a) == normalize_category(b)

func is_category(cat_id: String, raw: String = "") -> bool:
	var value := raw if raw != "" else categoria_actual
	return normalize_category(value) == cat_id

func category_tr_key(cat: String = "") -> String:
	var id := normalize_category(cat if cat != "" else categoria_actual)
	match id:
		CAT_EFEMERIDE:
			return "Ephemerides"
		CAT_CITA:
			return "Famous Quotes"
		CAT_CURIOSIDADES:
			return "Curiosities"
		CAT_FRAGMENTO:
			return "Literary Fragments"
		_:
			return cat if cat != "" else categoria_actual

func category_display_name(cat: String = "") -> String:
	return tr(category_tr_key(cat))

func category_color(cat: String = "") -> Color:
	match normalize_category(cat if cat != "" else categoria_actual):
		CAT_CITA:
			return Color(0.106, 0.541, 0.812)
		CAT_EFEMERIDE:
			return Color(0.812, 0.408, 0.38)
		CAT_FRAGMENTO:
			return Color(0.4, 0.824, 0.698)
		CAT_CURIOSIDADES:
			return Color(0.812, 0.463, 0.176)
		_:
			return Color(0.5, 0.5, 0.5)

func all_category_ids() -> PackedStringArray:
	return PackedStringArray([CAT_EFEMERIDE, CAT_FRAGMENTO, CAT_CITA, CAT_CURIOSIDADES])

func difficulty_display_name(diff: int = -1) -> String:
	var d := diff if diff >= 0 else dificultad_actual
	match d:
		1:
			return tr("Easy")
		2:
			return tr("Normal")
		3:
			return tr("Hard")
		4:
			return tr("PRO")
		_:
			return "?"

func _ready():
	partida_terminada = false
	randomize()
	change_letters_aphabet_array()
	cargar_frases_desde_json()
	if frases_db.size() >= 1:
		seleccionar_frase_aleatoria()
	else:
		# Fallback a la literal que ya tenías si el XML no existe/falla
		_inicializar_datos()
		_inicializar_lista_numeros_original()
	
	_inicializar_datos()
	set_hints_based_on_difficulty()
	
	lista_celdas.clear()
	SignalManager.update_stars.emit()
	SignalManager.decrease_live.connect(decrease_live)
	SignalManager.game_finished.connect(_game_finished)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			PlayerPrefs.bump_app_version()
			get_viewport().set_input_as_handled()


func set_level_normal_unlocked(state: bool) -> void:
	level_normal_unlocked = state
	
func set_level_dificil_unlocked(state: bool) -> void:
	level_dificil_unlocked = state
	
func set_level_pro_unlocked(state: bool) -> void:
	level_pro_unlocked = state

func set_lives_init() -> void:
	if dificultad_actual == 1:
		lives = 4
	elif dificultad_actual == 2:
		lives = 3
	elif dificultad_actual == 3:
		lives = 2
	else:
		lives = 1
	
func letra_corresponde_a_numero(letra: String, celda_seleccionada_numero: int) -> bool:
	if celda_seleccionada_numero == busca_posicion_letra_en_array(letra):
		return true
	else:
		return false

func busca_posicion_letra_en_array(letra_comp: String) -> int:
	if letra_comp.is_empty():
		return -1
	
	var L := letra_comp.strip_edges().to_upper()
	return GameManager.lista_numeros[GameManager.letters_aphabet_array.find(letra_comp)] + 1
	
func decrease_live() -> void:
	lives -= 1
	
	if lives <=0:
		SignalManager.game_finished_lost.emit()
		print("GAME LOST")
		#queue_free()
		return
		
	SignalManager.update_lives.emit(lives)

func set_calculo_letras_iniciales() -> void:
	if letras_iniciales != "" or dificultad_actual ==4:
		return
	else:
		if dificultad_actual == 1:
			var r1 :String= InitialLettersPicker.pick_initials_for_level(frase_original, 1)
			letras_iniciales = r1
			print ("LETRAS INICIALES CALCULADAS:" ,letras_iniciales)
		elif dificultad_actual == 2:
			var r2 :String= InitialLettersPicker.pick_initials_for_level(frase_original, 2)
			letras_iniciales = r2
			print ("LETRAS INICIALES CALCULADAS:" ,letras_iniciales)
		else:
			# only level 3 difficulty possible
			var r3 :String= InitialLettersPicker.pick_initials_for_level(frase_original, 3)
			letras_iniciales = r3
			print ("LETRAS INICIALES CALCULADAS:" ,letras_iniciales)
	
func set_hints_based_on_difficulty() -> void:
	if dificultad_actual==1:
		set_pista1()
	else:
		#waiting to define rest of the difficulties if they have hints revealed or not
		set_pista1()
		
func set_categoria_actual(categoria: String) -> void:
	categoria_actual = normalize_category(categoria)

func set_game_mode_actual(mode: String) -> void:
	game_mode_actual = MODE_CRYPTOGRAM if mode == MODE_CRYPTOGRAM else MODE_QUICK

func set_dificultad_actual(dificultad: int) -> void:
	dificultad_actual = dificultad
	set_lives_init()
 
func set_coins(number:int) -> void:
	coins = number

func resetear_partida_terminada() -> void:
	partida_terminada= false
	
func reset_game_paremeters() -> void:
	score = score_init
	pistas = 0
	pistas_utilizadas_1 = 0
#	letras_compradas = 0
#	vocales_compradas = 0
	vocalesAE_compradas = 0
	vocalesIOU_compradas = 0
	consonantes_compradas = 0
	cambios_hechos = 0
	pistas_utilizadas_2 = 0 
	tiempo_partida = 0	
	reset_puzzle_stars()

func _game_finished() -> void:
	partida_terminada = true
	print("singal game finished launch")
	
func reset_cell_select() -> void:
	selected_celda_number = 100
	celda_seleccionada_numero = 100
	for celda:Celda in get_tree().get_nodes_in_group("Celda"): 
		celda.deselect_cell()
	celda_seleccionada_numero = 0
	
func set_go_to_game_enable() -> void:
	go_to_game = true
	
func set_go_to_game_disable() -> void:
	go_to_game = false
	
func calcula_score() -> void:
	#
	score = score_init - 5000 * int(GameManager.pista_3) - 3000 * GameManager.vocalesAE_compradas - 2000 * GameManager.vocalesIOU_compradas - 1000 * GameManager.consonantes_compradas - 500 * int(GameManager.pista_2) - GameManager.tiempo_partida 
	
func cambios_increase() -> void:
	cambios_hechos = cambios_hechos + 1

func _inicializar_datos():
	_inicializar_lista_letras(frase_original)
	_inicializar_lista_numeros()
	_inicializar_lista_colores_asignados()
	_inicializar_lista_celdas()
	_inicializar_lista_numeros_original()
	
	pista_1 = false
	pista_2 = false
	pista_3 = false
	pistas_utilizadas_1 = 0
	pistas_utilizadas_2 = 0
	
	vocalesAE_compradas = 0
	vocalesIOU_compradas = 0
	consonantes_compradas = 0

func increment_vocalesAE_compradas() -> void:
	if vocalesAE_compradas == 0:
		vocalesAE_compradas =1
	else:
		vocalesAE_compradas = 2
	
func increment_vocalesIOU_compradas() -> void:
	vocalesIOU_compradas += 1
	if vocalesIOU_compradas >=3:
		vocalesIOU_compradas = 3
		
func increment_consonantes_compradas() -> void:
	consonantes_compradas += 1

func set_pista1() -> void:
	pista_1 = true


func set_pista2() -> void:
	pista_2 = true
	pistas_utilizadas_1 = 1
	
func set_pista3() -> void:
	pista_3 = true
	pistas_utilizadas_2 = 1
	
func set_pistas_utilizadas(pistas:int) -> void:
	pistas_utilizadas = pistas


func reset_puzzle_stars() -> void:
	puzzle_stars = 5
	_penalized_reveal_errors.clear()
	_penalized_hints.clear()
	reveal_errors_count = 0
	SignalManager.update_puzzle_stars.emit(puzzle_stars)


func subtract_puzzle_stars(amount: int) -> void:
	if amount <= 0:
		return
	puzzle_stars = maxi(0, puzzle_stars - amount)
	SignalManager.update_puzzle_stars.emit(puzzle_stars)


func register_hint_used(hint_id: String) -> void:
	if hint_id == "" or _penalized_hints.has(hint_id):
		return
	_penalized_hints[hint_id] = true
	subtract_puzzle_stars(1)


func reveal_assignment_errors() -> int:
	var new_errors := 0
	var wrong_numbers: Dictionary = {}
	var correct_numbers: Dictionary = {}
	var wrong_letters: Dictionary = {}
	var correct_letters: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		var cell := node as Celda
		if cell.numero >= 100 or cell.letter_user == "":
			continue
		if letra_corresponde_a_numero(cell.letter_user, cell.numero):
			correct_numbers[cell.numero] = true
			correct_letters[cell.letter_user.to_upper()] = true
			cell.mostrar_letra()
		else:
			wrong_numbers[cell.numero] = cell.letter_user
			wrong_letters[cell.letter_user.to_upper()] = true
			cell.mostrar_letra_errada()

	for node: Node in get_tree().get_nodes_in_group("Letra"):
		if not node is Letra:
			continue
		var keyboard_letter := node as Letra
		var letter_key := keyboard_letter.letra.to_upper()
		if correct_letters.has(letter_key):
			keyboard_letter.mark_as_correct()
		elif wrong_letters.has(letter_key):
			keyboard_letter.mark_as_wrong_deselected()
		else:
			keyboard_letter.mark_as_unassigned()

	# Clear fill-color slots that pointed at now-verified cipher numbers.
	_clear_fill_color_slots_for_numbers(correct_numbers)

	for number: Variant in correct_numbers:
		_penalized_reveal_errors.erase(number)
	for number: Variant in wrong_numbers:
		var assigned_letter: String = str(wrong_numbers[number])
		if str(_penalized_reveal_errors.get(number, "")) == assigned_letter:
			continue
		_penalized_reveal_errors[number] = assigned_letter
		new_errors += 1

	reveal_errors_count += new_errors
	subtract_puzzle_stars(new_errors)
	update_numero_letras_reveladas(true)
	return wrong_numbers.size()


func _clear_fill_color_slots_for_numbers(correct_numbers: Dictionary) -> void:
	if correct_numbers.has(number_1):
		number_1 = 0
	if correct_numbers.has(number_2):
		number_2 = 0
	if correct_numbers.has(number_3):
		number_3 = 0
	if correct_numbers.has(number_4):
		number_4 = 0
	if correct_numbers.has(number_5):
		number_5 = 0

func set_mostrar_tuto_antes_partida_enable() -> void:
	mostrar_tuto_antes_partida = true

func set_mostrar_tuto_antes_partida_disable() -> void:
	mostrar_tuto_antes_partida = false

	
func _inicializar_lista_letras(frase: String) -> void:
	lista_letras_frase_original.clear()
	lista_letras_frase_original_sin_espacios_ni_puntuacion.clear()
	TOTAL_CELDAS = frase.length()
	calculate_rows()
	
	for i in frase.length():
		lista_letras_frase_original.append(frase[i])
		
		var c := frase[i]
		if not EXCLUIR.has(c):
			if c=="Á":
				lista_letras_frase_original_sin_espacios_ni_puntuacion.append("A")
			elif c=="É":
				lista_letras_frase_original_sin_espacios_ni_puntuacion.append("E")
			elif c=="Í":
				lista_letras_frase_original_sin_espacios_ni_puntuacion.append("I")
			elif c=="Ó":
				lista_letras_frase_original_sin_espacios_ni_puntuacion.append("O")
			elif c=="Ú":
				lista_letras_frase_original_sin_espacios_ni_puntuacion.append("U")
			else: 
				lista_letras_frase_original_sin_espacios_ni_puntuacion.append(c)
			
	numero_letras_a_revelar_originales = lista_letras_frase_original_sin_espacios_ni_puntuacion.size()
	
	#print(lista_letras_frase_original_sin_espacios_ni_puntuacion)
	#print("numero de caracteres a revelar ",numero_letras_a_revelar_originales )
	
	
func calculate_rows() -> void:
	NUM_FILAS = ceil(TOTAL_CELDAS / NUM_COLUMNAS)

func set_columns_and_rows(col: int, row: int) -> void:
	NUM_COLUMNAS = col
	NUM_FILAS = row

func _inicializar_lista_numeros():
	lista_numeros = []
	for i in range(1, letters_aphabet_array.size() +1):
		lista_numeros.append(i)
	lista_numeros.shuffle()

func _inicializar_lista_colores_asignados():
	lista_colores_asignados = []
	for _i in letters_aphabet_array:
		lista_colores_asignados.append(0) # Ningún color asignado aún

func _inicializar_lista_celdas():
	lista_celdas.clear()
	for i in range(TOTAL_CELDAS):
		var celda = Celda.new()
		lista_celdas.append(celda)

# Puedes añadir métodos para obtener colores, comentarios, etc.
func get_color_pastel(id_color: int) -> Color:
	if id_color in range(1, 6):
		return lista_tonos_colores[id_color - 1]
	return Color(1, 1, 1) # Blanco por defecto

func get_comentario_color(id_color: int) -> String:
	if id_color in range(1, 6):
		return lista_comentarios_colores[id_color - 1]
	return ""
	
#func letra(orden: int) -> String:
	#return letters_aphabet_array[orden]
	

func _inicializar_lista_numeros_original():
	lista_numeros_frase_original.clear()
	for i in lista_letras_frase_original.size():
		lista_numeros_frase_original.append(letra_a_numero(lista_letras_frase_original[i])+1)
		
func letra_a_numero(letra_input: String) -> int:
	var letra_temp: String
	letra_temp = letra_input
	if letra_input == "Á":
		letra_temp = "A"
	elif letra_input == "É":
		letra_temp = "E"
	elif letra_input == "Í":
		letra_temp = "I"
	elif letra_input == "Ó":
		letra_temp = "O"
	elif letra_input == "Ú":
		letra_temp = "U"
	
	for i in letters_aphabet_array.size():
		if letters_aphabet_array[i] == letra_temp:
			return lista_numeros[i]
	return 0
	
func añade_celda(celda_a_añadir:Celda) -> void:
	lista_celdas.append(celda_a_añadir)
	
func show_letter_error(cell_numbero: int) -> void:
		
	for node: Node in get_tree().get_nodes_in_group("Celda"):
		if node is Celda:
			var c:Celda = node
			if c.numero == cell_numbero:
				c.mostrar_letra_errada()


func set_celda_seleccionada(orden_celda:int, numero_celda:int) -> void:
	selected_celda_number = orden_celda
	celda_seleccionada_numero = numero_celda
	
func pinta_celdas(numero_en_celda: int, color_a_pintar: int) -> void:
	#print("ITERACIONNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN")
	for i in GameManager.lista_celdas.size():
		#print("Lista celdas numero: " ,lista_celdas[i].numero)
		#print("numero en celda " + str(numero_en_celda))
		if lista_celdas[i].numero == numero_en_celda:
			lista_celdas[i].cambia_color(color_a_pintar)
			
func set_number1(numero_a_guardar: int) -> void:
	number_1 = numero_a_guardar

func set_number2(numero_a_guardar: int) -> void:
	number_2 = numero_a_guardar

func set_number3(numero_a_guardar: int) -> void:
	number_3 = numero_a_guardar

func set_number4(numero_a_guardar: int) -> void:
	number_4 = numero_a_guardar

func set_number5(numero_a_guardar: int) -> void:
	number_5 = numero_a_guardar

func set_zoom_scale(scale:float) -> void:
	game_scale *= scale
	
func calculate_max_y_canvas() -> void:
	max_y_canvas = -165 * GameManager.NUM_FILAS
















func update_numero_letras_reveladas(check_solution: bool = false) -> void:
	#numero_letras_reveladas = numero_letras_reveladas + 1
	# I have to count it by hand because I will use the initial sequence of adding letters for the buying routine
	
	var total := 0
	for n in get_tree().get_nodes_in_group("Celda"):
		if n.celda_mostrada:
			total += 1
	
	numero_letras_reveladas = total

	
	SignalManager.update_resting_characters.emit()

	if numero_letras_reveladas < numero_letras_a_revelar_originales:
		board_fill_prompt_shown = false
	
	if not check_solution and numero_letras_a_revelar_originales > 0 \
			and numero_letras_a_revelar_originales == numero_letras_reveladas:
		if not board_fill_prompt_shown:
			board_fill_prompt_shown = true
			SignalManager.board_filled.emit()
		return

	if check_solution and numero_letras_a_revelar_originales == numero_letras_reveladas:
		print("GAME END")
		calcula_lista_letras_frase_usuario()
		
		if frase_usuario == "".join(lista_letras_frase_original_sin_espacios_ni_puntuacion):
			print ("GAME WINNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN")
			if dificultad_actual == 1 and GameManager.level_normal_unlocked == false	:
				# unlock dificult NORMAL
				set_level_normal_unlocked(true)
				PlayerPrefs.save_prefs()
			elif dificultad_actual == 2 and GameManager.level_dificil_unlocked == false	:
				# unlock dificult DIFFICULT
				set_level_dificil_unlocked(true)
				PlayerPrefs.save_prefs()
			elif dificultad_actual == 3 and GameManager.level_pro_unlocked == false	:
				# unlock dificult PRO
				set_level_pro_unlocked(true)
				PlayerPrefs.save_prefs()
			
			if dificultad_actual == 1:
				score = score + 30000
			elif dificultad_actual == 2:
				score = score + 40000
			elif dificultad_actual == 3:
				score = score + 50000
			else:
				score = score + 60000
			
			SignalManager.partida_finalizada.emit(str(GameManager.score))
			if HistoryManager.partida_dentro_de_record(GameManager.categoria_actual, GameManager.dificultad_actual, GameManager.score):
				SignalManager.game_finished.emit()
				GameManager.set_categoria_ultima_partida(GameManager.categoria_actual)
				GameManager.set_score_ultima_partida(GameManager.score)
				GameManager.set_dificultad_ultima_partida(GameManager.dificultad_actual)
				# Set game name
				#SignalManager.player_name_for_records.emit()
			else:
				GameManager.set_categoria_ultima_partida("")
				GameManager.set_score_ultima_partida(0)
				GameManager.set_dificultad_ultima_partida(0)
				SignalManager.game_finished.emit()
		else:
			print ("last letter wrong?!!?!?!?!")
		
func calcula_lista_letras_frase_usuario() -> void:
	lista_letras_frase_usuario.clear()

	for celda: Celda in get_tree().get_nodes_in_group("Celda"):
		var ch: String = celda.letter_user
		if celda.numero >= 100:
			# space and ,.: etc not inserted in list
			continue
		else: 
			lista_letras_frase_usuario.append(ch) 
	#print ("lista usuario", lista_letras_frase_usuario)
	frase_usuario = "".join(lista_letras_frase_usuario)
	#print ("frase usuario: ", frase_usuario)
	#print ("frase origina: ", "".join(lista_letras_frase_original_sin_espacios_ni_puntuacion))

		

func disminuye_numero_letras_reveladas() -> void:
	numero_letras_reveladas = numero_letras_reveladas - 1
	SignalManager.update_resting_characters.emit()
	
func set_selected_letter_user(letra: String) -> void:
	selected_letra = letra


func cargar_frases_desde_json() -> void:
	var loc := locale_code()
	match loc:
		"en":
			frases_json_path = frases_json_path_en
		"eu":
			frases_json_path = frases_json_path_eu
		"fr":
			frases_json_path = frases_json_path_fr
		"de":
			frases_json_path = frases_json_path_de
		"it":
			frases_json_path = frases_json_path_it
		"pt":
			frases_json_path = frases_json_path_pt
		_:
			frases_json_path = frases_json_path_es
	
	frases_db.clear()

	if not FileAccess.file_exists(frases_json_path):
		push_error("JSON no encontrado: " + frases_json_path)
		return

	var f := FileAccess.open(frases_json_path, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir: " + frases_json_path)
		return

	var txt := f.get_as_text() # UTF-8
	f.close()

	# 1) Vacío
	if txt.strip_edges().is_empty():
		push_error("El JSON está vacío: " + frases_json_path)
		return

	# 2) Parseo
	var parsed :Variant= JSON.parse_string(txt)
	if parsed == null:
		push_error("JSON inválido: no se pudo parsear (revisa comas finales, comillas y codificación UTF-8).")
		return

	# 3) Raíz: Array esperado (o Dictionary con 'phrases')
	var arr: Array = []
	match typeof(parsed):
		TYPE_ARRAY:
			arr = parsed
		TYPE_DICTIONARY:
			if (parsed as Dictionary).has("phrases") and typeof(parsed.phrases) == TYPE_ARRAY:
				arr = parsed.phrases
			else:
				push_error("Se esperaba un Array en la raíz o un Dictionary con la clave 'phrases'.")
				return
		_:
			push_error("Tipo raíz no soportado (usa Array o Dictionary['phrases']).")
			return

	# 4) Volcado tipado a frases_db
	for item in arr:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var dict := item as Dictionary
		if not dict.has("text"):
			continue

		var d: Dictionary = {}
		d.index             = int(dict.get("index", frases_db.size() + 1))
		d.text              = String(dict.get("text", ""))
		d.letters_init       = String( dict.get("letters_init", "")).to_upper()
		#d.letters_total     = int(dict.get("letters_total", 0))
		#d.letters_discover  = int(dict.get("letters_discover", 0))
		#d.description_init  = String(dict.get("description", ""))
		d.description_end   = String(dict.get("description_end", ""))
		d.category          = normalize_category(String(dict.get("category", "")))
		d.language          = String(dict.get("language", loc)).to_lower()
		d.difficulty        = int(dict.get("difficulty", 1))
		d.image_number      = int(dict.get("image_number", -1))
		d.hint_1            = String(dict.get("hint_1", ""))
		d.hint_2            = String(dict.get("hint_2", ""))
		d.hint_3            = String(dict.get("hint_3", ""))

		## ---- TIPADO SEGURO DE HINTS ----
		#var hints_variant = dict.get("hints", [])
		#var hints_typed: Array[String] = []
		#if typeof(hints_variant) == TYPE_ARRAY:
			#for h in hints_variant:
				#hints_typed.append(String(h))
		#while hints_typed.size() < 3:
			#hints_typed.append("")
		#d.hints = hints_typed
		
		if d.language.is_empty() or d.language == loc or String(d.language).begins_with(loc):
			frases_db.append(d)

	print("Frases JSON cargadas: ", frases_db.size())

	
func seleccionar_frase_por_indice_db(index_val: int) -> void:
	# Busca por atributo 'index' del XML
	for i in frases_db.size():
		if int(frases_db[i].index) == index_val:
			_aplicar_frase_desde_db(i)
			#print("categoria : ", frases_db[i].category)
			return
	push_error("No existe frase con index=" + str(index_val))

func seleccionar_frase_por_posicion(pos: int) -> void:
	if pos < 0 or pos >= frases_db.size():
		push_error("Posición fuera de rango: " + str(pos))
		return
	_aplicar_frase_desde_db(pos)

func seleccionar_frase_aleatoria() -> void:
	if frases_db.is_empty():
		push_error("No hay frases cargadas.")
		return
	var pos := randi() % frases_db.size()
	print("ID FRASE: " , str(id_frase))
	if id_frase != -1:
		_aplicar_frase_desde_db(id_frase)
	else:
		_aplicar_frase_desde_db(pos)

func _aplicar_frase_desde_db(pos: int) -> void:
	print("pasa por rutina de frase")
	frase_index_actual = pos
	var item: Dictionary = frases_db[pos]

	
	# Inyecta en tu pipeline actual
	id_frase           = int(item.index)
	frase_original_til = String(item.text)
	descripcion_final_actual  = String(item.description_end)
	categoria_actual   = normalize_category(String(item.category))
	dificultad_actual  = int(item.difficulty)
	id_image           = int(item.image_number)
	letras_iniciales   = String(item.letters_init)
	hint_1             = String(item.hint_1)
	hint_2             = String(item.hint_2)
	hint_3             = String(item.hint_3)
	
	frase_original = normalizar_frase_idioma(frase_original_til, locale_code())
	#descripcion_final_actual = descripcion_final
	
	# Reinicia tus estructuras como ya haces
	set_calculo_letras_iniciales()
	_inicializar_datos()
	_inicializar_lista_numeros_original()
	

	#print("Frase seleccionada -> index:", item.index, " cat:", categoria_actual, " diff:", dificultad_actual)

func add_letter_to_letras_iniciales(letter_to_add: String) -> void:
	letras_iniciales = letras_iniciales + letter_to_add

func seleccionar_por_categoria_y_dificultad(cat: String, diff: int) -> void:
	# cat = "" : all categories
	var candidatos: Array[int] = []

	# Buscar frases que cumplan los dos criterios
	for i in frases_db.size():
		var item: Dictionary = frases_db[i]
		var same_cat := cat == "" or categories_match(String(item.category), cat)
		if same_cat and int(item.difficulty) == diff:
			candidatos.append(i)

	if candidatos.is_empty():
		push_warning("No hay frases con categoría=" + cat + " y dificultad=" + str(diff))
		return

	# Selecciona una al azar de los candidatos
	var pos := candidatos[randi() % candidatos.size()]
	_aplicar_frase_desde_db(pos)

func seleccionar_por_index(index: int) -> void:
	reset_puzzle_stars()
	# Buscar frases que cumplan el criterio
	for i in frases_db.size():
		var item: Dictionary = frases_db[i]
		if (item.index == index ):
			_aplicar_frase_desde_db(i)




func button_blink(button: Button):
	var t := create_tween()
	# Escala original
	var original_scale := button.scale
	# Escala aumentada (20% más grande, por ejemplo)
	var big_scale := original_scale * 1.1

	# Aumenta en 0.25 segundos
	t.tween_property(button, "scale", big_scale, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Luego vuelve al tamaño original en otros 0.25 segundos
	t.tween_property(button, "scale", original_scale, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func button_blink_texture(button: TextureButton):
	var t := create_tween()
	# Escala original
	var original_scale := button.scale
	# Escala aumentada (20% más grande, por ejemplo)
	var big_scale := original_scale * 1.1

	# Aumenta en 0.25 segundos
	t.tween_property(button, "scale", big_scale, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Luego vuelve al tamaño original en otros 0.25 segundos
	t.tween_property(button, "scale", original_scale, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func reset_numero_letras_reveladas() -> void:
	numero_letras_reveladas = 0
	board_fill_prompt_shown = false

func play_pop_animation(node: Node):
	var tween = create_tween()
	node.scale = Vector2.ZERO  # empieza invisible
	node.visible = true
	# 1. Crece hasta un poco más del tamaño final (1.2x)
	tween.tween_property(node, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 2. Vuelve al tamaño normal (1x)
	tween.tween_property(node, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func play_pop_close_animation(node: Node):
	var tween = create_tween()

	# 1. Escala un poco más grande (1.2x) antes de encogerse
	#tween.tween_property(node, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 2. Luego se reduce a cero (desaparece)
	tween.tween_property(node, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	node.visible = false
	node.scale = Vector2(1,1)

func set_tiempo_partida(tiempo: int) -> void:
	if !partida_terminada:
		if tiempo_partida != tiempo:
			tiempo_partida = tiempo
			SignalManager.update_score.emit()

func formatear_numero(n: int) -> String:
	var s := str(n)
	var resultado := ""
	var contador := 0
	
	# Recorremos la cadena al revés y añadimos puntos cada 3 dígitos
	for i in range(s.length() - 1, -1, -1):
		resultado = s[i] + resultado
		contador += 1
		if contador % 3 == 0 and i > 0:
			resultado = "." + resultado
	
	return resultado
	
func change_letters_aphabet_array() -> void:
	letters_aphabet_array = get_letters_for_lang(locale_code())

# Devuelve un Array[String] con las letras (MAYÚSCULAS) del idioma pedido,
# sin tildes/diacríticos. Puedes ajustar opciones en 'opts'.
#
# opts:
#   include_enye (bool)      -> ES: incluir "Ñ" además de A–Z (por defecto true)
#   italian_21 (bool)        -> IT: usar alfabeto "clásico" de 21 letras (por defecto true)
#   basque_strict (bool)     -> EU: quitar letras poco usadas (C,Q,V,W,Y) (por defecto true)
#
func get_letters_for_lang(lang: String, opts := {}) -> Array:
	var L := lang.to_lower()
	
	# Valores por defecto de las opciones
	var include_enye   = true
	var italian_21     = true
	var basque_strict  = true
	
	# Sobrescribir si el diccionario trae claves
	if opts.has("include_enye"):
		include_enye = bool(opts["include_enye"])
	if opts.has("italian_21"):
		italian_21 = bool(opts["italian_21"])
	if opts.has("basque_strict"):
		basque_strict = bool(opts["basque_strict"])

	match L:
		"es", "spa", "es_es":
			var base := _letters_a_z()
			if include_enye:
				base.insert(15, "Ñ") # después de la N
			return base

		"en", "eng", "en_us", "en_gb":
			return _letters_a_z()

		"fr", "fra", "fr_fr":
			return _letters_a_z()

		"de", "deu", "de_de":
			return _letters_a_z()

		"it", "ita", "it_it":
			if italian_21:
				return ["A","B","C","D","E","F","G","H","I","L","M","N","O","P","Q","R","S","T","U","V","Z"]
			else:
				return _letters_a_z()

		"eu", "eus", "eu_es", "euskera", "basque":
			if basque_strict:
				return ["A","B","D","E","F","G","H","I","J","K","L","M","N","O","P","R","S","T","U","X","Z"]
			else:
				return _letters_a_z()

		_:
			return _letters_a_z()


func _letters_a_z() -> Array:
	var a := []
	for i in range(65, 91): # ASCII A..Z
		a.append(char(i))
	return a


# ---------- EJEMPLOS DE USO ----------

# 1) Español (incluyendo Ñ):
# GameManager.lista_letras = get_letters_for_lang("es")

# 2) Español SIN Ñ (si quieres estrictamente sin diacríticos):
# GameManager.lista_letras = get_letters_for_lang("es", {"include_enye": false})

# 3) Italiano clásico (21 letras):
# GameManager.lista_letras = get_letters_for_lang("it")

# 4) Italiano extendido (A–Z):
# GameManager.lista_letras = get_letters_for_lang("it", {"italian_21": false})

# 5) Euskera estricto:
# GameManager.lista_letras = get_letters_for_lang("eu")

# 6) Euskera no estricto (A–Z):
# GameManager.lista_letras = get_letters_for_lang("eu", {"basque_strict": false})

# Normaliza texto:
# - Lo convierte a MAYÚSCULAS
# - Quita tildes/diacríticos según idioma
# - Opciones por idioma en 'opts' (ver abajo)
func normalizar_frase_idioma(texto: String, lang: String, opts := {}) -> String:
	var L := lang.to_lower()
	var s := texto.to_upper()

	# ---------- Opciones ----------
	var es_keep_enye := true           # ES: mantener Ñ (true) o convertirla a N (false)
	var de_digraphs  := true           # DE: Ä→AE, Ö→OE, Ü→UE (true). Si false: A/O/U.
	var eu_keep_enye := false          # EU: por defecto NO se usa Ñ; si quieres mantenerla, pon true.

	if opts.has("es_keep_enye"):
		es_keep_enye = bool(opts["es_keep_enye"])
	if opts.has("de_digraphs"):
		de_digraphs = bool(opts["de_digraphs"])
	if opts.has("eu_keep_enye"):
		eu_keep_enye = bool(opts["eu_keep_enye"])

	# ---------- Mapas base (comunes) ----------
	var base_map := {
		"Á":"A","À":"A","Â":"A","Ã":"A","Ä":"A","Å":"A",
		"É":"E","È":"E","Ê":"E","Ë":"E",
		"Í":"I","Ì":"I","Î":"I","Ï":"I",
		"Ó":"O","Ò":"O","Ô":"O","Õ":"O","Ö":"O",
		"Ú":"U","Ù":"U","Û":"U","Ü":"U",
		"Ý":"Y","Ÿ":"Y",
		"Ç":"C"
	}

	# Caracteres compuestos frecuentes
	var lig_map := {
		"Æ":"AE", "Œ":"OE"
	}

	# Siempre convertir ß/ẞ a SS (seguro para todos los idiomas)
	var ss_map := {"ß":"SS", "ẞ":"SS"}

	# ---------- Aplicar según idioma ----------
	match L:
		"es", "spa", "es_es":
			# Español: mantener Ñ según opción
			if not es_keep_enye:
				base_map["Ñ"] = "N"
			# Aplicamos: ligaduras no son habituales, pero no molestan
			s = _reemplazar_varios(s, lig_map)
			s = _reemplazar_varios(s, ss_map)
			s = _reemplazar_varios(s, base_map)

		"en", "eng", "en_us", "en_gb":
			# Inglés: casi sin diacríticos; limpiar si aparecen
			s = _reemplazar_varios(s, lig_map)
			s = _reemplazar_varios(s, ss_map)
			s = _reemplazar_varios(s, base_map)
			# Ñ rara vez aparece; convertir por defecto
			s = s.replace("Ñ", "N")

		"fr", "fra", "fr_fr":
			# Francés: mantener AE/OE
			s = _reemplazar_varios(s, lig_map)  # Æ, Œ
			s = _reemplazar_varios(s, ss_map)
			s = _reemplazar_varios(s, base_map)
			# En FR no hay Ñ estándar
			s = s.replace("Ñ", "N")

		"it", "ita", "it_it":
			# Italiano: solo acentos simples
			s = _reemplazar_varios(s, ss_map)
			s = _reemplazar_varios(s, base_map)
			s = s.replace("Ñ", "N")

		"pt", "por", "pt_pt", "pt_br":
			# Portugués: usa Ã/Õ/Ç (ya cubiertos en base_map y Ç)
			s = _reemplazar_varios(s, ss_map)
			s = _reemplazar_varios(s, base_map)
			s = s.replace("Ñ", "N")

		"de", "deu", "de_de":
			# Alemán: ß→SS y, opcionalmente, Ä→AE, Ö→OE, Ü→UE
			s = _reemplazar_varios(s, ss_map)
			if de_digraphs:
				s = s.replace("Ä", "AE").replace("Ö", "OE").replace("Ü", "UE")
				# Quitar otras tildes residuales
				var de_map := base_map.duplicate()
				de_map.erase("Ä"); de_map.erase("Ö"); de_map.erase("Ü")
				s = _reemplazar_varios(s, de_map)
			else:
				s = _reemplazar_varios(s, base_map)
			s = s.replace("Ñ", "N")

		"eu", "eus", "eu_es", "euskera", "basque":
			# Euskera: no estándar con Ñ; por defecto convertir a N
			if not eu_keep_enye:
				base_map["Ñ"] = "N"
			s = _reemplazar_varios(s, ss_map)
			s = _reemplazar_varios(s, lig_map)
			s = _reemplazar_varios(s, base_map)

		_:
			# Desconocido: aplicar limpieza general
			s = _reemplazar_varios(s, lig_map)
			s = _reemplazar_varios(s, ss_map)
			s = _reemplazar_varios(s, base_map)
			s = s.replace("Ñ", "N")

	return s


# Helper: aplica un diccionario de reemplazos { "Á":"A", ... }
func _reemplazar_varios(cadena: String, mapa: Dictionary) -> String:
	for k in mapa.keys():
		cadena = cadena.replace(String(k), String(mapa[k]))
	return cadena


func set_score_ultima_partida(score_ultima: int) -> void:
	score_ultima_partida = score_ultima 
		
func set_categoria_ultima_partida(categoria_ultima: String) -> void:
	categoria_ultima_partida = normalize_category(categoria_ultima) 

func set_dificultad_ultima_partida(dificultad_ultima: int) -> void:
	dificultad_ultima_partida = dificultad_ultima 

## Devuelve true si hay al menos una celda editable con letra puesta.
func hay_letra_que_borrar() -> bool:
	for c in get_tree().get_nodes_in_group("Celda"):
		if c.letter_user != "" and not c.bloqueada:
			return true
	return false


## True si la selección actual es una letra ya verificada en verde (correcta).
func seleccion_es_letra_verificada_correcta() -> bool:
	var selected := selected_letra.strip_edges().to_upper()
	if selected == "":
		# Empty cell selected: still block if the cipher number is locked.
		if celda_seleccionada_numero > 0 and celda_seleccionada_numero < 100:
			for node: Node in get_tree().get_nodes_in_group("Celda"):
				if not node is Celda:
					continue
				var cell := node as Celda
				if cell.numero == celda_seleccionada_numero and cell.bloqueada:
					return true
		return false
	for node: Node in get_tree().get_nodes_in_group("Letra"):
		if not node is Letra:
			continue
		var keyboard_letter := node as Letra
		if keyboard_letter.letra.to_upper() == selected and keyboard_letter.verificada_correcta:
			return true
	if celda_seleccionada_numero > 0 and celda_seleccionada_numero < 100:
		for node: Node in get_tree().get_nodes_in_group("Celda"):
			if not node is Celda:
				continue
			var cell := node as Celda
			if cell.numero != celda_seleccionada_numero:
				continue
			if cell.bloqueada:
				return true
	return false


## Frees an unverified keyboard letter so it can be assigned again.
func liberar_letra_teclado(letra_a_liberar: String) -> void:
	var key := letra_a_liberar.strip_edges().to_upper()
	if key == "":
		return
	for node: Node in get_tree().get_nodes_in_group("Letra"):
		if not node is Letra:
			continue
		var keyboard_letter := node as Letra
		if keyboard_letter.letra.to_upper() == key:
			keyboard_letter.liberar_para_reuso()


## Clears an unverified letter from every matching cell on the board.
func borrar_letra_en_tablero(letra_a_borrar: String) -> void:
	var key := letra_a_borrar.strip_edges().to_upper()
	if key == "":
		return
	for node: Node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		var cell := node as Celda
		if cell.bloqueada:
			continue
		if cell.letter_user.strip_edges().to_upper() == key:
			cell.limpiar_letra_usuario()
	update_numero_letras_reveladas()
	SignalManager.deselect_all_cells_in_canvas.emit()


func set_player_name(nombre: String) -> void:
	player_name = nombre

func playfab_table() -> String:
	if GameManager.dificultad_actual ==1:
		return "Score_Facil"
	elif GameManager.dificultad_actual ==2:
		return "Score_Normal"
	else:
		return "Score_Dificil"
	
func codifica_score(score_to_codi: int) -> int:
	var score_final: int = score_to_codi * 10
	if is_category(CAT_FRAGMENTO):
		score_final += 1
		return score_final
	elif is_category(CAT_EFEMERIDE):
		score_final += 2
		return score_final
	elif is_category(CAT_CURIOSIDADES):
		score_final += 3
		return score_final
	elif is_category(CAT_CITA):
		score_final += 4
		return score_final
	else:
		return 0

## Devuelve un String concatenando todas las letras mostradas
func recoger_letras_mostradas() -> String:
	var resultado := ""
	# Recorre todos los nodos en el grupo "Letra"
	for nodo in get_tree().get_nodes_in_group("Letra"):
		# 
		if nodo.letra_mostrada == true:
			print("letra añadida")
			resultado += str(nodo.letra)
			# Si no, por defecto añade el nombre del nodo
	#letras_reveladas = resultado
	return resultado

func blink_resting_cells() -> void:
	for celda:Celda in get_tree().get_nodes_in_group("Celda"): 
		if !celda.celda_mostrada:
			celda._blink()
		else:
			celda._blink_stop()
	
