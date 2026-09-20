extends Node

const AdsConfig := preload("res://ads/ads_config.gd")

var _mobile_ready := false
var _web_ready := false
var _busy := false
var _js_keep: Array = []
var _mobile_keep: Array = []
var _interstitial_ad: Object = null
var _rewarded_ad: Object = null
var _interstitial_waiting := false
var _interstitial_shown := false
var _rewarded_waiting := false
var _rewarded_earned := false
var _rewarded_closed := false
var _mock_layer: CanvasLayer = null
var _mobile_init_started := false
var _ump_updated := false
var _shown_after_puzzle := false
var _boot_started := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not SignalManager.full_game_changed.is_connected(_on_full_game_changed):
		SignalManager.full_game_changed.connect(_on_full_game_changed)
	if not SignalManager.partida_iniciada.is_connected(_on_partida_iniciada):
		SignalManager.partida_iniciada.connect(_on_partida_iniciada)
	print("[AdMob] AdManager boot os=%s" % OS.get_name())
	if ads_removed():
		print("[AdMob] skipped: full game unlocked")
		return
	AdsConfig.warn_if_misconfigured()
	print("[AdMob] test=%s interstitial=%s rewarded=%s" % [
		AdsConfig.using_test_ads(),
		AdsConfig.interstitial_unit_id(),
		AdsConfig.rewarded_unit_id()
	])
	if OS.has_feature("web"):
		_init_web()
	elif OS.get_name() == "iOS" or OS.get_name() == "Android":
		_boot_mobile()
	elif _has_mobile_ads():
		_init_mobile()
	else:
		print("[AdMob] native plugin not present; editor uses simulated ads")


func ads_removed() -> bool:
	return GameManager.has_full_game()


func has_daily_access() -> bool:
	return true


func show_interstitial_after_puzzle() -> void:
	if ads_removed():
		print("[AdMob] skip interstitial: full game unlocked")
		return
	if _shown_after_puzzle:
		print("[AdMob] skip interstitial: already shown this puzzle")
		return
	if not _should_show_interstitial():
		print("[AdMob] skip interstitial: mode=%s source=%s" % [
			GameManager.game_mode_actual,
			GameManager.session_source
		])
		return
	print("[AdMob] show interstitial after puzzle unit=%s" % AdsConfig.interstitial_unit_id())
	await present_interstitial()
	if _interstitial_shown:
		_shown_after_puzzle = true


func present_interstitial() -> void:
	if ads_removed():
		print("[AdMob] present skipped: full game unlocked")
		return
	while _busy:
		await get_tree().process_frame
	if _shown_after_puzzle:
		print("[AdMob] present skipped: already shown this puzzle")
		return
	if OS.get_name() == "iOS" or OS.get_name() == "Android":
		await _boot_mobile()
	if not OS.has_feature("web") and not _has_mobile_ads() and not _can_mock():
		push_error("[AdMob] cannot show interstitial: native iOS/Android plugin is missing from this build")
		return
	_busy = true
	if OS.has_feature("web"):
		await _present_web_interstitial()
	elif _has_mobile_ads():
		await _present_mobile_interstitial()
	elif _can_mock():
		await _present_mock(false)
	_busy = false


func show_rewarded() -> bool:
	if ads_removed():
		return true
	if _busy:
		return false
	_busy = true
	var ok := false
	if OS.get_name() == "iOS" or OS.get_name() == "Android":
		await _boot_mobile()
	if OS.has_feature("web"):
		ok = await _present_web_rewarded()
	elif _has_mobile_ads():
		ok = await _present_mobile_rewarded()
	elif _can_mock():
		await _present_mock(true)
		ok = true
	_busy = false
	return ok


func note_puzzle_completed_for_ads() -> void:
	if ads_removed():
		return
	if GameManager.is_practice_session():
		return
	if GameManager.session_source == GameManager.SOURCE_DAILY:
		return
	if GameManager.game_mode_actual != GameManager.MODE_QUICK:
		return
	PlayerPrefs.ads_quick_streak += 1
	PlayerPrefs.save_prefs()
	print("[AdMob] quick streak=%s/%s" % [
		PlayerPrefs.ads_quick_streak,
		AdsConfig.QUICK_PUZZLES_PER_INTERSTITIAL
	])


func _should_show_interstitial() -> bool:
	if ads_removed():
		return false
	if GameManager.is_practice_session():
		return false
	if GameManager.session_source == GameManager.SOURCE_DAILY:
		return false
	if GameManager.game_mode_actual == GameManager.MODE_CRYPTOGRAM:
		return true
	if GameManager.game_mode_actual != GameManager.MODE_QUICK:
		return false
	var show: bool = PlayerPrefs.ads_quick_streak >= AdsConfig.QUICK_PUZZLES_PER_INTERSTITIAL
	if show:
		PlayerPrefs.ads_quick_streak = 0
		PlayerPrefs.save_prefs()
	return show


func _on_partida_iniciada() -> void:
	_shown_after_puzzle = false
	_interstitial_shown = false


func _on_full_game_changed() -> void:
	if ads_removed():
		_destroy_mobile_ads()
		_clear_mock()
		return
	if OS.has_feature("web") and not _web_ready:
		_init_web()
	elif (OS.get_name() == "iOS" or OS.get_name() == "Android") and not _mobile_ready:
		_boot_mobile()


func _can_mock() -> bool:
	return OS.has_feature("editor")


func _has_mobile_ads() -> bool:
	# GDScript class_name always exists. Ads only work if the native iOS/Android
	# singleton was actually linked into the export.
	return (
		Engine.has_singleton("PoingGodotAdMob")
		or Engine.has_singleton("PoingGodotAdMobInterstitialAd")
	)


func _log_poing_singletons() -> void:
	var found: PackedStringArray = []
	for name in Engine.get_singleton_list():
		var text := str(name)
		if text.findn("Poing") != -1 or text.findn("AdMob") != -1:
			found.append(text)
	if found.is_empty():
		print("[AdMob] engine singletons: (none)")
	else:
		print("[AdMob] engine singletons: %s" % ", ".join(found))


func _boot_mobile() -> void:
	if _mobile_ready:
		return
	if _boot_started:
		var wait := 0.0
		while not _mobile_ready and wait < 12.0:
			await get_tree().process_frame
			wait += get_process_delta_time()
		return
	_boot_started = true
	var elapsed := 0.0
	while not _has_mobile_ads() and elapsed < 8.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_log_poing_singletons()
	if _has_mobile_ads():
		_init_mobile()
		var init_wait := 0.0
		while not _mobile_ready and init_wait < 8.0:
			await get_tree().process_frame
			init_wait += get_process_delta_time()
		return
	push_error("[AdMob] native plugin not present after wait; interstitial cannot show")


func _loc(key: String, fallback: String) -> String:
	var value := tr(key)
	return fallback if value == key or value.is_empty() else value


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


# --- HTML / H5 Games Ads -------------------------------------------------

func _init_web() -> void:
	if not OS.has_feature("web"):
		return
	var js := JavaScriptBridge
	js.eval("window.__cifraAdsenseClient = '%s'; window.__cifraH5Test = %s;" % [
		AdsConfig.ADSENSE_CLIENT,
		"true" if AdsConfig.H5_TEST_MODE else "false"
	], true)
	js.eval(AdsConfig.H5_BOOTSTRAP_JS, true)
	_web_ready = true


func _js_callback(callable: Callable) -> JavaScriptObject:
	var cb: JavaScriptObject = JavaScriptBridge.create_callback(callable)
	_js_keep.append(cb)
	return cb


func _present_web_interstitial() -> void:
	if not _web_ready:
		_init_web()
	var done := false
	var cb := _js_callback(func(_args: Array) -> void:
		done = true
	)
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return
	window.__cifraShowInterstitial(cb)
	var elapsed := 0.0
	while not done and elapsed < AdsConfig.INTERSTITIAL_TIMEOUT_SEC:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if not done and _can_mock():
		await _present_mock(false)


func _present_web_rewarded() -> bool:
	if not _web_ready:
		_init_web()
	var done := false
	var earned := false
	var cb := _js_callback(func(args: Array) -> void:
		earned = args.size() > 0 and bool(args[0])
		done = true
	)
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return _can_mock()
	window.__cifraShowRewarded(cb)
	var elapsed := 0.0
	while not done and elapsed < AdsConfig.REWARDED_TIMEOUT_SEC:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if done:
		return earned
	if _can_mock():
		await _present_mock(true)
		return true
	return false


# --- AdMob (Poing official GDScript API) ---------------------------------

func _init_mobile() -> void:
	_mobile_keep.clear()
	_mobile_init_started = false
	_ump_updated = false
	_mobile_ready = false
	print("[AdMob] native singletons PoingGodotAdMob=%s Interstitial=%s Consent=%s" % [
		Engine.has_singleton("PoingGodotAdMob"),
		Engine.has_singleton("PoingGodotAdMobInterstitialAd"),
		Engine.has_singleton("PoingGodotAdMobConsentInformation"),
	])
	_request_ump_then_initialize()


func _request_ump_then_initialize() -> void:
	if ads_removed():
		return
	if AdsConfig.using_test_ads():
		print("[AdMob] test ads: skip UMP, initialize SDK now")
		_finish_mobile_init()
		return
	if not Engine.has_singleton("PoingGodotAdMobConsentInformation"):
		print("[AdMob] UMP plugin missing, initializing SDK")
		_finish_mobile_init()
		return
	var info := ConsentInformation.new()
	var params := ConsentRequestParameters.new()
	params.tag_for_under_age_of_consent = false
	_mobile_keep.append(info)
	_mobile_keep.append(params)
	var on_ok := func() -> void:
		_on_consent_info_updated(info)
	var on_fail := func(_err) -> void:
		push_warning("[AdMob] UMP update failed")
		_ump_updated = true
		_finish_mobile_init()
	info.update(params, on_ok, on_fail)
	var elapsed := 0.0
	while not _ump_updated and elapsed < AdsConfig.UMP_UPDATE_TIMEOUT_SEC:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if not _ump_updated:
		push_warning("[AdMob] UMP update timed out")
		_finish_mobile_init()


func _on_consent_info_updated(info: ConsentInformation) -> void:
	_ump_updated = true
	if _mobile_init_started or ads_removed() or info == null:
		return
	var status := int(info.get_consent_status())
	print("[AdMob] UMP consent status=", status)
	if status == ConsentInformation.ConsentStatus.REQUIRED and info.get_is_consent_form_available():
		var on_form := func(form: ConsentForm) -> void:
			if form == null:
				_finish_mobile_init()
				return
			_mobile_keep.append(form)
			form.show(func(_err) -> void:
				_finish_mobile_init()
			)
		var on_form_fail := func(_err) -> void:
			push_warning("[AdMob] consent form failed to load")
			_finish_mobile_init()
		UserMessagingPlatform.load_consent_form(on_form, on_form_fail)
		return
	_finish_mobile_init()


func _finish_mobile_init() -> void:
	if _mobile_init_started or ads_removed():
		return
	_mobile_init_started = true
	print("[AdMob] initializing MobileAds SDK")
	_apply_test_device_ids()
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status) -> void:
		print("[AdMob] SDK initialized")
		_mobile_ready = true
		_load_interstitial()
		_load_rewarded()
	_mobile_keep.append(listener)
	if OS.get_name() == "iOS":
		MobileAds.set_ios_app_pause_on_background(true)
	MobileAds.initialize(listener)
	_ensure_sdk_ready_fallback()


func _apply_test_device_ids() -> void:
	if not AdsConfig.using_test_ads() or AdsConfig.TEST_DEVICE_IDS.is_empty():
		return
	var config := RequestConfiguration.new()
	config.test_device_ids.assign(AdsConfig.TEST_DEVICE_IDS)
	_mobile_keep.append(config)
	MobileAds.set_request_configuration(config)
	print("[AdMob] test device ids=%s" % ",".join(AdsConfig.TEST_DEVICE_IDS))


func _ensure_sdk_ready_fallback() -> void:
	var elapsed := 0.0
	while not _mobile_ready and elapsed < 6.0:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if _mobile_ready:
		return
	push_warning("[AdMob] SDK init callback missing; loading ads anyway")
	_mobile_ready = true
	_load_interstitial()
	_load_rewarded()


func _load_interstitial() -> void:
	if ads_removed():
		return
	if not Engine.has_singleton("PoingGodotAdMobInterstitialAd"):
		push_warning("[AdMob] interstitial native plugin missing")
		return
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		print("[AdMob] interstitial loaded")
		_interstitial_ad = ad
		_bind_interstitial_callbacks(ad)
	callback.on_ad_failed_to_load = func(err: LoadAdError) -> void:
		_interstitial_ad = null
		push_warning("[AdMob] interstitial failed to load: %s" % _ad_error_text(err))
	var loader := InterstitialAdLoader.new()
	_mobile_keep.append(callback)
	_mobile_keep.append(loader)
	print("[AdMob] loading interstitial %s" % AdsConfig.interstitial_unit_id())
	loader.load(AdsConfig.interstitial_unit_id(), AdRequest.new(), callback)


func _bind_interstitial_callbacks(ad: InterstitialAd) -> void:
	if ad == null:
		return
	var cb := FullScreenContentCallback.new()
	cb.on_ad_dismissed_full_screen_content = func() -> void:
		print("[AdMob] interstitial dismissed")
		_interstitial_shown = true
		_interstitial_waiting = false
		_destroy_ad(_interstitial_ad)
		_interstitial_ad = null
		_load_interstitial()
	cb.on_ad_failed_to_show_full_screen_content = func(err) -> void:
		push_warning("[AdMob] interstitial failed to show: %s" % _ad_error_text(err))
		_interstitial_shown = false
		_interstitial_waiting = false
		_destroy_ad(_interstitial_ad)
		_interstitial_ad = null
		_load_interstitial()
	ad.full_screen_content_callback = cb


func _present_mobile_interstitial() -> void:
	if not _mobile_ready:
		print("[AdMob] waiting for SDK before interstitial")
		var elapsed_init := 0.0
		while not _mobile_ready and elapsed_init < 6.0:
			await get_tree().process_frame
			elapsed_init += get_process_delta_time()
	if _interstitial_ad == null:
		_load_interstitial()
		var elapsed := 0.0
		while _interstitial_ad == null and elapsed < AdsConfig.INTERSTITIAL_TIMEOUT_SEC:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
	if _interstitial_ad == null:
		push_warning("[AdMob] interstitial not ready to show")
		if _can_mock():
			await _present_mock(false)
		return
	_interstitial_waiting = true
	_interstitial_shown = false
	print("[AdMob] showing interstitial")
	_interstitial_ad.show()
	var elapsed_show := 0.0
	while _interstitial_waiting and elapsed_show < AdsConfig.INTERSTITIAL_TIMEOUT_SEC:
		await get_tree().process_frame
		elapsed_show += get_process_delta_time()
	_interstitial_waiting = false


func _load_rewarded() -> void:
	if ads_removed():
		return
	if not Engine.has_singleton("PoingGodotAdMobRewardedAd"):
		push_warning("[AdMob] rewarded native plugin missing")
		return
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		print("[AdMob] rewarded loaded")
		_rewarded_ad = ad
		_bind_rewarded_callbacks(ad)
	callback.on_ad_failed_to_load = func(err: LoadAdError) -> void:
		_rewarded_ad = null
		push_warning("[AdMob] rewarded failed to load: %s" % _ad_error_text(err))
	var loader := RewardedAdLoader.new()
	_mobile_keep.append(callback)
	_mobile_keep.append(loader)
	print("[AdMob] loading rewarded %s" % AdsConfig.rewarded_unit_id())
	loader.load(AdsConfig.rewarded_unit_id(), AdRequest.new(), callback)


func _bind_rewarded_callbacks(ad: RewardedAd) -> void:
	if ad == null:
		return
	var cb := FullScreenContentCallback.new()
	cb.on_ad_dismissed_full_screen_content = func() -> void:
		print("[AdMob] rewarded dismissed earned=%s" % _rewarded_earned)
		_rewarded_closed = true
		_rewarded_waiting = false
		_destroy_ad(_rewarded_ad)
		_rewarded_ad = null
		_load_rewarded()
	cb.on_ad_failed_to_show_full_screen_content = func(err) -> void:
		push_warning("[AdMob] rewarded failed to show: %s" % _ad_error_text(err))
		_rewarded_earned = false
		_rewarded_closed = true
		_rewarded_waiting = false
		_destroy_ad(_rewarded_ad)
		_rewarded_ad = null
		_load_rewarded()
	ad.full_screen_content_callback = cb


func _present_mobile_rewarded() -> bool:
	if not _mobile_ready:
		var elapsed_init := 0.0
		while not _mobile_ready and elapsed_init < 6.0:
			await get_tree().process_frame
			elapsed_init += get_process_delta_time()
	if _rewarded_ad == null:
		_load_rewarded()
		var elapsed := 0.0
		while _rewarded_ad == null and elapsed < AdsConfig.REWARDED_TIMEOUT_SEC:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
	if _rewarded_ad == null:
		if _can_mock():
			await _present_mock(true)
			return true
		return false
	_rewarded_waiting = true
	_rewarded_earned = false
	_rewarded_closed = false
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item) -> void:
		_rewarded_earned = true
	_mobile_keep.append(listener)
	_rewarded_ad.show(listener)
	var elapsed_show := 0.0
	while _rewarded_waiting and elapsed_show < AdsConfig.REWARDED_TIMEOUT_SEC:
		await get_tree().process_frame
		elapsed_show += get_process_delta_time()
	_rewarded_waiting = false
	return _rewarded_earned


func _destroy_ad(ad: Object) -> void:
	if ad and ad.has_method("destroy"):
		ad.call("destroy")


func _ad_error_text(err: Variant) -> String:
	if err == null:
		return "unknown"
	if typeof(err) == TYPE_OBJECT:
		var code: Variant = err.get("code")
		var message: Variant = err.get("message")
		if message != null:
			return "%s (code=%s)" % [str(message), str(code)]
	return str(err)


func _destroy_mobile_ads() -> void:
	_destroy_ad(_interstitial_ad)
	_destroy_ad(_rewarded_ad)
	_interstitial_ad = null
	_rewarded_ad = null
	_mobile_keep.clear()
	_mobile_ready = false
	_mobile_init_started = false
	_ump_updated = false
	_boot_started = false


# --- Editor / debug placeholder ------------------------------------------

func _present_mock(is_rewarded: bool) -> void:
	_clear_mock()
	var layer := CanvasLayer.new()
	layer.layer = 128
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_mock_layer = layer
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.06, 0.05, 0.04, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1, 0.96, 0.9, 1))
	label.text = _loc("AdSimulated", "Anuncio")
	if is_rewarded:
		label.text = "%s\n%s" % [label.text, _loc("DailyWatchAd", "Ver anuncio para jugar")]
	dim.add_child(label)
	await _wait(AdsConfig.MOCK_REWARDED_SEC if is_rewarded else AdsConfig.MOCK_INTERSTITIAL_SEC)
	_clear_mock()


func _clear_mock() -> void:
	if is_instance_valid(_mock_layer):
		_mock_layer.queue_free()
	_mock_layer = null
