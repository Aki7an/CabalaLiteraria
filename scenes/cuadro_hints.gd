extends ColorRect
@onready var cuadro_salir_partida = $CuadroSalirPartida


## === Exports ===
# Escena FINAL ya instanciada por debajo (pásala por el inspector)
#@export_node_path var next_scene_node_path: NodePath
# Ruta del botón 'Btn_pistas' dentro de esa escena final
# Duración de la transición
@export var next_scene_root_group: String = "Scene_App"   # raíz de la escena inferior ya instanciada
@export var old_visual_group: String = "FondoHint"        # SOLO este nodo se anima
@export var also_free_whole_current_scene: bool = false   # opcional: liberar toda la escena actual

@export var btn_group_name: String = "Btn_pista"

# ¿Desvanecer además de mover y escalar?
@export var fade_out: bool = false
# Escala final (0.1 es “encoger casi a punto”)
@export var final_scale: Vector2 = Vector2(0.01, 0.01)

var _transition_running := false
## Config por defecto
@export var next_scene_path: String = "res://scenes/App.tscn"            # p.ej. "res://ui/PantallaFinal.tscn"
@export var btn_pistas_path_in_next: String = "$ButtonPista0"
@export var duration: float = 1.0   
				# segundos
var _next_packed: PackedScene
var _next_instance: Node


@onready var score_text = $ScoreText
@onready var score_2 = %Score2

@onready var label_10000 = $CuadroSalirPartida/CuadroHint3/Label10000
@onready var label_coste = $CuadroSalirPartida/CuadroHint3/LabelCoste
@onready var label_coins = $CuadroSalirPartida/CuadroHint3/LabelCoins

@onready var label_unkocked_hint_1 = $CuadroSalirPartida/CuadroHint1/LabelUnkockedHint1
@onready var label_unkocked_hint_2 = $CuadroSalirPartida/CuadroHint2/LabelUnkockedHint2
@onready var label_paid_2 = $CuadroSalirPartida/CuadroHint3/LabelPAID2

@onready var label_paid = $CuadroSalirPartida/CuadroHint2/LabelPAID

@onready var rich_text_label_hint_2 = $CuadroSalirPartida/CuadroHint2/RichTextLabelHint2

@onready var candado = $CuadroSalirPartida/CuadroHint3/ButtonHint3/Candado
@onready var button_hint_3 = $CuadroSalirPartida/CuadroHint3/ButtonHint3

@onready var label_locked_hint_3 = $CuadroSalirPartida/CuadroHint3/LabelLockedHint3
@onready var label_available_hint_2 = $CuadroSalirPartida/CuadroHint2/LabelAvailableHint2

@onready var label_unkocked_hint_3 = $CuadroSalirPartida/CuadroHint3/LabelUnkockedHint3

@onready var color_habilitado : Color = Color(0.859, 0.918, 0.859)
@onready var color_deshabilitado : Color = Color(0.961, 0.949, 0.918)

@onready var rich_text_label_hint_3 = $CuadroSalirPartida/CuadroHint3/RichTextLabelHint3
@onready var label_available_hint_3 = $CuadroSalirPartida/CuadroHint3/LabelAvailableHint3
@onready var coin = $CuadroSalirPartida/CuadroHint3/Coin

@onready var cuadro_hint_1 = $CuadroSalirPartida/CuadroHint1
@onready var cuadro_hint_2 = $CuadroSalirPartida/CuadroHint2
@onready var cuadro_hint_3 = $CuadroSalirPartida/CuadroHint3

@onready var imagen_viñeta = $CuadroSalirPartida/CuadroHint1/ImagenViñeta
@onready var imagen_viñeta_big = $CuadroSalirPartida/CuadroImageBig/ImagenViñetaBIG

const IMG_DIR := "res://data/images"  

@onready var button_hint_2 = $CuadroSalirPartida/CuadroHint2/ButtonHint2
@onready var cuadro_image_big = $CuadroSalirPartida/CuadroImageBig

func _ready():
	_load_image()
	cuadro_image_big.visible = false
	rich_text_label_hint_2.text = pasa_a_asteriscos(GameManager.hint_1)
	if GameManager.pista_1 and !GameManager.pista_2 and !GameManager.pista_3:
		#Pista 1
		_state_hint1()
	elif GameManager.pista_1 and GameManager.pista_2 and !GameManager.pista_3:
		#Pista 2
		_state_hint2()
	elif GameManager.pista_1 and GameManager.pista_2 and GameManager.pista_3:
		#Pista 3
		_state_hint3()
	cuadro_salir_partida.self_modulate.a = 0.8
	score_text.visible = true
	score_2.visible = true 
	
## Carga IMAGE<index>.PNG en el TextureRect dado.
#func set_texture_from_index(texrect: TextureRect, dir_path: String, index: int) -> void:
	#var filename := "image%d.png" % index
	#var path := dir_path.path_join(filename)
#
	## Si no existe en mayúsculas, prueba .png
	#if not FileAccess.file_exists(path):
		#var alt := path.get_base_dir().path_join("%s.png" % path.get_file().get_basename())
		#if FileAccess.file_exists(alt):
			#path = alt
#
	## Si está dentro de res:// y está importada, puedes usar load()
	#if path.begins_with("res://"):
		#var tex := load(path)
		#if tex is Texture2D:
			#texrect.texture = tex
			#return
	## Si es user:// (o un PNG sin importar), usa Image + ImageTexture
	#var img := Image.new()
	#var err := img.load(path)
	#if err != OK:
		#push_error("No se pudo cargar la imagen: %s (err %d)" % [path, err])
		#return
	#texrect.texture = ImageTexture.create_from_image(img)
	
	# Siempre dentro de res://, todo en minúsculas.


func set_texture_from_index(texrect: TextureRect, index: int) -> void:
	var path := GameManager.find_level_image_path(index)
	if path.is_empty():
		path = "%s/image%d.png" % [IMG_DIR, index]
	if ResourceLoader.exists(path):
		var tex := load(path)
		if tex is Texture2D:
			texrect.texture = tex
		else:
			push_warning("El recurso no es Texture2D: %s" % path)
	else:
		push_warning("No existe la imagen: %s" % path)


func _load_image() -> void:
	set_texture_from_index(imagen_viñeta, GameManager.id_image)
	set_texture_from_index(imagen_viñeta_big, GameManager.id_image)
	print("id image" , GameManager.id_image)
	
func _process(delta):
	score_2.text = GameManager.formatear_numero(GameManager.score)
	
func _state_hint1() -> void:
	label_unkocked_hint_1.visible = true
	label_paid_2.visible = false
	label_unkocked_hint_2.visible = false
	label_unkocked_hint_3.visible = false
	
	label_locked_hint_3.visible = true
	label_available_hint_2.visible = true
	
	button_hint_2.visible = true
	label_paid.visible = false
	
	candado.visible = true
	button_hint_3.disabled = true
	label_available_hint_3.visible = false
	label_locked_hint_3.visible = true
	set_label_bg_only(cuadro_hint_1, color_habilitado)
	set_label_bg_only(cuadro_hint_2, color_habilitado)
	set_label_bg_only(cuadro_hint_3, color_deshabilitado)
	
	label_10000.visible = true
	label_coins.visible = true
	label_coste.visible = true
	
	set_alpha(label_10000, 0.3)
	set_alpha(label_coins, 0.3)
	set_alpha(label_coste, 0.3)
	
	coin.visible = true
	set_alpha(coin, 0.3)
	

	
func pasa_a_asteriscos(frase:String) -> String:
	var frase_final_asteriscos : String =""
	for i in frase.length():
		if frase.substr(i,1) == " ":
			frase_final_asteriscos = frase_final_asteriscos + " "
		else:
			frase_final_asteriscos = frase_final_asteriscos + "*"
	return frase_final_asteriscos
	
func _on_button_cancel_pressed():
	#queue_free()
	# transition to button Pistas position.
	SignalManager.update_difficulty.emit(GameManager.frase_original, GameManager.recoger_letras_mostradas()) 
	
	cuadro_salir_partida.self_modulate.a = 0.0
	score_text.visible = false
	score_2.visible = false
	start_transition("Btn_pista", .8)
	
	























# Transición: reducir SOLO el nodo marcado con grupo "FondoHint"
# y moverlo hasta el centro del botón en la escena inferior (grupo "Btn_pistas").




func start_transition(p_btn_group_name: String = "", p_duration: float = -1.0) -> void:
	if _transition_running:
		return
	_transition_running = true

	if p_btn_group_name != "":
		btn_group_name = p_btn_group_name
	if p_duration > 0.0:
		duration = p_duration

	var tree := get_tree()
	var current_root := tree.current_scene
	if current_root == null:
		push_error("No hay current_scene.")
		_transition_running = false
		return

	# --- Escena inferior (ya instanciada) por grupo de raíz ---
	var next_scene := _find_scene_by_group_root(next_scene_root_group)
	if next_scene == null:
		push_error("No se encontró la escena inferior en el grupo '%s'." % next_scene_root_group)
		_transition_running = false
		return

	# --- SOLO el nodo visual a animar: por grupo 'FondoHint' en cualquier parte del árbol actual ---
	var old_visual := _find_node_by_group_any(old_visual_group)
	if old_visual == null:
		push_error("No se encontró el nodo a animar con grupo '%s'." % old_visual_group)
		_transition_running = false
		return

	# 1) Botón objetivo por grupo dentro del subárbol de next_scene
	var btn_node := _find_node_in_subtree_by_group(next_scene, btn_group_name)

	# 2) Centro objetivo (botón si existe; si no, centro de la escena inferior)
	var target_pos: Vector2 = _get_node_center_global(btn_node) if btn_node != null else _get_scene_center_global(next_scene)
	print(target_pos)
	target_pos = Vector2(500,256)
	## 3) Pivot para escalar desde el centro SOLO del nodo "FondoHint"
	if old_visual is ColorRect:
		var oc := old_visual as Control
		oc.pivot_offset = oc.size * 0.5

	# 4) Tween paralelo sobre "old_visual": mover + escalar (+ desvanecer) con ease-in
	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(old_visual, "global_position", target_pos, duration)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(old_visual, "scale", final_scale, duration)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)

	if fade_out and old_visual is CanvasItem:
		var ci := old_visual as CanvasItem
		var to_mod := Color(ci.modulate.r, ci.modulate.g, ci.modulate.b, 0.0)
		tween.tween_property(old_visual, "modulate", to_mod, duration)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	await tween.finished

	# 5) Promover la inferior y liberar lo que toque
	if next_scene.get_parent() != tree.root:
		tree.root.add_child(next_scene)
	tree.set_current_scene(next_scene)

	# Libera SOLO el nodo visual animado (lo que pediste)
	old_visual.queue_free()

	# (Opcional) Si quieres limpiar todo lo anterior:
	if also_free_whole_current_scene and is_instance_valid(current_root):
		current_root.queue_free()

	_transition_running = false


# ------------------ Helpers ------------------

# Busca una escena RAÍZ bajo root por nombre de grupo (tag de la raíz)
func _find_scene_by_group_root(group_name: String) -> Node:
	for n in get_tree().get_nodes_in_group(group_name):
		if n.get_parent() == get_tree().root:
			return n
	return null

# Busca un nodo por grupo en cualquier parte del árbol
func _find_node_by_group_any(group_name: String) -> Node:
	var nodes := get_tree().get_nodes_in_group(group_name)
	return nodes[0] if nodes.size() > 0 else null

# Busca nodos del grupo dentro del subárbol 'root_subtree'
func _find_node_in_subtree_by_group(root_subtree: Node, group_name: String) -> Node:
	for n in get_tree().get_nodes_in_group(group_name):
		if n is Node and _is_in_subtree(n, root_subtree):
			return n
	return null

func _is_in_subtree(candidate: Node, subtree_root: Node) -> bool:
	var cur := candidate
	while cur != null:
		if cur == subtree_root:
			return true
		cur = cur.get_parent()
	return false

func _get_node_center_global(n: Node) -> Vector2:
	if n == null:
		return get_viewport().get_visible_rect().get_center()
	if n is Control:
		return (n as Control).get_global_rect().get_center()
	elif n is Node2D:
		return (n as Node2D).global_position
	elif "global_position" in n:
		return n.global_position
	return get_viewport().get_visible_rect().get_center()

func _get_scene_center_global(scene_node: Node) -> Vector2:
	if scene_node is Control:
		return (scene_node as Control).get_global_rect().get_center()
	elif scene_node is Node2D:
		return (scene_node as Node2D).global_position
	return get_viewport().get_visible_rect().get_center()



































func _on_button_hint_2_pressed():
		
	GameManager.set_pistas_utilizadas(1)
	GameManager.register_hint_used("hint_2")
	rich_text_label_hint_2.text = GameManager.hint_1
	rich_text_label_hint_3.text = pasa_a_asteriscos(GameManager.hint_2)
	GameManager.set_pista2()
	_state_hint2()
	SignalManager.compra_pista_2.emit(GameManager.tiempo_partida)
	
func _state_hint2():
	rich_text_label_hint_2.text = GameManager.hint_1
	rich_text_label_hint_3.text = pasa_a_asteriscos(GameManager.hint_2)
	label_unkocked_hint_1.visible = true
	label_unkocked_hint_2.visible = true
	label_paid_2.visible = false
	label_unkocked_hint_3.visible = false
	label_paid.visible = true
	
	label_locked_hint_3.visible = true
	label_available_hint_2.visible = false
	
	button_hint_3.disabled = false
	
	candado.visible = false
	label_available_hint_3.visible = true
	set_label_bg_only(cuadro_hint_1, color_habilitado)
	set_label_bg_only(cuadro_hint_2, color_habilitado)
	set_label_bg_only(cuadro_hint_3, color_habilitado)
	label_locked_hint_3.visible = false
	button_hint_2.visible = false

	label_10000.visible = true
	label_coins.visible = true
	label_coste.visible = true
	
	set_alpha(label_10000, 1)
	set_alpha(label_coins, 1)
	set_alpha(label_coste, 1)
	
	coin.visible = true
	set_alpha(coin, 1)
	
## Cambia solo el color de fondo del Label en el estilo "normal".
func set_label_bg_only(lbl: Label, col: Color) -> void:
	var base := lbl.get_theme_stylebox("normal")
	if base:
		var copy := base.duplicate()
		if copy is StyleBoxFlat:
			var flat := copy as StyleBoxFlat
			flat.bg_color = col
			lbl.add_theme_stylebox_override("normal", flat)
		else:
			# Si el estilo del tema no es Flat (p.ej. Texture), creamos uno nuevo
			var flat := StyleBoxFlat.new()
			for s in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				flat.set_content_margin(s, base.get_content_margin(s))
			flat.bg_color = col
			lbl.add_theme_stylebox_override("normal", flat)
	else:
		# El Label no tenía fondo: crea uno plano
		var flat := StyleBoxFlat.new()
		flat.bg_color = col
		# opcional: esquinas redondeadas / borde si quieres
		# flat.set_corner_radius_all(12)
		# flat.set_border_width_all(1); flat.border_color = Color.hex("E2C58C")
		lbl.add_theme_stylebox_override("normal", flat)

func set_alpha(node: CanvasItem, a: float) -> void:
	a = clampf(a, 0.0, 1.0)
	var c: Color = node.modulate
	c.a = a
	node.modulate = c
	
func _on_button_hint_3_pressed():
	
	if GameManager.coins >= 5:
		var coins:int = GameManager.coins
		GameManager.set_coins(coins - 5)
		SignalManager.update_coins.emit()
		GameManager.register_hint_used("hint_3")
		GameManager.set_pista3()
	else:
		return
	GameManager.set_pistas_utilizadas(2)
	rich_text_label_hint_3.text = GameManager.hint_2
	_state_hint3()
	SignalManager.compra_pista_3.emit(GameManager.tiempo_partida)
	
func _state_hint3() -> void:
	rich_text_label_hint_2.text = GameManager.hint_1
	rich_text_label_hint_3.text = GameManager.hint_2
	label_unkocked_hint_1.visible = true
	label_unkocked_hint_2.visible = true
	label_paid_2.visible = true
	label_unkocked_hint_3.visible = true
	label_paid.visible = true
	
	label_locked_hint_3.visible = true
	label_available_hint_2.visible = false
	
	button_hint_3.visible = false
	
	candado.visible = false
	label_available_hint_3.visible = false
	set_label_bg_only(cuadro_hint_1, color_habilitado)
	set_label_bg_only(cuadro_hint_2, color_habilitado)
	set_label_bg_only(cuadro_hint_3, color_habilitado)
	label_locked_hint_3.visible = false
	button_hint_2.visible = false

	label_10000.visible = true
	label_coins.visible = true
	label_coste.visible = true
	
	set_alpha(label_10000, 1)
	set_alpha(label_coins, 1)
	set_alpha(label_coste, 1)
	
	coin.visible = true
	set_alpha(coin, 1)


func _on_button_pressed():
	print("IMAGEN TOCADA")
	cuadro_image_big.visible = true

func _on_button_image_big_pressed():
	cuadro_image_big.visible = false
