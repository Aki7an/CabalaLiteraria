extends Button

@onready var lbl: Label        = $Label            # ajusta si tu ruta es otra
@onready var tex: TextureRect  = $TextureRect      # ajusta si tu ruta es otra

var _ready_done: bool = false

func _ready() -> void:
	# Arranca deshabilitado y atenuado
	_apply_disabled_state(true)

	# Conecta DEFERRED para evitar timing issues
	SignalManager.update_rubber.connect(_on_update_rubber, CONNECT_DEFERRED)

	_ready_done = true

func _exit_tree() -> void:
	if SignalManager.update_rubber.is_connected(_on_update_rubber):
		SignalManager.update_rubber.disconnect(_on_update_rubber)

# Señal: puede venir con bool o sin parámetro
func _on_update_rubber(can_erase_opt: Variant = null) -> void:
	print("SIGNAL RUBBER")
	#if !_ready_done: 
		#return

	var can_erase: bool = GameManager.hay_letra_que_borrar()
	#if can_erase_opt != null:
		#can_erase = GameManager.hay_letra_que_borrar()
	## Si no llega parámetro, puedes decidir tu política (p.ej. mantener false)

	_apply_disabled_state(not can_erase)

func _apply_disabled_state(disabled_state: bool) -> void:
	self.disabled = disabled_state
	var a: float = 0.3 if disabled_state else 1.0
	_set_alpha_if_valid(lbl, a)
	_set_alpha_if_valid(tex, a)

func _set_alpha_if_valid(node: CanvasItem, a: float) -> void:
	if !is_instance_valid(node):
		return
	# Lee/escribe el color desde "visibility/modulate"
	var col: Color = node.modulate
	col.a = a
	node.modulate = col


#func _ready():
	##btn_erase.disabled = true
	#SignalManager.update_rubber.connect(_update_rubber)
	#_prev_disabled = btn_erase.disabled
	#_sync_label_alpha()
	##set_process(true)  # vigilamos cambios en tiempo real
	#
	#
#func _on_pressed():
	#SignalManager.update_canvas_grid.emit(1)
	#
#func _update_rubber() -> void:
	##btn_erase.disabled = false
	#btn_erase.disabled = disabled
	#var c :Color= label.modulate
	#c.a = 0.3 if disabled else 1.0
	#label.modulate = c
#
#
#
#func _sync_label_alpha() -> void:
	#var c : Color= label.modulate
	#c.a = 0.3 if btn_erase.disabled else 1.0
	#label.modulate = c
