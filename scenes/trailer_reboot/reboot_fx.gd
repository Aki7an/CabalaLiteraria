extends Object

const T = preload("res://scenes/trailer_reboot/reboot_timing.gd")
const FULLHD := Vector2i(1920, 1080)


static func apply_fullhd(host: Node) -> void:
	if host == null:
		return
	var win := host.get_window()
	if win == null:
		return
	win.mode = Window.MODE_WINDOWED
	win.min_size = FULLHD
	win.size = FULLHD
	win.content_scale_size = FULLHD
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	if host is Control:
		(host as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func wait(host: Node, sec: float) -> void:
	if host == null or host.get_tree() == null or sec <= 0.0:
		return
	await host.get_tree().create_timer(sec, true, true).timeout


static func wait_remaining(host: Node, timer: SceneTreeTimer) -> void:
	if host == null or timer == null:
		return
	if timer.time_left > 0.0:
		await timer.timeout


static func beat_timer(host: Node, duration: float) -> SceneTreeTimer:
	if host == null or host.get_tree() == null:
		return null
	return host.get_tree().create_timer(duration, true, true)


static func fade(host: Node, node: CanvasItem, alpha: float, sec: float) -> void:
	if node == null:
		return
	node.visible = true
	var tw := host.create_tween()
	tw.tween_property(node, "modulate:a", alpha, sec)
	await tw.finished
	if is_zero_approx(alpha):
		node.visible = false


static func cue(event_name: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var sm: Node = tree.root.get_node_or_null("SoundManager") if tree else null
	if sm == null:
		return
	match event_name:
		"hook", "moon", "categories", "mosaic", "logo":
			if sm.has_method("play"):
				sm.play("ButtonClick")
		"letter", "huella":
			if sm.has_method("play"):
				sm.play("ClickLetra")
		"error":
			if sm.has_method("play_red_letter_click"):
				sm.play_red_letter_click()
			elif sm.has_method("play"):
				sm.play("ClickLetra")
		"correct", "discover":
			if sm.has_method("play"):
				sm.play("PlayAvailable")
		_:
			pass
