extends RefCounted

## Google test IDs until production AdMob / AdSense units are set.
## Android/iOS: install "AdMob Plugin" by Poing Studios from the AssetLib,
## then replace the app and unit IDs below with your AdMob values.
## HTML: replace ADSENSE_CLIENT with your AdSense publisher (ca-pub-…).
const USE_TEST_ADS := true
const H5_TEST_MODE := true

const ADMOB_APP_ID_ANDROID := "ca-app-pub-3940256099942544~3347511713"
const ADMOB_APP_ID_IOS := "ca-app-pub-3940256099942544~1458002511"

const ANDROID_INTERSTITIAL_TEST := "ca-app-pub-3940256099942544/1033173712"
const IOS_INTERSTITIAL_TEST := "ca-app-pub-3940256099942544/4411468910"
const ANDROID_REWARDED_TEST := "ca-app-pub-3940256099942544/5224354917"
const IOS_REWARDED_TEST := "ca-app-pub-3940256099942544/1712485313"

const ANDROID_INTERSTITIAL := ANDROID_INTERSTITIAL_TEST
const IOS_INTERSTITIAL := IOS_INTERSTITIAL_TEST
const ANDROID_REWARDED := ANDROID_REWARDED_TEST
const IOS_REWARDED := IOS_REWARDED_TEST

## AdSense client for H5 Games Ads on the web export.
const ADSENSE_CLIENT := "ca-pub-3940256099942544"

const QUICK_PUZZLES_PER_INTERSTITIAL := 2
const INTERSTITIAL_TIMEOUT_SEC := 8.0
const REWARDED_TIMEOUT_SEC := 20.0
const MOCK_INTERSTITIAL_SEC := 1.4
const MOCK_REWARDED_SEC := 2.0


static func is_ios() -> bool:
	return OS.get_name() == "iOS"


static func interstitial_unit_id() -> String:
	if is_ios():
		return IOS_INTERSTITIAL_TEST if USE_TEST_ADS else IOS_INTERSTITIAL
	return ANDROID_INTERSTITIAL_TEST if USE_TEST_ADS else ANDROID_INTERSTITIAL


static func rewarded_unit_id() -> String:
	if is_ios():
		return IOS_REWARDED_TEST if USE_TEST_ADS else IOS_REWARDED
	return ANDROID_REWARDED_TEST if USE_TEST_ADS else ANDROID_REWARDED


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
