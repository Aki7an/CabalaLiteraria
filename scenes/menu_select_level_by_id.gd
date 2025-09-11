# res://ui/ImageGrid.gd
extends Control
## Grid 3 columnas; cada celda es Button cuadrado que se adapta al ancho disponible.
## Filtra por GameManager.categoria_actual y GameManager.dificultad_actual.
## Al pulsar, asigna GameManager.id_frase = image_number y cambia de escena según flags.

const scene_to_tutorial = preload("res://scenes/MenuTutorial.tscn")
const scene_to_load_App = preload("res://scenes/App.tscn")

@export_dir var IMAGES_DIR: String = "res://data/images/"
@export var COLUMNS: int = 3
@export var FILE_EXTS: PackedStringArray = [".png", ".jpg", ".jpeg", ".webp"]
@export var H_SEP: int = 8   # separación horizontal entre celdas (px)
@export var V_SEP: int = 8   # separación vertical entre celdas (px)
@export_file("*.json") var JSON_PATH: String = "res://data/ejemplo.json"

var _grid: GridContainer = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0; offset_top = 0; offset_right = 0; offset_bottom = 0

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_bottom = -300   # deja 300px libres en la parte inferior
	add_child(scroll)


	_grid = GridContainer.new()
	_grid.name = "Grid"
	_grid.columns = max(1, COLUMNS)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", H_SEP)
	_grid.add_theme_constant_override("v_separation", V_SEP)
	var wrapper := MarginContainer.new()
	wrapper.name = "GridWrapper"
	wrapper.add_theme_constant_override("margin_top", 200)
	wrapper.add_theme_constant_override("margin_bottom", 300) # <- nuevo
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(wrapper)
	wrapper.add_child(_grid)

	# Recalcular celdas cuando cambie el tamaño
	resized.connect(_update_cell_sizes)
	_grid.resized.connect(_update_cell_sizes)

	if JSON_PATH != "":
		_load_and_populate_from_path(JSON_PATH)

# ================== API ==================

func populate_from_json_text(json_text: String) -> void:
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null:
		push_error("JSON inválido.")
		return
	_populate_from_parsed(parsed)

func populate_from_array(data: Array) -> void:
	_populate_from_parsed(data)

# ================== Lógica ==================

func _populate_from_parsed(parsed: Variant) -> void:
	if _grid == null:
		push_error("Grid no inicializado.")
		return

	_clear_grid_children()

	var items: Array
	if typeof(parsed) == TYPE_ARRAY:
		items = parsed
	elif typeof(parsed) == TYPE_DICTIONARY:
		items = [parsed]
	else:
		push_error("El JSON debe ser Array o Dictionary.")
		return

	var creados := 0
	var descartados := 0

	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue

		# --- FILTRO por GameManager (categoría/dificultad) ---
		if not _passes_filters(item):
			descartados += 1
			continue

		var img_num := int(item.get("image_number", -1))
		if img_num < 0:
			continue

		var path := _find_image_path(img_num)
		var btn := _create_image_button_node(img_num, path)

		# Tooltip con info útil (usar str(...) en lugar de String(...))
		var tt: PackedStringArray = []
		if item.has("category"): tt.append(str(item["category"]))
		if item.has("difficulty"): tt.append("Dif: %s" % str(item["difficulty"]))
		if item.has("text"): tt.append(str(item["text"]))
		btn.tooltip_text = "\n".join(tt)

		_grid.add_child(btn)
		creados += 1

	print("ImageGrid: creados=%d | descartados_por_filtro=%d | columnas=%d" %
		[creados, descartados, _grid.columns])

	# Recalcular tamaño de celdas tras poblar
	_update_cell_sizes()

func _passes_filters(item: Dictionary) -> bool:
	# Si no hay GameManager, no filtramos
	if typeof(GameManager) == TYPE_NIL:
		return true

	var ok := true

	# --- Categoría ---
	var target_cat := str(GameManager.categoria_actual).strip_edges().to_lower()
	if target_cat != "":
		var item_cat := str(item.get("category", "")).strip_edges().to_lower()
		ok = ok and (item_cat == target_cat)

	# --- Dificultad ---
	# Convención: si dificultad_actual es -1 (u otro valor fuera de rango), no se filtra
	var target_diff := int(GameManager.dificultad_actual)
	if target_diff != -1:
		var item_diff := int(item.get("difficulty", -9999))
		ok = ok and (item_diff == target_diff)

	return ok

func _clear_grid_children() -> void:
	if _grid == null: return
	for child in _grid.get_children():
		child.queue_free()

# ----- Construcción de cada celda -----
func _create_image_button_node(image_number: int, image_path: String) -> Button:
	var btn := Button.new()
	btn.name = "Image_%d" % image_number
	# Expandirse; el tamaño final lo fijamos en _update_cell_sizes
	btn.size_flags_horizontal = Control.SIZE_FILL
	btn.size_flags_vertical = Control.SIZE_FILL
	btn.text = ""  # overlay con Label
	btn.auto_translate = false

	# Imagen de fondo (cover)
	var texrect := TextureRect.new()
	texrect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texrect.offset_left = 0; texrect.offset_top = 0; texrect.offset_right = 0; texrect.offset_bottom = 0
	texrect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texrect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texrect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if image_path != "":
		var tex := load(image_path) as Texture2D
		if tex:
			texrect.texture = tex
	btn.add_child(texrect)

	# Texto "ID n" centrado y 3× más grande (overlay)
	var lbl := Label.new()
	lbl.text = "ID %d" % image_number
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 0; lbl.offset_top = 0; lbl.offset_right = 0; lbl.offset_bottom = 0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_sz := lbl.get_theme_font_size("font_size")
	lbl.add_theme_font_size_override("font_size", int(base_sz * 3))
	# Mejora opcional de legibilidad:
	# lbl.add_theme_color_override("font_outline_color", Color(0,0,0,0.85))
	# lbl.add_theme_constant_override("outline_size", 2)
	btn.add_child(lbl)

	# Metadatos y señal
	btn.set_meta("image_number", image_number)
	btn.set_meta("image_path", image_path)
	btn.pressed.connect(func(): _on_image_button_pressed(image_number, image_path))

	return btn

func _on_image_button_pressed(image_number: int, image_path: String) -> void:
	# Asignar al autoload GameManager (si existe)
	if typeof(GameManager) != TYPE_NIL:
		GameManager.id_frase = image_number
	else:
		push_warning("GameManager no encontrado como autoload. No se pudo asignar id_frase.")
	print("Pulsado image_number=%d | path=%s" % [image_number, image_path])

	if typeof(GameManager) != TYPE_NIL and GameManager.mostrar_tuto_antes_partida:
		GameManager.set_go_to_game_enable()
		TransitionScreen.transition_to_black()
		await TransitionScreen._on_animation_finished("fade_to_black", 1)
		get_tree().change_scene_to_packed(scene_to_tutorial)
	else:
		TransitionScreen.transition_to_black()
		if typeof(GameManager) != TYPE_NIL:
			GameManager.set_go_to_game_disable()
		await TransitionScreen._on_animation_finished("fade_to_black", 1)
		get_tree().change_scene_to_packed(scene_to_load_App)

# ----- Redimensión de celdas para ocupar toda la fila -----
func _update_cell_sizes() -> void:
	if _grid == null: return
	var cols :Variant= max(1, _grid.columns)
	var hsep := _grid.get_theme_constant("h_separation")
	var total_w := int(_grid.size.x)

	# Ancho disponible = ancho grid - separaciones
	var usable_w :Variant= max(0, total_w - (cols - 1) * hsep)
	var cell_w := 0
	if cols > 0:
		cell_w = int(floor(usable_w / cols))

	# Forzar cuadrado (cell_w x cell_w) para llenar sin huecos
	for child in _grid.get_children():
		if child is Button:
			(child as Button).custom_minimum_size = Vector2(cell_w, cell_w)

# ----- Utilidades -----
func _find_image_path(image_number: int) -> String:
	var base := "image%d" % image_number
	var dir := _rstrip_slash(IMAGES_DIR)
	for ext in FILE_EXTS:
		var candidate := "%s/%s%s" % [dir, base, ext]
		if ResourceLoader.exists(candidate):
			return candidate
	return ""

func _load_and_populate_from_path(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("No existe el JSON: %s" % path)
		return
	var json_text := FileAccess.get_file_as_string(path)
	if json_text == "":
		push_error("JSON vacío o no legible: %s" % path)
		return
	populate_from_json_text(json_text)

func _rstrip_slash(p: String) -> String:
	if p.ends_with("/"):
		return p.substr(0, p.length() - 1)
	return p


func _on_button_random_pressed() -> void:
	GameManager.id_frase = -1
	TransitionScreen.transition_to_black()
	if typeof(GameManager) != TYPE_NIL:
		GameManager.set_go_to_game_disable()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_packed(scene_to_load_App)
