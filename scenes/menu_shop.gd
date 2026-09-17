extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"

var _buy_blink: Tween
var _tpl_puzzles := ""
var _tpl_quick := ""
var _tpl_crypto := ""

@onready var title_label: Label = $Header/Title
@onready var tagline_label: Label = $Header/TaglineRow/Tagline
@onready var offer_title: Label = %OfferTitle
@onready var offer_body: Label = %OfferBody
@onready var label_puzzles: Label = %LabelPuzzles
@onready var label_quick: Label = %LabelQuick
@onready var label_crypto: Label = %LabelCrypto
@onready var label_daily: Label = %LabelDaily
@onready var label_ost: Label = %LabelOst
@onready var extra_soundtrack: Label = %ExtraSoundtrack
@onready var button_buy: Button = %ButtonBuy
@onready var label_buy_verb: Label = %LabelBuyVerb
@onready var label_buy_price: Label = %LabelBuyPrice
@onready var label_owned: Label = %LabelOwned
@onready var button_restore: Button = %ButtonRestore
@onready var label_restore_status: Label = %LabelRestoreStatus


func _ready() -> void:
	_tpl_puzzles = label_puzzles.text
	_tpl_quick = label_quick.text
	_tpl_crypto = label_crypto.text
	_refresh_copy()
	_refresh_purchase_state()
	if not SignalManager.full_game_changed.is_connected(_refresh_purchase_state):
		SignalManager.full_game_changed.connect(_refresh_purchase_state)
	if not SignalManager.store_price_changed.is_connected(_apply_store_price):
		SignalManager.store_price_changed.connect(_apply_store_price)


func _exit_tree() -> void:
	if is_instance_valid(_buy_blink):
		_buy_blink.kill()


func _refresh_copy() -> void:
	var counts := _catalog_counts()
	title_label.text = _t("Shop", title_label.text)
	tagline_label.text = _t("ShopTagline", tagline_label.text)
	offer_title.text = _t("ShopBaseTitle", offer_title.text)
	offer_body.text = _t("ShopBaseBody", offer_body.text)
	label_puzzles.text = _fill(_t("ShopPuzzles", _tpl_puzzles), counts.total)
	label_quick.text = _fill(_t("ShopQuick", _tpl_quick), counts.quick)
	label_crypto.text = _fill(_t("ShopCryptograms", _tpl_crypto), counts.crypto)
	label_daily.text = _t("ShopDailyIncluded", label_daily.text)
	if label_ost:
		var ost_row := label_ost.get_parent() as Control
		if ost_row:
			ost_row.visible = false
	extra_soundtrack.text = _t("ShopFinalNote", extra_soundtrack.text)
	button_restore.text = _t("ShopRestore", button_restore.text)
	label_owned.text = _t("ShopOwned", label_owned.text)
	label_buy_verb.text = _t("ShopUnlockVerb", label_buy_verb.text)
	_apply_store_price()


func _apply_store_price() -> void:
	if label_buy_price:
		label_buy_price.text = StoreManager.price_text()


func _refresh_purchase_state() -> void:
	var owned := GameManager.has_full_game()
	button_buy.visible = not owned
	label_owned.visible = owned
	if owned:
		if is_instance_valid(_buy_blink):
			_buy_blink.kill()
	else:
		_start_buy_blink()


func _catalog_counts() -> Dictionary:
	var total := 0
	var quick := 0
	var crypto := 0
	for item in GameManager.frases_db:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = item
		if GameManager.is_daily_puzzle(entry):
			continue
		total += 1
		if GameManager.level_game_mode(entry) == GameManager.MODE_CRYPTOGRAM:
			crypto += 1
		else:
			quick += 1
	if total <= 0:
		return {"total": 96, "quick": 72, "crypto": 24}
	return {"total": total, "quick": quick, "crypto": crypto}


func _start_buy_blink() -> void:
	if button_buy == null or not button_buy.visible:
		return
	if is_instance_valid(_buy_blink):
		_buy_blink.kill()
	await get_tree().process_frame
	if not is_instance_valid(button_buy) or not button_buy.visible:
		return
	button_buy.pivot_offset = button_buy.size * 0.5
	if not button_buy.resized.is_connected(_on_buy_resized):
		button_buy.resized.connect(_on_buy_resized)
	_buy_blink = create_tween()
	_buy_blink.set_loops()
	_buy_blink.set_trans(Tween.TRANS_SINE)
	_buy_blink.set_ease(Tween.EASE_IN_OUT)
	_buy_blink.tween_property(button_buy, "scale", Vector2(1.03, 1.03), 0.55)
	_buy_blink.parallel().tween_property(button_buy, "modulate", Color(1.06, 1.04, 1.02, 1), 0.55)
	_buy_blink.tween_property(button_buy, "scale", Vector2.ONE, 0.55)
	_buy_blink.parallel().tween_property(button_buy, "modulate", Color.WHITE, 0.55)
	_buy_blink.tween_interval(0.28)


func _on_buy_resized() -> void:
	if button_buy:
		button_buy.pivot_offset = button_buy.size * 0.5


func _on_buy_pressed() -> void:
	SoundManager.play("ButtonClick")
	GameManager.button_blink(button_buy)
	label_restore_status.visible = false
	GameManager.unlock_full_game()


func _on_restore_pressed() -> void:
	SoundManager.play("ButtonClick")
	if GameManager.restore_full_game():
		label_restore_status.text = _t("ShopOwned", label_owned.text)
	else:
		label_restore_status.text = _t("ShopRestoreNone", "No hay compras que restaurar.")
	label_restore_status.visible = true


func _fill(template: String, value: Variant) -> String:
	return template % str(value) if "%s" in template else template


func _t(key: String, fallback: String) -> String:
	var value := tr(key)
	return fallback if value == key or value.is_empty() else value


func _go_to(path: String) -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file(path)


func _on_button_back_pressed() -> void:
	_go_to(PATH_MAIN)
