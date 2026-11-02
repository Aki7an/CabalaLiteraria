extends Control

const DESIGN := Vector2(1280, 720)


func _enter_tree() -> void:
	var menu := get_node_or_null("Menu")
	if menu == null:
		return
	menu.set_meta("compact_title", true)
	menu.set_meta("ui_scale", 1.0)
	menu.set_meta("cz_simple_home", true)
	if _cg_logged_in():
		menu.set_meta("cg_logged_home", true)
		menu.visible = false
		var home := get_node_or_null("LoggedHome")
		if home != null:
			home.visible = true


func _ready() -> void:
	_fit_to_window()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_fit_to_window):
		viewport.size_changed.connect(_fit_to_window)


func hide_for_puzzle_link() -> void:
	var home := get_node_or_null("LoggedHome")
	if home != null:
		home.visible = false
	var menu := get_node_or_null("Menu")
	if menu != null and menu.has_method("hide_for_puzzle_link"):
		menu.call("hide_for_puzzle_link")


func reveal_main_menu() -> void:
	if _cg_logged_in():
		var home := get_node_or_null("LoggedHome")
		if home != null:
			home.visible = true
			if home.has_method("refresh"):
				home.call("refresh")
		var menu := get_node_or_null("Menu")
		if menu != null:
			menu.visible = false
		return
	var guest_menu := get_node_or_null("Menu")
	if guest_menu != null and guest_menu.has_method("reveal_main_menu"):
		guest_menu.call("reveal_main_menu")


func _cg_logged_in() -> bool:
	if str(GameManager.crazygames_username).strip_edges() != "":
		return true
	return Distribution.running_from_editor() and Distribution.is_horizontal()


func _fit_to_window() -> void:
	var view := get_viewport_rect().size
	if view.x < 2.0 or view.y < 2.0:
		return
	var fitted := minf(view.x / DESIGN.x, view.y / DESIGN.y)
	scale = Vector2(fitted, fitted)
	pivot_offset = Vector2.ZERO
	position = (view - DESIGN * fitted) * 0.5
