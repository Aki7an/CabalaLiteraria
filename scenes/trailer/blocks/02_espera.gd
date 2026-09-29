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
	clip_contents = false
	var phone := FX.trailer_phone(self)
	var title := %TitleEspera as Label
	STYLE.apply_body(title, STYLE.SIZE_BODY)
	title.text = COPY.text("TRAILER_CIPHER")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.z_as_relative = false
	title.z_index = 24
	if phone:
		phone.show_game_background()
		phone.z_as_relative = false
		phone.z_index = 20
	title.size = Vector2(1760.0, 120.0)
	title.position = Vector2(80.0, 40.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	await FX.fade_in(self, title, T.CIPHER_CAPTION_IN)
	await FX.wait(self, T.CIPHER_CAPTION_HOLD)
	await FX.fade_out(self, title, T.CIPHER_CAPTION_OUT)
	title.visible = false
	await FX.wait_remaining(self, started, T.SEC_02)
