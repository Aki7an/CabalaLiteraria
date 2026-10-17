extends "res://distribution/adapters/platform_adapter.gd"

const _AD_TIMEOUT_MS := 90000
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
