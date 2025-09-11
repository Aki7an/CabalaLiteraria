extends Control
# PlayFab Leaderboard con estilo por código (GridContainer 3 columnas) — Godot 4.4.x
@onready var dificultad: Label = $ColorRect/TituloDificultadCategoria4/Dificultad/VBoxContainer/HBoxContainer/Dificultad

const DIFF_LABELS: Array[String] = ["Fácil", "Normal", "Difícil"]
const DIFF_CODES: Array[int] = [1, 2, 3]

@onready var ob_dificultad: OptionButton = %Dificultad

# ----------------- PLAYFAB -----------------
const TITLE_ID: String = "1BC2FD"
var LEADERBOARD_NAME: String = "Score_Facil"   # <- ahora normal (no @onready) para reasignarlo a tiempo
const MAX_RESULTS: int = 10
const TOP_TO_SHOW: int = 8
const CUSTOM_ID_PREFIX: String = "CL_TEST_"

var session_ticket: String = ""
var leaderboard: Array[Dictionary] = [] # [{pos:int,name:String,score:int,playfab_id:String}]

@onready var http: HTTPRequest = HTTPRequest.new()

# ----------------- UI TARGET -----------------
@export var grid_path: NodePath
@export var header_rows_count: int = 0
@export var force_grid_columns_to_3: bool = true

var _grid: GridContainer

# ----------------- ESTILO -----------------
const FIRST_COL_MIN_W: int = 200

const RAD: int = 12                                      # radio de esquinas
const ROW_H: int = 64                                    # alto mínimo fila
const PADDING: Vector4 = Vector4(16.0, 10.0, 16.0, 10.0) # L,T,R,B

const COLOR_BG_A: Color = Color(1.0, 1.0, 1.0)
const COLOR_BG_B: Color = Color(0.942, 0.912, 0.875)
const COLOR_BG_TOP: Color = Color(0.839, 0.768, 0.677)

const COLOR_POS: Color = Color(0.396, 0.216, 0.157)
const COLOR_NAME: Color = Color(0.396, 0.216, 0.157)
const COLOR_SCORE: Color = Color(0.0, 0.0, 0.0)
const COLOR_HEADER: Color = Color(0.481, 0.0, 0.0)

const FS_POS: int = 45
const FS_NAME: int = 45
const FS_SCORE: int = 45
const FS_SCORE_TOP: int = 50
const FS_HEADER: int = 18

const H_SEP: int = 0
const V_SEP: int = 10

func _ready() -> void:
	add_child(http)
	http.timeout = 30

	# 1) Poblar primero (y fijar LEADERBOARD_NAME en base a GameManager)
	_poblar_optionbuttons()

	# 2) Conectar señales después de poblar (evita refreshs innecesarios)
	_conectar_signals()

	# 3) Resolver grid y aspecto
	_grid = get_node_or_null(grid_path) as GridContainer
	if _grid == null:
		push_error("GridContainer no encontrado. Asigna 'grid_path'.")
		return
	if force_grid_columns_to_3:
		_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", H_SEP)
	_grid.add_theme_constant_override("v_separation", V_SEP)

	# 4) Cargar leaderboard inicial con la dificultad ya aplicada
	_ensure_playfab_session_and_load()
	#dificultad._update_stars(GameManager.dificultad_ultima_partida)

# ----------------- OPTIONBUTTON / DIFICULTAD -----------------

func _poblar_optionbuttons() -> void:
	ob_dificultad.clear()
	for i: int in DIFF_LABELS.size():
		ob_dificultad.add_item(DIFF_LABELS[i])
		ob_dificultad.set_item_metadata(i, DIFF_CODES[i])

	# Selección inicial según GameManager (si existe)
	var sel_idx: int = 0
	if typeof(GameManager) != TYPE_NIL:
		if GameManager.dificultad_ultima_partida == 3:
			sel_idx = 2
		elif GameManager.dificultad_ultima_partida == 2:
			sel_idx = 1
		else:
			sel_idx = 0
	ob_dificultad.selected = sel_idx

	# 🔑 Aplicar inmediatamente estrellas y leaderboard en base a la selección efectiva del OptionButton
	var diff_code: int = _current_diff_code_from_ui()
	dificultad._update_stars(diff_code)        # ← estrellas ya sincronizadas en el primer frame
	LEADERBOARD_NAME = _stat_name_for_diff(diff_code)

func _conectar_signals() -> void:
	ob_dificultad.item_selected.connect(func(_i: int) -> void:
		_refrescar_lista()
	)

func _current_diff_code_from_ui() -> int:
	var idx: int = ob_dificultad.selected
	if idx >= 0 and idx < ob_dificultad.item_count:
		var md: Variant = ob_dificultad.get_item_metadata(idx)
		if typeof(md) != TYPE_NIL:
			return int(md)
	# Fallback por índice si no hay metadata
	return (DIFF_CODES[idx] if (idx >= 0 and idx < DIFF_CODES.size()) else 1)

func _stat_name_for_diff(diff_code: int) -> String:
	match diff_code:
		1: return "Score_Facil"
		2: return "Score_Normal"
		3: return "Score_Dificil"
		_: return "Score" # fallback

# ----------------- LOGIN + CARGA INICIAL -----------------

func _ensure_playfab_session_and_load() -> void:
	await get_tree().process_frame

	# Reaplicar por seguridad el leaderboard según UI actual ANTES de pedir datos
	LEADERBOARD_NAME = _stat_name_for_diff(_current_diff_code_from_ui())

	# 1) Si no hay sesión, intentar login con autoload PlayFabTools
	if typeof(PlayFabTools) != TYPE_NIL and not PlayFabTools.is_logged_in():
		var custom_id: String = PlayFabTools._get_device_custom_id()
		var ok: bool = await PlayFabTools.login_with_custom_id(custom_id, true)
		if not ok:
			push_warning("❌ No se pudo iniciar sesión en PlayFab desde leaderboard.")
			return

	# 2) Copiar ticket
	if typeof(PlayFabTools) != TYPE_NIL:
		session_ticket = PlayFabTools.session_ticket

	# 3) Pedir leaderboard correcto y pintar
	var ok_lb: bool = await fetch_leaderboard(LEADERBOARD_NAME, MAX_RESULTS, 0)
	if not ok_lb:
		push_warning("❌ No se pudo obtener leaderboard: " + LEADERBOARD_NAME)
		return

	_render_styled_grid()

# ----------------- GET LEADERBOARD -----------------

func fetch_leaderboard(stat_name: String, max_results: int, start_pos: int) -> bool:
	if session_ticket == "":
		return false

	var url: String = "https://%s.playfabapi.com/Client/GetLeaderboard" % TITLE_ID
	var body: Dictionary = {
		"StatisticName": stat_name,
		"StartPosition": start_pos,
		"MaxResultsCount": max_results
	}
	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
		"Accept-Encoding: identity",
		"X-Authorization: " + session_ticket,
		"X-ReportErrorAsSuccess: true"
	])

	var err: int = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		return false

	var r: Array = await http.request_completed
	var response_code: int = int(r[1])
	var body_bytes: PackedByteArray = r[3] as PackedByteArray
	var text: String = body_bytes.get_string_from_utf8()

	var parsed: Variant = JSON.parse_string(text)
	if !(parsed is Dictionary):
		return false
	var json: Dictionary = parsed as Dictionary

	if int(json.get("code", response_code)) != 200:
		return false

	var data_any: Variant = json.get("data", {})
	var data: Dictionary = (data_any as Dictionary) if (data_any is Dictionary) else {}
	var entries_any: Variant = data.get("Leaderboard", [])
	var entries: Array = (entries_any as Array) if (entries_any is Array) else []

	leaderboard.clear()
	for i: int in entries.size():
		var e_var: Variant = entries[i]
		if !(e_var is Dictionary):
			continue
		var entry: Dictionary = e_var as Dictionary
		var pos: int = int(entry.get("Position", -1))
		var name: String = str(entry.get("DisplayName", "Anon"))
		var score: int = drop_last_digit(int(entry.get("StatValue", 0)))
		var pid: String = str(entry.get("PlayFabId", ""))
		leaderboard.append({"pos": pos, "name": name, "score": score, "playfab_id": pid})
	return true

func drop_last_digit(n: int) -> int:
	return int(n / 10)

# ----------------- RENDER ESTILIZADO -----------------

func _render_styled_grid() -> void:
	_clear_rows_preserving_headers()

	leaderboard.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["pos"]) < int(b["pos"])
	)
	var count: int = min(TOP_TO_SHOW, leaderboard.size())

	for i: int in count:
		var e: Dictionary = leaderboard[i]
		var human_pos: int = int(e["pos"]) + 1
		var name: String = str(e["name"])
		var score_txt: String = _format_thousands(int(e["score"]))
		var is_top: bool = (i == 0)
		var bg: Color = (COLOR_BG_TOP if is_top else (COLOR_BG_A if i % 2 == 0 else COLOR_BG_B))

		_grid.add_child(_make_cell(str(human_pos), FS_POS, COLOR_POS, bg, 0, HORIZONTAL_ALIGNMENT_LEFT))
		_grid.add_child(_make_cell(name,         FS_NAME, COLOR_NAME, bg, 1, HORIZONTAL_ALIGNMENT_LEFT))
		var fs_score: int = (FS_SCORE_TOP if is_top else FS_SCORE)
		_grid.add_child(_make_cell(score_txt, fs_score, COLOR_SCORE, bg, 2, HORIZONTAL_ALIGNMENT_RIGHT))

func _make_cell(text: String, font_size: int, font_color: Color, bg_color: Color, col_index: int, align: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()

	if col_index == 0:
		panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		panel.custom_minimum_size = Vector2(float(FIRST_COL_MIN_W), float(ROW_H))
	else:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size = Vector2(0.0, float(ROW_H))

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.corner_radius_top_left = (RAD if col_index == 0 else 0)
	sb.corner_radius_bottom_left = (RAD if col_index == 0 else 0)
	sb.corner_radius_top_right = (RAD if col_index == 2 else 0)
	sb.corner_radius_bottom_right = (RAD if col_index == 2 else 0)
	sb.shadow_size = 1
	sb.shadow_color = Color(0, 0, 0, 0.07)
	sb.set_content_margin_all(0.0)
	sb.content_margin_left = PADDING.x
	sb.content_margin_top = PADDING.y
	sb.content_margin_right = PADDING.z
	sb.content_margin_bottom = PADDING.w
	panel.add_theme_stylebox_override("panel", sb)

	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	panel.add_child(label)

	return panel

func _clear_rows_preserving_headers() -> void:
	var keep: int = header_rows_count * 3
	var children: Array[Node] = _grid.get_children()
	for i: int in range(children.size() - 1, -1, -1):
		if i < keep:
			continue
		children[i].queue_free()

func _format_thousands(n: int) -> String:
	var s: String = str(abs(n))
	var parts: Array[String] = []
	while s.length() > 3:
		parts.push_front(s.substr(s.length() - 3, 3))
		s = s.substr(0, s.length() - 3)
	parts.push_front(s)
	var out: String = ",".join(parts)
	out = out.replace(",", ".")
	return ("-" if n < 0 else "") + out

# (Opcional) Navegación
func _on_button_back_pressed() -> void:
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	SoundManager.play("ButtonClick")
	get_tree().change_scene_to_file("res://scenes/MenuMain.tscn")

# Señal del botón (si la usas)
func _on_dificultad_pressed() -> void:
	print("button pressed OPTIONS, check if option changed")

# Refresca la lista leyendo PlayFab según la dificultad seleccionada y repinta la grid.
func _refrescar_lista() -> void:
	
	var diff_code: int = _current_diff_code_from_ui()
	LEADERBOARD_NAME = _stat_name_for_diff(diff_code)
	dificultad._update_stars(diff_code)
	print("Dificultad option: ", diff_code)
	if session_ticket.is_empty():
		push_warning("No hay SessionTicket. Inicia sesión antes de refrescar la lista.")
		return

	var ok_lb: bool = await fetch_leaderboard(LEADERBOARD_NAME, MAX_RESULTS, 0)
	if ok_lb:
		_render_styled_grid()
	else:
		push_warning("No se pudo obtener leaderboard para: " + LEADERBOARD_NAME)
