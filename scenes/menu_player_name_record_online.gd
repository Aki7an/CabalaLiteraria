extends ColorRect

@onready var label_2 = $CuadroSalirBorrado/Label2
@onready var label_3 = $CuadroSalirBorrado/Label3

@onready var color_cat_citas_celebres: Color = Color(0.106, 0.541, 0.812)
@onready var color_cat_efemerides: Color = Color(0.812, 0.408, 0.38)
@onready var color_cat_fragmentos_literarios: Color = Color(0.4, 0.824, 0.698)
@onready var color_cat_curiosidades: Color = Color(0.812, 0.463, 0.176)

@onready var cuadro_salir_borrado: Label = $CuadroSalirBorrado
@onready var label_5 = $CuadroSalirBorrado/Label5


func _on_button_back_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SoundManager.play("ButtonClick")
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")

func _ready():
	if GameManager.dificultad_actual == 1:
		label_2.text = "FÁCIL - " + GameManager.categoria_actual
	elif GameManager.dificultad_actual == 2:
		label_2.text = "NORMAL - " + GameManager.categoria_actual
	elif GameManager.dificultad_actual == 3:
		label_2.text = "DIFÍCIL - " + GameManager.categoria_actual
	else:
		label_2.text = "PRO - " + GameManager.categoria_actual
		

	if GameManager.categoria_actual == "Efeméride":
		#label_cat_diff.text = dificultad_actual + " - Efemérides"
		set_label_bg_only(cuadro_salir_borrado, color_cat_efemerides)

	if GameManager.categoria_actual == "Fragmento":
		#label_cat_diff.text = dificultad_actual + " - Fragmento"
		set_label_bg_only(cuadro_salir_borrado, color_cat_fragmentos_literarios)

	if GameManager.categoria_actual == "Cita":
		#label_cat_diff.text = dificultad_actual + " - Citas Célebres"
		set_label_bg_only(cuadro_salir_borrado, color_cat_citas_celebres)
		
	if GameManager.categoria_actual == "Curiosidades":
		#label_cat_diff.text = dificultad_actual + " - Citas Bíblicas"
		set_label_bg_only(cuadro_salir_borrado, color_cat_curiosidades)

	label_3.text = "Posición Online Nº " + str(await PlayFabTools.get_player_rank_in_current_difficulty())
	label_5.text = GameManager.player_name
		
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
