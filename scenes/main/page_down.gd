extends Button


func _on_pressed():
	SignalManager.move_canvas.emit(GameManager.canvas_wide)
