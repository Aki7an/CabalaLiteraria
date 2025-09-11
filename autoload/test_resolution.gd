extends Node

# Porcentaje deseado para la ventana en modo reproducción en PC (50 %)
var WINDOW_SCALE := 0.5
#const WINDOW_SCALE := 0.5
const DESKTOP_PLATFORMS := ["Windows", "Linux", "macOS"]

func _ready() -> void:
	# Solo tocar ventana cuando corremos en debug (Play) y en plataformas de escritorio
	if not OS.is_debug_build():
		return
	if not DESKTOP_PLATFORMS.has(OS.get_name()):
		return

	# Lee tu resolución final del proyecto (Viewport Width/Height)
	var vw: int = int(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var vh: int = int(ProjectSettings.get_setting("display/window/size/viewport_height"))
	if vw <= 0 or vh <= 0:
		return

	var target := Vector2i(roundi(vw * WINDOW_SCALE), roundi(vh * WINDOW_SCALE))
	DisplayServer.window_set_size(target)

	# (Opcional) Centrar la ventana en la pantalla actual
	var screen_size := DisplayServer.screen_get_size()
	var pos := (screen_size - target) / 2
	DisplayServer.window_set_position(pos)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				_accion_F1()
			KEY_F2:
				_accion_F2()

func _accion_F1() -> void:
	print("Se pulsó la tecla A. Tamaño para PC")
	WINDOW_SCALE = 0.5
	_ready()

func _accion_F2() -> void:
	print("Se pulsó la tecla W. Tamaño real para MAC")
	WINDOW_SCALE = 0.68
	_ready()
