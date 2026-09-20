extends RefCounted

## Store links used in the share text.
const STORE_URL_ANDROID := "https://play.google.com/store/apps/details?id=com.akidev.cifraletra"
const STORE_URL_IOS := "https://apps.apple.com/app/id6807821718"
const TWITTER_PACKAGE_ANDROID := "com.twitter.android"
const INSTAGRAM_PACKAGE_ANDROID := "com.instagram.android"
const FACEBOOK_PACKAGE_ANDROID := "com.facebook.katana"
const TIKTOK_PACKAGE_ANDROID := "com.zhiliaoapp.musically"
const CARD_WIDTH := 1080
const CARD_HEIGHT := 1350
const PNG_NAME := "cifraletra_share.png"
const IOS_INBOX := "cifraletra_share_inbox.json"
const STUDIO := "Arima Play"
const FILE_PROVIDER_SUFFIX := ".fileprovider"


static func store_url() -> String:
	if OS.get_name() == "iOS":
		return STORE_URL_IOS
	return STORE_URL_ANDROID


static func android_package(network: String) -> String:
	match network:
		"x":
			return TWITTER_PACKAGE_ANDROID
		"instagram":
			return INSTAGRAM_PACKAGE_ANDROID
		"facebook":
			return FACEBOOK_PACKAGE_ANDROID
		"tiktok":
			return TIKTOK_PACKAGE_ANDROID
		_:
			return ""
