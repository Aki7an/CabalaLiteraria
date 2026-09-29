extends Control

const FX = preload("res://scenes/trailer/trailer_anim.gd")
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


func play_block() -> void:
	var started := Time.get_ticks_msec()
	FX.hide_legacy_stage(self)
	var phone := FX.trailer_phone(self)
	var title := %TitleDescubre as Label
	var caption := %Caption as Label
	STYLE.apply_title(title, STYLE.SIZE_BEAT)
	STYLE.apply_body(caption, STYLE.SIZE_QUOTE, STYLE.INK)
	title.text = COPY.text("TRAILER_DESCUBRE")
	caption.text = COPY.text("TRAILER_QUOTE")
	title.z_as_relative = false
	title.z_index = 24
	caption.z_as_relative = false
	caption.z_index = 24
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size = Vector2(1760.0, 110.0)
	title.position = Vector2(80.0, 36.0)
	caption.size = Vector2(1680.0, 180.0)
	caption.position = Vector2(120.0, 820.0)
	caption.modulate.a = 0.0
	title.modulate.a = 0.0
	var sm: Node = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("trailer_music_swell"):
		sm.trailer_music_swell(-2.0, 0.8)
	await _pulse_module()
	if phone:
		phone.reveal_all_remaining(FX.INK)
	FX.cue("discover")
	_burst_stars()
	await FX.hide_hand(self)
	await _clear_stage_for_quote(phone)
	await FX.fade_in(self, title, T.BANNER_IN)
	await FX.fade_in(self, caption, T.CAPTION_IN)
	await FX.wait(self, T.QUOTE_HOLD)
	await FX.fade_out(self, title, T.BANNER_OUT)
	await FX.fade_out(self, caption, T.CAPTION_IN)
	await FX.wait_remaining(self, started, T.SEC_06)


func _clear_stage_for_quote(phone: Control) -> void:
	if phone:
		var tw := create_tween()
		tw.tween_property(phone, "modulate:a", 0.0, T.CAM_SEC)
		await tw.finished
		phone.visible = false
	var card := FX.trailer_theme_card(self)
	if card:
		card.visible = true
		var dest := Vector2(650.0, 156.0)
		var fade := create_tween()
		fade.set_parallel(true)
		fade.tween_property(card, "position", dest, T.CAM_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		fade.tween_property(card, "scale", Vector2(1.0, 1.0), T.CAM_SEC)
		fade.tween_property(card, "modulate:a", 1.0, T.CAM_SEC * 0.5)
		await fade.finished


func _pulse_module() -> void:
	var card := FX.trailer_theme_card(self)
	if card == null:
		return
	var module := card.get_node_or_null("ModuleHighlight") as CanvasItem
	if module == null:
		return
	module.visible = true
	var tw := create_tween()
	tw.tween_property(module, "modulate:a", 1.0, T.FOOTPRINT_IN)
	tw.tween_property(module, "modulate:a", 0.4, 0.12)
	tw.tween_property(module, "modulate:a", 1.0, 0.12)
	await tw.finished


func _burst_stars() -> void:
	var stars := %Stars
	for star in stars.get_children():
		if not star is CanvasItem:
			continue
		star.visible = true
		star.modulate.a = 1.0
		star.position = Vector2(960, 560)
		var angle := TAU * float(star.get_index()) / float(maxi(stars.get_child_count(), 1))
		var dest := Vector2(960, 560) + Vector2(cos(angle), sin(angle)) * 320.0
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(star, "position", dest, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(star, "modulate:a", 0.0, 0.85)
