extends RefCounted

## AdMob / AdSense IDs.
## Keep USE_TEST_ADS true until Play Console + AdMob are linked.
## App IDs must also match Project Settings → Admob → Android/iOS → App Id
## (that value is what the export writes into the AndroidManifest).
const USE_TEST_ADS := true
const H5_TEST_MODE := true

const TEST_APP_ID_ANDROID := "ca-app-pub-3940256099942544~3347511713"
const TEST_APP_ID_IOS := "ca-app-pub-3940256099942544~1458002511"
const ANDROID_INTERSTITIAL_TEST := "ca-app-pub-3940256099942544/1033173712"
const IOS_INTERSTITIAL_TEST := "ca-app-pub-3940256099942544/4411468910"
const ANDROID_REWARDED_TEST := "ca-app-pub-3940256099942544/5224354917"
const IOS_REWARDED_TEST := "ca-app-pub-3940256099942544/1712485313"

## Production IDs from https://apps.admob.com (Apps → CifraLetra).
## Package / bundle: com.akidev.cifraletra
const ADMOB_APP_ID_ANDROID := "ca-app-pub-4839644126711617~7447184050"
const ADMOB_APP_ID_IOS := "ca-app-pub-4839644126711617~1601271488"
const ANDROID_INTERSTITIAL := "ca-app-pub-4839644126711617/2886432990"
const IOS_INTERSTITIAL := "ca-app-pub-4839644126711617/3133845009"
const ANDROID_REWARDED := "ca-app-pub-4839644126711617/6691525641"
const IOS_REWARDED := "ca-app-pub-4839644126711617/3816371285"

## AdSense client for H5 Games Ads on the web export.
const ADSENSE_CLIENT := "ca-pub-3940256099942544"

const QUICK_PUZZLES_PER_INTERSTITIAL := 2
const INTERSTITIAL_TIMEOUT_SEC := 15.0
const REWARDED_TIMEOUT_SEC := 25.0
const MOCK_INTERSTITIAL_SEC := 1.4
const MOCK_REWARDED_SEC := 2.0
const UMP_UPDATE_TIMEOUT_SEC := 8.0


static func is_ios() -> bool:
	return OS.get_name() == "iOS"


static func using_test_ads() -> bool:
	return USE_TEST_ADS


static func app_id() -> String:
	if is_ios():
		return ADMOB_APP_ID_IOS if not ADMOB_APP_ID_IOS.is_empty() else TEST_APP_ID_IOS
	return ADMOB_APP_ID_ANDROID if not ADMOB_APP_ID_ANDROID.is_empty() else TEST_APP_ID_ANDROID


static func interstitial_unit_id() -> String:
	if is_ios():
		if not USE_TEST_ADS and not IOS_INTERSTITIAL.is_empty():
			return IOS_INTERSTITIAL
		return IOS_INTERSTITIAL_TEST
	if not USE_TEST_ADS and not ANDROID_INTERSTITIAL.is_empty():
		return ANDROID_INTERSTITIAL
	return ANDROID_INTERSTITIAL_TEST


static func rewarded_unit_id() -> String:
	if is_ios():
		if not USE_TEST_ADS and not IOS_REWARDED.is_empty():
			return IOS_REWARDED
		return IOS_REWARDED_TEST
	if not USE_TEST_ADS and not ANDROID_REWARDED.is_empty():
		return ANDROID_REWARDED
	return ANDROID_REWARDED_TEST


static func warn_if_misconfigured() -> void:
	var setting_path := "admob/general/ios/app_id" if is_ios() else "admob/general/android/app_id"
	var setting_id := str(ProjectSettings.get_setting(setting_path, ""))
	var runtime_id := app_id()
	if setting_id.is_empty():
		push_warning("[AdMob] Missing App ID in Project Settings (%s)." % setting_path)
	elif setting_id != runtime_id:
		push_warning("[AdMob] Project Settings App ID (%s) does not match ads_config (%s)." % [setting_id, runtime_id])
	if not USE_TEST_ADS and runtime_id.begins_with("ca-app-pub-3940256099942544"):
		push_warning("[AdMob] USE_TEST_ADS is false but production App ID is still empty.")


const H5_BOOTSTRAP_JS := """
(function () {
  if (window.__cifraAdsInit) { return; }
  window.__cifraAdsInit = true;
  window.adsbygoogle = window.adsbygoogle || [];
  var client = window.__cifraAdsenseClient || "ca-pub-3940256099942544";
  if (!document.querySelector("script[data-cifra-h5ads]")) {
    var script = document.createElement("script");
    script.async = true;
    script.setAttribute("data-cifra-h5ads", "1");
    script.setAttribute("data-ad-frequency-hint", "30s");
    if (window.__cifraH5Test) { script.setAttribute("data-adbreak-test", "on"); }
    script.crossOrigin = "anonymous";
    script.src = "https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=" + client;
    document.head.appendChild(script);
  }
  if (typeof window.adConfig === "function") {
    window.adConfig({ preloadAdBreaks: "on", sound: "on" });
  }
  window.__cifraShowInterstitial = function (done) {
    var finished = false;
    var finish = function () {
      if (finished) { return; }
      finished = true;
      try { done(); } catch (err) {}
    };
    if (typeof adBreak !== "function") { finish(); return; }
    adBreak({ type: "next", name: "puzzle-interstitial", adBreakDone: function () { finish(); } });
  };
  window.__cifraShowRewarded = function (done) {
    var finished = false;
    var finish = function (ok) {
      if (finished) { return; }
      finished = true;
      try { done(!!ok); } catch (err) {}
    };
    if (typeof adBreak !== "function") { finish(false); return; }
    adBreak({
      type: "reward",
      name: "daily-challenge",
      beforeReward: function (showAdFn) { showAdFn(); },
      adViewed: function () { finish(true); },
      adDismissed: function () { finish(false); },
      adBreakDone: function (info) {
        if (finished) { return; }
        var status = info && info.breakStatus ? String(info.breakStatus) : "";
        finish(status === "viewed" || status === "completed");
      }
    });
  };
})();
"""
