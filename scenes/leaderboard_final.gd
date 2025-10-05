extends Control

@onready var titulo_dificultad_categoria: Label = $ColorRect/TituloDificultadCategoria
@onready var titulo_dificultad_categoria_2: Label = $ColorRect/TituloDificultadCategoria2

@onready var color_cat_citas_celebres: Color = Color(0.106, 0.541, 0.812)
@onready var color_cat_adivinanzas: Color = Color(0.812, 0.718, 0.251)
@onready var color_cat_efemerides: Color = Color(0.812, 0.408, 0.38)
@onready var color_cat_fragmentos_literarios: Color = Color(0.4, 0.824, 0.698)
@onready var color_cat_curiosidades: Color = Color(0.812, 0.463, 0.176)

# =========================================================
# CONFIG & NODOS
# =========================================================
@export var fila_scene: PackedScene = preload("res://scenes/ScoreRow.tscn")
@export var history_node_path: NodePath

@onready var ob_dificultad: OptionButton = %Dificultad
@onready var ob_categoria:  OptionButton = %Categoria
@onready var lista_contenido: VBoxContainer = %Contenido

const DIFF_LABELS := ["Fácil", "Normal", "Difícil", "PRO"]
const DIFF_CODES  := [1, 2, 3, 4]
const MAX_ROWS    := 8

var _history_provider: Object = null

# =========================================================
# AJUSTES EXPUESTOS (TIPOGRAFÍA & COLORES)
# =========================================================
@export_range(8, 48, 1) var font_size_filters: int = 40
@export_range(8, 48, 1) var font_size_pos: int = 16
@export_range(8, 48, 1) var font_size_name: int = 16
@export_range(8, 48, 1) var font_size_points: int = 16
@export_range(8, 48, 1) var font_size_date: int = 12

@export var color_text: Color = Color(0.227, 0.227, 0.227, 1.0)
@export var color_date: Color = Color(0.533, 0.533, 0.533, 1.0)
@export var color_pos1: Color = Color(0.965, 0.651, 0.416, 1.0)
@export var color_pos2: Color = Color(0.525, 0.765, 0.635, 1.0)
@export var color_pos3: Color = Color(0.722, 0.549, 0.435, 1.0)
@export var color_placeholder_dim: Color = Color(0.55, 0.55, 0.55, 1.0)

# Estilos (tema) internos
var _chip_normal: StyleBoxFlat
var _chip_hover:  StyleBoxFlat
var _chip_focus:  StyleBoxFlat

var _row_even: StyleBoxFlat
var _row_odd:  StyleBoxFlat
var _row_highlight: StyleBoxFlat   # <— NUEVO

func _ready() -> void:
	_history_provider = _resolve_history_provider()

	# === Seleccionar filtros por última partida (si existen) ===
	_aplicar_filtros_de_ultima_partida()


func _resolve_history_provider() -> Object:
	if history_node_path != NodePath(""):
		var n := get_node_or_null(history_node_path)
		if n and n.has_method("get_results_filtered"):
			return n
	for child in get_tree().root.get_children():
		if child.has_method("get_results_filtered"):
			return child
	push_error("No encuentro proveedor de historial con get_results_filtered().")
	return null

func _get_categorias_desde_history() -> Array:
	if _history_provider and _history_provider.has_method("get_history"):
		var h: Array = _history_provider.call("get_history")
		var set := {}
		for e in h:
			if e is Dictionary:
				set[e.get("categoria","")] = true
		var arr: Array = []
		for k in set.keys():
			if str(k).strip_edges() != "":
				arr.append(k)
		return arr
	return []



# === NUEVO: aplicar filtros por última partida si existen ===
func _aplicar_filtros_de_ultima_partida() -> void:
	# --- Dificultad ---
	var diff_last: int = -1
	var diff_val: Variant = GameManager.get("dificultad_ultima_partida")
	if diff_val != null:
		diff_last = int(diff_val)
	if diff_last != -1:
		var idx_diff: int = DIFF_CODES.find(diff_last)
		if idx_diff != -1:
			ob_dificultad.select(idx_diff)

	# --- Categoría ---
	var cat_last: String = ""
	var cat_val: Variant = GameManager.get("categoria_ultima_partida")
	if cat_val != null:
		cat_last = str(cat_val)
	if cat_last != "":
		var target := cat_last.to_lower()
		for i in ob_categoria.item_count:
			if ob_categoria.get_item_text(i).to_lower() == target:
				ob_categoria.select(i)
				break

func _on_button_back_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")
	SoundManager.play("ButtonClick")
