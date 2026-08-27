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
	label_2.text = GameManager.difficulty_display_name().to_upper() + " - " + GameManager.category_display_name()
	set_label_bg_only(cuadro_salir_borrado, GameManager.category_color())

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
