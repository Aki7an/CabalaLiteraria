extends ColorRect

@onready var score_text = $ScoreText
@onready var score_2 = %Score2
@onready var letra_seleccionada = $LetraSeleccionada
@onready var button_comprar = $CuadroSalirPartida/ButtonComprar
@onready var letra_sel: String = ""

func _on_button_cancel_pressed():
	queue_free()


func _on_button_comprar_pressed():
	if letra_sel == "":
		print("letra vacia")
		return
	else:
		# añade la letra a la lista de inicio y cierra
		print("añade a letras iniciales")
		
		if letra_sel == "A" or letra_sel =="E":
			GameManager.increment_vocalesAE_compradas()
			SignalManager.compra_vocal_ae.emit(GameManager.tiempo_partida)
		elif letra_sel == "I" or letra_sel == "O" or letra_sel == "U":
			GameManager.increment_vocalesIOU_compradas()
			SignalManager.compra_vocal_iou.emit(GameManager.tiempo_partida)
		else:
			GameManager.increment_consonantes_compradas()
			SignalManager.compra_consonante.emit(GameManager.tiempo_partida)
		
		GameManager.add_letter_to_letras_iniciales(letra_sel)
		SignalManager.añade_las_letras_iniciales.emit()
		#var todos_los_caracteres_a_evaluar: String = GameManager.recoger_letras_mostradas() + GameManager.letras_iniciales
		SignalManager.update_difficulty.emit(GameManager.frase_original, GameManager.recoger_letras_mostradas() )
		queue_free()

func _process(delta):
	score_2.text = GameManager.formatear_numero(GameManager.score)

func _ready():
	letra_sel = ""
	SignalManager.letra_seleccionada_para_comprar.connect(_letra_seleccionada_para_comprar)

func _letra_seleccionada_para_comprar(letra: String) -> void:
	letra_seleccionada.text = letra
	letra_sel = letra
	button_comprar.text = "COMPRAR : " + letra_sel
