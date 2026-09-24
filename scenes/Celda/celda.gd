extends Control
class_name Celda

@export var celda_mostrada: bool  = false
## Locked cells (initial gifts or verified-correct) cannot change letter; green cells can still receive color.
@export var bloqueada: bool = false
## Gifted at the start of the puzzle (grey). Turns green on reveal.
@export var es_regalo_inicial: bool = false
## Verified correct: green letter on white.
@export var revelada_verde: bool = false

# Letra que contiene la celda (puede estar vacía inicialmente)
@export var letra: String = ""
@export var letter_user: String = ""

@export var color_error: Color = Color(0.81, 0.0, 0.0, 0.42)
@export var color_font_default: Color = Color(0.169, 0.18, 0.188)

@export var font_size_inicial: int = 40
@export var font_size_asignada: int = 30

# Número asociado a la celda (1-27)
@export var numero: int = 0

# Número asociado a la celda dentro de todas las que son en la frase
@export var orden: int = 0

# ID del color asignado (0 = ninguno, 1–5 según lista_colores del GameManager)
@export var color_id: int = 0

# La celda ha de tener también los signos de ortografia: , " : ;... pueden hasta ser dos ".
@export  var punto_ortografia: String = ""
@onready var label_numero: Label = $Fondo/LabelNumero
@onready var label_letra: Label = $Fondo/LabelLetra

@onready var label_puntuacion_punto: Label = $Fondo/LabelPuntuacionPunto
@onready var label_puntuacion_coma: Label = $Fondo/LabelPuntuacionComa
@onready var label_puntuacion_punto_coma: Label = $Fondo/LabelPuntuacionPuntoComa
@onready var label_puntuacion_dos_puntos: Label = $Fondo/LabelPuntuacionDosPuntos
@onready var label_puntuacion_comillas_inicio: Label = $Fondo/LabelPuntuacionComillasInicio
@onready var label_puntuacion_comillas_fin: Label = $Fondo/LabelPuntuacionComillasFin
@onready var label_puntuacion_exclamación_inicio: Label = $Fondo/LabelPuntuacionExclamaciónInicio
@onready var label_puntuacion_exclamación_fin: Label = $Fondo/LabelPuntuacionExclamaciónFin
@onready var label_puntuacion_e_interrogacion_inicio: Label = $Fondo/LabelPuntuacionEInterrogacionInicio
@onready var label_puntuacion_e_interrogacion_fin: Label = $Fondo/LabelPuntuacionEInterrogacionFin
@onready var espacio_blanco: Panel = $Fondo/EspacioBlanco
@onready var panel_celda: Panel = $Fondo

@onready var celda_selected: Panel = $Fondo/CeldaSelected

@onready var tween := get_tree().create_tween()

@onready var color_init: Color = Color(0.975, 0.965, 0.945)
@onready var color_rellena: Color = Color(0.78, 0.76, 0.74)
@onready var color_fondo_blanco: Color = Color(1.0, 1.0, 1.0)
@onready var color_letra_correcta: Color = Color(0.22, 0.62, 0.28)
const COLOR_HINT_YELLOW := Color(1.0, 0.86, 0.18, 1.0)
const COLOR_SAME_NUMBER := Color(1.0, 0.94, 0.68, 1.0)

var _remaining_hint_tween: Tween
var _remaining_hint_active := false
var _same_number_highlight := false

func _ready():
	add_to_group("Celda")
	_inicializar_puntuacion()
	_inicializar_letra()
	_inicializar_numero()
	mouse_filter = Control.MOUSE_FILTER_STOP
	SignalManager.update_size_celdas.connect(set_font_size)
	
func set_font_size() -> void:
	set_letter_font_size()
	set_number_font_size()
	
func _inicializar_puntuacion() -> void:
	label_puntuacion_punto.visible = false
	label_puntuacion_coma.visible = false
	label_puntuacion_punto_coma.visible = false
	label_puntuacion_dos_puntos.visible = false
	label_puntuacion_comillas_inicio.visible = false
	label_puntuacion_comillas_fin.visible = false
	label_puntuacion_exclamación_inicio.visible = false
	label_puntuacion_exclamación_fin.visible = false
	label_puntuacion_e_interrogacion_inicio.visible = false
	label_puntuacion_e_interrogacion_fin.visible = false
	espacio_blanco.visible = false
	
	celda_selected.visible = false
	
func set_letter_font_size() -> void:
	var size := 85
	if GameManager.NUM_COLUMNAS == 8:
		size = 120
	elif GameManager.NUM_COLUMNAS == 9:
		size = 110
	elif GameManager.NUM_COLUMNAS == 10:
		size = 100
	elif GameManager.NUM_COLUMNAS == 11:
		size = 95
	elif GameManager.NUM_COLUMNAS == 12:
		size = 90
	if _displayed_board_letter() == "J":
		size = maxi(roundi(float(size) * 0.78), 1)
	label_letra.add_theme_font_size_override("font_size", size)


func _displayed_board_letter() -> String:
	var shown := letter_user if letter_user != "" else letra
	return shown.strip_edges().to_upper() 
		
func set_number_font_size() -> void:
	label_numero.add_theme_font_size_override("font_size", font_size_inicial)
		
		
func _inicializar_letra() -> void:
	label_letra.text = letra
	label_letra.visible = false
	
	set_letter_font_size()
		
	celda_mostrada = false
	bloqueada = false
	es_regalo_inicial = false
	revelada_verde = false
	label_numero.add_theme_font_size_override("font_size",font_size_inicial )
	if _is_blank_mark(letra):
		espacio_blanco.visible = true


func _is_blank_mark(character: String) -> bool:
	return character == " " or character == "\n" or character == "\t" \
		or character == "\u00a0" or character == "\u200b"


func _inicializar_numero() -> void:
	label_numero.text = str(numero)
	label_numero.visible = true
	label_numero.stop_blink()
	
	set_number_font_size()
	
	# Punctuation and other non-letters start solved: visible mark, no cipher number.
	if GameManager.is_excluded_character(letra):
		label_numero.visible = false
		label_numero.text = "101"
		numero = 101
		celda_mostrada = true
		bloqueada = true
		if _is_blank_mark(letra):
			espacio_blanco.visible = true
			label_letra.visible = false
		else:
			label_letra.visible = true
			label_letra.text = letra
			set_letter_font_size()
		

func _blink() -> void:
	start_remaining_hint()

func _blink_stop() -> void:
	stop_remaining_hint()


func start_remaining_hint() -> void:
	if _remaining_hint_active or panel_celda == null or numero >= 100:
		return
	_remaining_hint_active = true
	var style := _ensure_fondo_style()
	style.bg_color = color_fondo_blanco
	if is_instance_valid(_remaining_hint_tween):
		_remaining_hint_tween.kill()
	_remaining_hint_tween = create_tween()
	_remaining_hint_tween.set_loops()
	_remaining_hint_tween.tween_property(style, "bg_color", COLOR_HINT_YELLOW, 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_remaining_hint_tween.tween_property(style, "bg_color", color_fondo_blanco, 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func stop_remaining_hint() -> void:
	if not _remaining_hint_active:
		return
	_remaining_hint_active = false
	if is_instance_valid(_remaining_hint_tween):
		_remaining_hint_tween.kill()
	_remaining_hint_tween = null
	_refresh_fondo()


func _idle_fondo_color() -> Color:
	if color_id > 0 and color_id < GameManager.lista_tonos_colores.size():
		return GameManager.lista_tonos_colores[color_id]
	if es_regalo_inicial:
		return color_rellena
	if bloqueada and celda_mostrada:
		return color_fondo_blanco
	return color_init


func _exit_tree() -> void:
	if is_instance_valid(_remaining_hint_tween):
		_remaining_hint_tween.kill()

func configurar_celda(letra_config: String, numero_config: int, orden_config:int , color_id_config: int) -> void:
	color_id = color_id_config
	orden = orden_config
	letra = letra_config
	_inicializar_letra()
	numero = numero_config
	_inicializar_numero()
	_inicializar_puntuacion()
	
func set_number(number:int) -> void:
	numero = number
	
func set_letter(letter:String) -> void:
	letra = letter

func set_letter_user(letter:String) -> void:
	letter_user = letter
	
func set_order(order:int) -> void:
	orden = order
	
func asignar_letra(order:int) -> void:
	label_numero.add_theme_font_size_override("font_size",font_size_asignada)

func _on_button_pressed() -> void:
	if bloqueada and not revelada_verde:
		return
	if letra == " " or numero >= 100:
		return
	SoundManager.play("ClickCelda")
	SignalManager.puzzle_input.emit("cell", {
		"orden": orden,
		"numero": numero,
		"letter": letter_user,
	})
	if color_id > 0:
		GameManager.borrar_color_de_numero(numero)
	GameManager.set_celda_seleccionada(orden, numero)
	if letter_user != "":
		GameManager.set_selected_letter_user(letter_user)
	else:
		GameManager.set_selected_letter_user("")
	
func cambia_color(color_a_cambiar: int) -> void:
	color_id = color_a_cambiar
	_same_number_highlight = false
	if celda_selected:
		celda_selected.visible = false
	if _remaining_hint_active:
		return
	_refresh_fondo()


func set_number_highlight(active: bool, is_primary: bool = false) -> void:
	_same_number_highlight = active
	if celda_selected:
		celda_selected.visible = is_primary
	if _remaining_hint_active:
		return
	_refresh_fondo()


func _refresh_fondo() -> void:
	if _same_number_highlight:
		_set_fondo_color(_idle_fondo_color().lerp(COLOR_SAME_NUMBER, 0.72))
	else:
		_set_fondo_color(_idle_fondo_color())


func _set_fondo_color(color: Color) -> void:
	if panel_celda == null:
		return
	var style := _ensure_fondo_style()
	style.bg_color = color


func _ensure_fondo_style() -> StyleBoxFlat:
	var current := panel_celda.get_theme_stylebox("panel")
	var style: StyleBoxFlat
	if current is StyleBoxFlat:
		style = current.duplicate() as StyleBoxFlat
	else:
		style = StyleBoxFlat.new()
	panel_celda.add_theme_stylebox_override("panel", style)
	return style

func deselect_all_cels() -> void:
	for celda:Celda in get_tree().get_nodes_in_group("Celda"):
		celda.deselect_cell()

func deselect_cell() -> void:
	set_number_highlight(false)
		
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_button_pressed()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_on_button_pressed()
		accept_event()

## Player assignment: visible letter, still editable.
func mostrar_letra_jugador() -> void:
	label_letra.text = letter_user
	set_letter_font_size()
	label_letra.visible = letter_user != ""
	label_letra.add_theme_color_override("font_color", color_font_default)
	celda_mostrada = letter_user != ""
	bloqueada = false
	es_regalo_inicial = false
	revelada_verde = false
	if celda_mostrada:
		stop_remaining_hint()

## Verified correct: white background, green letter, locked.
func mostrar_letra() -> void:
	stop_remaining_hint()
	label_letra.text = letter_user
	set_letter_font_size()
	label_letra.visible = true
	label_letra.add_theme_color_override("font_color", color_letra_correcta)
	color_id = 0
	celda_mostrada = true
	bloqueada = true
	revelada_verde = true
	_refresh_fondo()

func limpiar_letra_usuario() -> void:
	letter_user = ""
	label_letra.text = ""
	set_letter_font_size()
	label_letra.visible = false
	label_letra.add_theme_color_override("font_color", color_font_default)
	celda_mostrada = false
	bloqueada = false
	es_regalo_inicial = false
	revelada_verde = false

func mostrar_letra_errada() -> void:
	label_letra.text = letter_user
	set_letter_font_size()
	label_letra.add_theme_color_override("font_color", color_error)
	label_letra.visible = true
	celda_mostrada = false
	bloqueada = false
	revelada_verde = false

	
func mostrar_letra_especifica(letra_a_mostrar: String) -> void:
	#solo se usa para las letras que regalo al principio de la partida que así se diferencian de las del jugador
	letter_user = letra_a_mostrar
	label_letra.text = letra_a_mostrar
	set_letter_font_size()
	label_letra.visible = true
	label_letra.add_theme_color_override("font_color", color_font_default)
	celda_mostrada = true
	bloqueada = true
	es_regalo_inicial = true
	revelada_verde = false
	var style = StyleBoxFlat.new()
	style.bg_color = color_rellena
	#style.bg_color = Color(0.795, 0.295, 0.482)
	panel_celda.add_theme_stylebox_override("panel", style)


func hide_letter_visual() -> void:
	if numero >= 100:
		return
	if label_letra:
		label_letra.visible = false


func apply_enter_letter_look(shown: String, orange: Color) -> void:
	letter_user = shown
	if label_letra == null:
		return
	label_letra.text = shown
	set_letter_font_size()
	label_letra.visible = true
	label_letra.add_theme_color_override("font_color", orange)
	celda_mostrada = true
	clip_contents = true
	if size.x > 1.0:
		pivot_offset = size * 0.5


func finish_enter_letter_look(as_gift: bool) -> void:
	clip_contents = false
	scale = Vector2.ONE
	if as_gift:
		mostrar_letra_especifica(letter_user if letter_user != "" else letra)
	elif label_letra:
		label_letra.add_theme_color_override("font_color", color_font_default)
