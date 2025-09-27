extends Label
@onready var label_nuevo_record: Label = $"."
@onready var label_puesto_top: Label = $LabelPuestoTOP
@onready var label_cat_diff: Label = $LabelCatDiff

@onready var color_cat_citas_celebres: Color = Color(0.106, 0.541, 0.812)
@onready var color_cat_efemerides: Color = Color(0.812, 0.408, 0.38)
@onready var color_cat_fragmentos_literarios: Color = Color(0.4, 0.824, 0.698)
@onready var color_cat_curiosidad: Color = Color(0.812, 0.463, 0.176)

func _ready() -> void:
	var dificultad_actual: String
	var categoria_actual: String = GameManager.categoria_actual
	var puesto_local: int = HistoryManager.numero_de_record_de_partida_dentro_de_record(GameManager.categoria_actual, GameManager.dificultad_actual, GameManager.score)
	
	if GameManager.dificultad_actual == 1:
		dificultad_actual = "Fácil"
	elif GameManager.dificultad_actual == 2:
		dificultad_actual = "Normal"
	elif GameManager.dificultad_actual == 3:
		dificultad_actual = "Difícil"
	elif GameManager.dificultad_actual == 4:
		dificultad_actual = "PRO"
	else:
		dificultad_actual = "?"
	
	label_puesto_top.text = "Puesto " + str(puesto_local) + " en TOP LOCAL"
		
	# (tu lógica de color de cabecera se mantiene)

	if GameManager.categoria_actual == "Efeméride":
		label_cat_diff.text = dificultad_actual + " - Efemérides"
		set_label_bg_only(label_nuevo_record, color_cat_efemerides)

	if GameManager.categoria_actual == "Fragmento":
		label_cat_diff.text = dificultad_actual + " - Fragmento"
		set_label_bg_only(label_nuevo_record, color_cat_fragmentos_literarios)

	if GameManager.categoria_actual == "Cita":
		label_cat_diff.text = dificultad_actual + " - Citas Célebres"
		set_label_bg_only(label_nuevo_record, color_cat_citas_celebres)

	if GameManager.categoria_actual == "Curiosidades":
		label_cat_diff.text = dificultad_actual + " - Curiosidades"
		set_label_bg_only(label_nuevo_record, color_cat_curiosidad )


		

# Cambia solo el color de fondo del Label manteniendo su estilo
func set_label_bg_only(lbl: Label, col: Color) -> void:
	var base := lbl.get_theme_stylebox("normal")
	if base == null:
		var flat := StyleBoxFlat.new()
		flat.bg_color = col
		lbl.add_theme_stylebox_override("normal", flat)
		return
	var copy := base.duplicate()
	if copy is StyleBoxFlat:
		var flat := copy as StyleBoxFlat
		flat.bg_color = col
		lbl.add_theme_stylebox_override("normal", flat)
	else:
		var flat := StyleBoxFlat.new()
		for s in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			flat.set_content_margin(s, base.get_content_margin(s))
		flat.bg_color = col
		lbl.add_theme_stylebox_override("normal", flat)
