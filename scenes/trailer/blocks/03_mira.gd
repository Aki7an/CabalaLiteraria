extends Control

const FX = preload("res://scenes/trailer/trailer_anim.gd")
const CAM = preload("res://scenes/trailer/trailer_camera.gd")
const T = preload("res://scenes/trailer/trailer_timing.gd")
const STYLE = preload("res://scenes/trailer/trailer_style.gd")
const COPY = preload("res://scenes/trailer/trailer_copy.gd")


func _enter_tree() -> void:
	if owner == null:
		FX.apply_fullhd(self)


func _ready() -> void:
	if owner == null:
		FX.apply_fullhd(self)
		await play_block()


func uses_previous_board() -> bool:
	return true


func keep_on_stage() -> bool:
	return true


func play_block() -> void:
	var started := Time.get_ticks_msec()
	_hide_own_stage()
	var phone := FX.trailer_phone(self)
	if phone:
		phone.z_as_relative = false
		phone.z_index = 20
	var title := %TitleMira as Label
	STYLE.apply_title(title, STYLE.SIZE_BEAT)
	title.text = COPY.text("TRAILER_MIRA")
	title.z_as_relative = false
	title.z_index = 8
	title.size = Vector2(780.0, 140.0)
	var start := Vector2(-820.0, 40.0)
	var center := Vector2(56.0, 40.0)
	var exit := Vector2(1920.0, 40.0)
	title.position = start
	title.visible = true
	title.modulate.a = 1.0
	await FX.fly_banner_in(self, title, start, center, T.MIRA_IN)
	FX.cue("image")
	await _split_to_moon(phone)
	_fly_mira_out(title, exit)
	await _pulse_highlight(_theme_node("FootprintHighlight"))
	await _link_footprint_to_board(phone)
	await _type_huella(phone)
	FX.cue("huella")
	await FX.wait(self, T.HUELLA_FINISH)
	if has_node("%Hand"):
		%Hand.visible = false
	await FX.wait_remaining(self, started, T.SEC_03)


func _split_to_moon(phone: Control) -> void:
	var card := %ThemeCard as Control
	if card:
		card.z_as_relative = false
		card.z_index = 16
		card.visible = true
		card.modulate.a = 0.0
		card.scale = Vector2(1.05, 1.05)
		card.position = Vector2(-920.0, 88.0)
	if phone:
		phone.show_play_chrome()
	var dest_phone: Dictionary = phone.phone_right_xform() if phone and phone.has_method("phone_right_xform") else {}
	var slide := create_tween()
	slide.set_parallel(true)
	if phone and not dest_phone.is_empty():
		slide.tween_property(phone, "scale", dest_phone["scale"], T.PHONE_MOVE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		slide.tween_property(phone, "position", dest_phone["position"], T.PHONE_MOVE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if card:
		slide.tween_property(card, "position", Vector2(28.0, 88.0), T.PHONE_MOVE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		slide.tween_property(card, "scale", Vector2(1.46, 1.46), T.PHONE_MOVE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		slide.tween_property(card, "modulate:a", 1.0, T.THEME_IN)
	await slide.finished
	if phone:
		CAM.store_rest(phone)
		if phone.has_method("pin_board_canvas"):
			phone.pin_board_canvas()


func _link_footprint_to_board(phone: Control) -> void:
	if phone == null:
		return
	var foot := _theme_node("FootprintHighlight") as Control
	var cell: Control = phone.first_cell("H")
	if foot == null or cell == null:
		return
	var line := _ensure_link()
	var from := foot.get_global_rect().get_center() - global_position
	var to := cell.get_global_rect().get_center() - global_position
	line.points = PackedVector2Array([from, to])
	line.visible = true
	line.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(line, "modulate:a", 1.0, T.LINK_SEC)
	tw.tween_property(line, "modulate:a", 0.0, T.LINK_SEC)
	await tw.finished
	line.visible = false


func _ensure_link() -> Line2D:
	var line := get_node_or_null("TrailerLink") as Line2D
	if line:
		return line
	line = Line2D.new()
	line.name = "TrailerLink"
	line.width = 5.0
	line.default_color = STYLE.NOTE
	line.z_as_relative = false
	line.z_index = 30
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(line)
	return line


func _type_huella(phone: Control) -> void:
	if phone == null:
		return
	for letter in ["H", "U", "E", "L", "A"]:
		if phone.letter_is_shown(letter):
			continue
		var cell: Control = phone.first_cell(letter)
		var key: Control = phone.letter_key(letter)
		await FX.hand_tap(self, cell, T.HAND_QUICK)
		await FX.hand_tap(self, key, T.HAND_QUICK)
		phone.reveal_letter(letter, FX.INK, true)
		FX.cue("letter")
		await FX.wait(self, T.HUELLA_STEP)


func _fly_mira_out(title: Control, exit: Vector2) -> void:
	var fly := create_tween()
	fly.tween_interval(T.MIRA_HOLD)
	fly.tween_property(title, "position", exit, T.MIRA_OUT).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fly.finished.connect(func() -> void: title.visible = false)


func _pulse_highlight(node: CanvasItem) -> void:
	if node == null:
		return
	node.visible = true
	node.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", 1.0, T.FOOTPRINT_IN)
	tw.tween_property(node, "modulate:a", 0.5, 0.1)
	tw.tween_property(node, "modulate:a", 1.0, 0.1)
	await tw.finished


func _theme_node(node_name: String) -> CanvasItem:
	var card := %ThemeCard as Node
	if card == null:
		return null
	return card.get_node_or_null(node_name) as CanvasItem


func _hide_own_stage() -> void:
	FX.hide_legacy_stage(self)
	if has_node("%Caption"):
		%Caption.visible = false
	if has_node("%ThemeCard"):
		%ThemeCard.visible = false
		%ThemeCard.modulate.a = 0.0
	if has_node("%Hand"):
		%Hand.visible = false
		%Hand.z_as_relative = false
		%Hand.z_index = 40
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
