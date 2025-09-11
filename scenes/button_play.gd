extends Button
@onready var button_play = $"."
@onready var jugar = $Jugar
@onready var play = $Play
@onready var label_aviso = $LabelAviso

func _ready():
	enable_or_disable_button()

func enable_or_disable_button() -> void:
	if button_play.disabled:
		jugar.modulate.a = .1
		play.modulate.a = .1
		label_aviso.visible = true
	else:
		jugar.modulate.a = 1
		play.modulate.a = 1
		label_aviso.visible = false
		
func enable_button() -> void:
	jugar.modulate.a = 1
	play.modulate.a = 1
	label_aviso.visible = false
