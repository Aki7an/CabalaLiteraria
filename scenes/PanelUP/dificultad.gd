extends Label

@onready var estrella_contorno_2 = %EstrellaContorno2
@onready var estrella_contorno_3 = %EstrellaContorno3
@onready var estrella_contorno_1 = %EstrellaContorno1
@onready var estrella_1 = %Estrella1
@onready var estrella_2 = %Estrella2
@onready var estrella_3 = %Estrella3


func _ready():
	SignalManager.update_stars.connect(_update_stars)
	_update_stars(GameManager.dificultad_actual)
	
func _update_stars(diff: int) -> void:
	if diff == 1:
		estrella_contorno_2.visible = true
		estrella_contorno_3.visible = true
		estrella_1.visible = true
		estrella_2.visible = false
		estrella_3.visible = false
	elif diff == 2:
		estrella_contorno_1.visible = false
		estrella_contorno_2.visible = false
		estrella_contorno_3.visible = true
		estrella_1.visible = true
		estrella_2.visible = true
		estrella_3.visible = false
	elif diff == 3:
		estrella_contorno_1.visible = false
		estrella_contorno_2.visible = false
		estrella_contorno_3.visible = false
		estrella_1.visible = true
		estrella_2.visible = true
		estrella_3.visible = true
	else:
		estrella_contorno_2.visible = true
		estrella_contorno_3.visible = true
		estrella_contorno_1.visible = true
		estrella_1.visible = false
		estrella_2.visible = false
		estrella_3.visible = false
