extends "res://distribution/adapters/platform_adapter.gd"

const _AD_TIMEOUT_MS := 90000
const _LOGIN_TIMEOUT_MS := 12000
const _REQUEST_AD := """
(function(kind){
	window.__cifraCgAd = {done:false, ok:false};
	var sdk = window.CrazyGames && window.CrazyGames.SDK;
	if (!sdk || !sdk.ad || typeof sdk.ad.requestAd !== 'function') {
		window.__cifraCgAd.done = true;
		return;
	}
	try {
		sdk.ad.requestAd(kind, {
			adFinished: function(){ window.__cifraCgAd.done = true; window.__cifraCgAd.ok = true; },
			adError: function(){ window.__cifraCgAd.done = true; window.__cifraCgAd.ok = false; }
		});
	} catch (e) {
		window.__cifraCgAd.done = true;
	}
})('%s');
"""


func login_user() -> Dictionary:
	if not OS.has_feature("web") or not _sdk_ready():
		return {}
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or not await _wait_until_ready(tree):
		return {}
	var user := await _signal_dictionary(tree, CrazyGamesBridge.callbacks.get_user_complete, CrazyGamesBridge.get_user)
	if not _valid_user(user) and CrazyGames.User.is_user_account_available():
		user = await _signal_dictionary(tree, CrazyGamesBridge.callbacks.show_auth_prompt_complete, CrazyGamesBridge.show_auth_prompt)
	if not _valid_user(user):
		return {}
	var token := await _signal_string(tree, CrazyGamesBridge.callbacks.get_user_token_complete, CrazyGamesBridge.get_user_token)
	var user_id := _user_id_from_token(token)
	if user_id == "":
		user_id = str(user.get("username", "")).strip_edges()
	if user_id == "":
		return {}
	return {
		"custom_id": "CG_" + user_id,
		"username": str(user.get("username", "")).strip_edges(),
	}


func show_interstitial_after_puzzle() -> void:
	if _use_portal_sdk():
		await _request_ad("midgame")
		return
	await super.show_interstitial_after_puzzle()


func show_rewarded() -> bool:
	if _use_portal_sdk():
		var ok := await _request_ad("rewarded")
		AdManager.reward_result = "earned" if ok else "unavailable"
		return ok
	return await super.show_rewarded()


func _sdk_ready() -> bool:
	return (
		typeof(CrazyGames) != TYPE_NIL
		and typeof(CrazyGamesBridge) != TYPE_NIL
		and CrazyGamesBridge.callbacks != null
	)


func _wait_until_ready(tree: SceneTree) -> bool:
	var start := Time.get_ticks_msec()
	while not CrazyGames.is_initialised:
		if Time.get_ticks_msec() - start >= _LOGIN_TIMEOUT_MS:
			return false
		await tree.process_frame
	return CrazyGamesBridge.callbacks != null


func _valid_user(user: Dictionary) -> bool:
	return str(user.get("username", "")).strip_edges() != ""


func _signal_dictionary(tree: SceneTree, sig: Signal, start: Callable) -> Dictionary:
	var result := {}
	var done := false
	var on_done := func(value: Dictionary) -> void:
		result = value
		done = true
	sig.connect(on_done, CONNECT_ONE_SHOT)
	start.call()
	var began := Time.get_ticks_msec()
	while not done and Time.get_ticks_msec() - began < _LOGIN_TIMEOUT_MS:
		await tree.process_frame
	if sig.is_connected(on_done):
		sig.disconnect(on_done)
	return result


func _signal_string(tree: SceneTree, sig: Signal, start: Callable) -> String:
	var result := ""
	var done := false
	var on_done := func(value: String) -> void:
		result = value
		done = true
	sig.connect(on_done, CONNECT_ONE_SHOT)
	start.call()
	var began := Time.get_ticks_msec()
	while not done and Time.get_ticks_msec() - began < _LOGIN_TIMEOUT_MS:
		await tree.process_frame
	if sig.is_connected(on_done):
		sig.disconnect(on_done)
	return result


func _user_id_from_token(token: String) -> String:
	var parts := token.split(".")
	if parts.size() < 2:
		return ""
	var payload := parts[1].replace("-", "+").replace("_", "/")
	while payload.length() % 4 != 0:
		payload += "="
	var parsed: Variant = JSON.parse_string(Marshalls.base64_to_raw(payload).get_string_from_utf8())
	if parsed is Dictionary:
		return str(parsed.get("userId", "")).strip_edges()
	return ""


func _use_portal_sdk() -> bool:
	return OS.has_feature("web") and not OS.has_feature("editor")


func _request_ad(kind: String) -> bool:
	if kind != "midgame" and kind != "rewarded":
		return false
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false
	var js := JavaScriptBridge
	js.eval(_REQUEST_AD % kind)
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < _AD_TIMEOUT_MS:
		if js.eval("window.__cifraCgAd && window.__cifraCgAd.done === true") == true:
			return js.eval("window.__cifraCgAd && window.__cifraCgAd.ok === true") == true
		await tree.process_frame
	return false
