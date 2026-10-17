extends Control

enum Profile { MOBILE, CRAZYGAMES }

@export var profile: Profile = Profile.MOBILE


func hide_for_puzzle_link() -> void:
	var menu := get_node_or_null("Menu")
	if menu and menu.has_method("hide_for_puzzle_link"):
		menu.call("hide_for_puzzle_link")


func reveal_main_menu() -> void:
	var menu := get_node_or_null("Menu")
	if menu and menu.has_method("reveal_main_menu"):
		menu.call("reveal_main_menu")
