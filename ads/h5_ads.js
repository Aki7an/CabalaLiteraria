(function () {
  if (window.__cifraAdsInit) {
    return;
  }
  window.__cifraAdsInit = true;
  window.adsbygoogle = window.adsbygoogle || [];
  var client = window.__cifraAdsenseClient || "ca-pub-3940256099942544";
  if (!document.querySelector("script[data-cifra-h5ads]")) {
    var script = document.createElement("script");
    script.async = true;
    script.setAttribute("data-cifra-h5ads", "1");
    script.setAttribute("data-ad-frequency-hint", "30s");
    if (window.__cifraH5Test) {
      script.setAttribute("data-adbreak-test", "on");
    }
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
      if (finished) {
        return;
      }
      finished = true;
      try {
        done();
      } catch (err) {}
    };
    if (typeof adBreak !== "function") {
      finish();
      return;
    }
    adBreak({
      type: "next",
      name: "puzzle-interstitial",
      adBreakDone: function () {
        finish();
      }
    });
  };
  window.__cifraShowRewarded = function (done) {
    var finished = false;
    var finish = function (ok) {
      if (finished) {
        return;
      }
      finished = true;
      try {
        done(!!ok);
      } catch (err) {}
    };
    if (typeof adBreak !== "function") {
      finish(false);
      return;
    }
    adBreak({
      type: "reward",
      name: "daily-challenge",
      beforeReward: function (showAdFn) {
        showAdFn();
      },
      adViewed: function () {
        finish(true);
      },
      adDismissed: function () {
        finish(false);
      },
      adBreakDone: function (info) {
        if (finished) {
          return;
        }
        var status = info && info.breakStatus ? String(info.breakStatus) : "";
        finish(status === "viewed" || status === "completed");
      }
    });
  };
})();
