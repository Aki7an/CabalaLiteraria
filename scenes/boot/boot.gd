extends Node

func _ready() -> void:
	Distribution.apply_display()
	if Distribution.is_horizontal():
		call_deferred("_open_cg_start")
		return
	get_tree().call_deferred("change_scene_to_file", Distribution.home_scene())


func _open_cg_start() -> void:
	await PlayerProgress.ensure_loaded()
	if await _cg_session_logged_in():
		get_tree().change_scene_to_file(Distribution.home_scene())
		return
	PlayerProgress.open_current_puzzle()


func _cg_session_logged_in() -> bool:
	if Distribution.running_from_editor():
		return true
	var start := Time.get_ticks_msec()
	while typeof(PlayFabTools) != TYPE_NIL and not PlayFabTools.login_is_finished():
		if Time.get_ticks_msec() - start >= 8000:
			break
		await get_tree().process_frame
	return str(GameManager.crazygames_username).strip_edges() != ""
