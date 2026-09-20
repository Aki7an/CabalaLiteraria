extends Node

var idioma: String = "es"
var volumen_musica: float = 0.8
var volumen_fx: float = 0.8
var mute_musica: bool = true
var mute_fx: bool = true
var mostrar_tuto_antes_partida: bool = true
## Displayed as "0.XX". Starts at 1 → 0.01. F2 increases by 1.
## Source of truth is project.godot + data/app_version.json so exports and Git stay in sync.
var app_version_code: int = 1

var level_normal_unlocked: bool = false
var level_dificil_unlocked: bool = false
var level_pro_unlocked: bool = false
var last_completed_replay_date: String = ""
var skip_reveal_dialog: bool = false
var share_solve_data: bool = false
var hide_share_solve_dialog: bool = false
var favorite_ids: PackedInt32Array = PackedInt32Array()
var daily_date: String = ""
var daily_puzzle_id: int = -1
var daily_completed: bool = false
var daily_stars: int = 0
var daily_ids: PackedInt32Array = PackedInt32Array()
var full_game: bool = false
var ads_quick_streak: int = 0
var daily_rewarded_date: String = ""


const SAVE_PATH := "user://prefs.cfg"
const VERSION_JSON_PATH := "res://data/app_version.json"
const VERSION_TXT_PATH := "res://data/demo_version.txt"
const PROJECT_PATH := "res://project.godot"
const EXPORT_PRESETS_PATH := "res://export_presets.cfg"


func _ready() -> void:
	load_version_file()
	load_prefs()


func version_display() -> String:
	return version_name()


func version_name() -> String:
	return "0.%02d" % maxi(app_version_code, 1)


func bump_app_version() -> void:
	if not OS.has_feature("editor"):
		return
	app_version_code += 1
	save_version_file()
	SignalManager.app_version_changed.emit(version_display())


func load_version_file() -> void:
	var loaded := _code_from_project_settings()
	if loaded <= 0:
		loaded = _code_from_json()
	if loaded <= 0:
		loaded = _code_from_text(_read_text(VERSION_TXT_PATH))
	if loaded <= 0:
		loaded = 1
	app_version_code = loaded


func save_version_file() -> void:
	if not OS.has_feature("editor"):
		return
	var code := maxi(app_version_code, 1)
	var name := "0.%02d" % code
	_write_text(VERSION_JSON_PATH, JSON.stringify({"code": code}, "\t") + "\n")
	_write_text(VERSION_TXT_PATH, "%d\n" % code)
	_sync_project_settings(name)
	_sync_project_file(name)
	_sync_export_presets(code, name)


func _code_from_project_settings() -> int:
	if not ProjectSettings.has_setting("application/config/version"):
		return 0
	return _code_from_text(str(ProjectSettings.get_setting("application/config/version", "")))


func _code_from_json() -> int:
	var raw := _read_text(VERSION_JSON_PATH)
	if raw.is_empty():
		return 0
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		return maxi(int(parsed.get("code", 0)), 0)
	return _code_from_text(raw)


func _code_from_text(raw: String) -> int:
	var text := raw.strip_edges()
	if text.is_empty():
		return 0
	if text.is_valid_int():
		return maxi(int(text), 1)
	var digits := text.get_slice(".", text.get_slice_count(".") - 1)
	digits = digits.replace("\"", "")
	if digits.is_valid_int():
		return maxi(int(digits), 1)
	return 0


func _sync_project_settings(name: String) -> void:
	ProjectSettings.set_setting("application/config/version", name)


func _sync_project_file(name: String) -> void:
	var text := _read_text(PROJECT_PATH)
	if text.is_empty():
		return
	var re := RegEx.new()
	re.compile("(?m)^config/version=.*$")
	if re.search(text) != null:
		text = re.sub(text, 'config/version="%s"' % name, false)
	else:
		text = text.replace(
			'config/name="CifraLetra"',
			'config/name="CifraLetra"\nconfig/version="%s"' % name
		)
	_write_text(PROJECT_PATH, text)


func _sync_export_presets(code: int, name: String) -> void:
	var text := _read_text(EXPORT_PRESETS_PATH)
	if text.is_empty():
		return
	text = _replace_line(text, "version/code", str(code))
	text = _replace_quoted(text, "version/name", name)
	text = _replace_quoted(text, "application/short_version", name)
	text = _replace_quoted(text, "application/version", str(code))
	text = _replace_quoted(text, "include_filter", "*.json,*.txt")
	_write_text(EXPORT_PRESETS_PATH, text)


func _replace_line(text: String, key: String, value: String) -> String:
	var re := RegEx.new()
	re.compile("(?m)^%s=.*$" % key)
	if re.search(text) == null:
		return text
	return re.sub(text, "%s=%s" % [key, value], true)


func _replace_quoted(text: String, key: String, value: String) -> String:
	var re := RegEx.new()
	re.compile("(?m)^%s=.*$" % key)
	if re.search(text) == null:
		return text
	return re.sub(text, '%s="%s"' % [key, value], true)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var raw := file.get_as_text()
	file.close()
	return raw


func _write_text(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo escribir %s" % path)
		return
	file.store_string(contents)
	file.close()


# Guardar en disco
func save_prefs() -> void:
	if GameManager.mostrar_tuto_antes_partida != null:
		mostrar_tuto_antes_partida = GameManager.mostrar_tuto_antes_partida
	else:
		mostrar_tuto_antes_partida = true
		
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("general", "idioma", idioma)
	cfg.set_value("general", "player_name", GameManager.player_name)
	cfg.set_value("general", "guest_online_id", GameManager.guest_online_id)
	cfg.set_value("general", "online_name_chosen", GameManager.online_name_chosen)
	cfg.set_value("general", "mostrar_tutorial_antes_de_partida", mostrar_tuto_antes_partida)
	cfg.set_value("audio", "volumen_musica", volumen_musica)
	cfg.set_value("audio", "volumen_fx", volumen_fx)
	cfg.set_value("audio", "mute_musica", mute_musica)
	cfg.set_value("audio", "mute_fx", mute_fx)
	cfg.set_value("levels","levelNormalUnlocked", GameManager.level_normal_unlocked )
	cfg.set_value("levels","levelDificilUnlocked", GameManager.level_dificil_unlocked )
	cfg.set_value("levels","levelProUnlocked", GameManager.level_pro_unlocked)
	cfg.set_value("levels", "last_completed_replay_date", last_completed_replay_date)
	cfg.set_value("general", "skip_reveal_dialog", skip_reveal_dialog)
	cfg.set_value("general", "share_solve_data", share_solve_data)
	cfg.set_value("general", "hide_share_solve_dialog", hide_share_solve_dialog)
	cfg.set_value("library", "favorite_ids", Array(favorite_ids))
	cfg.set_value("daily", "date", daily_date)
	cfg.set_value("daily", "puzzle_id", daily_puzzle_id)
	cfg.set_value("daily", "completed", daily_completed)
	cfg.set_value("daily", "stars", daily_stars)
	cfg.set_value("daily", "ids", Array(daily_ids))
	cfg.set_value("shop", "full_game", full_game)
	cfg.set_value("ads", "quick_streak", ads_quick_streak)
	cfg.set_value("ads", "daily_rewarded_date", daily_rewarded_date)
	cfg.save(SAVE_PATH)
	

# Cargar de disco
func load_prefs() -> void:
	var cfg := ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err == OK:
		idioma = cfg.get_value("general", "idioma", idioma)
		GameManager.player_name = str(cfg.get_value("general", "player_name", GameManager.player_name))
		GameManager.guest_online_id = str(cfg.get_value("general", "guest_online_id", GameManager.guest_online_id))
		if cfg.has_section_key("general", "online_name_chosen"):
			GameManager.online_name_chosen = bool(cfg.get_value("general", "online_name_chosen", false))
		else:
			GameManager.online_name_chosen = GameManager.looks_like_chosen_online_name(GameManager.player_name)
		mostrar_tuto_antes_partida = cfg.get_value("general", "mostrar_tutorial_antes_de_partida", mostrar_tuto_antes_partida)
		volumen_musica = cfg.get_value("audio", "volumen_musica", volumen_musica)
		volumen_fx = cfg.get_value("audio", "volumen_fx", volumen_fx)
		mute_musica = bool(cfg.get_value("audio", "mute_musica", mute_musica))
		mute_fx = bool(cfg.get_value("audio", "mute_fx", mute_fx))
		level_normal_unlocked = cfg.get_value("levels","levelNormalUnlocked", level_normal_unlocked )
		GameManager.set_level_normal_unlocked(level_normal_unlocked)
		level_dificil_unlocked = cfg.get_value("levels","levelDificilUnlocked", level_dificil_unlocked )
		GameManager.set_level_dificil_unlocked(level_dificil_unlocked)
		level_pro_unlocked = cfg.get_value("levels","levelProUnlocked", level_pro_unlocked )
		GameManager.set_level_pro_unlocked(level_pro_unlocked)
		last_completed_replay_date = str(cfg.get_value(
			"levels",
			"last_completed_replay_date",
			last_completed_replay_date
		))
		skip_reveal_dialog = bool(cfg.get_value("general", "skip_reveal_dialog", skip_reveal_dialog))
		share_solve_data = bool(cfg.get_value("general", "share_solve_data", share_solve_data))
		hide_share_solve_dialog = bool(cfg.get_value("general", "hide_share_solve_dialog", hide_share_solve_dialog))
		favorite_ids = _load_favorite_ids(cfg)
		daily_date = str(cfg.get_value("daily", "date", daily_date))
		daily_puzzle_id = int(cfg.get_value("daily", "puzzle_id", daily_puzzle_id))
		daily_completed = bool(cfg.get_value("daily", "completed", daily_completed))
		daily_stars = int(cfg.get_value("daily", "stars", daily_stars))
		daily_ids = _load_int_ids(cfg, "daily", "ids")
		full_game = bool(cfg.get_value("shop", "full_game", full_game))
		ads_quick_streak = int(cfg.get_value("ads", "quick_streak", ads_quick_streak))
		daily_rewarded_date = str(cfg.get_value("ads", "daily_rewarded_date", daily_rewarded_date))
		
		if mostrar_tuto_antes_partida:
			GameManager.set_mostrar_tuto_antes_partida_enable()
		else:
			GameManager.set_mostrar_tuto_antes_partida_disable()

	if GameManager.ensure_online_identity():
		save_prefs()

	var locale := idioma.strip_edges()
	if locale.is_empty():
		locale = "es"
		idioma = locale
	TranslationServer.set_locale(locale)


func today_date_key() -> String:
	if typeof(GameManager) != TYPE_NIL:
		return GameManager.daily_date_key()
	var date := Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_system()))
	return "%04d-%02d-%02d" % [int(date.year), int(date.month), int(date.day)]


func has_daily_reward_today() -> bool:
	return daily_rewarded_date == today_date_key()


func mark_daily_rewarded_today() -> void:
	daily_rewarded_date = today_date_key()
	save_prefs()


func can_replay_completed_today() -> bool:
	return last_completed_replay_date != today_date_key()


func mark_completed_replay_today() -> void:
	last_completed_replay_date = today_date_key()
	save_prefs()


func reset_completed_replay_today() -> void:
	last_completed_replay_date = ""
	save_prefs()


func reset_player_progress() -> void:
	level_normal_unlocked = false
	level_dificil_unlocked = false
	level_pro_unlocked = false
	last_completed_replay_date = ""
	skip_reveal_dialog = false
	share_solve_data = false
	hide_share_solve_dialog = false
	favorite_ids = PackedInt32Array()
	daily_date = ""
	daily_puzzle_id = -1
	daily_completed = false
	daily_stars = 0
	daily_ids = PackedInt32Array()
	full_game = false
	ads_quick_streak = 0
	daily_rewarded_date = ""
	mostrar_tuto_antes_partida = true
	GameManager.set_level_normal_unlocked(false)
	GameManager.set_level_dificil_unlocked(false)
	GameManager.set_level_pro_unlocked(false)
	GameManager.set_mostrar_tuto_antes_partida_enable()
	GameManager.online_name_chosen = false
	GameManager.guest_online_id = ""
	GameManager.player_name = ""
	GameManager.ensure_online_identity()
	save_prefs()
	SignalManager.full_game_changed.emit()


func set_mostrar_tutorial(enabled: bool) -> void:
	mostrar_tuto_antes_partida = enabled
	if enabled:
		GameManager.set_mostrar_tuto_antes_partida_enable()
	else:
		GameManager.set_mostrar_tuto_antes_partida_disable()
	save_prefs()


func _load_favorite_ids(cfg: ConfigFile) -> PackedInt32Array:
	return _load_int_ids(cfg, "library", "favorite_ids")


func _load_int_ids(cfg: ConfigFile, section: String, key: String) -> PackedInt32Array:
	var loaded := PackedInt32Array()
	var raw: Variant = cfg.get_value(section, key, [])
	if raw is PackedInt32Array:
		return raw
	if raw is Array:
		for value in raw:
			var puzzle_id := int(value)
			if puzzle_id >= 0 and not loaded.has(puzzle_id):
				loaded.append(puzzle_id)
	return loaded


func daily_puzzle_id_for(date_key: String) -> int:
	if daily_date == date_key:
		return daily_puzzle_id
	return -1


func lock_daily_puzzle(date_key: String, puzzle_id: int) -> void:
	if daily_date == date_key and daily_puzzle_id == puzzle_id:
		return
	daily_date = date_key
	daily_puzzle_id = puzzle_id
	daily_completed = false
	daily_stars = 0
	save_prefs()


func is_daily_completed_today() -> bool:
	return daily_date == GameManager.daily_date_key() and daily_completed


func mark_daily_completed(puzzle_id: int, stars: int) -> void:
	daily_date = GameManager.daily_date_key()
	daily_puzzle_id = puzzle_id
	daily_completed = true
	daily_stars = stars
	if puzzle_id >= 0 and not daily_ids.has(puzzle_id):
		daily_ids.append(puzzle_id)
	save_prefs()


func is_daily_discovered(puzzle_id: int) -> bool:
	return daily_ids.has(puzzle_id)


func is_favorite(puzzle_id: int) -> bool:
	return favorite_ids.has(puzzle_id)


func toggle_favorite(puzzle_id: int) -> bool:
	var idx := favorite_ids.find(puzzle_id)
	if idx == -1:
		favorite_ids.append(puzzle_id)
		save_prefs()
		return true
	favorite_ids.remove_at(idx)
	save_prefs()
	return false


func set_show_reveal_explanation(enabled: bool) -> void:
	skip_reveal_dialog = not enabled
	save_prefs()


func set_share_solve_data(enabled: bool) -> void:
	share_solve_data = enabled
	save_prefs()


func set_hide_share_solve_dialog(enabled: bool) -> void:
	hide_share_solve_dialog = enabled
	save_prefs()
