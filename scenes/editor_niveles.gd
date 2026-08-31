extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const JSON_DIR := "res://data"
const IMAGE_DIR := "res://data/images"
const EDITOR_DESIGN_SIZE := Vector2i(2412, 1400)
const STAR_ON := preload("res://images/estrella_plano.png")
const STAR_OFF := preload("res://images/contorno_estrella.png")

const LANGUAGE_FILES := {
	"es": "frases_es.json",
	"en": "frases_en.json",
	"eu": "frases_eu.json",
	"fr": "frases_fr.json",
	"de": "frases_de.json",
	"it": "frases_it.json",
	"pt": "frases_pt.json",
}

const LANGUAGES := [
	["Español", "es"],
	["English", "en"],
	["Euskara", "eu"],
	["Français", "fr"],
	["Deutsch", "de"],
	["Italiano", "it"],
	["Português", "pt"],
]

const CATEGORY_VALUES := [
	["Efeméride", "Efeméride"],
	["Cita célebre", "Cita célebre"],
	["Curiosidades", "Curiosidades"],
	["Fragmento literario", "Fragmento literario"],
]

const MODE_VALUES := [
	["RÁPIDO", GameManager.MODE_QUICK],
	["CRIPTOGRAMA", GameManager.MODE_CRYPTOGRAM],
]

const FILTER_ALL := "all"

@onready var language_selector: OptionButton = %LanguageSelector
@onready var position_label: Label = %PositionLabel
@onready var previous_button: Button = %PreviousButton
@onready var next_button: Button = %NextButton
@onready var save_button: Button = %SaveButton
@onready var filter_mode: OptionButton = %FilterMode
@onready var filter_category: OptionButton = %FilterCategory
@onready var filter_count: Label = %FilterCount
@onready var image_dialog: FileDialog = %ImageDialog
@onready var delete_dialog: ConfirmationDialog = %DeleteDialog
@onready var jump_id: SpinBox = %JumpId
@onready var status_label: Label = %StatusLabel
@onready var validation_label: Label = %ValidationLabel

@onready var image_preview: TextureRect = %ImagePreview
@onready var image_path_label: Label = %ImagePathLabel
@onready var stars_row: HBoxContainer = %StarsRow
@onready var mode_field: OptionButton = %ModeField
@onready var length_label: Label = %LengthValue

@onready var id_field: SpinBox = %IdField
@onready var image_field: SpinBox = %ImageField
@onready var difficulty_field: SpinBox = %DifficultyField
@onready var category_field: OptionButton = %CategoryField

@onready var phrase_field: TextEdit = %PhraseField
@onready var initial_letters_field: TextEdit = %InitialLettersField
@onready var description_init_field: TextEdit = %DescriptionInitField
@onready var completion_field: TextEdit = %CompletionField
@onready var hint_1_field: TextEdit = %Hint1Field
@onready var hint_2_field: TextEdit = %Hint2Field
@onready var hint_3_field: TextEdit = %Hint3Field
@onready var hint_4_field: TextEdit = %Hint4Field

var _levels: Array[Dictionary] = []
var _current_index := -1
var _current_language := "es"
var _current_path := ""
var _loading_fields := false
var _dirty := false
var _star_nodes: Array[TextureRect] = []
var _previous_content_scale_size := Vector2i.ZERO
var _previous_window_size := Vector2i.ZERO
var _pending_preview_texture: Texture2D
var _image_picker: Window
var _image_picker_grid: GridContainer
var _image_picker_status: Label


func _ready() -> void:
	_configure_editor_window()
	_build_image_picker()
	_populate_selectors()
	_connect_field_changes()
	for child in stars_row.get_children():
		if child is TextureRect:
			_star_nodes.append(child as TextureRect)
	var requested_language := GameManager.locale_code()
	if not LANGUAGE_FILES.has(requested_language):
		requested_language = "es"
	_select_option_by_metadata(language_selector, requested_language)
	_load_language(requested_language)


func _exit_tree() -> void:
	if not is_instance_valid(get_window()):
		return
	if _previous_content_scale_size != Vector2i.ZERO:
		get_window().content_scale_size = _previous_content_scale_size
	if _previous_window_size != Vector2i.ZERO:
		get_window().size = _previous_window_size


func _configure_editor_window() -> void:
	var window := get_window()
	_previous_content_scale_size = window.content_scale_size
	_previous_window_size = window.size
	window.content_scale_size = EDITOR_DESIGN_SIZE
	if DisplayServer.get_name() == "headless":
		return
	window.size = Vector2i(1500, 870)
	var screen_size := DisplayServer.screen_get_size()
	window.position = Vector2i(
		maxi(0, int((screen_size.x - window.size.x) / 2)),
		maxi(0, int((screen_size.y - window.size.y) / 2))
	)


func _populate_selectors() -> void:
	language_selector.clear()
	for entry in LANGUAGES:
		language_selector.add_item(str(entry[0]))
		language_selector.set_item_metadata(language_selector.item_count - 1, entry[1])
	category_field.clear()
	for entry in CATEGORY_VALUES:
		category_field.add_item(str(entry[0]))
		category_field.set_item_metadata(category_field.item_count - 1, entry[1])
	mode_field.clear()
	for entry in MODE_VALUES:
		mode_field.add_item(str(entry[0]))
		mode_field.set_item_metadata(mode_field.item_count - 1, entry[1])
	filter_mode.clear()
	filter_mode.add_item("Todos")
	filter_mode.set_item_metadata(0, FILTER_ALL)
	for entry in MODE_VALUES:
		filter_mode.add_item(str(entry[0]))
		filter_mode.set_item_metadata(filter_mode.item_count - 1, entry[1])
	filter_category.clear()
	filter_category.add_item("Todas")
	filter_category.set_item_metadata(0, FILTER_ALL)
	for entry in CATEGORY_VALUES:
		filter_category.add_item(str(entry[0]))
		filter_category.set_item_metadata(filter_category.item_count - 1, entry[1])


func _connect_field_changes() -> void:
	for text_field in [
		phrase_field,
		initial_letters_field,
		description_init_field,
		completion_field,
		hint_1_field,
		hint_2_field,
		hint_3_field,
		hint_4_field,
	]:
		(text_field as TextEdit).text_changed.connect(_on_field_changed)
	id_field.value_changed.connect(_on_numeric_field_changed)
	image_field.value_changed.connect(_on_image_number_changed)
	difficulty_field.value_changed.connect(_on_difficulty_changed)
	category_field.item_selected.connect(_on_category_changed)
	mode_field.item_selected.connect(_on_mode_changed)


func _load_language(language_code: String) -> void:
	_current_language = language_code
	_current_path = "%s/%s" % [
		JSON_DIR,
		str(LANGUAGE_FILES.get(language_code, LANGUAGE_FILES["es"])),
	]
	_levels.clear()
	if not FileAccess.file_exists(_current_path):
		_set_status("No existe el archivo %s" % _current_path, true)
		_show_empty_state()
		return
	var source := FileAccess.get_file_as_string(_current_path)
	var parsed: Variant = JSON.parse_string(source)
	var source_array: Array = []
	if parsed is Array:
		source_array = parsed
	elif parsed is Dictionary:
		source_array = (parsed as Dictionary).get("phrases", [])
	else:
		_set_status("El JSON no tiene un formato válido.", true)
		_show_empty_state()
		return
	for value in source_array:
		if value is Dictionary:
			_levels.append((value as Dictionary).duplicate(true))
	_dirty = false
	_apply_filters(false, false)


func _populate_current_level() -> void:
	if _current_index < 0 or _current_index >= _levels.size():
		_show_empty_state()
		return
	_loading_fields = true
	var level := _levels[_current_index]
	id_field.value = int(level.get("index", _current_index + 1))
	jump_id.value = id_field.value
	image_field.value = int(level.get("image_number", -1))
	difficulty_field.value = clampi(int(level.get("difficulty", 1)), 1, 4)
	_select_category(str(level.get("category", "")))
	_select_option_by_metadata(mode_field, GameManager.level_game_mode(level))
	phrase_field.text = str(level.get("text", ""))
	initial_letters_field.text = str(level.get("letters_init", ""))
	description_init_field.text = str(level.get("description_init", ""))
	completion_field.text = str(level.get("description_end", ""))
	hint_1_field.text = str(level.get("hint_1", ""))
	hint_2_field.text = str(level.get("hint_2", ""))
	hint_3_field.text = str(level.get("hint_3", ""))
	hint_4_field.text = str(level.get("hint_4", ""))
	_loading_fields = false
	_update_derived_fields()
	_update_navigation()
	_update_validation()


func _capture_current_level() -> void:
	if _loading_fields or _current_index < 0 or _current_index >= _levels.size():
		return
	var level := _levels[_current_index]
	level["index"] = int(id_field.value)
	level["image_number"] = int(image_field.value)
	level["text"] = phrase_field.text.strip_edges()
	level["letters_init"] = initial_letters_field.text.strip_edges().to_upper()
	level["description_init"] = description_init_field.text.strip_edges()
	level["description_end"] = completion_field.text.strip_edges()
	level["category"] = _selected_metadata(category_field)
	level["language"] = _current_language
	level["difficulty"] = int(difficulty_field.value)
	level["game_mode"] = _selected_metadata(mode_field)
	level["hint_1"] = hint_1_field.text.strip_edges()
	level["hint_2"] = hint_2_field.text.strip_edges()
	level["hint_3"] = hint_3_field.text.strip_edges()
	level["hint_4"] = hint_4_field.text.strip_edges()
	level["Longitud frase"] = _phrase_letter_count(phrase_field.text)
	_levels[_current_index] = level


func _navigate(delta: int) -> void:
	if _levels.is_empty():
		return
	_capture_current_level()
	var indices := _filtered_indices()
	if indices.is_empty():
		_current_index = -1
		_show_empty_state()
		return
	var position_in_filter := indices.find(_current_index)
	if position_in_filter < 0:
		_current_index = indices[0]
	else:
		_current_index = indices[clampi(position_in_filter + delta, 0, indices.size() - 1)]
	_populate_current_level()


func _on_previous_button_pressed() -> void:
	_navigate(-1)


func _on_next_button_pressed() -> void:
	_navigate(1)


func _on_jump_button_pressed() -> void:
	_capture_current_level()
	var requested_id := int(jump_id.value)
	for index in range(_levels.size()):
		if int(_levels[index].get("index", -1)) == requested_id:
			_current_index = index
			if not _level_matches_filters(_levels[index]):
				_set_status(
					"El ID %d está fuera del filtro actual." % requested_id,
					true
				)
			_populate_current_level()
			return
	_set_status("No existe ningún nivel con ID %d." % requested_id, true)


func _on_filter_changed(_index: int = 0) -> void:
	if _loading_fields:
		return
	_apply_filters(true)


func _on_new_button_pressed() -> void:
	_capture_current_level()
	var next_id := _next_available_id()
	var level := {
		"index": next_id,
		"image_number": -1,
		"text": "",
		"letters_init": "",
		"description_init": "",
		"description_end": "",
		"category": "Efeméride",
		"language": _current_language,
		"difficulty": 1,
		"game_mode": GameManager.MODE_QUICK,
		"hint_1": "",
		"hint_2": "",
		"hint_3": "",
		"hint_4": "",
		"Longitud frase": 0,
	}
	if _selected_metadata(filter_category) != FILTER_ALL:
		level["category"] = _selected_metadata(filter_category)
	if _selected_metadata(filter_mode) != FILTER_ALL:
		level["game_mode"] = _selected_metadata(filter_mode)
	_levels.append(level)
	_current_index = _levels.size() - 1
	_dirty = true
	_populate_current_level()
	_set_status("Nivel nuevo creado en memoria. Pulsa GUARDAR.", false)


func _on_duplicate_button_pressed() -> void:
	if _current_index < 0 or _current_index >= _levels.size():
		return
	_capture_current_level()
	var copy := _levels[_current_index].duplicate(true)
	copy["index"] = _next_available_id()
	_levels.append(copy)
	_current_index = _levels.size() - 1
	_dirty = true
	_populate_current_level()
	_set_status("Nivel duplicado. Revisa el ID y pulsa GUARDAR.", false)


func _on_delete_button_pressed() -> void:
	if _current_index < 0 or _current_index >= _levels.size():
		return
	delete_dialog.dialog_text = (
		"¿Eliminar el nivel con ID %d?\n"
		+ "Se quitará ahora mismo de la lista y del archivo."
	) % int(id_field.value)
	delete_dialog.popup_centered()


func _on_delete_dialog_confirmed() -> void:
	if _current_index < 0 or _current_index >= _levels.size():
		return
	var removed_id := int(_levels[_current_index].get("index", -1))
	var removed_level := _levels[_current_index].duplicate(true)
	var removed_index := _current_index
	_loading_fields = true
	_levels.remove_at(_current_index)
	if not _write_levels_to_disk():
		_levels.insert(removed_index, removed_level)
		_current_index = removed_index
		_loading_fields = false
		_populate_current_level()
		_set_status(
			"No se pudo eliminar el nivel %d del archivo." % removed_id,
			true
		)
		return
	_dirty = false
	if _levels.is_empty():
		_current_index = -1
		_loading_fields = false
		_show_empty_state()
	else:
		_current_index = mini(_current_index, _levels.size() - 1)
		_loading_fields = false
		_apply_filters(true, false)
	_update_navigation()
	_set_status("Nivel %d eliminado de %s" % [removed_id, _current_path], false)


func _on_assign_image_button_pressed() -> void:
	_refresh_image_picker()
	_image_picker.popup_centered()


func _on_import_external_image_pressed() -> void:
	image_dialog.access = FileDialog.ACCESS_FILESYSTEM
	image_dialog.use_native_dialog = true
	image_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	image_dialog.current_dir = ProjectSettings.globalize_path(IMAGE_DIR)
	image_dialog.popup_centered_ratio(0.78)


func _on_image_dialog_file_selected(selected_path: String) -> void:
	var normalized_path := selected_path.replace("\\", "/")
	var image_number := -1
	_pending_preview_texture = null
	if _is_project_image_path(normalized_path):
		image_number = _image_number_from_filename(normalized_path.get_file())
		if image_number < 0:
			_set_status(
				"La imagen debe llamarse imageN.ext, por ejemplo image42.png.",
				true
			)
			return
	else:
		image_number = _next_image_number()
		var extension := normalized_path.get_extension().to_lower()
		if extension not in ["png", "jpg", "jpeg", "webp"]:
			_set_status("Formato de imagen no compatible.", true)
			return
		var destination := "%s/image%d.%s" % [IMAGE_DIR, image_number, extension]
		var copy_error := DirAccess.copy_absolute(
			selected_path,
			ProjectSettings.globalize_path(destination)
		)
		if copy_error != OK:
			_set_status("No se pudo copiar la imagen al proyecto.", true)
			return
		var source_image := Image.new()
		if source_image.load(selected_path) == OK:
			_pending_preview_texture = ImageTexture.create_from_image(source_image)
	_assign_image_number(image_number)


func _assign_image_number(image_number: int) -> void:
	image_field.value = image_number
	if _pending_preview_texture != null:
		image_preview.texture = _pending_preview_texture
		image_path_label.text = (
			"%s/image%d · pendiente de importación" % [IMAGE_DIR, image_number]
		)
	else:
		_update_image()
	_dirty = true
	_update_navigation()
	_update_validation()
	_set_status(
		"Imagen asignada como image%d. Pulsa GUARDAR CAMBIOS." % image_number,
		false
	)
	if is_instance_valid(_image_picker):
		_image_picker.hide()


func _is_project_image_path(path: String) -> bool:
	var normalized := path.replace("\\", "/")
	var abs_dir := ProjectSettings.globalize_path(IMAGE_DIR).replace("\\", "/")
	return (
		normalized.begins_with(IMAGE_DIR + "/")
		or normalized.begins_with(abs_dir + "/")
	)


func _build_image_picker() -> void:
	_image_picker = Window.new()
	_image_picker.title = "Imágenes de puzles"
	_image_picker.size = Vector2i(1080, 740)
	_image_picker.unresizable = false
	_image_picker.transient = true
	_image_picker.exclusive = true
	_image_picker.visible = false
	_image_picker.close_requested.connect(_image_picker.hide)
	add_child(_image_picker)

	var background := Panel.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_theme_stylebox_override(
		"panel",
		_picker_style(Color(0.99, 0.96, 0.88, 1), 0)
	)
	_image_picker.add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_top = 20
	root.offset_right = -24
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 16)
	_image_picker.add_child(root)

	var header := Label.new()
	header.text = "Elige una imagen de res://data/images"
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(0.27, 0.15, 0.08, 1))
	root.add_child(header)

	_image_picker_status = Label.new()
	_image_picker_status.add_theme_font_size_override("font_size", 20)
	_image_picker_status.add_theme_color_override("font_color", Color(0.43, 0.31, 0.21, 0.82))
	root.add_child(_image_picker_status)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_image_picker_grid = GridContainer.new()
	_image_picker_grid.columns = 4
	_image_picker_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_image_picker_grid.add_theme_constant_override("h_separation", 16)
	_image_picker_grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(_image_picker_grid)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	root.add_child(actions)

	var import_button := Button.new()
	import_button.text = "IMPORTAR DESDE OTRA CARPETA…"
	import_button.custom_minimum_size = Vector2(360, 58)
	import_button.pressed.connect(_on_import_external_image_pressed)
	actions.add_child(import_button)

	var close_button := Button.new()
	close_button.text = "CERRAR"
	close_button.custom_minimum_size = Vector2(160, 58)
	close_button.pressed.connect(_image_picker.hide)
	actions.add_child(close_button)


func _refresh_image_picker() -> void:
	for child in _image_picker_grid.get_children():
		child.queue_free()
	var images := _list_project_images()
	if images.is_empty():
		_image_picker_status.text = "No hay imágenes en %s" % IMAGE_DIR
		return
	_image_picker_status.text = "%d imágenes en %s  ·  clic para asignar" % [
		images.size(),
		IMAGE_DIR,
	]
	var current_number := int(image_field.value)
	for image_data in images:
		var image_number: int = int(image_data["number"])
		var path: String = str(image_data["path"])
		var card := Button.new()
		card.custom_minimum_size = Vector2(230, 250)
		card.toggle_mode = true
		card.button_pressed = image_number == current_number
		card.focus_mode = Control.FOCUS_NONE
		card.tooltip_text = path
		card.add_theme_stylebox_override(
			"normal",
			_picker_style(Color(1, 0.98, 0.93, 1), 18)
		)
		card.add_theme_stylebox_override(
			"hover",
			_picker_style(Color(1, 0.95, 0.84, 1), 18)
		)
		card.add_theme_stylebox_override(
			"pressed",
			_picker_style(Color(0.93, 0.86, 0.68, 1), 18)
		)
		card.pressed.connect(_on_picker_image_pressed.bind(image_number))
		_image_picker_grid.add_child(card)

		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.offset_left = 10
		box.offset_top = 10
		box.offset_right = -10
		box.offset_bottom = -10
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation", 8)
		card.add_child(box)

		var preview := TextureRect.new()
		preview.custom_minimum_size = Vector2(0, 170)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var texture := load(path)
		if texture is Texture2D:
			preview.texture = texture
		box.add_child(preview)

		var caption := Label.new()
		caption.text = "image%d" % image_number
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 20)
		caption.add_theme_color_override("font_color", Color(0.27, 0.15, 0.08, 1))
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(caption)


func _on_picker_image_pressed(image_number: int) -> void:
	_pending_preview_texture = null
	_assign_image_number(image_number)


func _list_project_images() -> Array[Dictionary]:
	var images: Array[Dictionary] = []
	var directory := DirAccess.open(IMAGE_DIR)
	if directory == null:
		return images
	directory.list_dir_begin()
	var filename := directory.get_next()
	while filename != "":
		if not directory.current_is_dir():
			var extension := filename.get_extension().to_lower()
			if extension in ["png", "jpg", "jpeg", "webp"]:
				var image_number := _image_number_from_filename(filename)
				if image_number >= 0:
					images.append({
						"number": image_number,
						"path": "%s/%s" % [IMAGE_DIR, filename],
					})
		filename = directory.get_next()
	directory.list_dir_end()
	images.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["number"]) < int(b["number"])
	)
	return images


func _picker_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color = Color(0.78, 0.62, 0.40, 0.55)
	return style


func _on_save_button_pressed() -> void:
	_capture_current_level()
	var errors := _validation_errors()
	if not errors.is_empty():
		_set_status("No se puede guardar: %s" % " · ".join(errors), true)
		return
	if not _write_levels_to_disk():
		return
	_dirty = false
	_update_navigation()
	_set_status("Cambios guardados en %s" % _current_path, false)


func _write_levels_to_disk() -> bool:
	var file := FileAccess.open(_current_path, FileAccess.WRITE)
	if file == null:
		_set_status(
			"No se pudo abrir %s para escritura. Ejecuta esta escena desde el editor."
			% _current_path,
			true
		)
		return false
	file.store_string(JSON.stringify(_levels, "\t", false))
	file.close()
	if _current_language == GameManager.locale_code():
		GameManager.cargar_frases_desde_json()
	return true


func _on_language_selector_item_selected(index: int) -> void:
	if _loading_fields:
		return
	if _dirty:
		_loading_fields = true
		_select_option_by_metadata(language_selector, _current_language)
		_loading_fields = false
		_set_status(
			"Guarda o descarta los cambios antes de cambiar de idioma.",
			true
		)
		return
	var language_code: String = str(language_selector.get_item_metadata(index))
	_load_language(language_code)


func _on_field_changed() -> void:
	if _loading_fields:
		return
	_dirty = true
	_update_derived_fields()
	_update_navigation()
	_update_validation()


func _on_numeric_field_changed(_value: float) -> void:
	_on_field_changed()


func _on_image_number_changed(_value: float) -> void:
	_on_field_changed()
	_update_image()


func _on_difficulty_changed(_value: float) -> void:
	_on_field_changed()
	_update_difficulty()


func _on_category_changed(_index: int) -> void:
	_on_field_changed()


func _on_mode_changed(_index: int) -> void:
	_on_field_changed()
	_update_mode_style()


func _update_derived_fields() -> void:
	_update_difficulty()
	_update_mode_style()
	_update_image()
	length_label.text = str(_phrase_letter_count(phrase_field.text))
	_update_filter_labels()


func _update_mode_style() -> void:
	var mode := _selected_metadata(mode_field)
	var is_crypto := mode == GameManager.MODE_CRYPTOGRAM
	var color := Color(0.46, 0.31, 0.68, 1) if is_crypto else Color(0.08, 0.55, 0.5, 1)
	mode_field.add_theme_color_override("font_color", color)
	mode_field.add_theme_color_override("font_hover_color", color)
	mode_field.add_theme_color_override("font_pressed_color", color)
	mode_field.add_theme_color_override("font_focus_color", color)


func _update_difficulty() -> void:
	var difficulty := clampi(int(difficulty_field.value), 1, 4)
	var maximum_stars := GameManager.get_puzzle_difficulty_stars(difficulty)
	var mode := _selected_metadata(mode_field)
	for index in range(_star_nodes.size()):
		var star := _star_nodes[index]
		star.texture = STAR_ON if index < maximum_stars else STAR_OFF
		star.modulate = (
			GameManager.star_fill_color(mode)
			if index < maximum_stars
			else Color(0.45, 0.35, 0.26, 0.42)
		)


func _update_image() -> void:
	var image_number := int(image_field.value)
	var path := _find_image_path(image_number)
	if path == "":
		image_preview.texture = null
		image_path_label.text = "Sin imagen para image%d" % image_number
		image_path_label.add_theme_color_override(
			"font_color",
			Color(0.74, 0.2, 0.16, 1)
		)
		return
	var resource := load(path)
	image_preview.texture = resource as Texture2D
	image_path_label.text = path
	image_path_label.add_theme_color_override(
		"font_color",
		Color(0.16, 0.47, 0.36, 1)
	)


func _find_image_path(image_number: int) -> String:
	if image_number < 0:
		return ""
	var basename := "%s/image%d" % [IMAGE_DIR, image_number]
	var extensions := (
		[".PNG", ".png", ".jpg", ".jpeg", ".webp"]
		if image_number == 1
		else [".png", ".PNG", ".jpg", ".jpeg", ".webp"]
	)
	for extension in extensions:
		var path: String = basename + str(extension)
		if ResourceLoader.exists(path):
			return path
	return ""


func _image_number_from_filename(filename: String) -> int:
	var expression := RegEx.new()
	if expression.compile("^image(\\d+)\\.") != OK:
		return -1
	var result := expression.search(filename.to_lower())
	if result == null:
		return -1
	return int(result.get_string(1))


func _next_image_number() -> int:
	var highest := 0
	var directory := DirAccess.open(IMAGE_DIR)
	if directory == null:
		return 1
	directory.list_dir_begin()
	var filename := directory.get_next()
	while filename != "":
		if not directory.current_is_dir():
			highest = maxi(highest, _image_number_from_filename(filename))
		filename = directory.get_next()
	directory.list_dir_end()
	return highest + 1


func _update_navigation() -> void:
	var indices := _filtered_indices()
	var position_in_filter := indices.find(_current_index)
	previous_button.disabled = position_in_filter <= 0
	next_button.disabled = (
		position_in_filter < 0
		or position_in_filter >= indices.size() - 1
	)
	save_button.text = "GUARDAR CAMBIOS *" if _dirty else "GUARDAR CAMBIOS"


func _apply_filters(keep_current_if_possible: bool, capture := true) -> void:
	if capture:
		_capture_current_level()
	var indices := _filtered_indices()
	if indices.is_empty():
		_current_index = -1
		_show_empty_state()
		_set_status("Ningún nivel coincide con el filtro.", true)
		return
	if keep_current_if_possible and indices.has(_current_index):
		_populate_current_level()
	else:
		_current_index = indices[0]
		_populate_current_level()
	_set_status(
		"%d de %d niveles con el filtro actual" % [indices.size(), _levels.size()],
		false
	)


func _filtered_indices() -> Array[int]:
	var indices: Array[int] = []
	for index in range(_levels.size()):
		if _level_matches_filters(_levels[index]):
			indices.append(index)
	return indices


func _level_matches_filters(level: Dictionary) -> bool:
	var mode_filter := _selected_metadata(filter_mode)
	if mode_filter != FILTER_ALL and GameManager.level_game_mode(level) != mode_filter:
		return false
	var category_filter := _selected_metadata(filter_category)
	if (
		category_filter != FILTER_ALL
		and not GameManager.categories_match(
			str(level.get("category", "")),
			category_filter
		)
	):
		return false
	return true


func _update_filter_labels() -> void:
	var indices := _filtered_indices()
	var position_in_filter := indices.find(_current_index)
	if position_in_filter < 0:
		position_label.text = "0 / %d" % indices.size()
	else:
		position_label.text = "%d / %d" % [position_in_filter + 1, indices.size()]
	if _selected_metadata(filter_mode) == FILTER_ALL \
			and _selected_metadata(filter_category) == FILTER_ALL:
		filter_count.text = "%d niveles" % _levels.size()
	else:
		filter_count.text = "%d de %d niveles" % [indices.size(), _levels.size()]


func _update_validation() -> void:
	var errors := _validation_errors(false)
	if errors.is_empty():
		validation_label.text = "✓ Nivel válido"
		validation_label.add_theme_color_override(
			"font_color",
			Color(0.12, 0.5, 0.34, 1)
		)
	else:
		validation_label.text = "⚠ " + " · ".join(errors)
		validation_label.add_theme_color_override(
			"font_color",
			Color(0.76, 0.28, 0.12, 1)
		)


func _validation_errors(check_all_levels := true) -> PackedStringArray:
	var errors := PackedStringArray()
	if phrase_field.text.strip_edges() == "":
		errors.append("falta la frase")
	if completion_field.text.strip_edges() == "":
		errors.append("falta el texto de felicitación")
	if int(image_field.value) < 0:
		errors.append("falta image_number")
	elif _find_image_path(int(image_field.value)) == "":
		errors.append("la imagen no existe")
	if check_all_levels:
		var ids := {}
		for level in _levels:
			var level_id := int(level.get("index", -1))
			if ids.has(level_id):
				errors.append("ID %d duplicado" % level_id)
				break
			ids[level_id] = true
	return errors


func _next_available_id() -> int:
	var maximum := 0
	for level in _levels:
		maximum = maxi(maximum, int(level.get("index", 0)))
	return maximum + 1


func _phrase_letter_count(text: String) -> int:
	var count := 0
	var normalized := GameManager.normalizar_frase_idioma(text, _current_language)
	for character in normalized:
		if not GameManager.is_excluded_character(character):
			count += 1
	return count


func _select_category(category: String) -> void:
	var normalized := GameManager.normalize_category(category)
	for index in range(category_field.item_count):
		var candidate := str(category_field.get_item_metadata(index))
		if GameManager.normalize_category(candidate) == normalized:
			category_field.select(index)
			return
	category_field.select(0)


func _select_option_by_metadata(option: OptionButton, value: String) -> void:
	for index in range(option.item_count):
		if str(option.get_item_metadata(index)) == value:
			option.select(index)
			return


func _selected_metadata(option: OptionButton) -> String:
	if option.selected < 0:
		return ""
	return str(option.get_item_metadata(option.selected))


func _show_empty_state() -> void:
	_loading_fields = true
	position_label.text = "0 / 0"
	phrase_field.text = ""
	completion_field.text = ""
	image_preview.texture = null
	_loading_fields = false
	_update_filter_labels()
	_update_navigation()


func _set_status(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.add_theme_color_override(
		"font_color",
		Color(0.76, 0.23, 0.16, 1)
		if is_error
		else Color(0.16, 0.45, 0.34, 1)
	)


func _on_button_back_pressed() -> void:
	if _dirty:
		_set_status(
			"Hay cambios sin guardar. Guarda antes de salir o vuelve a pulsar atrás.",
			true
		)
		_dirty = false
		return
	get_tree().change_scene_to_file(PATH_MAIN)
