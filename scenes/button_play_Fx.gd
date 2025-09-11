extends TextureButton

@export var interval_seconds := 2.0
@export var sheen_duration := 0.4
@export var sheen_angle_deg := 45
@export var blink_duration := 0.2
@export var blink_scale := 1.01
@export var blink_rotation_deg := 2.0

@export var enable_sheen := true
@export var enable_scale := true
@export var enable_rotation := true


var _timer: Timer
var _sheen: TextureRect

func _ready() -> void:
	pivot_offset = size / 2.0
	resized.connect(_on_resized)

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

# -------------------- Reflejo (sheen con máscara) --------------------

func _create_sheen() -> void:
	_sheen = TextureRect.new()
	_sheen.name = "Sheen"
	_sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheen.stretch_mode = TextureRect.STRETCH_SCALE
	_sheen.visible = false
	add_child(_sheen)

	# Crear shader que recorta por alfa del botón
	var shader := Shader.new()
	shader.code = """
		shader_type canvas_item;
		render_mode blend_add;

		uniform sampler2D mask_tex;
		uniform float progress : hint_range(-0.3,1.3) = -0.3;
		uniform float width : hint_range(0.0,1.0) = 0.22;
		uniform float angle_deg : hint_range(-90.0,90.0) = 30.0;
		uniform float intensity : hint_range(0.0,2.0) = 0.9;

		void fragment() {
			// gradiente blanco
			vec4 sheen = texture(TEXTURE, UV);
			// alfa del botón (mask)
			float mask_a = texture(mask_tex, UV).a;
			sheen.a *= mask_a;
			COLOR = sheen;
		}
	"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_sheen.material = mat

	# Gradiente del sheen
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1,1,1,0), Color(1,1,1,0.85), Color(1,1,1,0)])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.width = 128
	gtex.height = 1024
	_sheen.texture = gtex

	# Asignar como máscara la textura normal del botón
	if texture_normal:
		mat.set_shader_parameter("mask_tex", texture_normal)

func _resize_sheen() -> void:
	if _sheen == null:
		clip_contents = true
		return
	var diag := size.length() * 1.6
	_sheen.size = Vector2(diag, diag)
	_sheen.rotation_degrees = sheen_angle_deg
	clip_contents = true

func _run_sheen() -> void:
	var mat := material as ShaderMaterial
	if mat:
		# Asegura que al empezar está invisible
		mat.set_shader_parameter("alpha", 0.0)

		var t := create_tween()
		# 1) Animar progress
		t.tween_method(
			func(v): mat.set_shader_parameter("progress", v),
			-0.3, 1.3, sheen_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# 2) En paralelo subir/bajar alpha para que solo se vea mientras pasa
		var t_alpha := create_tween()
		t_alpha.tween_property(mat, "shader_parameter/alpha", 0.4, sheen_duration * 0.5)
		t_alpha.tween_property(mat, "shader_parameter/alpha", 0.0, sheen_duration * 0.5)


# -------------------- Blink (escala + rotación con rebote) --------------------

func _run_blink() -> void:
	var third := blink_duration / 3.0

	# Escala
	if enable_scale:
		var t_scale := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t_scale.tween_property(self, "scale", Vector2(blink_scale, blink_scale), third * 1.5)
		t_scale.tween_property(self, "scale", Vector2.ONE, third * 1.5)

	# Rotación con rebote suave: 0 -> +θ -> -θ -> 0
	if enable_rotation:
		var t_rot := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t_rot.tween_property(self, "rotation_degrees", blink_rotation_deg, third)
		t_rot.tween_property(self, "rotation_degrees", -blink_rotation_deg, third)
		t_rot.tween_property(self, "rotation_degrees", 0.0, third)
