extends Control

const PATH_CATEGORY := "res://scenes/MenuSelectCategory.tscn"
const MODE_QUICK := "quick"
const MODE_CRYPTOGRAM := "cryptogram"
const STAR_TEXTURE: Texture2D = preload("res://images/estrella_plano.png")
const STAR_OFF_TEXTURE: Texture2D = preload("res://images/contorno_estrella.png")
const THEME_PREVIEW := preload("res://scenes/game/PuzzleThemePreview.tscn")
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
		"level": "Nivel",
		"lock_title": "Puzle ya completado",
		"lock_body": "Este puzle ya está completado. Para repetir uno terminado hay que esperar 48 horas desde que se completó.\n\nNo se puede elegir cuál: se elige al azar entre los 5 con menos estrellas y peor puntuación (más ayudas, más fallos), siempre que lleven más de 48 h y no tengan puntuación perfecta.\n\nSolo se puede repetir un puzle al día.",
		"lock_body_random": "No hay puzles nuevos ni en curso.\n\nPara repetir uno terminado hay que esperar 48 horas. No se puede elegir cuál: se elige al azar entre los 5 con menos estrellas y peor puntuación (más ayudas, más fallos), siempre que lleven más de 48 h y no tengan puntuación perfecta.\n\nSolo se puede repetir un puzle al día.",
		"lock_pool": "Puzles que se pueden repetir",
		"lock_empty": "No hay puzles disponibles para repetir.",
		"lock_daily": "Hoy ya has repetido un puzle. Vuelve mañana.",
		"lock_play": "JUGAR AL AZAR",
		"lock_cancel": "CANCELAR",
		"lock_ok": "ENTENDIDO"
	},
	"en": {
		"title": "Collection",
		"quick": "Quick",
		"cryptogram": "Cryptogram",
		"progress": "%d of %d discovered",
		"random": "Choose at random",
		"empty": "No levels available",
		"level": "Level",
		"lock_title": "Puzzle already completed",
		"lock_body": "This puzzle is already completed. To replay a finished one you must wait 48 hours after completing it.\n\nYou cannot pick which one: a random puzzle is chosen among the 5 with the fewest stars and worst score (more hints, more mistakes), as long as they were completed more than 48 hours ago and are not perfect.\n\nYou can replay only one puzzle per day.",
		"lock_body_random": "There are no new or in-progress puzzles.\n\nTo replay a finished one you must wait 48 hours. You cannot pick which one: a random puzzle is chosen among the 5 with the fewest stars and worst score, as long as they were completed more than 48 hours ago and are not perfect.\n\nYou can replay only one puzzle per day.",
		"lock_pool": "Puzzles you can replay",
		"lock_empty": "There are no puzzles available to replay.",
		"lock_daily": "You already replayed a puzzle today. Come back tomorrow.",
		"lock_play": "PLAY RANDOM",
		"lock_cancel": "CANCEL",
		"lock_ok": "GOT IT"
	},
	"eu": {
		"title": "Bilduma",
		"quick": "Azkarra",
		"cryptogram": "Kriptograma",
		"progress": "%d / %d aurkituta",
		"random": "Ausaz aukeratu",
		"empty": "Ez dago mailarik",
		"level": "Maila",
		"lock_title": "Puzzlea jada osatuta",
		"lock_body": "Puzzle hau jada osatuta dago. Amaitutako bat berriro jokatzeko, osatu zenetik 48 ordu itxaron behar da.\n\nEzin da zehatz aukeratu zein: ausaz aukeratzen da izar gutxien eta puntuazio txarrena duten 5en artean, 48 ordu baino gehiago daramatzatenak eta puntuazio perfektua ez dutenak.\n\nEguneko puzzle bakarra errepika daiteke.",
		"lock_body_random": "Ez dago puzzle berririk ez eta martxan dagoenik.\n\nAmaitutako bat errepikatzeko 48 ordu itxaron behar da. Ezin da zehatz aukeratu: ausaz aukeratzen da izar gutxien eta puntuazio txarrena duten 5en artean.\n\nEguneko puzzle bakarra errepika daiteke.",
		"lock_pool": "Errepika daitezkeen puzzleak",
		"lock_empty": "Ez dago errepikatzeko puzzle erabilgarririk.",
		"lock_daily": "Gaur jada puzzle bat errepikatu duzu. Bihar itzuli.",
		"lock_play": "AUSAZ JOKATU",
		"lock_cancel": "UTZI",
		"lock_ok": "ULERTUTA"
	},
	"fr": {
		"title": "Collection",
		"quick": "Rapide",
		"cryptogram": "Cryptogramme",
		"progress": "%d sur %d découverts",
		"random": "Choisir au hasard",
		"empty": "Aucun niveau disponible",
		"level": "Niveau",
		"lock_title": "Puzzle déjà terminé",
		"lock_body": "Ce puzzle est déjà terminé. Pour en rejouer un, il faut attendre 48 heures après l'avoir fini.\n\nOn ne peut pas choisir lequel : un puzzle est tiré au hasard parmi les 5 avec le moins d'étoiles et le pire score (plus d'aides, plus d'erreurs), s'ils ont plus de 48 h et n'ont pas un score parfait.\n\nOn ne peut rejouer qu'un seul puzzle par jour.",
		"lock_body_random": "Il n'y a ni puzzle nouveau ni puzzle en cours.\n\nPour en rejouer un déjà terminé, il faut attendre 48 heures. On ne peut pas choisir lequel : un puzzle est tiré au hasard parmi les 5 avec le moins d'étoiles et le pire score.\n\nOn ne peut rejouer qu'un seul puzzle par jour.",
		"lock_pool": "Puzzles que l'on peut rejouer",
		"lock_empty": "Aucun puzzle n'est disponible à rejouer.",
		"lock_daily": "Tu as déjà rejoué un puzzle aujourd'hui. Reviens demain.",
		"lock_play": "JOUER AU HASARD",
		"lock_cancel": "ANNULER",
		"lock_ok": "COMPRIS"
	},
	"de": {
		"title": "Sammlung",
		"quick": "Schnell",
		"cryptogram": "Kryptogramm",
		"progress": "%d von %d entdeckt",
		"random": "Zufällig wählen",
		"empty": "Keine Level verfügbar",
		"level": "Level",
		"lock_title": "Rätsel bereits abgeschlossen",
		"lock_body": "Dieses Rätsel ist bereits abgeschlossen. Um ein fertiges erneut zu spielen, musst du 48 Stunden warten.\n\nDu kannst keines gezielt wählen: Es wird zufällig unter den 5 mit den wenigsten Sternen und der schlechtesten Wertung gewählt, sofern sie vor mehr als 48 Stunden abgeschlossen wurden und nicht perfekt sind.\n\nPro Tag kann nur ein Rätsel wiederholt werden.",
		"lock_body_random": "Es gibt keine neuen oder laufenden Rätsel.\n\nUm ein abgeschlossenes erneut zu spielen, musst du 48 Stunden warten. Du kannst keines gezielt wählen: Es wird zufällig unter den 5 mit den wenigsten Sternen und der schlechtesten Wertung gewählt.\n\nPro Tag kann nur ein Rätsel wiederholt werden.",
		"lock_pool": "Rätsel, die wiederholt werden können",
		"lock_empty": "Es gibt keine Rätsel zum Wiederholen.",
		"lock_daily": "Du hast heute schon ein Rätsel wiederholt. Komm morgen wieder.",
		"lock_play": "ZUFÄLLIG SPIELEN",
		"lock_cancel": "ABBRECHEN",
		"lock_ok": "VERSTANDEN"
	},
	"it": {
		"title": "Collezione",
		"quick": "Rapida",
		"cryptogram": "Crittogramma",
		"progress": "%d di %d scoperti",
		"random": "Scegli a caso",
		"empty": "Nessun livello disponibile",
		"level": "Livello",
		"lock_title": "Puzzle già completato",
		"lock_body": "Questo puzzle è già completato. Per ripeterne uno finito bisogna aspettare 48 ore dal completamento.\n\nNon si può scegliere quale: viene scelto a caso tra i 5 con meno stelle e il punteggio peggiore (più aiuti, più errori), se sono completati da più di 48 ore e non hanno un punteggio perfetto.\n\nSi può ripetere un solo puzzle al giorno.",
		"lock_body_random": "Non ci sono puzzle nuovi né in corso.\n\nPer ripetere uno già finito bisogna aspettare 48 ore. Non si può scegliere quale: viene scelto a caso tra i 5 con meno stelle e il punteggio peggiore.\n\nSi può ripetere un solo puzzle al giorno.",
		"lock_pool": "Puzzle che si possono ripetere",
		"lock_empty": "Non ci sono puzzle disponibili da ripetere.",
		"lock_daily": "Oggi hai già ripetuto un puzzle. Torna domani.",
		"lock_play": "GIOCA A CASO",
		"lock_cancel": "ANNULLA",
		"lock_ok": "CAPITO"
	},
	"pt": {
		"title": "Coleção",
		"quick": "Rápido",
		"cryptogram": "Criptograma",
		"progress": "%d de %d descobertos",
		"random": "Escolher ao acaso",
		"empty": "Nenhum nível disponível",
		"level": "Nível",
		"lock_title": "Puzzle já concluído",
		"lock_body": "Este puzzle já está concluído. Para repetir um terminado é preciso esperar 48 horas após o completar.\n\nNão se pode escolher qual: é escolhido ao acaso entre os 5 com menos estrelas e pior pontuação (mais ajudas, mais erros), desde que tenham mais de 48 h e não sejam perfeitos.\n\nSó se pode repetir um puzzle por dia.",
		"lock_body_random": "Não há puzzles novos nem em curso.\n\nPara repetir um já terminado é preciso esperar 48 horas. Não se pode escolher qual: é escolhido ao acaso entre os 5 com menos estrelas e pior pontuação.\n\nSó se pode repetir um puzzle por dia.",
		"lock_pool": "Puzzles que se podem repetir",
		"lock_empty": "Não há puzzles disponíveis para repetir.",
		"lock_daily": "Já repetiste um puzzle hoje. Volta amanhã.",
		"lock_play": "JOGAR AO ACASO",
		"lock_cancel": "CANCELAR",
		"lock_ok": "ENTENDIDO"
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
	_load_completed_ids()

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
	var saved_summary: Dictionary = PuzzleSaveManager.get_puzzle_summary(index_number)
	var puzzle_status := _puzzle_status(index_number)
	var completed := puzzle_status == "completed"
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
	if puzzle_status == "completed":
		image_frame.add_child(_hours_badge(index_number))

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
		GameManager.star_fill_color()
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


func _on_level_pressed(item: Dictionary, allow_completed := false) -> void:
	if _drag_active:
		return
	var index_number: int = int(item.get("index", -1))
	if index_number < 0:
		return
	if not get_tree().get_nodes_in_group("PuzzleThemePreview").is_empty():
		return
	if _is_completed(index_number) and not allow_completed:
		_show_completed_lock_dialog()
		return
	if allow_completed and not PlayerPrefs.can_replay_completed_today():
		_show_completed_lock_dialog()
		return
	SoundManager.play("ButtonClick")
	GameManager.allow_completed_replay = allow_completed and _is_completed(index_number)
	if GameManager.allow_completed_replay:
		PlayerPrefs.mark_completed_replay_today()
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
	var pool := _random_pool()
	if pool.is_empty() or _is_completed(int(pool[0].get("index", -1))):
		_show_completed_lock_dialog(true)
		return
	var chosen: Dictionary = pool.pick_random()
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
	if typeof(HistoryManager) != TYPE_NIL:
		for value in HistoryManager.get_history():
			if value is Dictionary:
				var entry: Dictionary = value
				if bool(entry.get("partida_ganada", false)):
					_completed_ids[int(entry.get("id", -1))] = true
	if typeof(PuzzleSaveManager) == TYPE_NIL:
		return
	for item in _visible_items:
		var puzzle_id := int(item.get("index", -1))
		if str(PuzzleSaveManager.get_puzzle_summary(puzzle_id).get("status", "")) == "completed":
			_completed_ids[puzzle_id] = true


func _is_completed(puzzle_id: int) -> bool:
	return _puzzle_status(puzzle_id) == "completed"


func _puzzle_status(puzzle_id: int) -> String:
	if typeof(PuzzleSaveManager) != TYPE_NIL:
		var save_status := str(
			PuzzleSaveManager.get_puzzle_summary(puzzle_id).get("status", "new")
		)
		if save_status == "in_progress":
			return "in_progress"
		if save_status == "completed":
			return "completed"
	if _completed_ids.has(puzzle_id):
		return "completed"
	return "new"


func _random_pool() -> Array[Dictionary]:
	var not_started: Array[Dictionary] = []
	var in_progress: Array[Dictionary] = []
	var completed: Array[Dictionary] = []
	for item in _visible_items:
		var status := _puzzle_status(int(item.get("index", -1)))
		match status:
			"completed":
				completed.append(item)
			"in_progress":
				in_progress.append(item)
			_:
				not_started.append(item)
	if not not_started.is_empty():
		return not_started
	if not in_progress.is_empty():
		return in_progress
	return _replay_pool(completed)


func _replay_pool(completed_items: Array[Dictionary]) -> Array[Dictionary]:
	var eligible: Array[Dictionary] = []
	for item in completed_items:
		var puzzle_id := int(item.get("index", -1))
		if PuzzleSaveManager.can_replay_completed(puzzle_id):
			eligible.append(item)
	eligible.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var key_a := _replay_sort_key(a)
		var key_b := _replay_sort_key(b)
		if key_a[0] != key_b[0]:
			return key_a[0] < key_b[0]
		if key_a[1] != key_b[1]:
			return key_a[1] < key_b[1]
		if key_a[2] != key_b[2]:
			return key_a[2] > key_b[2]
		return key_a[3] > key_b[3]
	)
	var limit := mini(5, eligible.size())
	var pool: Array[Dictionary] = []
	for index in range(limit):
		pool.append(eligible[index])
	return pool


func _replay_sort_key(item: Dictionary) -> Array:
	var summary: Dictionary = PuzzleSaveManager.get_puzzle_summary(
		int(item.get("index", -1))
	)
	return [
		1 if bool(summary.get("is_perfect", false)) else 0,
		int(summary.get("stars_remaining", 99)),
		int(summary.get("aids_used", 0)),
		int(summary.get("failed_letters", 0)),
	]


func _all_completed_items() -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	var seen: Dictionary = {}
	var source: Array = GameManager.frases_db if typeof(GameManager) != TYPE_NIL else []
	for value in source:
		if not (value is Dictionary):
			continue
		var item: Dictionary = value
		var puzzle_id := int(item.get("index", -1))
		if puzzle_id < 0 or seen.has(puzzle_id):
			continue
		if _puzzle_status(puzzle_id) != "completed":
			continue
		if not GameManager.level_has_image(item):
			continue
		seen[puzzle_id] = true
		completed.append(item)
	return completed


func _eligible_replay_pool() -> Array[Dictionary]:
	return _replay_pool(_all_completed_items())


func _hours_badge(puzzle_id: int) -> Panel:
	var hours := PuzzleSaveManager.hours_since_completed(puzzle_id)
	if hours < 0:
		hours = 0
	var ready := hours >= 48
	var badge := Panel.new()
	badge.name = "HoursBadge"
	badge.position = Vector2(10, 10)
	badge.size = Vector2(108, 44)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override(
		"panel",
		_make_overlay_style(
			Color(0.08, 0.52, 0.32, 0.92) if ready else Color(0.82, 0.16, 0.12, 0.92),
			16
		)
	)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_override("font", _title_label.get_theme_font("font"))
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.text = "+48H" if ready else "%dH" % hours
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)
	return badge


func _show_completed_lock_dialog(from_random := false) -> void:
	if get_node_or_null("ReplayLockDialog") != null:
		return
	GameManager.allow_completed_replay = false
	SoundManager.play("ButtonClick")
	var pool := _eligible_replay_pool()
	var can_play := (
		not pool.is_empty()
		and PlayerPrefs.can_replay_completed_today()
	)

	var overlay := ColorRect.new()
	overlay.name = "ReplayLockDialog"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.08, 0.04, 0.02, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 80
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(1080, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 0.965, 0.86, 1)
	card_style.border_color = Color(0.62, 0.4, 0.16, 0.46)
	card_style.set_border_width_all(4)
	card_style.border_width_bottom = 9
	card_style.set_corner_radius_all(48)
	card_style.shadow_color = Color(0.14, 0.08, 0.03, 0.34)
	card_style.shadow_size = 24
	card_style.shadow_offset = Vector2(0, 17)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 32)
	card.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 16)
	margin.add_child(inner)

	var title := Label.new()
	title.add_theme_font_override("font", _title_label.get_theme_font("font"))
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08, 1))
	title.text = _copy("lock_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(title)

	var body := Label.new()
	body.add_theme_font_override("font", _title_label.get_theme_font("font"))
	body.add_theme_font_size_override("font_size", 36)
	body.add_theme_color_override("font_color", Color(0.28, 0.17, 0.1, 1))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = _copy("lock_body_random" if from_random else "lock_body")
	inner.add_child(body)

	var pool_title := Label.new()
	pool_title.add_theme_font_override("font", _title_label.get_theme_font("font"))
	pool_title.add_theme_font_size_override("font_size", 30)
	pool_title.add_theme_color_override("font_color", Color(0.24, 0.14, 0.08, 0.88))
	pool_title.text = _copy("lock_pool")
	pool_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(pool_title)

	if pool.is_empty():
		var empty := Label.new()
		empty.add_theme_font_override("font", _title_label.get_theme_font("font"))
		empty.add_theme_font_size_override("font_size", 32)
		empty.add_theme_color_override("font_color", Color(0.72, 0.22, 0.14, 1))
		empty.text = _copy("lock_empty")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(empty)
	else:
		inner.add_child(_replay_thumb_row(pool))

	if not PlayerPrefs.can_replay_completed_today():
		var daily := Label.new()
		daily.add_theme_font_override("font", _title_label.get_theme_font("font"))
		daily.add_theme_font_size_override("font_size", 30)
		daily.add_theme_color_override("font_color", Color(0.72, 0.22, 0.14, 1))
		daily.text = _copy("lock_daily")
		daily.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		daily.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(daily)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 28)
	inner.add_child(buttons)

	var cancel := _make_dialog_button(
		_copy("lock_cancel"),
		Color(1, 0.982, 0.92, 1),
		Color(0.66, 0.44, 0.2, 0.7),
		Color(0.32, 0.18, 0.08, 1)
	)
	cancel.pressed.connect(func() -> void:
		SoundManager.play("ButtonClick")
		overlay.queue_free()
	)
	buttons.add_child(cancel)

	var play := _make_dialog_button(
		_copy("lock_play"),
		Color(0.18, 0.65, 0.46, 1) if can_play else Color(0.62, 0.58, 0.52, 1),
		Color(0.1, 0.42, 0.3, 1) if can_play else Color(0.42, 0.38, 0.34, 1),
		Color.WHITE
	)
	play.disabled = not can_play
	play.pressed.connect(func() -> void:
		if not can_play or pool.is_empty():
			return
		SoundManager.play("ButtonClick")
		var chosen: Dictionary = pool.pick_random()
		overlay.queue_free()
		_on_level_pressed(chosen, true)
	)
	buttons.add_child(play)

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if not (event is InputEventMouseButton and event.pressed):
			return
		var mouse := event as InputEventMouseButton
		if card.get_global_rect().has_point(mouse.global_position):
			return
		SoundManager.play("ButtonClick")
		overlay.queue_free()
	)


func _replay_thumb_row(pool: Array[Dictionary]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.custom_minimum_size = Vector2(0, 210)
	for item in pool:
		row.add_child(_replay_thumb(item))
	return row


func _replay_thumb(item: Dictionary) -> Panel:
	var index_number := int(item.get("index", -1))
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(176, 210)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _make_image_frame_style())
	frame.clip_contents = true

	var image := TextureRect.new()
	image.position = Vector2(6, 6)
	image.size = Vector2(164, 164)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := _find_image_path(int(item.get("image_number", -1)), index_number)
	var texture: Texture2D = PLACEHOLDER_TEX
	if path != "":
		var loaded := load(path) as Texture2D
		if loaded != null:
			texture = loaded
	image.texture = texture
	frame.add_child(image)

	var summary: Dictionary = PuzzleSaveManager.get_puzzle_summary(index_number)
	var stars_max := _difficulty_to_stars(int(item.get("difficulty", 1)))
	var stars := _star_icons(
		clampi(int(summary.get("stars_remaining", 0)), 0, stars_max),
		stars_max,
		22,
		GameManager.star_fill_color()
	)
	stars.position = Vector2(4, 172)
	stars.size = Vector2(168, 32)
	frame.add_child(stars)
	return frame


func _make_dialog_button(
	text: String,
	fill: Color,
	border: Color,
	font_color: Color
) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 120)
	button.add_theme_font_override("font", _title_label.get_theme_font("font"))
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.72))
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.border_width_bottom = 8
	style.set_corner_radius_all(30)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	return button


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
	return clampi(difficulty, 1, 5)


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
		if not GameManager.is_excluded_character(character):
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
