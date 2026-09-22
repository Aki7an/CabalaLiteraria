extends RefCounted

## Product IDs must match App Store Connect / Google Play Console.
const PRODUCT_REMOVE_ADS_ANDROID := "cifraletra_remove_ads"
const PRODUCT_OPTION_ANDROID := "remove-ads"
const PRODUCT_REMOVE_ADS_IOS := "com.aki7an.cifraletra.removeads"
const FALLBACK_PRICE := "2,99 €"
const QUERY_TIMEOUT_SEC := 8.0
const PURCHASE_TIMEOUT_SEC := 180.0
const IOS_INBOX := "cifraletra_iap_inbox.json"
const IOS_OUTBOX := "cifraletra_iap_outbox.jsonl"
const IOS_READY := "cifraletra_iap_ready"
const NATIVE_WAIT_SEC := 3.0
const SHEET_WAIT_SEC := 60.0


static func remove_ads_id() -> String:
	if OS.get_name() == "iOS":
		return PRODUCT_REMOVE_ADS_IOS
	return PRODUCT_REMOVE_ADS_ANDROID
