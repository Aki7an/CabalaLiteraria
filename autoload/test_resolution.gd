extends Node

# Tamaño máximo solicitado y porcentaje de pantalla que puede ocupar F5.
var WINDOW_SCALE := 0.5
const SCREEN_USAGE := 0.88
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

	_resize_window_to_fit(vw, vh, WINDOW_SCALE)

func _resize_window_to_fit(vw: int, vh: int, requested_scale: float) -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	var usable_size := Vector2(usable_rect.size) * SCREEN_USAGE

	var fit_scale := minf(
		usable_size.x / float(vw),
		usable_size.y / float(vh)
	)
	var final_scale := clampf(minf(requested_scale, fit_scale), 0.1, 1.0)
	var target := Vector2i(
		roundi(float(vw) * final_scale),
		roundi(float(vh) * final_scale)
	)

	DisplayServer.window_set_size(target)

	# Solo se centra al iniciar o pulsar F1/F2; después puede moverse normalmente.
	var pos := usable_rect.position + (usable_rect.size - target) / 2
	DisplayServer.window_set_position(pos)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				_accion_F1()
			KEY_F2:
				_accion_F2()

func _accion_F1() -> void:
	print("Vista F5 ajustada al monitor")
	WINDOW_SCALE = 0.5
	_ready()

func _accion_F2() -> void:
	print("Vista F5 grande ajustada al monitor")
	WINDOW_SCALE = 1.0
	_ready()
