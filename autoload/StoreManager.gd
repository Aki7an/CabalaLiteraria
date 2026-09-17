extends Node

const StoreConfig := preload("res://store/store_config.gd")

var _price := ""
var _android: Object = null
var _ios: Object = null
var _querying := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	_query_store_price()


func price_text() -> String:
	var text := _price.strip_edges()
	return text if text != "" else StoreConfig.FALLBACK_PRICE


func _query_store_price() -> void:
	if _querying:
		return
	if OS.get_name() == "Android" and _start_android_query():
		return
	if OS.get_name() == "iOS" and _start_ios_query():
		return
	_set_price("")


func _start_android_query() -> bool:
	if not Engine.has_singleton("GodotGooglePlayBilling"):
		return false
	_android = Engine.get_singleton("GodotGooglePlayBilling")
	if _android == null:
		return false
	_querying = true
	_connect_if_present(_android, "connected", _on_android_connected)
	_connect_if_present(_android, "connect_error", _on_android_failed)
	_connect_if_present(_android, "disconnected", _on_android_failed)
	_connect_if_present(_android, "product_details_query_completed", _on_android_products)
	_connect_if_present(_android, "product_details_query_error", _on_android_failed)
	_connect_if_present(_android, "sku_details_query_completed", _on_android_products)
	_connect_if_present(_android, "sku_details_query_error", _on_android_failed)
	if _android.has_method("startConnection"):
		_android.startConnection()
	elif _android.has_method("start_connection"):
		_android.start_connection()
	else:
		_querying = false
		return false
	_start_timeout()
	return true


func _on_android_connected(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	var ids := PackedStringArray([StoreConfig.PRODUCT_REMOVE_ADS])
	if _android != null and _android.has_method("queryProductDetails"):
		_android.queryProductDetails(ids, "inapp")
	elif _android != null and _android.has_method("querySkuDetails"):
		_android.querySkuDetails(ids, "inapp")
	else:
		_finish_query("")


func _on_android_products(products: Variant = null, _extra: Variant = null) -> void:
	_finish_query(_extract_price(products))


func _on_android_failed(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	_finish_query("")


func _start_ios_query() -> bool:
	if not Engine.has_singleton("InAppStore"):
		return false
	_ios = Engine.get_singleton("InAppStore")
	if _ios == null or not _ios.has_method("request_product_info"):
		return false
	_querying = true
	_ios.request_product_info({"product_ids": [StoreConfig.PRODUCT_REMOVE_ADS]})
	set_process(true)
	_start_timeout()
	return true


func _process(_delta: float) -> void:
	if _ios == null or not _ios.has_method("get_pending_event_count"):
		set_process(false)
		return
	while int(_ios.get_pending_event_count()) > 0:
		var event: Variant = _ios.pop_pending_event()
		if typeof(event) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = event
		var kind := str(data.get("type", ""))
		if kind != "product_info":
			continue
		if str(data.get("result", "")) != "ok":
			_finish_query("")
			return
		_finish_query(_extract_price(data))
		return


func _start_timeout() -> void:
	var timer := get_tree().create_timer(StoreConfig.QUERY_TIMEOUT_SEC)
	timer.timeout.connect(func() -> void:
		if _querying:
			_finish_query(_price)
	)


func _finish_query(price: String) -> void:
	_querying = false
	set_process(false)
	_set_price(price)


func _set_price(price: String) -> void:
	var next := price.strip_edges()
	if _price == next:
		return
	_price = next
	SignalManager.store_price_changed.emit()


func _extract_price(payload: Variant) -> String:
	if payload == null:
		return ""
	if payload is String:
		return (payload as String).strip_edges()
	if payload is Dictionary:
		return _price_from_dict(payload)
	if payload is Array:
		for item in payload:
			var found := _extract_price(item)
			if found != "":
				return found
	return ""


func _price_from_dict(data: Dictionary) -> String:
	for key in ["formatted_price", "localized_price", "localizedPrice", "price"]:
		var value := str(data.get(key, "")).strip_edges()
		if value != "" and not _looks_like_product_id(value):
			return value
	var offer: Variant = data.get("one_time_purchase_offer_details", {})
	if offer is Dictionary:
		var formatted := str(offer.get("formatted_price", "")).strip_edges()
		if formatted != "":
			return formatted
	for key in ["localized_prices", "prices", "products"]:
		var found := _extract_price(data.get(key, null))
		if found != "":
			return found
	return ""


func _looks_like_product_id(value: String) -> bool:
	return value == StoreConfig.PRODUCT_REMOVE_ADS or value.begins_with("com.")


func _connect_if_present(host: Object, signal_name: String, cb: Callable) -> void:
	if host == null or not host.has_signal(signal_name):
		return
	if host.is_connected(signal_name, cb):
		return
	host.connect(signal_name, cb)
