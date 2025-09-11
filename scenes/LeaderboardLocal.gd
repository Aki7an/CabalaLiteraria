extends Control

@onready var titulo_dificultad_categoria: Label = $ColorRect/TituloDificultadCategoria
@onready var titulo_dificultad_categoria_2: Label = $ColorRect/TituloDificultadCategoria2

@onready var color_cat_citas_celebres: Color = Color(0.106, 0.541, 0.812)
@onready var color_cat_adivinanzas: Color = Color(0.812, 0.718, 0.251)
@onready var color_cat_refranes_populares: Color = Color(0.416, 0.812, 0.424)
@onready var color_cat_efemerides: Color = Color(0.812, 0.408, 0.38)
@onready var color_cat_citas_biblicas: Color = Color(0.576, 0.42, 0.812)
@onready var color_cat_fragmentos_literarios: Color = Color(0.4, 0.824, 0.698)
@onready var color_cat_chistes: Color = Color(0.812, 0.463, 0.176)

# =========================================================
# CONFIG & NODOS
# =========================================================
@export var fila_scene: PackedScene = preload("res://scenes/ScoreRow.tscn")
@export var history_node_path: NodePath

@onready var ob_dificultad: OptionButton = %Dificultad
@onready var ob_categoria:  OptionButton = %Categoria
@onready var lista_contenido: VBoxContainer = %Contenido

const DIFF_LABELS := ["Fácil", "Normal", "Difícil"]
const DIFF_CODES  := [1, 2, 3]
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
	_ensure_background()

	_poblar_optionbuttons()
	_style_filters()
	_init_row_styles()
	_conectar_signals()

	# === Seleccionar filtros por última partida (si existen) ===
	_aplicar_filtros_de_ultima_partida()

	_refrescar_lista()

# =========================================================
# ESTILO / TEMA
# =========================================================
func _ensure_background() -> void:
	if has_node("BG"):
		return
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0.961, 0.929, 0.890, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	move_child(bg, 0)

func _style_filters() -> void:
	_chip_normal = StyleBoxFlat.new()
	_chip_hover  = StyleBoxFlat.new()
	_chip_focus  = StyleBoxFlat.new()

	var chip_boxes := [_chip_normal, _chip_hover, _chip_focus]
	for box in chip_boxes:
		box.corner_radius_top_left = 12
		box.corner_radius_top_right = 12
		box.corner_radius_bottom_left = 12
		box.corner_radius_bottom_right = 12
		box.border_width_top = 1
		box.border_width_right = 1
		box.border_width_bottom = 1
		box.border_width_left = 1
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 6
		box.content_margin_bottom = 6

	_chip_normal.bg_color = Color(0.953, 0.906, 0.855, 1.0)
	_chip_hover.bg_color  = Color(0.937, 0.863, 0.812, 1.0)
	_chip_focus.bg_color  = Color(0.918, 0.824, 0.757, 1.0)

func _init_row_styles() -> void:
	_row_even = StyleBoxFlat.new()
	_row_odd  = StyleBoxFlat.new()
	_row_highlight = StyleBoxFlat.new()   # <— NUEVO

	var row_boxes := [_row_even, _row_odd, _row_highlight]
	for rb in row_boxes:
		rb.corner_radius_top_left = 12
		rb.corner_radius_top_right = 12
		rb.corner_radius_bottom_left = 12
		rb.corner_radius_bottom_right = 12
		rb.border_width_top = 1
		rb.border_width_right = 1
		rb.border_width_bottom = 1
		rb.border_width_left = 1
		rb.border_color = Color(0.914, 0.882, 0.847, 1.0)
		rb.content_margin_left = 12
		rb.content_margin_right = 12
		rb.content_margin_top = 6
		rb.content_margin_bottom = 6

	_row_even.bg_color = Color(1, 1, 1, 1)
	_row_odd.bg_color  = Color(0.969, 0.953, 0.933, 1.0)
	_row_highlight.bg_color = Color(1.0, 0.878, 0.4) # amarillo (resaltado)

func _row_style_for_index(idx: int, highlight: bool=false) -> StyleBox:
	if highlight:
		return _row_highlight
	return _row_even if (idx % 2 == 0) else _row_odd

# =========================================================
# DATOS / HISTORIAL
# =========================================================
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

# =========================================================
# UI: FILTROS
# =========================================================
func _poblar_optionbuttons() -> void:
	# Dificultad
	ob_dificultad.clear()
	for i in DIFF_LABELS.size():
		ob_dificultad.add_item(DIFF_LABELS[i])
		ob_dificultad.set_item_metadata(i, DIFF_CODES[i])
	ob_dificultad.selected = 0

	# Categorías
	var cats := _get_categorias_desde_history()
	if cats.is_empty():
		cats = [
			"Efemérides","Adivinanzas","Fragmentos literarios",
			"Citas célebres","Chistes","Refranes populares","Citas Bíblicas"
		]
	cats.sort_custom(func(a,b): return a.naturalnocasecmp_to(b) < 0)
	ob_categoria.clear()
	for c in cats:
		ob_categoria.add_item(c)
	ob_categoria.selected = 0

func _conectar_signals() -> void:
	ob_dificultad.item_selected.connect(func(_i): _refrescar_lista())
	ob_categoria.item_selected.connect(func(_i): _refrescar_lista())

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


# =========================================================
# UI: REFRESCO LISTA
# =========================================================
func _refrescar_lista() -> void:
	SignalManager.update_stars.emit(ob_dificultad.get_item_metadata(ob_dificultad.selected))

	for c in lista_contenido.get_children():
		c.queue_free()

	if _history_provider == null:
		return
	if fila_scene == null:
		push_error("fila_scene no asignada. Asigna tu ScoreRow.tscn en el Inspector.")
		return

	var diff_code: int = ob_dificultad.get_item_metadata(ob_dificultad.selected)
	var cat_label: String = ob_categoria.get_item_text(ob_categoria.selected)

	var results: Array = (_history_provider.call(
		"get_results_filtered", cat_label, diff_code
	) as Array)

	var row_index: int = 0
	var to_show: int = int(min(MAX_ROWS, results.size()))
	for i in range(to_show):
		var e: Dictionary = results[i]
		var nombre: String = str(e.get("jugador_nombre", "-"))
		var puntos: int = int(e.get("score", 0))
		var fecha_iso: String = _extraer_iso(e.get("fecha", {}))

		var highlight := _es_fila_resaltada(puntos, fecha_iso)   # <— NUEVO
		_add_row(row_index, nombre, puntos, fecha_iso, highlight)
		row_index += 1

	for i in range(row_index, MAX_ROWS):
		_add_placeholder_row(i)

	titulo_dificultad_categoria.text = str(ob_dificultad.get_item_text(ob_dificultad.selected)) + " - " + str(ob_categoria.get_item_text(ob_categoria.selected))

	# (tu lógica de color de cabecera se mantiene)
	if str(ob_categoria.get_item_text(ob_categoria.selected)) == "Adivinanza":
		set_label_bg_only(titulo_dificultad_categoria, color_cat_adivinanzas)
		set_label_bg_only(titulo_dificultad_categoria_2, color_cat_adivinanzas)
	if str(ob_categoria.get_item_text(ob_categoria.selected)) == "Efeméride":
		set_label_bg_only(titulo_dificultad_categoria, color_cat_efemerides)
		set_label_bg_only(titulo_dificultad_categoria_2, color_cat_efemerides)
	if str(ob_categoria.get_item_text(ob_categoria.selected)) == "Fragmento":
		set_label_bg_only(titulo_dificultad_categoria, color_cat_fragmentos_literarios)
		set_label_bg_only(titulo_dificultad_categoria_2, color_cat_fragmentos_literarios)
	if str(ob_categoria.get_item_text(ob_categoria.selected)) == "Cita célebre":
		set_label_bg_only(titulo_dificultad_categoria, color_cat_citas_celebres)
		set_label_bg_only(titulo_dificultad_categoria_2, color_cat_citas_celebres)
	if str(ob_categoria.get_item_text(ob_categoria.selected)) == "Chiste":
		set_label_bg_only(titulo_dificultad_categoria, color_cat_chistes)
		set_label_bg_only(titulo_dificultad_categoria_2, color_cat_chistes)
	if str(ob_categoria.get_item_text(ob_categoria.selected)) == "Refrán":
		set_label_bg_only(titulo_dificultad_categoria, color_cat_refranes_populares)
		set_label_bg_only(titulo_dificultad_categoria_2, color_cat_refranes_populares)
	if str(ob_categoria.get_item_text(ob_categoria.selected)) == "Cita Biblia":
		set_label_bg_only(titulo_dificultad_categoria, color_cat_citas_biblicas)
		set_label_bg_only(titulo_dificultad_categoria_2, color_cat_citas_biblicas)

# === NUEVO: comprobar si una fila es la de la última partida (score + fecha de hoy) ===
func _es_fila_resaltada(puntos: int, fecha_iso: String) -> bool:
	var last_score: int = -1
	var last_score_val: Variant = GameManager.get("score_ultima_partida")
	if last_score_val != null:
		last_score = int(last_score_val)

	if last_score == -1:
		return false

	var today_iso: String = Time.get_date_string_from_system()   # "YYYY-MM-DD"
	var fecha10: String = fecha_iso.substr(0, 10) if fecha_iso.length() >= 10 else fecha_iso
	return (puntos == last_score) and (fecha10 == today_iso)


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

func _add_row(idx: int, nombre: String, puntos: int, fecha_iso: String, highlight: bool=false) -> void:
	var fila := fila_scene.instantiate()
	var row_bg := PanelContainer.new()
	row_bg.add_theme_stylebox_override("panel", _row_style_for_index(idx, highlight))
	row_bg.add_child(fila)
	lista_contenido.add_child(row_bg)

	fila.set_data(idx + 1, nombre, puntos, fecha_iso)
	_apply_row_theme(fila, idx + 1, false)

func _add_placeholder_row(idx: int) -> void:
	var fila := fila_scene.instantiate()
	var row_bg := PanelContainer.new()
	row_bg.add_theme_stylebox_override("panel", _row_style_for_index(idx, false))
	row_bg.add_child(fila)
	lista_contenido.add_child(row_bg)

	if fila.has_method("set_placeholder"):
		fila.set_placeholder(idx + 1)
	else:
		fila.set_data(idx + 1, "--", 0, "--")
	_apply_row_theme(fila, idx + 1, true)

# =========================================================
# APLICAR TEMA A CADA FILA
# =========================================================
func _apply_row_theme(fila: Node, rank: int, placeholder: bool) -> void:
	var pos_label := fila.get_node_or_null("PosLabel") as Label
	var nombre_label := fila.get_node_or_null("NombreFecha/NombreLabel") as Label
	var fecha_label := fila.get_node_or_null("NombreFecha/FechaLabel") as Label
	var puntos_label := fila.get_node_or_null("PuntosLabel") as Label

	var name_col: Color = color_placeholder_dim if placeholder else color_text
	var points_col: Color = color_placeholder_dim if placeholder else color_text
	var date_col: Color = color_placeholder_dim if placeholder else color_date

	if nombre_label: nombre_label.add_theme_color_override("font_color", name_col)
	if puntos_label: puntos_label.add_theme_color_override("font_color", points_col)
	if fecha_label:  fecha_label.add_theme_color_override("font_color", date_col)

	if pos_label:
		var rank_col: Color = color_text
		if rank == 1: rank_col = color_pos1
		elif rank == 2: rank_col = color_pos2
		elif rank == 3: rank_col = color_pos3
		if placeholder: rank_col = color_placeholder_dim
		pos_label.add_theme_color_override("font_color", rank_col)

# ========================================================= 
# FORMATO / UTILIDADES
# =========================================================
func _extraer_iso(fecha_val: Variant) -> String:
	if typeof(fecha_val) == TYPE_DICTIONARY:
		var fd := fecha_val as Dictionary
		if fd.has("iso"):
			return str(fd["iso"])
		if fd.has_all(["anio","mes","dia"]):
			return "%04d-%02d-%02d" % [int(fd["anio"]), int(fd["mes"]), int(fd["dia"])]
		return ""
	elif typeof(fecha_val) == TYPE_STRING:
		return fecha_val
	return ""

func _on_button_back_pressed():
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")
	SoundManager.play("ButtonClick")
