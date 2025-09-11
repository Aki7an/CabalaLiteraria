extends ColorRect
@onready var canvas_juego = $".."

func _process(delta) -> void:
	if global_position.y < 1400:
		#print ("AJUSTE AJUSTE AJUSTE AJUSTE AJUSTE AJUSTE AJUSTE AJUSTE AJUSTE")
		canvas_juego.position.y += 20
