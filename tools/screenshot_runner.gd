extends Node

const LOCALES := ["es", "en", "de", "fr", "eu", "it", "pt"]
const PUZZLE_INDEX := 3066
const GIRAFFE_INDEX := 1009
const OUT_ROOT := "res://Capturas Store/v0.25"
const VOWELS := ["A", "E", "I", "O", "U"]
const SCENE_MAIN := "res://scenes/MenuMain.tscn"
const SCENE_SELECT := "res://scenes/MenuSelectCategory.tscn"
const SCENE_SELECT_LEVEL := "res://scenes/MenuSelectLevelByID.tscn"
const SCENE_GAME := "res://scenes/App.tscn"
const SCENE_RANK := "res://scenes/LeaderboardFINAL.tscn"
const SCENE_LIBRARY := "res://scenes/MenuLibrary.tscn"
const SCENE_SETTINGS := "res://scenes/MenuSettings.tscn"
const SCENE_VICTORY := "res://scenes/menu_game_over.tscn"
const SCENE_TUTORIAL := "res://scenes/MenuTutorial.tscn"

var _current: Node
var _original_locale := "es"
var _original_full_game := false
var _original_tutorial := true


func _ready() -> void:
	Engine.set_meta("store_screenshot", true)
	GameManager.puzzle_enter_pending = false
	_mute_audio()
	_original_locale = str(PlayerPrefs.idioma)
	if _original_locale.strip_edges().is_empty():
		_original_locale = "es"
	_original_full_game = PlayerPrefs.full_game
	_original_tutorial = PlayerPrefs.mostrar_tuto_antes_partida
	PlayerPrefs.full_game = true
	PlayerPrefs.mostrar_tuto_antes_partida = false
	PlayerPrefs.hide_share_solve_dialog = true
	GameManager.set_mostrar_tuto_antes_partida_disable()
	GameManager.session_source = GameManager.SOURCE_NONE
	await _capture_all()
	_restore_prefs()
	get_tree().quit()


func _mute_audio() -> void:
	for bus_i in AudioServer.bus_count:
		AudioServer.set_bus_mute(bus_i, true)


func _restore_prefs() -> void:
	PlayerPrefs.full_game = _original_full_game
	PlayerPrefs.mostrar_tuto_antes_partida = _original_tutorial
	if _original_tutorial:
		GameManager.set_mostrar_tuto_antes_partida_enable()
	else:
		GameManager.set_mostrar_tuto_antes_partida_disable()
	GameManager.apply_language(_original_locale)


func _capture_all() -> void:
	for locale in LOCALES:
		print("[screenshots] locale=", locale)
		GameManager.apply_language(locale)
		_seed_library_preview()
		_ensure_giraffe_playable()
		await _wait_frames(2)
		var folder := "%s/%s" % [OUT_ROOT, locale]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))

		_set_tutorial(false)
		await _show_scene(SCENE_MAIN)
		await _wait_sec(0.45)
		await _shot(folder, "01_principal")

		var select := await _show_scene(SCENE_SELECT)
		await _wait_frames(3)
		if select.has_method("_select_category"):
			select._select_category(GameManager.CAT_CITA, select.button_citas_celebres)
			select._select_mode(select.MODE_QUICK, select.button_quick)
		await _wait_sec(0.30)
		await _shot(folder, "02_tipo_partida")

		await _prepare_puzzle()
		await _show_scene(SCENE_GAME)
		await _wait_sec(0.90)
		await _shot(folder, "03_juego_rapido")

		var rank := await _show_scene(SCENE_RANK)
		await _wait_ranking(rank)
		await _shot(folder, "04_clasificacion")

		await _prepare_puzzle()
		await _show_scene(SCENE_GAME)
		await _wait_sec(0.90)
		_dress_board()
		await _wait_frames(4)
		await _shot(folder, "05_juego_vocales_reveladas")

		await _show_scene(SCENE_LIBRARY)
		await _wait_sec(0.50)
		await _shot(folder, "06_coleccion")

		await _show_scene(SCENE_SETTINGS)
		await _wait_sec(0.35)
		await _shot(folder, "07_opciones")

		await _prepare_puzzle()
		GameManager.tiempo_partida = 198
		GameManager.puzzle_stars = mini(2, GameManager.get_puzzle_difficulty_stars())
		await _show_scene(SCENE_VICTORY)
		await _wait_sec(0.70)
		await _shot(folder, "08_victoria")

		await _prepare_giraffe()
		var levels := await _show_scene(SCENE_SELECT_LEVEL)
		await _wait_sec(0.70)
		_open_giraffe_preview(levels)
		await _wait_sec(0.45)
		await _shot(folder, "09_jirafa_antes")

		await _prepare_giraffe()
		await _show_scene(SCENE_GAME)
		await _wait_sec(1.25)
		_dress_giraffe_board()
		await _wait_sec(0.20)
		_dress_giraffe_board()
		await _wait_frames(4)
		await _shot(folder, "10_jirafa_juego")

		await _prepare_curiosities_quick()
		await _show_scene(SCENE_SELECT_LEVEL)
		await _wait_sec(0.80)
		await _shot(folder, "11_curiosidades_rapido")

	await _clear_current()
	print("[screenshots] done")


func _set_tutorial(enabled: bool) -> void:
	PlayerPrefs.mostrar_tuto_antes_partida = enabled
	if enabled:
		GameManager.set_mostrar_tuto_antes_partida_enable()
	else:
		GameManager.set_mostrar_tuto_antes_partida_disable()


func _ensure_giraffe_playable() -> void:
	PuzzleSaveManager._states.erase(str(GIRAFFE_INDEX))


func _prepare_curiosities_quick() -> void:
	GameManager.set_categoria_actual(GameManager.CAT_CURIOSIDADES)
	GameManager.set_game_mode_actual(GameManager.MODE_QUICK)
	GameManager.session_source = GameManager.SOURCE_NONE


func _prepare_giraffe() -> void:
	_prepare_curiosities_quick()
	GameManager.seleccionar_frase_por_indice_db(GIRAFFE_INDEX)
	GameManager.tiempo_partida = 96


func _item_by_index(puzzle_id: int) -> Dictionary:
	for item in GameManager.frases_db:
		if item is Dictionary and int(item.get("index", -1)) == puzzle_id:
			return item
	return {}


func _open_giraffe_preview(levels: Node) -> void:
	var item := _item_by_index(GIRAFFE_INDEX)
	if item.is_empty() or levels == null:
		push_error("[screenshots] missing giraffe level %d" % GIRAFFE_INDEX)
		return
	GameManager.session_source = GameManager.SOURCE_NONE
	GameManager.allow_completed_replay = false
	GameManager.id_frase = GIRAFFE_INDEX
	GameManager.set_dificultad_actual(int(item.get("difficulty", 1)))
	if GameManager.has_method("seleccionar_por_index"):
		GameManager.seleccionar_por_index(GIRAFFE_INDEX)
	else:
		GameManager.seleccionar_frase_por_indice_db(GIRAFFE_INDEX)
	if PuzzleSaveManager.has_method("prepare_current_puzzle_cipher"):
		PuzzleSaveManager.prepare_current_puzzle_cipher()
	GameManager.set_go_to_game_disable()
	var preview_scene := load("res://scenes/game/PuzzleThemePreview.tscn") as PackedScene
	var preview: Control = preview_scene.instantiate()
	preview.set("launch_game_on_start", true)
	preview.set("image_path", PuzzleThemePreview.find_image_path(
		int(item.get("image_number", -1)),
		GIRAFFE_INDEX
	))
	levels.add_child(preview)


func _dress_giraffe_board() -> void:
	_dress_board_custom(["A"], 3, true)


func _wait_tutorial() -> void:
	var waited := 0.0
	while waited < 3.2:
		await get_tree().create_timer(0.12).timeout
		waited += 0.12
		var tutorials := get_tree().get_nodes_in_group("BasicStartTutorial")
		if tutorials.is_empty():
			continue
		var tutorial: Node = tutorials[0]
		if int(tutorial.get("_step")) == 1:
			await _wait_sec(0.45)
			return
	await _wait_sec(0.2)


func _seed_library_preview() -> void:
	var marked := 0
	for item in GameManager.frases_db:
		if not (item is Dictionary):
			continue
		if GameManager.is_daily_puzzle(item):
			continue
		var puzzle_id := int(item.get("index", -1))
		if puzzle_id < 0:
			continue
		PuzzleSaveManager._states[str(puzzle_id)] = {
			"status": "completed",
			"meta": {
				"completed_at": int(Time.get_unix_time_from_system()),
				"letters_filled": 1,
				"letters_total": 1,
				"stars": 2,
			},
			"resolution": {},
			"attempt": {},
			"cipher": {},
		}
		marked += 1
		if marked >= 10:
			break


func _prepare_puzzle() -> void:
	GameManager.set_categoria_actual(GameManager.CAT_CITA)
	GameManager.set_game_mode_actual(GameManager.MODE_QUICK)
	GameManager.session_source = GameManager.SOURCE_NONE
	GameManager.seleccionar_frase_por_indice_db(PUZZLE_INDEX)
	GameManager.tiempo_partida = 142


func _dress_board() -> void:
	_dress_board_custom(VOWELS, 4)


func _is_initial_gift_letter(letter: String) -> bool:
	var gifts := GameManager.letras_iniciales.to_upper()
	return gifts.contains(letter)


func _dress_board_custom(letters_to_color: Array, reveal_count: int, skip_gifts := false) -> void:
	var cells: Array = get_tree().get_nodes_in_group("Celda")
	var number_to_letter := {}
	for node in cells:
		if not (node is Celda):
			continue
		var cell := node as Celda
		if cell.numero <= 0 or cell.numero >= 100:
			continue
		var letter := GameManager._hint_letter_key(cell.letra)
		if letter.length() != 1:
			continue
		if letter < "A" or letter > "Z":
			continue
		number_to_letter[cell.numero] = letter

	var colored_nums: Array[int] = []
	for letter in letters_to_color:
		for numero in number_to_letter.keys():
			if str(number_to_letter[numero]) == str(letter) and not colored_nums.has(int(numero)):
				colored_nums.append(int(numero))
				break

	for i in colored_nums.size():
		var numero: int = colored_nums[i]
		var letter := str(number_to_letter[numero])
		SignalManager.insert_letter_in_number.emit(letter, numero)
		GameManager.pinta_celdas(numero, i + 1)
		for node in cells:
			if node is Celda and (node as Celda).numero == numero:
				(node as Celda).cambia_color(i + 1)

	var revealed := 0
	var used_letters := {}
	var sorted_cells: Array = cells.duplicate()
	sorted_cells.sort_custom(func(a, b) -> bool:
		if not (a is Celda):
			return false
		if not (b is Celda):
			return true
		return (a as Celda).orden < (b as Celda).orden
	)
	for node in sorted_cells:
		if revealed >= reveal_count:
			break
		if not (node is Celda):
			continue
		var cell := node as Celda
		if cell.numero <= 0 or cell.numero >= 100:
			continue
		if colored_nums.has(cell.numero):
			continue
		var letter := str(number_to_letter.get(cell.numero, ""))
		if skip_gifts and (cell.es_regalo_inicial or _is_initial_gift_letter(letter)):
			continue
		if letter.is_empty() or used_letters.has(letter):
			continue
		if letters_to_color.has(letter):
			continue
		used_letters[letter] = true
		cell.set_letter_user(letter)
		cell.mostrar_letra()
		revealed += 1


func _show_scene(path: String) -> Node:
	await _clear_current()
	var packed := load(path) as PackedScene
	var inst := packed.instantiate()
	add_child(inst)
	_current = inst
	await _wait_frames(3)
	return inst


func _clear_current() -> void:
	if _current != null and is_instance_valid(_current):
		_current.queue_free()
		_current = null
		await _wait_frames(2)


func _wait_ranking(rank: Node) -> void:
	var waited := 0.0
	while waited < 6.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
		if rank != null and is_instance_valid(rank) and rank.get("_loading") == false:
			await _wait_sec(0.35)
			return
	await _wait_sec(0.2)


func _shot(folder: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	if tex == null:
		push_error("[screenshots] missing viewport texture for %s" % name)
		return
	var img := tex.get_image()
	if img == null:
		push_error("[screenshots] missing image for %s" % name)
		return
	var path := ProjectSettings.globalize_path("%s/%s.png" % [folder, name])
	var err := img.save_png(path)
	print("[screenshots] ", path, " err=", err)


func _wait_frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame


func _wait_sec(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
