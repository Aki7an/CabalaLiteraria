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
	var title := %TitleDescifra as Label
	var caption := %Caption as Label
	STYLE.apply_title(title, STYLE.SIZE_BEAT)
	STYLE.apply_body(caption, STYLE.SIZE_BODY)
	title.text = COPY.text("TRAILER_DESCIFRA")
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
	caption.text = COPY.text("TRAILER_HYPOTHESIS")
	caption.modulate.a = 0.0
	title.modulate.a = 0.0
	await FX.fade_in(self, title, T.CAPTION_IN)
	await FX.fade_in(self, caption, T.CAPTION_IN)
	await _reveal_if_needed(phone, "O", FX.INK)
	await FX.hide_hand(self)
	await FX.wait(self, T.REVEAL_GAP)
	caption.text = COPY.text("TRAILER_WORDS")
	await _reveal_if_needed(phone, "I", FX.INK)
	await FX.hide_hand(self)
	await FX.wait(self, T.REVEAL_GAP * 2.0)
	await FX.fade_out(self, title, T.BANNER_OUT)
	await FX.fade_out(self, caption, T.CAPTION_IN)
	await FX.wait_remaining(self, started, T.SEC_04)


func _reveal_if_needed(phone: Control, letter: String, color: Color) -> void:
	if phone == null:
		return
	if phone.letter_is_shown(letter):
		return
	await FX.phone_hand_tap_letter(self, phone, letter)
	await FX.phone_hand_tap_key(self, phone, letter)
	await FX.phone_reveal(self, phone, letter, color)
	FX.cue("letter")
