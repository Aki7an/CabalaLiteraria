# res://ui/ImageGrid.gd
extends Control

const PATH_TUTORIAL := "res://scenes/MenuTutorial.tscn"
const PATH_APP := "res://scenes/App.tscn"
var scene_to_tutorial: PackedScene
var scene_to_load_App: PackedScene
@onready var texture_rect_2 = $Panel/TextureRect2

@export_dir var IMAGES_DIR: String = "res://data/images/"
@export var COLUMNS: int = 3
@export var FILE_EXTS: PackedStringArray = [".png", ".jpg", ".jpeg", ".webp"]
@export var H_SEP: int = 8
@export var V_SEP: int = 8
@export_file("*.json") var JSON_PATH: String = "res://data/frases.json"

@export var LOAD_BATCH_SIZE: int = 12
@export var PLACEHOLDER_TEX: Texture2D

var _grid: GridContainer = null
var _pending_textures: Array[Button] = []
var _image_path_cache: Dictionary = {}   # {int: String}

func _ready() -> void:
	texture_rect_2.z_as_relative = false
	texture_rect_2.z_index = 1000      # o el valor alto que prefieras
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0; offset_top = 0; offset_right = 0; offset_bottom = 0

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_bottom = -300
	add_child(scroll)

	_grid = GridContainer.new()
	_grid.name = "Grid"
	_grid.columns = max(1, COLUMNS)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", H_SEP)
	_grid.add_theme_constant_override("v_separation", V_SEP)

	var wrapper: MarginContainer = MarginContainer.new()
	wrapper.name = "GridWrapper"
	wrapper.add_theme_constant_override("margin_top", 200)
	wrapper.add_theme_constant_override("margin_bottom", 300)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(wrapper)
	wrapper.add_child(_grid)

	resized.connect(_update_cell_sizes)
	_grid.resized.connect(_update_cell_sizes)

	# Espera 1 frame para que GameManager termine su _ready() y cargue frases_db
	await get_tree().process_frame

	if not _populate_from_gamemanager():
		if JSON_PATH != "":
			_load_and_populate_from_path(JSON_PATH)

	set_process(true)

func _process(_dt: float) -> void:
	var pending_size: int = _pending_textures.size()
	var n: int = min(LOAD_BATCH_SIZE, pending_size)
	for i in range(n):
		var btn: Button = _pending_textures.pop_front()
		_assign_real_texture(btn)

# === API ===
func refresh_from_gamemanager() -> void:
	_pending_textures.clear()
	_image_path_cache.clear()
	_populate_from_gamemanager()

func populate_from_json_text(json_text: String) -> void:
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null:
		push_error("JSON inválido.")
		return
	_pending_textures.clear()
	_image_path_cache.clear()
	_populate_from_parsed(parsed)

func populate_from_array(data: Array) -> void:
	_pending_textures.clear()
	_image_path_cache.clear()
	_populate_from_parsed(data)

# === Fuente en memoria (GameManager) ===
func _populate_from_gamemanager() -> bool:
	if typeof(GameManager) == TYPE_NIL:
		return false
	var arr: Array = GameManager.frases_db
	if arr is Array and arr.size() > 0:
		_populate_from_parsed(arr)
		return true
	return false

# === Lógica ===
func _populate_from_parsed(parsed: Variant) -> void:
	if _grid == null:
		push_error("Grid no inicializado.")
		return

	# Bloquea señales durante el poblado para evitar relayouts intermedios
	_grid.set_block_signals(true)
	_clear_grid_children()

	var items: Array
	if typeof(parsed) == TYPE_ARRAY:
		items = parsed
	elif typeof(parsed) == TYPE_DICTIONARY:
		items = [parsed]
	else:
		_grid.set_block_signals(false)
		push_error("El JSON debe ser Array o Dictionary.")
		return

	# Calcular tamaño de celda una vez
	var cols: int = max(1, _grid.columns)
	var hsep: int = _grid.get_theme_constant("h_separation")
	var total_w: int = int(_grid.size.x)
	var usable_w: int = max(0, total_w - (cols - 1) * hsep)
	var cell_w: int = int(floor(float(usable_w) / float(cols))) if cols > 0 else 0

	var creados: int = 0
	var descartados: int = 0

	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if not _passes_filters(item):
			descartados += 1
			continue

		var img_num: int = int(item.get("image_number", -1))
		if img_num < 0:
			continue
		
		var index_num: int = int(item.get("index", -1))
		if index_num < 0:
			continue

		var path: String = _find_image_path(img_num)
		var btn: Button = _create_image_button_node(index_num, img_num, path)
		btn.custom_minimum_size = Vector2(cell_w, cell_w)

		var tt: PackedStringArray = []
		if item.has("category"): tt.append(str(item["category"]))
		if item.has("difficulty"): tt.append("Dif: %s" % str(item["difficulty"]))
		btn.tooltip_text = "\n".join(tt)

		_grid.add_child(btn)
		creados += 1

	# Desbloquea señales y ajusta layout una sola vez
	_grid.set_block_signals(false)
	_update_cell_sizes()
	print("ImageGrid: creados=%d | descartados_por_filtro=%d | columnas=%d" %
		[creados, descartados, _grid.columns])

func _passes_filters(item: Dictionary) -> bool:
	if typeof(GameManager) == TYPE_NIL:
		return true
	var ok: bool = true
	var target_cat: String = str(GameManager.categoria_actual).strip_edges()
	if target_cat != "":
		var item_cat: String = str(item.get("category", ""))
		ok = ok and GameManager.categories_match(item_cat, target_cat)
	var target_diff: int = int(GameManager.dificultad_actual)
	if target_diff != -1:
		var item_diff: int = int(item.get("difficulty", -9999))
		ok = ok and (item_diff == target_diff)
	return ok

func _clear_grid_children() -> void:
	if _grid == null: return
	for child in _grid.get_children():
		child.queue_free()

# --- Celda ---
func _create_image_button_node(index_num: int, image_number: int, image_path: String) -> Button:
	var btn: Button = Button.new()
	btn.name = "Image_%d" % image_number
	btn.size_flags_horizontal = Control.SIZE_FILL
	btn.size_flags_vertical = Control.SIZE_FILL
	btn.text = ""
	btn.auto_translate = false

	var texrect: TextureRect = TextureRect.new()
	texrect.name = "BG"
	texrect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texrect.offset_left = 0; texrect.offset_top = 0; texrect.offset_right = 0; texrect.offset_bottom = 0
	texrect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texrect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texrect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if PLACEHOLDER_TEX:
		texrect.texture = PLACEHOLDER_TEX
	btn.add_child(texrect)

	var lbl: Label = Label.new()
	lbl.text = "ID %d" % index_num
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 0; lbl.offset_top = 0; lbl.offset_right = 0; lbl.offset_bottom = 0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_sz: int = lbl.get_theme_font_size("font_size")
	lbl.add_theme_font_size_override("font_size", int(base_sz * 3))
	btn.add_child(lbl)

	btn.set_meta("index", index_num)
	btn.set_meta("image_path", image_path)
	btn.pressed.connect(func(): _on_image_button_pressed(index_num, image_number, image_path))

	_pending_textures.append(btn)
	return btn

func _assign_real_texture(btn: Button) -> void:
	if not is_instance_valid(btn): return
	var texrect: TextureRect = btn.get_node_or_null("BG") as TextureRect
	if texrect == null: return
	var path: String = String(btn.get_meta("image_path", ""))
	if path == "": return
	var tex: Texture2D = load(path) as Texture2D
	if tex:
		texrect.texture = tex

func _on_image_button_pressed(index_num: int, image_number: int, _image_path: String) -> void:
	if typeof(GameManager) != TYPE_NIL:
		GameManager.id_frase = index_num
	else:
		push_warning("GameManager no encontrado como autoload. No se pudo asignar id_frase.")
	print("Pulsado image_number=%d" % index_num)

	if typeof(GameManager) != TYPE_NIL and GameManager.mostrar_tuto_antes_partida:
		GameManager.set_go_to_game_enable()
		TransitionScreen.transition_to_black()
		await TransitionScreen._on_animation_finished("fade_to_black", 1)
		_go_tutorial()
	else:
		if typeof(GameManager) != TYPE_NIL:
			GameManager.seleccionar_por_index(index_num)
			GameManager.set_go_to_game_disable()
		TransitionScreen.transition_to_black()
		await TransitionScreen._on_animation_finished("fade_to_black", 1)
		SignalManager.partida_iniciada.emit()
		_go_app()

# --- Redimensión ---
func _update_cell_sizes() -> void:
	if _grid == null: return
	var cols: int = max(1, _grid.columns)
	var hsep: int = _grid.get_theme_constant("h_separation")
	var total_w: int = int(_grid.size.x)
	var usable_w: int = max(0, total_w - (cols - 1) * hsep)
	var cell_w: int = int(floor(float(usable_w) / float(cols))) if cols > 0 else 0
	for child in _grid.get_children():
		if child is Button:
			(child as Button).custom_minimum_size = Vector2(cell_w, cell_w)

# --- Utilidades ---
func _find_image_path(image_number: int) -> String:
	if _image_path_cache.has(image_number):
		return String(_image_path_cache[image_number])
	var base: String = "image%d" % image_number
	var dir: String = _rstrip_slash(IMAGES_DIR)
	for ext in FILE_EXTS:
		var candidate: String = "%s/%s%s" % [dir, base, ext]
		if ResourceLoader.exists(candidate):
			_image_path_cache[image_number] = candidate
			return candidate
	_image_path_cache[image_number] = ""
	return ""

func _load_and_populate_from_path(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("No existe el JSON: %s" % path)
		return
	var json_text: String = FileAccess.get_file_as_string(path)
	if json_text == "":
		push_error("JSON vacío o no legible: %s" % path)
		return
	populate_from_json_text(json_text)

func _rstrip_slash(p: String) -> String:
	if p.ends_with("/"):
		return p.substr(0, p.length() - 1)
	return p

func _go_tutorial() -> void:
	if scene_to_tutorial == null:
		scene_to_tutorial = load(PATH_TUTORIAL)
	get_tree().change_scene_to_packed(scene_to_tutorial)

func _go_app() -> void:
	if scene_to_load_App == null:
		scene_to_load_App = load(PATH_APP)
	get_tree().change_scene_to_packed(scene_to_load_App)

func _on_button_random_pressed() -> void:
	# 1) Reunir botones clicables del grid
	if _grid == null:
		push_warning("Grid no inicializado: no se puede elegir aleatorio.")
		return

	var candidates: Array[Button] = []
	for child in _grid.get_children():
		if child is Button and child.visible and (child as Button).disabled == false:
			candidates.append(child)

	if candidates.is_empty():
		push_warning("No hay botones visibles/habilitados para elegir al azar.")
		return

	# 2) Elegir uno al azar
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var chosen: Button = candidates[rng.randi_range(0, candidates.size() - 1)]

	# 3) Obtener su 'index' y seguir el mismo flujo que un click normal
	var image_number: int = int(chosen.get_meta("index", -1))
	if image_number < 0:
		push_warning("El botón aleatorio elegido no tiene meta 'index' válida.")
		return

	# (Opcional) pequeño feedback visual
	if chosen.has_method("grab_focus"):
		chosen.grab_focus()

	# 4) Flujo igual que pulsación normal
	if typeof(GameManager) != TYPE_NIL:
		GameManager.id_frase = image_number
	else:
		push_warning("GameManager no encontrado como autoload. No se pudo asignar id_frase.")
	print("Aleatorio -> image_number=%d" % image_number)

	if typeof(GameManager) != TYPE_NIL and GameManager.mostrar_tuto_antes_partida:
		GameManager.set_go_to_game_enable()
		TransitionScreen.transition_to_black()
		await TransitionScreen._on_animation_finished("fade_to_black", 1)
		_go_tutorial()
	else:
		if typeof(GameManager) != TYPE_NIL:
			GameManager.seleccionar_por_index(image_number)
			GameManager.set_go_to_game_disable()
		TransitionScreen.transition_to_black()
		await TransitionScreen._on_animation_finished("fade_to_black", 1)
		SignalManager.partida_iniciada.emit()
		_go_app()
