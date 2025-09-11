extends Node

var idioma: String = "es"
var volumen_musica: float = 0.8
var volumen_fx: float = 0.8
var mute_musica: bool = false
var mute_fx: bool = false
var mostrar_tuto_antes_partida: bool = true

const SAVE_PATH := "user://prefs.cfg"

func _ready() -> void:
	load_prefs()

# Guardar en disco
func save_prefs() -> void:
	if GameManager.mostrar_tuto_antes_partida != null:
		mostrar_tuto_antes_partida = GameManager.mostrar_tuto_antes_partida
	else:
		mostrar_tuto_antes_partida = true
		
	var cfg := ConfigFile.new()
	cfg.set_value("general", "idioma", idioma)
	cfg.set_value("general", "mostrar_tutorial_antes_de_partida", mostrar_tuto_antes_partida)
	cfg.set_value("audio", "volumen_musica", volumen_musica)
	cfg.set_value("audio", "volumen_fx", volumen_fx)
	cfg.set_value("audio", "mute_musica", mute_musica)
	cfg.set_value("audio", "mute_fx", mute_fx)
	cfg.save(SAVE_PATH)

# Cargar de disco
func load_prefs() -> void:
	var cfg := ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err == OK:
		idioma = cfg.get_value("general", "idioma", idioma)
		mostrar_tuto_antes_partida = cfg.get_value("general", "mostrar_tutorial_antes_de_partida", mostrar_tuto_antes_partida) 
		volumen_musica = cfg.get_value("audio", "volumen_musica", volumen_musica)
		volumen_fx = cfg.get_value("audio", "volumen_fx", volumen_fx)
		mute_musica = cfg.get_value("audio", "mute_musica", mute_musica)
		mute_fx = cfg.get_value("audio", "mute_fx", mute_fx)
		
		if mostrar_tuto_antes_partida:
			GameManager.set_mostrar_tuto_antes_partida_enable()
		else:
			GameManager.set_mostrar_tuto_antes_partida_disable()
		
