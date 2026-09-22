extends CanvasLayer

const STAR_TEX: Texture2D = preload("res://images/estrella_plano.png")
const CHIME_SFX: AudioStream = preload("res://audio/MultimediaChime_SFXB.2894.wav")
const HALO_SHADER: Shader = preload("res://autoload/star_collect_halo.gdshader")
const STAGGER_SEC := 0.5
const FLY_SEC := 0.92
const PRE_FLY_SEC := 0.4
const TRAIL_GAP := 0.02
const TRAIL_LIFE := 0.95
const TRAIL_LIFE_LONG := 1.35
const HALO_FADE_PX := 40.0
const TREMBLE_AMP := 5.0

var pending_count := 0
var pending_mode: String = ""
var from_total := -1
var to_total := -1
var _ghosts: Array[Control] = []
var _trembling: Array[Control] = []
var _playing := false
var _veil: ColorRect
var _veil_tween: Tween
var _tremble_time := 0.0


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_veil()


func _ensure_veil() -> void:
	if _veil != null and is_instance_valid(_veil):
		return
	_veil = ColorRect.new()
	_veil.name = "WhiteVeil"
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.color = Color(1, 1, 1, 0)
	_veil.z_index = 0
	_veil.visible = false
	add_child(_veil)
	move_child(_veil, 0)


func is_covering() -> bool:
	return _veil != null and _veil.visible and _veil.color.a > 0.01


func show_white_cover() -> void:
	_ensure_veil()
	if _veil_tween != null and _veil_tween.is_valid():
		_veil_tween.kill()
	move_child(_veil, 0)
	_veil.visible = true
	_veil.color = Color(1, 1, 1, 1)
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP


func collect_duration() -> float:
	var n := _ghosts.size()
	if n <= 0:
		return 0.85
	return PRE_FLY_SEC + STAGGER_SEC * float(n - 1) + FLY_SEC + TRAIL_LIFE_LONG


func fade_white_cover(duration: float = -1.0) -> void:
	_ensure_veil()
	if not _veil.visible:
		return
	if duration <= 0.0:
		duration = collect_duration()
	if _veil_tween != null and _veil_tween.is_valid():
		_veil_tween.kill()
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil_tween = create_tween()
	_veil_tween.tween_property(_veil, "color:a", 0.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await _veil_tween.finished
	if is_instance_valid(_veil):
		_veil.visible = false
		_veil.color = Color(1, 1, 1, 0)
		_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE


func has_pending() -> bool:
	return pending_count > 0 and not _ghosts.is_empty()


func displayed_total(actual: int, mode: String) -> int:
	if has_pending() and pending_mode == mode and from_total >= 0:
		return from_total
	if has_pending() and pending_mode == mode and pending_count > 0:
		return maxi(0, actual - pending_count)
	return actual


func remember_counter(mode: String, before: int, after: int) -> void:
	pending_mode = mode
	from_total = maxi(0, before)
	to_total = maxi(from_total, after)


func clear() -> void:
	_trembling.clear()
	for ghost in _ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	_ghosts.clear()
	pending_count = 0
	pending_mode = ""
	from_total = -1
	to_total = -1
	_playing = false


func capture_earned(source_stars: Array[TextureRect], earned: int, mode: String) -> void:
	_trembling.clear()
	for ghost in _ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	_ghosts.clear()
	pending_mode = mode if mode != "" else pending_mode
	pending_count = maxi(0, earned)
	if pending_count <= 0:
		return
	for i in range(mini(earned, source_stars.size())):
		var src := source_stars[i]
		if src == null or not is_instance_valid(src) or not src.visible:
			continue
		var rect := src.get_global_rect()
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.clip_contents = false
		holder.z_index = 40
		holder.position = rect.position
		holder.size = rect.size
		holder.pivot_offset = rect.size * 0.5
		var halo := ColorRect.new()
		halo.name = "Halo"
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		halo.z_index = 0
		halo.color = Color.WHITE
		var halo_mat := ShaderMaterial.new()
		halo_mat.shader = HALO_SHADER
		halo.material = halo_mat
		var ghost := TextureRect.new()
		ghost.name = "Star"
		ghost.texture = src.texture if src.texture else STAR_TEX
		ghost.self_modulate = src.self_modulate
		ghost.modulate = Color.WHITE
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.z_index = 1
		holder.add_child(halo)
		holder.add_child(ghost)
		add_child(holder)
		_layout_holder(holder, rect.size, rect.get_center())
		_ghosts.append(holder)
		_trembling.append(holder)


func _process(delta: float) -> void:
	if _trembling.is_empty():
		return
	_tremble_time += delta
	var i := 0
	while i < _trembling.size():
		var holder := _trembling[i]
		if not is_instance_valid(holder):
			_trembling.remove_at(i)
			continue
		var star := holder.get_node_or_null("Star") as TextureRect
		if star:
			var phase := float(i) * 1.7
			star.position = Vector2(
				sin(_tremble_time * 42.0 + phase) * TREMBLE_AMP,
				cos(_tremble_time * 35.0 + phase * 1.3) * TREMBLE_AMP
			)
		i += 1


func play_to_slots(targets: Array) -> void:
	if _playing:
		return
	_playing = true
	if _ghosts.is_empty() or targets.is_empty():
		clear()
		return
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(PRE_FLY_SEC).timeout
	for i in range(_ghosts.size()):
		if i > 0:
			await get_tree().create_timer(STAGGER_SEC).timeout
		var ghost := _ghosts[i]
		var target: Control = targets[i] if i < targets.size() else null
		if not is_instance_valid(ghost) or target == null or not is_instance_valid(target):
			continue
		var target_rect := target.get_global_rect()
		await _fly_star(ghost, target_rect.get_center(), target_rect.size)
		pending_count = maxi(0, pending_count - 1)
		_reveal_slot(target)
		if is_instance_valid(ghost):
			ghost.queue_free()
	_ghosts.clear()
	pending_count = 0
	from_total = -1
	to_total = -1
	pending_mode = ""
	_playing = false


func _reveal_slot(target: Control) -> void:
	if target == null or not is_instance_valid(target):
		return
	target.modulate.a = 1.0
	target.visible = true
	_play_chime()
	_flash_node(target)
	_scale_blink(target)


func play_to_target(target: Control, counter: Label, start_value: int) -> void:
	if _playing:
		return
	_playing = true
	if target == null or _ghosts.is_empty():
		clear()
		return
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(PRE_FLY_SEC).timeout
	var target_rect := target.get_global_rect()
	var end_center := target_rect.get_center()
	var end_size := target_rect.size
	var value := start_value
	for i in range(_ghosts.size()):
		if i > 0:
			await get_tree().create_timer(STAGGER_SEC).timeout
		var ghost := _ghosts[i]
		if not is_instance_valid(ghost):
			continue
		await _fly_star(ghost, end_center, end_size)
		value += 1
		pending_count = maxi(0, pending_count - 1)
		_hit_counter(counter, target, value)
		if is_instance_valid(ghost):
			ghost.queue_free()
	_ghosts.clear()
	pending_count = 0
	from_total = -1
	to_total = -1
	pending_mode = ""
	_playing = false


func _fly_star(holder: Control, end_center: Vector2, end_size: Vector2) -> void:
	_stop_tremble(holder)
	var star := holder.get_node_or_null("Star") as TextureRect
	if star:
		star.position = Vector2.ZERO
	var start_pos := holder.position
	var start_size := holder.size
	var start_center := start_pos + start_size * 0.5
	var delta := end_center - start_center
	var perp := Vector2(-delta.y, delta.x)
	if perp.length_squared() < 1.0:
		perp = Vector2(120.0, 0.0)
	else:
		perp = perp.normalized() * clampf(delta.length() * 0.22, 70.0, 180.0)
	if start_center.x > end_center.x:
		perp = -perp
	var control := (start_center + end_center) * 0.5 + perp
	var trail := {"at": 0.0}
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_method(
		func(t: float) -> void: _update_fly(holder, start_center, control, end_center, start_size, end_size, trail, t),
		0.0,
		1.0,
		FLY_SEC
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished


func _update_fly(
	holder: Control,
	start_center: Vector2,
	control: Vector2,
	end_center: Vector2,
	start_size: Vector2,
	end_size: Vector2,
	trail: Dictionary,
	t: float
) -> void:
	if not is_instance_valid(holder):
		return
	var eased := t * t
	var center := _quad_bezier(start_center, control, end_center, eased)
	var size := start_size.lerp(end_size, eased)
	_layout_holder(holder, size, center)
	if t < 0.001 or t - float(trail.get("at", 0.0)) >= TRAIL_GAP:
		trail["at"] = t
		_spawn_trail(holder)


func _layout_holder(holder: Control, size: Vector2, center: Vector2) -> void:
	holder.size = size
	holder.pivot_offset = size * 0.5
	holder.position = center - size * 0.5
	var star := holder.get_node_or_null("Star") as TextureRect
	if star:
		star.size = size
		star.pivot_offset = size * 0.5
		if not _trembling.has(holder):
			star.position = Vector2.ZERO
	var halo := holder.get_node_or_null("Halo") as ColorRect
	if halo:
		var halo_size := size + Vector2(HALO_FADE_PX, HALO_FADE_PX) * 2.0
		halo.size = halo_size
		halo.position = (size - halo_size) * 0.5
		var mat := halo.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("rect_size", halo_size)
			mat.set_shader_parameter("star_radius_px", minf(size.x, size.y) * 0.5)
			mat.set_shader_parameter("fade_px", HALO_FADE_PX)


func _stop_tremble(holder: Control) -> void:
	_trembling.erase(holder)


func _quad_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2


func _spawn_trail(holder: Control) -> void:
	if not is_instance_valid(holder):
		return
	var star := holder.get_node_or_null("Star") as TextureRect
	if star == null:
		return
	_spawn_trail_spark(star.texture, star.self_modulate, holder, 0.72, 0.62, TRAIL_LIFE)
	_spawn_trail_spark(star.texture, star.self_modulate, holder, 0.48, 0.42, TRAIL_LIFE_LONG)


func _spawn_trail_spark(
	tex: Texture2D,
	tint: Color,
	holder: Control,
	size_scale: float,
	start_alpha: float,
	life: float
) -> void:
	var spark := TextureRect.new()
	spark.texture = tex
	spark.self_modulate = tint
	spark.modulate = Color(1, 1, 1, start_alpha)
	spark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spark.size = holder.size * size_scale
	spark.pivot_offset = spark.size * 0.5
	spark.position = holder.position + (holder.size - spark.size) * 0.5
	spark.z_index = 30
	add_child(spark)
	var fade := create_tween()
	fade.tween_property(spark, "modulate:a", 0.0, life)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade.parallel().tween_property(spark, "scale", Vector2(0.72, 0.72), life)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade.finished.connect(spark.queue_free)


func _hit_counter(counter: Label, icon: Control, value: int) -> void:
	if to_total >= 0:
		value = mini(value, to_total)
	if counter:
		counter.text = str(value)
	_play_chime()
	_flash_node(counter)
	_flash_node(icon)
	_scale_blink(counter)
	_scale_blink(icon)


func _flash_node(node: CanvasItem) -> void:
	if node == null or not is_instance_valid(node):
		return
	var base := node.modulate
	var tween := create_tween()
	tween.tween_property(node, "modulate", Color(1.6, 1.45, 0.85, 1.0), 0.08)
	tween.tween_property(node, "modulate", base, 0.16)
	tween.tween_property(node, "modulate", Color(1.35, 1.22, 0.75, 1.0), 0.08)
	tween.tween_property(node, "modulate", base, 0.18)


func _scale_blink(node: Control) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	var tween := create_tween()
	tween.tween_property(node, "scale", Vector2(1.28, 1.28), 0.10)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.14)
	tween.tween_property(node, "scale", Vector2(1.16, 1.16), 0.08)
	tween.tween_property(node, "scale", Vector2.ONE, 0.12)


func _play_chime() -> void:
	if CHIME_SFX == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = "SoundFx"
	player.stream = CHIME_SFX
	player.volume_db = -6.0
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
