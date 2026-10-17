extends Control

const FX = preload("res://scenes/trailer/trailer_anim.gd")
const T = preload("res://scenes/trailer/trailer_timing.gd")
const STYLE = preload("res://scenes/trailer/trailer_style.gd")


func _enter_tree() -> void:
	if owner == null:
		FX.apply_fullhd(self)


func _ready() -> void:
	if owner == null:
		FX.apply_fullhd(self)
		await play_block()


func play_block() -> void:
	var started := Time.get_ticks_msec()
	FX.cue("categories")
	var row := %Cards
	for card in row.get_children():
		var title := card.get_node_or_null("Title") as Label
		if title:
			STYLE.apply_title(title, 34)
	row.position = %CardsStart.position
	row.modulate.a = 0.0
	var inn := create_tween()
	inn.set_parallel(true)
	inn.tween_property(row, "modulate:a", 1.0, T.CAPTION_IN)
	inn.tween_property(row, "position", %CardsShown.position, T.BANNER_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await FX.wait(self, T.CARDS_HOLD)
	var leave := create_tween()
	leave.set_parallel(true)
	leave.tween_property(row, "position", %CardsExit.position, T.BANNER_OUT).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	leave.tween_property(row, "modulate:a", 0.0, T.CAPTION_IN)
	await leave.finished
	await FX.wait_remaining(self, started, T.SEC_07)
