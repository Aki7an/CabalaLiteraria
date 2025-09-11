extends OptionButton

@export var interval_seconds := 3.0
@export var sheen_duration := 0.8
@export var sheen_angle_deg := 30.0
@export var blink_duration := 0.45
@export var blink_scale := 1.06
@export var blink_rotation_deg := 2.0

@export var enable_sheen := true
@export var enable_scale := true
@export var enable_rotation := true

var _timer: Timer
var _sheen: TextureRect

func _ready() -> void:
	# Centro para rotación/escala del propio OptionButton
	pivot_offset = size / 2.0
	resized.connect(_on_resized)

	# Activa recorte para “cortar” el brillo a la forma del botón
	clip_contents = true

	if enable_sheen:
		_create_sheen()
	_resize_sheen()
	_create_timer()

func _on_resized() -> void:
	pivot_offset = size / 2.0
	_resize_sheen()

func _create_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = interval_seconds
	_timer.one_shot = false
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_on_pulse)

func _on_pulse() -> void:
	if enable_sheen:
		_run_sheen()
	if enable_scale or enable_rotation:
		_run_blink()

# -------------------- Sheen (brillo sin shader, con gradiente) --------------------

func _create_sheen() -> void:
	_sheen = TextureRect.new()
	_sheen.name = "Sheen"
	_sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheen.stretch_mode = TextureRect.STRETCH_SCALE
	_sheen.visible = true
	_sheen.modulate.a = 0.0
	add_child(_sheen)

	# Gradiente vertical blanco translúcido (fina franja brillante)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(1,1,1,0.0),
		Color(1,1,1,0.85),
		Color(1,1,1,0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])

	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.width = 96      # ancho de la franja
	gtex.height = 1024   # alto grande para no pixelar al rotar
	_sheen.texture = gtex

	# Material aditivo para “sumar luz” al pasar
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_sheen.material = mat

func _resize_sheen() -> void:
	if _sheen == null:
		return

	# Tamaño y orientación de la franja de brillo
	var diag := size.length() * 1.3
	_sheen.size = Vector2( diag * 0.28, diag ) # franja relativamente estrecha y alta
	_sheen.pivot_offset = _sheen.size / 2.0
	_sheen.rotation_degrees = sheen_angle_deg

	# Partimos fuera del botón por la izquierda
	# Posición base centrada y desplazada a la izquierda
	var start_x := -_sheen.size.x * 0.9
	_sheen.position = (size - _sheen.size) / 2.0 + Vector2(start_x, 0.0)

func _run_sheen() -> void:
	if _sheen == null:
		return

	# Recolocar al inicio (a la izquierda del botón)
	var base_pos := (size - _sheen.size) / 2.0
	var start_x := -_sheen.size.x * 0.9
	var end_x :=  size.x + _sheen.size.x * 0.9

	_sheen.position = base_pos + Vector2(start_x, 0.0)
	_sheen.modulate.a = 0.0

	# Tween de desplazamiento y alpha en paralelo
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_sheen, "position:x", base_pos.x + end_x, sheen_duration)

	var t_alpha := create_tween()
	t_alpha.tween_property(_sheen, "modulate:a", 0.45, sheen_duration * 0.5)
	t_alpha.tween_property(_sheen, "modulate:a", 0.0, sheen_duration * 0.5)

# -------------------- Blink (escala + rotación con rebote) --------------------

func _run_blink() -> void:
	var third := blink_duration / 3.0

	if enable_scale:
		var t_scale := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t_scale.tween_property(self, "scale", Vector2(blink_scale, blink_scale), third * 1.5)
		t_scale.tween_property(self, "scale", Vector2.ONE, third * 1.5)

	if enable_rotation:
		var t_rot := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t_rot.tween_property(self, "rotation_degrees", blink_rotation_deg, third)
		t_rot.tween_property(self, "rotation_degrees", -blink_rotation_deg, third)
		t_rot.tween_property(self, "rotation_degrees", 0.0, third)
