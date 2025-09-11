extends HBoxContainer

@onready var pos_label:    Label = %PosLabel
@onready var nombre_label: Label = %NombreLabel
@onready var fecha_label:  Label = %FechaLabel
@onready var puntos_label: Label = %PuntosLabel

const COL_DATE := Color(0.73, 0.491, 0.248)

func _ready() -> void:
	fecha_label.add_theme_color_override("font_color", COL_DATE)

# ---------- API ----------
func set_data(pos: int, nombre: String, puntos: int, fecha_iso: String) -> void:
	pos_label.text    = str(pos)
	nombre_label.text = pad_to_len10(enforce_len10(nombre))
	puntos_label.text = _fmt_miles(puntos)
	fecha_label.text  = _fmt_fecha_ddmmyyyy(fecha_iso)

# Devuelve la cadena con longitud 10. Si es menor, la rellena con espacios.
func pad_to_len10(text: String) -> String:
	var n := text.length()
	if n >= 10:
		return text
	var spaces := ""
	for i in range(10 - n):
		spaces += " "
	return text + spaces

func enforce_len10(text: String) -> String:
	if text.length() < 10:
		return pad_to_len10(text)
	return text.substr(0, 10)  # corta a 10

func set_placeholder(pos: int) -> void:
	pos_label.text    = str(pos)
	nombre_label.text = "__________"
	puntos_label.text = "__.___.___"
	fecha_label.text  = "__/__/____"
	# atenuado
	var dim := Color(0.55, 0.55, 0.55, 1.0)
	nombre_label.add_theme_color_override("font_color", dim)
	puntos_label.add_theme_color_override("font_color", dim)
	fecha_label.add_theme_color_override("font_color", dim)

func set_rank_style(pos: int) -> void:
	# colorea #1/#2/#3 si quieres
	pass

# ---------- FORMATO ----------
func _fmt_miles(p: int) -> String:
	var s := str(p)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func _fmt_fecha_ddmmyyyy(iso: String) -> String:
	return ("%s/%s/%s" % [iso.substr(8,2), iso.substr(5,2), iso.substr(0,4)]) if iso.length() >= 10 else iso
