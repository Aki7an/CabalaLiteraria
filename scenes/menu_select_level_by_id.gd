extends Control

const PATH_CATEGORY := "res://scenes/MenuSelectCategory.tscn"
const MODE_QUICK := "quick"
const MODE_CRYPTOGRAM := "cryptogram"
const STAR_TEXTURE: Texture2D = preload("res://images/estrella_plano.png")
const STAR_OFF_TEXTURE: Texture2D = preload("res://images/contorno_estrella.png")
const THEME_PREVIEW := preload("res://scenes/game/PuzzleThemePreview.tscn")
const COLOR_STAR_YELLOW := Color(1.0, 0.78, 0.12, 1)
const COLOR_STAR_EMPTY := Color(0.50, 0.38, 0.24, 0.55)
const DRAG_THRESHOLD := 14.0

@export_dir var IMAGES_DIR: String = "res://data/images/"
@export var FILE_EXTS: PackedStringArray = [".png", ".jpg", ".jpeg", ".webp"]
@export_file("*.json") var JSON_PATH: String = "res://data/frases.json"
@export var LOAD_BATCH_SIZE: int = 12
@export var PLACEHOLDER_TEX: Texture2D

@onready var _grid: GridContainer = $ContentFrame/Scroll/GridWrapper/Grid
@onready var _scroll: ScrollContainer = $ContentFrame/Scroll
@onready var _empty_state: Label = $ContentFrame/EmptyState
@onready var _title_label: Label = $Header/Title
@onready var _subtitle_label: Label = $Header/SubtitleRow/Subtitle
@onready var _progress_label: Label = $Header/ProgressCard/ProgressLabel
@onready var _progress_bar: ProgressBar = $Header/ProgressCard/ProgressBar
@onready var _random_text: Label = $ButtonRandom/Row/Text
@onready var _random_button: Button = $ButtonRandom

var _pending_textures: Array[Button] = []
var _image_path_cache: Dictionary = {}
var _visible_items: Array[Dictionary] = []
var _completed_ids: Dictionary = {}
var _drag_held := false
var _drag_active := false
var _drag_origin := Vector2.ZERO
var _drag_scroll_origin := 0

var _scene_to_category: PackedScene

const LOCALIZED_COPY := {
	"es": {
		"title": "Colección",
		"quick": "Rápido",
		"cryptogram": "Criptograma",
		"progress": "%d de %d descubiertos",
		"random": "Elegir al azar",
		"empty": "No hay niveles disponibles",
		"level": "Nivel"
	},
	"en": {
		"title": "Collection",
		"quick": "Quick",
		"cryptogram": "Cryptogram",
		"progress": "%d of %d discovered",
		"random": "Choose at random",
		"empty": "No levels available",
		"level": "Level"
	},
	"eu": {
		"title": "Bilduma",
		"quick": "Azkarra",
		"cryptogram": "Kriptograma",
		"progress": "%d / %d aurkituta",
		"random": "Ausaz aukeratu",
		"empty": "Ez dago mailarik",
		"level": "Maila"
	},
	"fr": {
		"title": "Collection",
		"quick": "Rapide",
		"cryptogram": "Cryptogramme",
		"progress": "%d sur %d découverts",
		"random": "Choisir au hasard",
		"empty": "Aucun niveau disponible",
		"level": "Niveau"
	},
	"de": {
		"title": "Sammlung",
		"quick": "Schnell",
		"cryptogram": "Kryptogramm",
		"progress": "%d von %d entdeckt",
		"random": "Zufällig wählen",
		"empty": "Keine Level verfügbar",
		"level": "Level"
	},
	"it": {
		"title": "Collezione",
		"quick": "Rapida",
		"cryptogram": "Crittogramma",
		"progress": "%d di %d scoperti",
		"random": "Scegli a caso",
		"empty": "Nessun livello disponibile",
		"level": "Livello"
	},
	"pt": {
		"title": "Coleção",
		"quick": "Rápido",
		"cryptogram": "Criptograma",
		"progress": "%d de %d descobertos",
		"random": "Escolher ao acaso",
		"empty": "Nenhum nível disponível",
		"level": "Nível"
	}
}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_random_button.disabled = true
	_load_completed_ids()
	_update_localized_copy()
	await get_tree().process_frame

	_scroll.scroll_deadzone = 16
	if not _populate_from_gamemanager() and JSON_PATH != "":
		_load_and_populate_from_path(JSON_PATH)
	set_process(true)


func _input(event: InputEvent) -> void:
	if not is_instance_valid(_scroll) or not _scroll.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_drag_press(event.pressed, event.position)
	elif event is InputEventMouseMotion and _drag_held:
		_handle_drag_motion(event.position)
	elif event is InputEventScreenTouch:
		_handle_drag_press(event.pressed, event.position)
	elif event is InputEventScreenDrag and _drag_held:
		_handle_drag_motion(event.position)


func _handle_drag_press(pressed: bool, position: Vector2) -> void:
	if pressed:
		if not _scroll.get_global_rect().has_point(position):
			return
		_drag_held = true
		_drag_active = false
		_drag_origin = position
		_drag_scroll_origin = _scroll.scroll_vertical
		return
	if _drag_active:
		get_viewport().set_input_as_handled()
	call_deferred("_end_drag")


func _handle_drag_motion(position: Vector2) -> void:
	var delta := position.y - _drag_origin.y
	if not _drag_active and absf(delta) >= DRAG_THRESHOLD:
		_drag_active = true
	if not _drag_active:
		return
	_scroll.scroll_vertical = _drag_scroll_origin - int(delta)
	get_viewport().set_input_as_handled()


func _end_drag() -> void:
	_drag_held = false
	_drag_active = false


func _process(_delta: float) -> void:
	var amount: int = min(LOAD_BATCH_SIZE, _pending_textures.size())
	for _i in range(amount):
		var button: Button = _pending_textures.pop_front()
		_assign_real_texture(button)
	if _pending_textures.is_empty():
		set_process(false)


func refresh_from_gamemanager() -> void:
	_pending_textures.clear()
	_image_path_cache.clear()
	_load_completed_ids()
	_populate_from_gamemanager()


func populate_from_json_text(json_text: String) -> void:
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null:
		push_error("JSON inválido.")
		return
	_populate_from_parsed(parsed)


func populate_from_array(data: Array) -> void:
	_populate_from_parsed(data)


func _populate_from_gamemanager() -> bool:
	if typeof(GameManager) == TYPE_NIL:
		return false
	var data: Array = GameManager.frases_db
	if data.is_empty():
		return false
	_populate_from_parsed(data)
	return true


func _populate_from_parsed(parsed: Variant) -> void:
	_pending_textures.clear()
	_visible_items.clear()
	_clear_grid_children()

	var items: Array = []
	if typeof(parsed) == TYPE_ARRAY:
		items = parsed
	elif typeof(parsed) == TYPE_DICTIONARY:
		items = [parsed]
	else:
		push_error("El JSON debe ser Array o Dictionary.")
		return

	var filtered_items: Array[Dictionary] = []
	for value in items:
		if value is Dictionary:
			var item: Dictionary = value
			if _passes_filters(item):
				filtered_items.append(item)

	_visible_items = filtered_items

	_visible_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var image_a: int = int(a.get("image_number", 0))
		var image_b: int = int(b.get("image_number", 0))
		if image_a == image_b:
			return int(a.get("difficulty", 1)) < int(b.get("difficulty", 1))
		return image_a < image_b
	)

	for item in _visible_items:
		_grid.add_child(_create_level_card(item))

	_empty_state.visible = _visible_items.is_empty()
	_scroll.visible = not _visible_items.is_empty()
	_random_button.disabled = _visible_items.is_empty()
	_update_header_progress()
	set_process(not _pending_textures.is_empty())


func _passes_filters(item: Dictionary) -> bool:
	var image_number: int = int(item.get("image_number", -1))
	var index_number: int = int(item.get("index", -1))
	if image_number < 0 or index_number < 0:
		return false
	if not GameManager.level_has_image(item):
		return false

	var target_category: String = str(GameManager.categoria_actual).strip_edges()
	if target_category != "":
		var item_category: String = str(item.get("category", ""))
		if not GameManager.categories_match(item_category, target_category):
			return false

	return GameManager.level_game_mode(item) == GameManager.game_mode_actual


func _create_level_card(item: Dictionary) -> Button:
	var index_number: int = int(item.get("index", -1))
	var image_number: int = int(item.get("image_number", -1))
	var difficulty: int = int(item.get("difficulty", 1))
	var completed: bool = _completed_ids.has(index_number)
	var saved_summary: Dictionary = PuzzleSaveManager.get_puzzle_summary(index_number)
	var puzzle_status := (
		"completed"
		if completed
		else str(saved_summary.get("status", "new"))
	)
	var stars_max := _difficulty_to_stars(difficulty)
	var stars_remaining := clampi(
		int(saved_summary.get("stars_remaining", stars_max)),
		0,
		stars_max
	)
	var letters_total := int(saved_summary.get("letters_total", 0))
	if letters_total <= 0:
		letters_total = _count_puzzle_letters(str(item.get("text", "")))
	var letters_filled := (
		letters_total
		if completed
		else int(saved_summary.get("letters_filled", 0))
	)

	var button := Button.new()
	button.name = "Level_%d" % index_number
	button.custom_minimum_size = Vector2(330, 490)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""
	button.auto_translate = false
	button.add_theme_stylebox_override("normal", _make_card_style(false, completed))
	button.add_theme_stylebox_override("hover", _make_card_style(true, completed))
	button.add_theme_stylebox_override("pressed", _make_card_pressed_style())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.tooltip_text = str(item.get("hint_1", ""))
	button.set_meta("item", item)
	button.set_meta("image_path", _find_image_path(image_number, index_number))
	button.pressed.connect(func() -> void: _on_level_pressed(item))

	var image_frame := Panel.new()
	image_frame.name = "ImageFrame"
	image_frame.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	image_frame.offset_left = 12.0
	image_frame.offset_top = 12.0
	image_frame.offset_right = -12.0
	image_frame.offset_bottom = 286.0
	image_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_frame.clip_contents = true
	image_frame.add_theme_stylebox_override("panel", _make_image_frame_style())
	button.add_child(image_frame)

	var texture := TextureRect.new()
	texture.name = "Image"
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.offset_left = 5.0
	texture.offset_top = 5.0
	texture.offset_right = -5.0
	texture.offset_bottom = -5.0
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if PLACEHOLDER_TEX != null:
		texture.texture = PLACEHOLDER_TEX
	image_frame.add_child(texture)

	var id_badge := Panel.new()
	id_badge.name = "IdBadge"
	id_badge.position = Vector2(188, 228)
	id_badge.size = Vector2(118, 44)
	id_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	id_badge.add_theme_stylebox_override("panel", _make_overlay_style(Color(0.08, 0.32, 0.34, 0.8), 20))
	button.add_child(id_badge)

	var id_label := Label.new()
	id_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	id_label.add_theme_font_override("font", _title_label.get_theme_font("font"))
	id_label.add_theme_font_size_override("font_size", 20)
	id_label.add_theme_color_override("font_color", Color.WHITE)
	id_label.text = "ID %d" % index_number
	id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	id_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	id_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	id_badge.add_child(id_label)

	var status := Panel.new()
	status.name = "Status"
	status.position = Vector2(22, 300)
	status.size = Vector2(286, 48)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var status_color := Color(0.92, 0.43, 0.035, 1)
	if puzzle_status == "completed":
		status_color = Color(0.08, 0.63, 0.64, 1)
	elif puzzle_status == "in_progress":
		status_color = Color(0.25, 0.58, 0.78, 1)
	status.add_theme_stylebox_override("panel", _make_overlay_style(status_color, 23))
	button.add_child(status)

	var status_label := Label.new()
	status_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status_label.add_theme_font_override("font", _title_label.get_theme_font("font"))
	status_label.add_theme_font_size_override("font_size", 22)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.text = {
		"completed": "✓  COMPLETADO",
		"in_progress": "▶  CONTINUAR",
	}.get(puzzle_status, "NUEVO")
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_child(status_label)

	var status_star_size := 54 if puzzle_status == "completed" else 27
	var status_star_color := (
		COLOR_STAR_YELLOW
		if puzzle_status == "completed"
		else Color(0.12, 0.09, 0.06, 1)
	)
	var status_stars := _star_icons(
		stars_remaining if puzzle_status != "new" else stars_max,
		stars_max,
		status_star_size,
		status_star_color
	)
	status_stars.position = Vector2(18, 348)
	status_stars.size = Vector2(294, 64 if puzzle_status == "completed" else 42)
	button.add_child(status_stars)

	var letters_progress := Label.new()
	letters_progress.position = Vector2(18, 418)
	letters_progress.size = Vector2(294, 42)
	letters_progress.add_theme_font_override("font", _title_label.get_theme_font("font"))
	letters_progress.add_theme_font_size_override("font_size", 23)
	letters_progress.add_theme_color_override("font_color", Color(0.25, 0.16, 0.11, 0.82))
	letters_progress.text = "%d / %d letras" % [letters_filled, letters_total]
	letters_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letters_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letters_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(letters_progress)

	_pending_textures.append(button)
	return button


func _assign_real_texture(button: Button) -> void:
	if not is_instance_valid(button):
		return
	var texture_rect := button.get_node_or_null("ImageFrame/Image") as TextureRect
	if texture_rect == null:
		return
	var path: String = str(button.get_meta("image_path", ""))
	if path == "":
		return
	var texture := load(path) as Texture2D
	if texture != null:
		texture_rect.texture = texture


func _on_level_pressed(item: Dictionary) -> void:
	if _drag_active:
		return
	var index_number: int = int(item.get("index", -1))
	if index_number < 0:
		return
	if not get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
		return
	SoundManager.play("ButtonClick")
	GameManager.id_frase = index_number
	GameManager.set_dificultad_actual(int(item.get("difficulty", 1)))
	GameManager.seleccionar_por_index(index_number)
	PuzzleSaveManager.prepare_current_puzzle_cipher()
	GameManager.set_go_to_game_disable()
	var preview := THEME_PREVIEW.instantiate()
	preview.set("launch_game_on_start", true)
	preview.set("image_path", _find_image_path(
		int(item.get("image_number", -1)),
		index_number
	))
	add_child(preview)


func _on_button_random_pressed() -> void:
	if _visible_items.is_empty():
		return
	var chosen: Dictionary = _visible_items.pick_random()
	_on_level_pressed(chosen)


func _on_button_back_pressed() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	if _scene_to_category == null:
		_scene_to_category = load(PATH_CATEGORY)
	get_tree().change_scene_to_packed(_scene_to_category)


func _load_completed_ids() -> void:
	_completed_ids.clear()
	if typeof(HistoryManager) == TYPE_NIL:
		return
	for value in HistoryManager.get_history():
		if value is Dictionary:
			var entry: Dictionary = value
			if bool(entry.get("partida_ganada", false)):
				_completed_ids[int(entry.get("id", -1))] = true


func _update_header_progress() -> void:
	var total: int = _visible_items.size()
	var completed: int = 0
	for item in _visible_items:
		if _completed_ids.has(int(item.get("index", -1))):
			completed += 1
	_progress_bar.max_value = max(total, 1)
	_progress_bar.value = completed
	_progress_label.text = _copy("progress") % [completed, total]


func _update_localized_copy() -> void:
	var category_name: String = GameManager.category_display_name()
	var mode_key := "cryptogram" if GameManager.game_mode_actual == MODE_CRYPTOGRAM else "quick"
	_title_label.text = _copy("title")
	_subtitle_label.text = "%s · %s" % [category_name, _copy(mode_key)]
	_random_text.text = _copy("random")
	_empty_state.text = _copy("empty")


func _copy(key: String) -> String:
	var locale: String = TranslationServer.get_locale().left(2).to_lower()
	var translations: Dictionary = LOCALIZED_COPY.get(locale, LOCALIZED_COPY["es"])
	return str(translations.get(key, LOCALIZED_COPY["es"].get(key, key)))


func _difficulty_to_stars(difficulty: int) -> int:
	return clampi(difficulty, 1, 4)


func _star_icons(filled: int, total: int, size: int, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	for index in range(total):
		var icon := TextureRect.new()
		var is_filled := index < filled
		icon.custom_minimum_size = Vector2(size, size)
		icon.texture = STAR_TEXTURE if is_filled else STAR_OFF_TEXTURE
		icon.self_modulate = color if is_filled else COLOR_STAR_EMPTY
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	return row


func _count_puzzle_letters(text: String) -> int:
	var count := 0
	for character in GameManager.normalizar_frase_idioma(
		text,
		GameManager.locale_code()
	):
		if not GameManager.EXCLUIR.has(character):
			count += 1
	return count


func _find_image_path(image_number: int, index_number: int) -> String:
	var cache_key := "%d:%d" % [image_number, index_number]
	if _image_path_cache.has(cache_key):
		return str(_image_path_cache[cache_key])
	var directory := IMAGES_DIR.trim_suffix("/")
	var candidate_numbers: Array[int] = [image_number]
	if index_number != image_number:
		candidate_numbers.append(index_number)
	for candidate_number in candidate_numbers:
		var basename := "image%d" % candidate_number
		if candidate_number == 1:
			var uppercase_png := "%s/%s.PNG" % [directory, basename]
			if ResourceLoader.exists(uppercase_png):
				_image_path_cache[cache_key] = uppercase_png
				return uppercase_png
		for extension in FILE_EXTS:
			var candidate := "%s/%s%s" % [directory, basename, extension]
			if ResourceLoader.exists(candidate):
				_image_path_cache[cache_key] = candidate
				return candidate
	_image_path_cache[cache_key] = ""
	return ""


func _load_and_populate_from_path(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("No existe el JSON: %s" % path)
		return
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		push_error("JSON vacío o no legible: %s" % path)
		return
	populate_from_json_text(text)


func _clear_grid_children() -> void:
	for child in _grid.get_children():
		child.queue_free()


func _make_card_style(hovered: bool, completed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.942, 0.786, 1) if not hovered else Color(1, 0.969, 0.865, 1)
	style.border_color = Color(0.75, 0.55, 0.28, 0.48) if not completed else Color(0.08, 0.63, 0.64, 0.72)
	style.set_border_width_all(4 if not completed else 5)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.38, 0.23, 0.08, 0.2 if not hovered else 0.27)
	style.shadow_size = 11 if not hovered else 15
	style.shadow_offset = Vector2(0, 9 if not hovered else 12)
	return style


func _make_card_pressed_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.85, 0.66, 1)
	style.border_color = Color(0.75, 0.46, 0.15, 0.72)
	style.set_border_width_all(5)
	style.set_corner_radius_all(28)
	return style


func _make_image_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.91, 0.81, 0.61, 1)
	style.border_color = Color(0.71, 0.49, 0.24, 0.62)
	style.set_border_width_all(4)
	style.set_corner_radius_all(22)
	return style


func _make_overlay_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style
