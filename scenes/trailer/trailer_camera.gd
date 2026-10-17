extends Object

const FX = preload("res://scenes/trailer/trailer_anim.gd")
const T = preload("res://scenes/trailer/trailer_timing.gd")


static func store_rest(phone: Control) -> void:
	if phone == null:
		return
	phone.set_meta("cam_rest_scale", phone.scale)
	phone.set_meta("cam_rest_pos", phone.position)


static func rest_xform(phone: Control) -> Dictionary:
	if phone and phone.has_meta("cam_rest_scale"):
		return {
			"scale": phone.get_meta("cam_rest_scale"),
			"position": phone.get_meta("cam_rest_pos"),
		}
	if phone and phone.has_method("phone_right_xform"):
		return phone.phone_right_xform()
	return {"scale": Vector2.ONE, "position": Vector2.ZERO}


static func apply(host: Node, phone: Control, dest: Dictionary, sec: float = T.CAM_SEC) -> void:
	await _tween_phone(host, phone, dest, sec)
	store_rest(phone)


static func mira(host: Node, phone: Control, sec: float = T.CAM_SEC) -> void:
	if phone and phone.has_method("mira_phone_xform"):
		await apply(host, phone, phone.mira_phone_xform(), sec)
	else:
		await wide(host, phone, sec)


static func play_board(host: Node, phone: Control, sec: float = T.CAM_SEC) -> void:
	if phone and phone.has_method("board_play_xform"):
		await apply(host, phone, phone.board_play_xform(), sec)
	else:
		await wide(host, phone, sec)


static func wide(host: Node, phone: Control, sec: float = T.CAM_SEC) -> void:
	await _tween_phone(host, phone, rest_xform(phone), sec)


static func board(host: Node, phone: Control, zoom: float = 1.22, sec: float = T.CAM_SEC) -> void:
	if phone == null:
		return
	var board := phone.get_node_or_null("BoardFrame") as Control
	var local := Vector2(603, 880)
	if board:
		local = board.position + board.size * 0.5
	await focus_local(host, phone, local, zoom, sec)


static func word(host: Node, phone: Control, token: String, zoom: float = 1.38, sec: float = T.CAM_SEC) -> void:
	if phone == null or not phone.has_method("cells_spelling"):
		return
	var found: Array = phone.cells_spelling(token)
	if found.is_empty():
		await board(host, phone, zoom, sec)
		return
	var acc := Vector2.ZERO
	var count := 0
	for cell in found:
		if cell is Control:
			acc += _to_phone_local(phone, (cell as Control).get_global_rect().get_center())
			count += 1
	if count == 0:
		await board(host, phone, zoom, sec)
		return
	await focus_local(host, phone, acc / float(count), zoom, sec)


static func focus_local(host: Node, phone: Control, local_pt: Vector2, zoom: float, sec: float) -> void:
	var rest: Dictionary = rest_xform(phone)
	var rest_scale: Vector2 = rest["scale"]
	var new_scale := rest_scale * zoom
	var target := Vector2(1240.0, 500.0)
	var dest := {
		"scale": new_scale,
		"position": target - local_pt * new_scale.x,
	}
	await _tween_phone(host, phone, dest, sec)


static func _to_phone_local(phone: Control, global_pt: Vector2) -> Vector2:
	return phone.get_global_transform().affine_inverse() * global_pt


static func _tween_phone(host: Node, phone: Control, dest: Dictionary, sec: float) -> void:
	if host == null or phone == null:
		return
	if sec <= 0.0:
		phone.scale = dest["scale"]
		phone.position = dest["position"]
		return
	var tw := host.create_tween()
	tw.set_parallel(true)
	tw.tween_property(phone, "scale", dest["scale"], sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(phone, "position", dest["position"], sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if phone.has_method("pin_board_canvas"):
		phone.pin_board_canvas()
