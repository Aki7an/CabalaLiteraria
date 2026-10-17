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
	var title := %TitleDeduce as Label
	var caption := %Caption as Label
	var cross := %Cross as Control
	STYLE.apply_title(title, STYLE.SIZE_BEAT)
	STYLE.apply_body(caption, STYLE.SIZE_BODY)
	title.text = COPY.text("TRAILER_DEDUCE")
	caption.text = COPY.text("TRAILER_TRY")
	title.z_as_relative = false
	title.z_index = 16
	caption.z_as_relative = false
	caption.z_index = 16
	title.size = Vector2(1760.0, 88.0)
	title.position = Vector2(80.0, 12.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.size = Vector2(1760.0, 56.0)
	caption.position = Vector2(80.0, 1004.0)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate.a = 0.0
	caption.modulate.a = 0.0
	cross.visible = false
	await FX.fade_in(self, title, T.CAPTION_IN)
	await FX.fade_in(self, caption, T.CAPTION_IN)
	await _try_mark_correct(phone, cross)
	await _reveal_if_needed(phone, "N", FX.INK)
	await FX.hide_hand(self)
	await FX.fade_out(self, title, T.CAPTION_IN)
	await FX.fade_out(self, caption, T.CAPTION_IN)
	await FX.wait_remaining(self, started, T.SEC_05)


func _try_mark_correct(phone: Control, cross: Control) -> void:
	if phone == null:
		return
	if phone.letter_is_shown("D"):
		return
	var first: Celda = phone.first_cell("D")
	if first == null:
		return
	await FX.hand_tap(self, first, T.HAND_QUICK)
	var key_b: Control = phone.letter_key("B")
	if key_b:
		await FX.hand_tap(self, key_b, T.HAND_QUICK)
	FX.cue("letter")
	var color_btn: Control = phone.color_button(4)
	if color_btn:
		await FX.hand_tap(self, color_btn, T.HAND_QUICK)
		FX.press(color_btn)
	phone.show_hypothesis("D", "B", STYLE.MARK)
	await FX.wait(self, 0.7)
	phone.show_wrong_on(first, "B")
	FX.cue("error")
	cross.global_position = first.get_global_rect().position + Vector2(8, -70)
	cross.visible = true
	cross.modulate.a = 1.0
	var mark := create_tween()
	mark.tween_property(cross, "position:y", cross.position.y - 30.0, T.ERROR_HOLD)
	mark.parallel().tween_property(cross, "modulate:a", 0.0, T.ERROR_HOLD)
	await FX.wait(self, T.ERROR_HOLD)
	phone.clear_hypothesis("D")
	await FX.hand_tap(self, first, T.HAND_QUICK)
	var key_d: Control = phone.letter_key("D")
	if key_d:
		await FX.hand_tap(self, key_d, T.HAND_QUICK)
	phone.reveal_letter("D", FX.INK, true)
	FX.cue("correct")
	await FX.wait(self, T.REVEAL_GAP)


func _reveal_if_needed(phone: Control, letter: String, color: Color) -> void:
	if phone == null:
		return
	if phone.letter_is_shown(letter):
		return
	await FX.phone_hand_tap_letter(self, phone, letter)
	await FX.phone_hand_tap_key(self, phone, letter)
	await FX.phone_reveal(self, phone, letter, color)
	FX.cue("letter")
