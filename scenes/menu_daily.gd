extends Control

const PATH_MAIN := "res://scenes/MenuMain.tscn"
const PATH_SHOP := "res://scenes/MenuShop.tscn"
const PATH_LIBRARY := "res://scenes/MenuLibrary.tscn"
const ICON_CITA: Texture2D = preload("res://images/Ilustres.png")
const ICON_EFEM: Texture2D = preload("res://images/Efemerides.png")
const ICON_CURIO: Texture2D = preload("res://images/Adivinanza.png")
const ICON_FRAG: Texture2D = preload("res://images/FragmentosLiterarios.png")
const ICON_QUICK: Texture2D = preload("res://images/mode_quick.svg")
const ICON_CRYPTO: Texture2D = preload("res://images/CriptogramaIcono.png")
const ICON_PLAY: Texture2D = preload("res://GUI/BotonPlaySimboloTextura.png")
const ICON_VIDEO: Texture2D = preload("res://images/ui_icon_video.svg")
const STAR_ON: Texture2D = preload("res://images/estrella_plano.png")
const STAR_OFF: Texture2D = preload("res://images/contorno_estrella.png")
const STAR_ON_CRYPTO := Color(1, 0.55, 0.14, 1)
const STAR_ON_QUICK := Color(1, 0.84, 0.18, 1)
const STAR_OFF_TINT := Color(0.62, 0.52, 0.46, 0.38)
const AD_FAIL := Color(0.78, 0.18, 0.14, 1)

var _item: Dictionary = {}
var _needs_ad := false
var _ad_busy := false
var _offline_blink: Tween
var _thanks_color := Color(0.48, 0.36, 0.26, 0.82)

@onready var title_label: Label = %Title
@onready var tagline_label: Label = %Tagline
@onready var date_label: Label = %DateLabel
@onready var status_available: Label = %StatusAvailable
@onready var status_done: Label = %StatusDone
@onready var image_block: CenterContainer = %ImageBlock
@onready var image_frame: Panel = %ImageFrame
@onready var puzzle_image: TextureRect = %PuzzleImage
@onready var completed_stamp: Panel = %CompletedStamp
@onready var type_icon: TextureRect = %TypeIcon
@onready var type_label: Label = %TypeLabel
@onready var diff_label: Label = %DiffLabel
@onready var time_label: Label = %TimeLabel
@onready var teaser: Label = %Teaser
@onready var ad_card: Control = %AdCard
@onready var ad_warning: Label = %AdWarning
@onready var ad_thanks: Label = %AdThanks
@onready var play_wrap: Control = %PlayWrap
@onready var play_button: Button = %PlayButton
@onready var play_icon: TextureRect = %PlayIcon
@onready var play_caption: Label = %PlayCaption
@onready var completed_box: Control = %CompletedBox
@onready var view_sheet: Button = %ViewSheet
@onready var offline_banner: Label = %OfflineBanner
@onready var version_label: Label = $Version
@onready var lock_overlay: Control = $LockOverlay
@onready var how_title: Label = %HowTitle
@onready var how1: Label = %How1
@onready var how2: Label = %How2
@onready var how3: Label = %How3
@onready var how4: Label = %How4
@onready var stars: Array[TextureRect] = [%Star1, %Star2, %Star3, %Star4, %Star5]


func _ready() -> void:
	var daily_scroll := get_node_or_null("%Scroll") as ScrollContainer
	if daily_scroll:
		ScrollOverflowHint.attach(daily_scroll)
	_apply_static_texts()
	if ad_thanks:
		_thanks_color = ad_thanks.get_theme_color("font_color")
	if image_block and not image_block.resized.is_connected(_fit_image_frame):
		image_block.resized.connect(_fit_image_frame)
	if not SignalManager.full_game_changed.is_connected(_refresh_content):
		SignalManager.full_game_changed.connect(_refresh_content)
	if not SignalManager.daily_puzzle_changed.is_connected(_refresh_content):
		SignalManager.daily_puzzle_changed.connect(_refresh_content)
	_refresh_content()


func _exit_tree() -> void:
	if is_instance_valid(_offline_blink):
		_offline_blink.kill()


func _apply_static_texts() -> void:
	if title_label:
		title_label.text = tr("DailyChallenge")
	if tagline_label:
		tagline_label.text = tr("DailyTagline")
	if how_title:
		how_title.text = tr("DailyHowTitle").to_upper()
	if how1:
		how1.text = tr("DailyHow1")
	if how2:
		how2.text = tr("DailyHow2")
	if how3:
		how3.text = tr("DailyHow3")
	if how4:
		how4.text = _t("DailyHow4", "El mismo puzle para todos los jugadores.")
	if status_available:
		status_available.text = tr("DailyAvailable")
	if status_done:
		status_done.text = tr("DailyCompletedShort")
	if ad_warning:
		ad_warning.text = _t("DailyAdWarning", "Mira un breve anuncio\npara desbloquear el reto de hoy.")
	if ad_thanks:
		ad_thanks.text = _t("DailyAdThanks", "Apoyas el desarrollo de CifraLetra. ¡Gracias!")
	if view_sheet:
		view_sheet.text = tr("DailyViewSheet")
	if offline_banner:
		offline_banner.text = _t("DailyOffline", "FUERA DE LÍNEA")
	if version_label:
		version_label.text = "%s %s" % [tr("Version"), PlayerPrefs.version_display()]
	var stamp_label := completed_stamp.get_node_or_null("StampLabel") as Label if completed_stamp else null
	if stamp_label:
		stamp_label.text = tr("DailyCompletedShort").to_upper()
	_apply_lock_texts()


func _refresh_content(_unused: Variant = null) -> void:
	_item = GameManager.todays_daily_item()
	var done := (
		PlayerPrefs.is_daily_completed_today()
		and PlayerPrefs.daily_puzzle_id == int(_item.get("index", -1))
	)
	_needs_ad = (not done) and GameManager.needs_daily_ad()
	if date_label:
		date_label.text = GameManager.format_long_date()
	if status_available:
		status_available.visible = not done
	if status_done:
		status_done.visible = done
	if completed_stamp:
		completed_stamp.visible = done
		if image_frame:
			image_frame.clip_contents = not done
	_fill_image()
	_fill_details()
	_fill_stars(done)
	if ad_card:
		ad_card.visible = _needs_ad
	if play_wrap:
		play_wrap.visible = not done
	if completed_box:
		completed_box.visible = done
	_apply_play_button(_needs_ad)
	if play_button:
		play_button.disabled = _item.is_empty()
	if ad_thanks:
		ad_thanks.add_theme_color_override("font_color", _thanks_color)
		ad_thanks.text = _t("DailyAdThanks", "Apoyas el desarrollo de CifraLetra. ¡Gracias!")
	_refresh_offline_banner()
	_fit_image_frame()


func _fill_image() -> void:
	if puzzle_image == null:
		return
	var cat_id := str(_item.get("category", ""))
	var path := GameManager.find_level_image_path(int(_item.get("image_number", -1)))
	var tex: Texture2D = _category_icon_for(cat_id)
	if path != "":
		var loaded := load(path) as Texture2D
		if loaded:
			tex = loaded
	puzzle_image.texture = tex


func _fill_details() -> void:
	var cat_id := str(_item.get("category", ""))
	var mode := GameManager.level_game_mode(_item)
	var is_crypto := mode == GameManager.MODE_CRYPTOGRAM
	var diff_name := tr("Medium") if int(_item.get("difficulty", 1)) == 2 else GameManager.difficulty_display_name(int(_item.get("difficulty", 1)))
	if type_icon:
		type_icon.texture = ICON_CRYPTO if is_crypto else ICON_QUICK
	if type_label:
		type_label.text = tr("DailyType") % (tr("Cryptogram") if is_crypto else tr("Quick"))
	if diff_label:
		diff_label.text = "%s %s" % [tr("DailyDifficulty").replace("%s", "").strip_edges(), diff_name]
	if time_label:
		time_label.text = tr("DailyEstimated") % _daily_time_range()
	if teaser:
		teaser.text = _teaser_for(cat_id)


func _fill_stars(done: bool) -> void:
	if not done:
		return
	var mode := GameManager.level_game_mode(_item)
	var is_crypto := mode == GameManager.MODE_CRYPTOGRAM
	var total := clampi(int(_item.get("difficulty", 1)), 1, 5)
	var got := clampi(int(PlayerPrefs.daily_stars), 0, total)
	for i in stars.size():
		var star := stars[i]
		if star == null:
			continue
		star.visible = i < total
		if i < got:
			star.texture = STAR_ON
			star.modulate = STAR_ON_CRYPTO if is_crypto else STAR_ON_QUICK
		else:
			star.texture = STAR_OFF
			star.modulate = STAR_OFF_TINT


func _apply_play_button(watch_ad: bool) -> void:
	if play_icon:
		play_icon.texture = ICON_VIDEO if watch_ad else ICON_PLAY
	if play_caption:
		play_caption.text = _t("DailyWatchAdPlay", "VER ANUNCIO Y JUGAR") if watch_ad else tr("DailyPlay")


func _fit_image_frame() -> void:
	if image_block == null or image_frame == null:
		return
	var side := mini(int(image_block.size.x), 820)
	if side > 1:
		image_frame.custom_minimum_size = Vector2(side, side)


func _refresh_offline_banner() -> void:
	if offline_banner == null:
		return
	var offline := GameManager.has_daily_access() and not GameManager.has_server_time()
	offline_banner.visible = offline
	if offline:
		_start_offline_blink()
	else:
		_stop_offline_blink()


func _start_offline_blink() -> void:
	if offline_banner == null:
		return
	if is_instance_valid(_offline_blink):
		_offline_blink.kill()
	offline_banner.modulate = Color.WHITE
	_offline_blink = create_tween()
	_offline_blink.set_loops()
	_offline_blink.set_trans(Tween.TRANS_SINE)
	_offline_blink.set_ease(Tween.EASE_IN_OUT)
	_offline_blink.tween_property(offline_banner, "modulate:a", 0.12, 0.42)
	_offline_blink.tween_property(offline_banner, "modulate:a", 1.0, 0.42)


func _stop_offline_blink() -> void:
	if is_instance_valid(_offline_blink):
		_offline_blink.kill()
	_offline_blink = null
	if offline_banner:
		offline_banner.modulate = Color.WHITE


func _daily_time_range() -> String:
	var value := tr("DailyTimeRange")
	return "3 – 5 min" if value == "DailyTimeRange" or value.is_empty() else value


func _teaser_for(cat_id: String) -> String:
	match GameManager.normalize_category(cat_id):
		GameManager.CAT_CITA:
			return tr("DailyTeaserQuotes")
		GameManager.CAT_EFEMERIDE:
			return tr("DailyTeaserEphemerides")
		GameManager.CAT_FRAGMENTO:
			return tr("DailyTeaserFragments")
		_:
			return tr("DailyTeaserCuriosities")


func _category_icon_for(cat_id: String) -> Texture2D:
	match GameManager.normalize_category(cat_id):
		GameManager.CAT_CITA:
			return ICON_CITA
		GameManager.CAT_EFEMERIDE:
			return ICON_EFEM
		GameManager.CAT_CURIOSIDADES:
			return ICON_CURIO
		GameManager.CAT_FRAGMENTO:
			return ICON_FRAG
		_:
			return ICON_CITA


func _apply_lock_texts() -> void:
	if lock_overlay == null:
		return
	var lock_title := lock_overlay.get_node_or_null("Card/Title") as Label
	var lock_body := lock_overlay.get_node_or_null("Card/Body") as Label
	var unlock_btn := lock_overlay.get_node_or_null("Card/Unlock") as Button
	var shop_btn := lock_overlay.get_node_or_null("Card/Shop") as Button
	var back_btn := lock_overlay.get_node_or_null("Card/Back") as Button
	if lock_title:
		lock_title.text = tr("DailyChallenge")
	if lock_body:
		lock_body.text = _t("DailyLockedBody", "Mira un anuncio para jugar el reto de hoy, o compra el juego para quitar todos los anuncios.")
	if unlock_btn:
		unlock_btn.text = _t("DailyWatchAd", "Ver anuncio para jugar")
	if shop_btn:
		shop_btn.text = tr("Shop")
	if back_btn:
		back_btn.text = tr("Back")


func _go_to(path: String) -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file(path)


func _t(key: String, fallback: String) -> String:
	var value := tr(key)
	return fallback if value == key or value.is_empty() else value


func _on_button_back_pressed() -> void:
	_go_to(PATH_MAIN)


func _on_shop_pressed() -> void:
	_go_to(PATH_SHOP)


func _on_lock_back_pressed() -> void:
	_go_to(PATH_MAIN)


func _on_unlock_pressed() -> void:
	if GameManager.has_daily_access():
		_refresh_content()
		return
	var unlock_btn := lock_overlay.get_node_or_null("Card/Unlock") as Button
	if unlock_btn:
		unlock_btn.disabled = true
		unlock_btn.text = _t("DailyAdLoading", "Cargando anuncio...")
	var ok: bool = await AdManager.show_rewarded()
	if unlock_btn:
		unlock_btn.disabled = false
	if ok:
		PlayerPrefs.mark_daily_rewarded_today()
		_refresh_content()
		return
	_apply_lock_texts()
	var lock_body := lock_overlay.get_node_or_null("Card/Body") as Label
	if lock_body:
		lock_body.text = _t("DailyAdFailed", "No hay anuncio disponible. Inténtalo de nuevo o compra el juego.")


func _on_view_sheet_pressed() -> void:
	var puzzle_id := int(_item.get("index", -1))
	if puzzle_id < 0:
		return
	GameManager.pending_library_puzzle_id = puzzle_id
	_go_to(PATH_LIBRARY)


func _on_play_pressed() -> void:
	if _ad_busy:
		return
	if _item.is_empty() or PlayerPrefs.is_daily_completed_today():
		return
	SoundManager.play("ButtonClick")
	if _needs_ad or GameManager.needs_daily_ad():
		_ad_busy = true
		if play_button:
			play_button.disabled = true
		if play_caption:
			play_caption.text = _t("DailyAdLoading", "Cargando anuncio...")
		var ok: bool = await AdManager.show_rewarded()
		_ad_busy = false
		if not ok:
			if play_button:
				play_button.disabled = false
			_apply_play_button(true)
			if ad_thanks:
				ad_thanks.text = _t("DailyAdFailed", "No hay anuncio disponible. Inténtalo de nuevo o compra el juego.")
				ad_thanks.add_theme_color_override("font_color", AD_FAIL)
			return
		PlayerPrefs.mark_daily_rewarded_today()
		_needs_ad = false
	var puzzle_id := int(_item.get("index", -1))
	if puzzle_id < 0:
		return
	GameManager.session_source = GameManager.SOURCE_DAILY
	GameManager.allow_completed_replay = true
	GameManager.id_frase = puzzle_id
	GameManager.set_game_mode_actual(GameManager.level_game_mode(_item))
	GameManager.set_dificultad_actual(int(_item.get("difficulty", 1)))
	GameManager.seleccionar_por_index(puzzle_id)
	PuzzleSaveManager.prepare_current_puzzle_cipher()
	GameManager.set_go_to_game_disable()
	if play_button:
		play_button.disabled = true
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	GameManager.launch_prepared_game()
