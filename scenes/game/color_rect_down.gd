extends ColorRect
@onready var canvas_juego = $".."
@onready var Color_rect_down_position_in_screen: float
@onready var Canvas_juego_position_in_screen: float
@onready var color_rect_down = $"."
@onready  var numero_pantallas: float = 0
@onready  var posicion_inicial: float = 440
@onready  var posicion_final: float = 1400
@onready  var longitud: float

func _ready():

	
	Color_rect_down_position_in_screen = canvas_juego.position.y + color_rect_down.position.y
	Canvas_juego_position_in_screen = canvas_juego.position.y
	SignalManager.intro_canvas_juego_tween.connect(_intro_canvas_juego_tween)
	

func _process(delta) -> void:
	
	if Canvas_juego_position_in_screen != canvas_juego.position.y:
		Canvas_juego_position_in_screen = canvas_juego.position.y
		Color_rect_down_position_in_screen = canvas_juego.position.y + color_rect_down.position.y
		print ("Posicion Canvas_Juego Y:" , Canvas_juego_position_in_screen)
		print ("Posicion Color_Rect_Down Y:" , Color_rect_down_position_in_screen)
		
		longitud = canvas_juego.position.y + color_rect_down.position.y
		numero_pantallas =  longitud / (posicion_final-posicion_inicial)
		print("longitud en start: ", longitud)
		print ("Numero de pantallas:" , numero_pantallas)
	if global_position.y < 1400:
		#print ("AJUSTE AJUSTE AJUSTE AJUSTE AJUSTE AJUSTE AJUSTE AJUSTE AJUSTE")
		canvas_juego.position.y += 20
		
func _intro_canvas_juego_tween() -> void:
		# retrasa este código
	canvas_juego.position = Vector2(canvas_juego.position.x, 1400 - color_rect_down.position.y )
	await get_tree().create_timer(0.8).timeout
	
	print ("Posicion a la que lo mando" , canvas_juego.position)
	tween_move_y(canvas_juego,1400 - color_rect_down.position.y, 440, 3,Tween.TRANS_EXPO, Tween.EASE_IN_OUT)


func tween_move_y(
	target: Control,
	y_from: float,
	y_to: float,
	duration: float,
	trans: Tween.TransitionType = Tween.TRANS_SINE,
	ease: Tween.EaseType = Tween.EASE_IN_OUT
) -> Tween:
	if !is_instance_valid(target):
		push_error("tween_move_y: target inválido")
		return null

	# Fija posición inicial (opción A)
	var start_pos := target.position
	start_pos.y = y_from
	target.position = start_pos

	var tween := create_tween()            # también puedes usar get_tree().create_tween()
	tween.set_trans(trans).set_ease(ease)  # transición y ease seleccionables

	# Interpola SOLO la componente Y (propiedad compuesta "position:y")
	var _tweener := tween.tween_property(target, "position:y", y_to, duration)

	# Alternativa a fijar antes la posición inicial:
	# _tweener.from(y_from)  # (si prefieres no tocar target.position antes)

	return tween
