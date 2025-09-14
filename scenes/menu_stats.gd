extends Node2D
const scene_to_load_MenuMain = preload("res://scenes/MenuMain.tscn")
@onready var label_score = $Panel/LabelScore
@onready var nombre: LineEdit = $Panel/LabelNuevoRecord/Nombre
@onready var nombre_remarcar: Label = $Panel/LabelNuevoRecord/NombreRemarcar
@onready var advertencia_hecha: bool = false
@onready var partida_en_record: bool = false
@onready var texture_rect_record = $Panel/TextureRectRECORD
@onready var label_nuevo_record = $Panel/LabelNuevoRecord
#@onready var nombre = $Panel/LabelNuevoRecord/Nombre
@onready var button_back = $ButtonBack

@onready var label_partidas_total = $Panel/LabelPartidasTotal
@onready var label_record_dificil = $Panel/LabelRecordDificil
@onready var label_record_normal = $Panel/LabelRecordNormal
@onready var label_record_facil = $Panel/LabelRecordFacil
@onready var label_partidas_facil = $Panel/LabelPartidasFacil
@onready var label_partidas_normal = $Panel/LabelPartidasNormal
@onready var label_partidas_dificil = $Panel/LabelPartidasDificil
@onready var label_pistas_facil = $Panel/LabelPistasFacil
@onready var label_pistas_normal = $Panel/LabelPistasNormal
@onready var label_pistas_dificil = $Panel/LabelPistasDificil
@onready var label_letras_facil = $Panel/LabelLetrasFacil
@onready var label_letras_normal = $Panel/LabelLetrasNormal
@onready var label_letras_dificil = $Panel/LabelLetrasDificil

@onready var label_vocales_ae_facil: Label = $Panel/LabelVocalesAEFacil
@onready var label_vocales_ae_normal: Label = $Panel/LabelVocalesAENormal
@onready var label_vocales_ae_dificil: Label = $Panel/LabelVocalesAEDificil

@onready var label_vocales_iou_facil: Label = $Panel/LabelVocalesIOUFacil
@onready var label_vocales_iou_normal: Label = $Panel/LabelVocalesIOUNormal
@onready var label_vocales_iou_dificil: Label = $Panel/LabelVocalesIOUDificil

@onready var label_borrador_facil = $Panel/LabelBorradorFacil
@onready var label_borrador_normal = $Panel/LabelBorradorNormal
@onready var label_borrador_dificil = $Panel/LabelBorradorDificil
@onready var label_tiempo_facil = $Panel/LabelTiempoFacil
@onready var label_tiempo_normal = $Panel/LabelTiempoNormal
@onready var label_tiempo_dificil = $Panel/LabelTiempoDificil
@onready var label_tiempo_total = $Panel/LabelTiempoTotal

@onready var label_tiempo_jugado_facil: Label = $Panel/LabelTiempoJugadoFacil
@onready var label_tiempo_jugado_normal: Label = $Panel/LabelTiempoJugadoNormal
@onready var label_tiempo_jugado_dificil: Label = $Panel/LabelTiempoJugadoDificil


func go_to_main_menu() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SoundManager.play("ButtonClick")
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")

func go_to_name_record_online() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SoundManager.play("ButtonClick")
	get_tree().change_scene_to_file("res://scenes/menu_player_name_record_online.tscn")



func _on_button_back_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")
	SoundManager.play("ButtonClick")


func _ready() -> void:
	label_partidas_total.text = HistoryManager.stat_matches_count_str
	label_tiempo_total.text = HistoryManager.stat_total_play_time_str
	
	label_record_dificil.text =  "-"
	label_record_normal.text = "-"
	label_record_facil.text = "-"
	label_partidas_facil.text = HistoryManager.stat_matches_facil_str
	label_partidas_normal.text = HistoryManager.stat_matches_normal_str
	label_partidas_dificil.text = HistoryManager.stat_matches_dificil_str
	
	label_pistas_facil.text =  HistoryManager.stat_hints_used_facil_str
	label_pistas_normal.text =  HistoryManager.stat_hints_used_normal_str
	label_pistas_dificil.text =  HistoryManager.stat_hints_used_dificil_str
	label_letras_facil.text = HistoryManager.stat_letters_bought_facil_str
	label_letras_normal.text = HistoryManager.stat_letters_bought_normal_str
	label_letras_dificil.text =  HistoryManager.stat_letters_bought_dificil_str
	label_vocales_ae_facil.text = HistoryManager.stat_vowelsAE_bought_facil_str
	label_vocales_ae_normal.text =  HistoryManager.stat_vowelsAE_bought_normal_str
	label_vocales_ae_dificil.text =  HistoryManager.stat_vowelsAE_bought_dificil_str
	label_vocales_iou_facil.text = HistoryManager.stat_vowelsIOU_bought_facil_str
	label_vocales_iou_normal.text = HistoryManager.stat_vowelsIOU_bought_normal_str
	label_vocales_iou_dificil.text = HistoryManager.stat_vowelsIOU_bought_dificil_str
	
	label_borrador_facil.text = HistoryManager.stat_swaps_made_facil_str
	label_borrador_normal.text =  HistoryManager.stat_swaps_made_normal_str
	label_borrador_dificil.text =  HistoryManager.stat_swaps_made_dificil_str
	label_tiempo_facil.text =  HistoryManager.stat_avg_time_facil_str
	print(HistoryManager.stat_avg_time_facil_str)
	label_tiempo_normal.text =  HistoryManager.stat_avg_time_normal_str
	label_tiempo_dificil.text =  HistoryManager.stat_avg_time_dificil_str
	
	label_tiempo_jugado_facil.text = HistoryManager.stat_time_facil_str
	label_tiempo_jugado_normal.text = HistoryManager.stat_time_normal_str
	label_tiempo_jugado_dificil.text = HistoryManager.stat_time_dificil_str
	
