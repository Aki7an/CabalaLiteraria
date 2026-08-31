extends Node

var idioma: String = "es"
var volumen_musica: float = 0.8
var volumen_fx: float = 0.8
var mute_musica: bool = false
var mute_fx: bool = false
var mostrar_tuto_antes_partida: bool = true
## Displayed as "Beta 0.XX". Starts at 1 → Beta 0.01. F2 increases by 1.
## Persisted in res://data/demo_version.txt so it syncs via Git between machines.
var app_version_code: int = 1

var level_normal_unlocked: bool = false
var level_dificil_unlocked: bool = false
var level_pro_unlocked: bool = false


const SAVE_PATH := "user://prefs.cfg"
const VERSION_PATH := "res://data/demo_version.txt"

func _ready() -> void:
	load_version_file()
	load_prefs()


func version_display() -> String:
	return "Beta 0.%02d" % maxi(app_version_code, 1)


func bump_app_version() -> void:
	app_version_code += 1
	save_version_file()
	SignalManager.app_version_changed.emit(version_display())


func load_version_file() -> void:
	if not FileAccess.file_exists(VERSION_PATH):
		save_version_file()
		return
	var file := FileAccess.open(VERSION_PATH, FileAccess.READ)
	if file == null:
		push_warning("No se pudo leer %s" % VERSION_PATH)
		return
	var raw := file.get_as_text().strip_edges()
	file.close()
	if raw.is_valid_int():
		app_version_code = maxi(int(raw), 1)
	else:
		# Accept legacy "Beta 0.01" lines if someone edited the file by hand.
		var digits := raw.get_slice(".", raw.get_slice_count(".") - 1)
		if digits.is_valid_int():
			app_version_code = maxi(int(digits), 1)


func save_version_file() -> void:
	var file := FileAccess.open(VERSION_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo escribir %s (solo funciona desde el editor / carpeta del proyecto)." % VERSION_PATH)
		return
	file.store_string("%d\n" % maxi(app_version_code, 1))
	file.close()


# Guardar en disco
func save_prefs() -> void:
	if GameManager.mostrar_tuto_antes_partida != null:
		mostrar_tuto_antes_partida = GameManager.mostrar_tuto_antes_partida
	else:
		mostrar_tuto_antes_partida = true
		
	var cfg := ConfigFile.new()
	cfg.set_value("general", "idioma", idioma)
	cfg.set_value("general", "player_name", GameManager.player_name)
	cfg.set_value("general", "mostrar_tutorial_antes_de_partida", mostrar_tuto_antes_partida)
	cfg.set_value("audio", "volumen_musica", volumen_musica)
	cfg.set_value("audio", "volumen_fx", volumen_fx)
	cfg.set_value("audio", "mute_musica", mute_musica)
	cfg.set_value("audio", "mute_fx", mute_fx)
	cfg.set_value("levels","levelNormalUnlocked", GameManager.level_normal_unlocked )
	cfg.set_value("levels","levelDificilUnlocked", GameManager.level_dificil_unlocked )
	cfg.set_value("levels","levelProUnlocked", GameManager.level_pro_unlocked)
	cfg.save(SAVE_PATH)
	

# Cargar de disco
func load_prefs() -> void:
	var cfg := ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err == OK:
		idioma = cfg.get_value("general", "idioma", idioma)
		GameManager.player_name = str(cfg.get_value("general", "player_name", GameManager.player_name))
		mostrar_tuto_antes_partida = cfg.get_value("general", "mostrar_tutorial_antes_de_partida", mostrar_tuto_antes_partida)
		volumen_musica = cfg.get_value("audio", "volumen_musica", volumen_musica)
		volumen_fx = cfg.get_value("audio", "volumen_fx", volumen_fx)
		mute_musica = cfg.get_value("audio", "mute_musica", mute_musica)
		mute_fx = cfg.get_value("audio", "mute_fx", mute_fx)
		level_normal_unlocked = cfg.get_value("levels","levelNormalUnlocked", level_normal_unlocked )
		GameManager.set_level_normal_unlocked(level_normal_unlocked)
		level_dificil_unlocked = cfg.get_value("levels","levelDificilUnlocked", level_dificil_unlocked )
		GameManager.set_level_dificil_unlocked(level_dificil_unlocked)
		level_pro_unlocked = cfg.get_value("levels","levelProUnlocked", level_pro_unlocked )
		GameManager.set_level_pro_unlocked(level_pro_unlocked)
		
		if mostrar_tuto_antes_partida:
			GameManager.set_mostrar_tuto_antes_partida_enable()
		else:
			GameManager.set_mostrar_tuto_antes_partida_disable()

	var locale := idioma.strip_edges()
	if locale.is_empty():
		locale = "es"
		idioma = locale
	TranslationServer.set_locale(locale)
