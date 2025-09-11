extends ColorRect

func _ready():
	print("Momento en el que se abre Fondo aviso")
	
func _on_button_cancel_pressed() -> void:
	#fondo_aviso_borrado.visible = false
	#GameManager.play_pop_animation(fondo_aviso_borrado)
	queue_free()



func _on_button_erase_pressed():
	
	#fondo_aviso_borrado.visible = false
	#GameManager.play_pop_animation(fondo_aviso_borrado)
	print("Borrado", GameManager.selected_letra)
	#SignalManager.erase_selected_letter.emit()
	GameManager.cambios_increase()
	#tree_exited.connect(_on_tree_exited, CONNECT_ONE_SHOT)
	SignalManager.erase_letter.emit(GameManager.selected_letra)
	SignalManager.update_rubber.emit()
	SignalManager.update_cambios.emit()
	print("señal emitida")
	SignalManager.añade_las_letras_iniciales.emit()
	queue_free()

#func _on_tree_exited() -> void:
	##emit_signal("closed")  # tu señal propia
	## Opcional: señal global
	#SignalManager.erase_letter.emit(GameManager.selected_letra)
	#SignalManager.update_rubber.emit()
	#SignalManager.update_cambios.emit()
	#print("señal emitida")
	
