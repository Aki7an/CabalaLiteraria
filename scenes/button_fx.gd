extends Button

# ====== SINCRONIZACIÓN ENTRE BOTONES ======
@export var intervaloentrebotones: float = 0.2        # separación entre inicios (s)
@export var tiempodeinicio: float = 1                 # retraso base antes de empezar (s)
const GROUP_SYNC := "IntroSyncButtons"                 # grupo común

# ====== CONFIG INICIO (una sola vez) ======
# (Los antiguos tiempo_resaltar_* ya no se usan; se deja la sync por Y + intervaloentrebotones)
@export var enable_intro_sheen: bool = false
@export var sheen_duration: float = 0.4
@export var sheen_angle_deg: float = 45.0
@export var use_icon_as_mask: bool = false  # usar icon del Button como máscara

@export var enable_intro_scale: bool = true
@export var enable_intro_rotation: bool = true
@export var intro_anim_time: float = 0.2
@export var intro_scale_factor: float = 1.05
@export var intro_rotation_deg: float = 2.0

# ====== INTERNOS ======
var _sheen: TextureRect

func _ready() -> void:
	pivot_offset = size / 2.0
	resized.connect(_on_resized)

	if enable_intro_sheen:
		_create_sheen()
	_resize_sheen()

	add_to_group(GROUP_SYNC)
	await get_tree().process_frame
	_schedule_intro_all_synced()

func _on_resized() -> void:
	pivot_offset = size / 2.0
	_resize_sheen()

# ===================== EFECTOS INTRO SINCRONIZADOS =====================
func _schedule_intro_all_synced() -> void:
	var members: Array = get_tree().get_nodes_in_group(GROUP_SYNC)
	var controls: Array = []
	for n in members:
		if n is Control and n.is_inside_tree() and (n as Control).is_visible_in_tree():
			controls.append(n)

	# Orden: primero por Y asc (arriba→abajo), empate por X
	controls.sort_custom(func(a, b):
		var ca: Control = a
		var cb: Control = b
		if ca.global_position.y == cb.global_position.y:
			return ca.global_position.x < cb.global_position.x
		return ca.global_position.y < cb.global_position.y
	)

	var my_index: int = controls.find(self)
	if my_index == -1:
		my_index = 0

	# Delay total = tiempodeinicio + (índice * intervaloentrebotones)
	var delay_s: float = max(0.0, tiempodeinicio) + max(0.0, float(my_index)) * max(0.0, intervaloentrebotones)
	_intro_all_once(delay_s)

func _intro_all_once(delay_s: float) -> void:
	await get_tree().create_timer(delay_s).timeout

	var tweens: Array = []

	if enable_intro_scale:
		var tw_s := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_s.tween_property(self, "scale", Vector2(intro_scale_factor, intro_scale_factor), intro_anim_time)
		tw_s.tween_property(self, "scale", Vector2.ONE, intro_anim_time)
		tweens.append(tw_s)

	if enable_intro_rotation:
		var tw_r := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		tw_r.tween_property(self, "rotation_degrees", intro_rotation_deg, intro_anim_time * 0.8)
		tw_r.tween_property(self, "rotation_degrees", 0.0,              intro_anim_time * 0.8)
		tweens.append(tw_r)

	if enable_intro_sheen:
		_run_sheen()

	for t in tweens:
		await (t as Tween).finished

# -------------------- Sheen (brillo diagonal) --------------------
func _create_sheen() -> void:
	if _sheen != null:
		return
	_sheen = TextureRect.new()
	_sheen.name = "Sheen"
	_sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheen.stretch_mode = TextureRect.STRETCH_SCALE
	_sheen.visible = false
	_sheen.modulate = Color(1,1,1,0.0)
	add_child(_sheen)

	var shader := Shader.new()
	shader.code = """
		shader_type canvas_item;
		render_mode blend_add;

		uniform bool use_mask = false;
		uniform sampler2D mask_tex;

		uniform float progress : hint_range(-0.3,1.3) = -0.3;
		uniform float width    : hint_range(0.05,1.0) = 0.22;
		uniform float angle_deg : hint_range(-90.0,90.0) = 30.0;
		uniform float intensity : hint_range(0.0,2.0) = 0.9;

		void fragment() {
			float ang = radians(angle_deg);
			vec2 uv0 = UV - vec2(0.5);
			mat2 R = mat2(cos(ang), -sin(ang), sin(ang), cos(ang));
			vec2 uv = R * uv0 + vec2(0.5);

			float band_x = (uv.x - progress) / width;
			vec2 g_uv = vec2(clamp(band_x, 0.0, 1.0), uv.y);
			vec4 g = texture(TEXTURE, g_uv);

			float mask_a = 1.0;
			if (use_mask) { mask_a = texture(mask_tex, UV).a; }

			COLOR = vec4(vec3(1.0), g.a * intensity * mask_a);
		}
	"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("angle_deg", sheen_angle_deg)
	mat.set_shader_parameter("width", 0.20)
	mat.set_shader_parameter("intensity", 0.9)

	if use_icon_as_mask and icon != null:
		mat.set_shader_parameter("mask_tex", icon)
		mat.set_shader_parameter("use_mask", true)
	else:
		mat.set_shader_parameter("use_mask", false)

	_sheen.material = mat

	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1,1,1,0), Color(1,1,1,0.85), Color(1,1,1,0)])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])

	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.width = 512
	gtex.height = 1024
	_sheen.texture = gtex

func _resize_sheen() -> void:
	if _sheen == null:
		# Sin reflejo no hay nada que recortar. Mantenerlo activo corta las
		# sombras de los StyleBoxFlat únicamente durante la ejecución.
		clip_contents = false
		return
	clip_contents = true
	var diag: float = size.length() * 1.6
	_sheen.size = Vector2(diag, diag)
	_sheen.rotation_degrees = sheen_angle_deg

func _run_sheen() -> void:
	if _sheen == null:
		return
	var mat: ShaderMaterial = _sheen.material as ShaderMaterial
	if mat == null:
		return

	_sheen.visible = true
	_sheen.modulate.a = 0.0

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("progress", v),
		-0.3, 1.3, sheen_duration
	)

	var t_alpha := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t_alpha.tween_property(_sheen, "modulate:a", 0.45, sheen_duration * 0.5)
	t_alpha.tween_property(_sheen, "modulate:a", 0.0,  sheen_duration * 0.5)

	await t_alpha.finished
	_sheen.visible = false
