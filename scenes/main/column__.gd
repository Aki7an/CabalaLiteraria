extends Button


func _on_pressed():
	SignalManager.update_canvas_grid.emit(-1)
	
