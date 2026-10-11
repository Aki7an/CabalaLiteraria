extends Control

const DESIGN := Vector2(1280, 720)


func _enter_tree() -> void:
	_fit_to_window()


func _ready() -> void:
	_fit_to_window()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_fit_to_window):
		viewport.size_changed.connect(_fit_to_window)


func _fit_to_window() -> void:
	var view := get_viewport_rect().size
	if view.x < 2.0 or view.y < 2.0:
		return
	var fitted := minf(view.x / DESIGN.x, view.y / DESIGN.y)
	scale = Vector2(fitted, fitted)
	pivot_offset = Vector2.ZERO
	position = (view - DESIGN * fitted) * 0.5
