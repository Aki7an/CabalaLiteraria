extends Node

const StoreConfig := preload("res://store/store_config.gd")

var _price := ""
var _android: Object = null
var _android_product_ready := false
var _android_purchase_option_id := ""
var _android_offer_id := ""
var _ios: Object = null
var _querying := false
var _busy := false
var _bridge_seen: Dictionary = {}
var _wait_kind := ""
var _wait_result := {}
var _seen_event_keys: Dictionary = {}
var _got_progress := false
var _left_app_during_wait := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if _wait_kind != "":
			_left_app_during_wait = true
			_got_progress = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if OS.get_name() == "iOS":
			_poll_ios_events()
			if _wait_kind != "" and GameManager.has_full_game():
				_finish_wait(_ok_result())

signal purchase_settled(result: Dictionary)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(OS.get_name() == "iOS" or OS.get_name() == "Android")
	if OS.get_name() == "iOS":
		_prepare_ios_bridge()
	if OS.get_name() == "Android":
		_connect_android()
	_query_store_price()


func price_text() -> String:
	var text := _price.strip_edges()
	return text if text != "" else StoreConfig.FALLBACK_PRICE


func is_busy() -> bool:
	return _busy


func can_use_store() -> bool:
	return OS.get_name() == "iOS" or _android != null


func purchase_remove_ads() -> Dictionary:
	if GameManager.has_full_game():
		return _ok_result()
	if _busy:
		return _fail_result("busy")
	if OS.get_name() == "iOS":
		return await _purchase_ios()
	if OS.get_name() == "Android":
		return await _purchase_android()
	return _fail_result("unavailable")


func restore_purchases() -> Dictionary:
	if GameManager.has_full_game():
		return _ok_result()
	if _busy:
		return _fail_result("busy")
	if OS.get_name() == "iOS":
		return await _restore_ios()
	if OS.get_name() == "Android":
		return await _restore_android()
	if GameManager.restore_full_game():
		return _ok_result()
	return _fail_result("none")


func _query_store_price() -> void:
	if _querying:
		return
	if OS.get_name() == "Android" and _start_android_query():
		return
	if OS.get_name() == "iOS" and _start_ios_query():
		return
	_set_price("")


func _connect_android() -> void:
	if not Engine.has_singleton("GodotGooglePlayBilling"):
		push_warning("[IAP] GodotGooglePlayBilling singleton is not available.")
		return
	if _android != null:
		return
	_android = BillingClient.new()
	if _android == null:
		return
	add_child(_android)
	_connect_if_present(_android, "connected", _on_android_connected)
	_connect_if_present(_android, "connect_error", _on_android_failed)
	_connect_if_present(_android, "disconnected", _on_android_failed)
	_connect_if_present(_android, "query_product_details_response", _on_android_products)
	_connect_if_present(_android, "query_purchases_response", _on_android_purchases_updated)
	_connect_if_present(_android, "on_purchase_updated", _on_android_purchase_updated)
	_connect_if_present(_android, "acknowledge_purchase_response", _on_android_acknowledged)


func _start_android_query() -> bool:
	if _android == null:
		_connect_android()
	if _android == null:
		return false
	_querying = true
	if _android.has_method("is_ready") and _android.is_ready():
		_query_android_product()
	elif _android.has_method("get_connection_state") \
			and int(_android.get_connection_state()) == BillingClient.ConnectionState.CONNECTING:
		pass
	elif _android.has_method("start_connection"):
		_android.start_connection()
	else:
		_querying = false
		return false
	_start_timeout()
	return true


func _on_android_connected(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	print("[IAP] Google Play Billing connected.")
	_query_android_product()
	if _wait_kind == "restore":
		_query_android_purchases()


func _query_android_product() -> void:
	var ids := PackedStringArray([StoreConfig.remove_ads_id()])
	if _android != null and _android.has_method("query_product_details"):
		_android.query_product_details(ids, BillingClient.ProductType.INAPP)
	else:
		_finish_query("")


func _on_android_products(products: Variant = null, extra: Variant = null) -> void:
	var response := _android_payload_to_dict(products, extra)
	var response_code := int(response.get("response_code", BillingClient.BillingResponseCode.ERROR))
	var found := _capture_android_purchase_option(response)
	var price := _extract_price(response)
	_android_product_ready = (
		response_code == BillingClient.BillingResponseCode.OK
		and found
	)
	print("[IAP] products ready=", _android_product_ready, " price=", price, " option=", _android_purchase_option_id, " payload=", response)
	if not _android_product_ready:
		push_warning("[IAP] product query failed: %s" % str(response))
	_finish_query(price if _android_product_ready or price != "" else "")


func _android_payload_to_dict(primary: Variant, extra: Variant = null) -> Dictionary:
	if primary is Dictionary:
		return primary
	if extra is Dictionary:
		return extra
	var response := {}
	if primary is Array:
		response["product_details"] = primary
		response["response_code"] = BillingClient.BillingResponseCode.OK
	elif extra is Array:
		response["product_details"] = extra
		response["response_code"] = BillingClient.BillingResponseCode.OK
	return response


func _capture_android_purchase_option(response: Dictionary) -> bool:
	_android_purchase_option_id = ""
	_android_offer_id = ""
	var products: Variant = _first_array(response, [
		"product_details",
		"productDetails",
		"products",
	])
	if not (products is Array):
		return _payload_has_remove_ads(response)
	var wanted := StoreConfig.remove_ads_id()
	for product_variant in products:
		if not (product_variant is Dictionary):
			continue
		var product := product_variant as Dictionary
		var product_id := str(_dict_value(product, ["product_id", "productId", "id"], ""))
		if product_id != "" and product_id != wanted:
			continue
		if product_id == "" and not _payload_has_remove_ads(product):
			continue
		var offers: Variant = _first_array(product, [
			"one_time_purchase_offer_details_list",
			"oneTimePurchaseOfferDetailsList",
			"purchase_options",
			"purchaseOptions",
		])
		if not (offers is Array) or (offers as Array).is_empty():
			var single: Variant = _dict_value(product, [
				"one_time_purchase_offer_details",
				"oneTimePurchaseOfferDetails",
			], {})
			if single is Dictionary and not (single as Dictionary).is_empty():
				offers = [single]
		if offers is Array and not (offers as Array).is_empty():
			var selected: Dictionary = {}
			for offer_variant in offers:
				if not (offer_variant is Dictionary):
					continue
				var offer := offer_variant as Dictionary
				if str(_dict_value(offer, ["offer_id", "offerId"], "")).is_empty():
					selected = offer
					break
			if selected.is_empty() and (offers as Array)[0] is Dictionary:
				selected = (offers as Array)[0] as Dictionary
			_android_purchase_option_id = str(_dict_value(selected, [
				"purchase_option_id",
				"purchaseOptionId",
			], ""))
			# Never send offerToken here: Billing treats it as a real offer_id and rejects the flow.
			_android_offer_id = str(_dict_value(selected, [
				"offer_id",
				"offerId",
			], ""))
		if _android_purchase_option_id.is_empty():
			_android_purchase_option_id = StoreConfig.PRODUCT_OPTION_ANDROID
		return true
	return _payload_has_remove_ads(response)


func _first_array(data: Dictionary, keys: Array) -> Variant:
	for key in keys:
		var value: Variant = data.get(key, null)
		if value is Array:
			return value
	return null


func _dict_value(data: Dictionary, keys: Array, fallback: Variant = "") -> Variant:
	for key in keys:
		if data.has(key) and str(data[key]) != "":
			return data[key]
	return fallback


func _on_android_failed(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	push_warning("[IAP] Google Play Billing error: %s %s" % [str(_a), str(_b)])
	_finish_query("")
	if _wait_kind != "":
		_finish_wait(_fail_result(str(_b) if _b != null else "billing_connection_failed"))


func _on_android_purchase_updated(payload: Variant = null) -> void:
	var response: Dictionary = payload if payload is Dictionary else {}
	var response_code := int(response.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if response_code == BillingClient.BillingResponseCode.USER_CANCELED:
		_finish_wait(_fail_result("cancelled"))
		return
	if response_code != BillingClient.BillingResponseCode.OK:
		var message := str(response.get("debug_message", "purchase_failed"))
		push_warning("[IAP] purchase failed: %s" % message)
		_finish_wait(_fail_result(message))
		return
	if _grant_android_purchase_from_response(response):
		_finish_wait(_ok_result())
	elif _wait_kind == "purchase":
		_finish_wait(_fail_result("pending"))


func _on_android_purchases_updated(payload: Variant = null, _extra: Variant = null) -> void:
	var response: Dictionary = payload if payload is Dictionary else {}
	var response_code := int(response.get("response_code", BillingClient.BillingResponseCode.ERROR))
	if response_code != BillingClient.BillingResponseCode.OK:
		var message := str(response.get("debug_message", "restore_failed"))
		push_warning("[IAP] purchase query failed: %s" % message)
		if _wait_kind == "restore":
			_finish_wait(_fail_result(message))
		return
	if _grant_android_purchase_from_response(response):
		if _wait_kind == "restore" or _wait_kind == "purchase":
			_finish_wait(_ok_result())
	elif _wait_kind == "restore":
		_finish_wait(_fail_result("none"))


func _grant_android_purchase_from_response(response: Dictionary) -> bool:
	var purchases: Variant = response.get("purchases", [])
	if not (purchases is Array):
		return false
	for purchase_variant in purchases:
		if not purchase_variant is Dictionary:
			continue
		var purchase := purchase_variant as Dictionary
		if not _purchase_contains_remove_ads(purchase):
			continue
		if int(purchase.get("purchase_state", BillingClient.PurchaseState.UNSPECIFIED_STATE)) \
				!= BillingClient.PurchaseState.PURCHASED:
			continue
		_grant_full_game()
		if not bool(purchase.get("is_acknowledged", false)):
			var token := str(purchase.get("purchase_token", ""))
			if token != "" and _android != null and _android.has_method("acknowledge_purchase"):
				_android.acknowledge_purchase(token)
		return true
	return false


func _purchase_contains_remove_ads(purchase: Dictionary) -> bool:
	var ids: Variant = purchase.get("product_ids", [])
	if ids is PackedStringArray or ids is Array:
		for product_id in ids:
			if str(product_id) == StoreConfig.remove_ads_id():
				return true
	return str(purchase.get("product_id", "")) == StoreConfig.remove_ads_id()


func _on_android_acknowledged(response: Dictionary) -> void:
	if int(response.get("response_code", BillingClient.BillingResponseCode.ERROR)) \
			!= BillingClient.BillingResponseCode.OK:
		push_warning("[IAP] purchase acknowledgement failed: %s" % str(response))


func _start_ios_query() -> bool:
	_bind_ios_singleton()
	_querying = true
	if _ios != null and _ios.has_method("request_product_info"):
		if _ios.has_method("set_auto_finish_transaction"):
			_ios.set_auto_finish_transaction(true)
		_ios.request_product_info({"product_ids": [StoreConfig.remove_ads_id()]})
	_write_ios_command({"action": "query", "product_id": StoreConfig.remove_ads_id()})
	_start_timeout()
	return true


func _bind_ios_singleton() -> void:
	if _ios != null:
		return
	if Engine.has_singleton("InAppStore"):
		_ios = Engine.get_singleton("InAppStore")


func _ios_bridge_dirs() -> PackedStringArray:
	var dirs: PackedStringArray = []
	var seen := {}
	for dir in [str(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)).strip_edges(), OS.get_user_data_dir()]:
		if dir.is_empty() or seen.has(dir):
			continue
		seen[dir] = true
		dirs.append(dir)
	return dirs


func _prepare_ios_bridge() -> void:
	for dir in _ios_bridge_dirs():
		var marker := FileAccess.open(dir.path_join("cifraletra_iap.dir"), FileAccess.WRITE)
		if marker:
			marker.store_string("ok")
	print("[IAP] ios bridge dirs=", _ios_bridge_dirs(), " ready=", _ios_native_ready())


func _ios_native_ready() -> bool:
	for dir in _ios_bridge_dirs():
		if FileAccess.file_exists(dir.path_join(StoreConfig.IOS_READY)):
			return true
	return false


func _wait_for_native() -> bool:
	if _ios_native_ready():
		return true
	var elapsed := 0.0
	while elapsed < StoreConfig.NATIVE_WAIT_SEC:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if _ios_native_ready():
			return true
	return _ios_native_ready()


func _write_ios_command(command: Dictionary) -> void:
	var payload := JSON.stringify(command)
	var wrote := false
	for dir in _ios_bridge_dirs():
		var file := FileAccess.open(dir.path_join(StoreConfig.IOS_INBOX), FileAccess.WRITE)
		if file == null:
			continue
		file.store_string(payload)
		wrote = true
	if not wrote:
		push_error("StoreManager: cannot write iOS IAP inbox.")
	else:
		print("[IAP] wrote command ", command)


func _poll_ios_events() -> void:
	_bind_ios_singleton()
	if _ios != null and _ios.has_method("get_pending_event_count"):
		while int(_ios.get_pending_event_count()) > 0:
			var event: Variant = _ios.pop_pending_event()
			if typeof(event) == TYPE_DICTIONARY:
				_handle_store_event(event)
	_poll_ios_outbox()


func _poll_ios_outbox() -> void:
	for dir in _ios_bridge_dirs():
		var path := dir.path_join(StoreConfig.IOS_OUTBOX)
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var offset := int(_bridge_seen.get(path, 0))
		var length := file.get_length()
		if offset > length:
			offset = 0
		file.seek(offset)
		while file.get_position() < length:
			var raw := file.get_line().strip_edges()
			if raw.is_empty():
				continue
			var parsed: Variant = JSON.parse_string(raw)
			if typeof(parsed) == TYPE_DICTIONARY:
				_handle_store_event(parsed)
		_bridge_seen[path] = file.get_position()


func _process(_delta: float) -> void:
	if OS.get_name() == "iOS":
		_poll_ios_events()


func _handle_store_event(data: Dictionary) -> void:
	var key := JSON.stringify(data)
	if _seen_event_keys.has(key):
		return
	_seen_event_keys[key] = true
	print("[IAP] event ", data)
	var kind := str(data.get("type", ""))
	var result := str(data.get("result", ""))
	if kind == "product_info":
		if result == "ok":
			_finish_query(_extract_price(data))
		elif _querying:
			_finish_query("")
		return
	if result == "progress":
		_got_progress = true
		return
	var product_id := str(data.get("product_id", ""))
	var matches := product_id.is_empty() or product_id == StoreConfig.remove_ads_id()
	if kind == "purchase" and result == "ok" and matches:
		_grant_full_game()
		_finish_wait(_ok_result())
		return
	if kind == "restore" and result == "ok" and matches:
		_grant_full_game()
		if _wait_kind == "restore":
			return
		_finish_wait(_ok_result())
		return
	if kind == "restore" and result == "completed":
		if GameManager.has_full_game():
			_finish_wait(_ok_result())
		else:
			_finish_wait(_fail_result("none"))
		return
	if result == "error":
		var cancelled := bool(data.get("cancelled", false))
		var message := str(data.get("error", "store_error"))
		if not cancelled and message.to_lower().contains("cancel"):
			cancelled = true
		if _wait_kind != "":
			_finish_wait({"ok": false, "cancelled": cancelled, "error": message, "owned": false})
		elif kind == "product_info":
			_finish_query("")


func _purchase_ios() -> Dictionary:
	_bind_ios_singleton()
	print("[IAP] purchase ", StoreConfig.remove_ads_id())
	if not await _wait_for_native():
		push_error("[IAP] native StoreKit is not running in this build")
		return _fail_result("unavailable")
	_busy = true
	_wait_kind = "purchase"
	_wait_result = {}
	_got_progress = false
	_left_app_during_wait = false
	_write_ios_command({
		"action": "purchase",
		"product_id": StoreConfig.remove_ads_id()
	})
	return await _await_store(StoreConfig.PURCHASE_TIMEOUT_SEC)


func _restore_ios() -> Dictionary:
	_bind_ios_singleton()
	print("[IAP] restore")
	if not await _wait_for_native():
		push_error("[IAP] native StoreKit is not running in this build")
		return _fail_result("unavailable")
	_busy = true
	_wait_kind = "restore"
	_wait_result = {}
	_got_progress = false
	_left_app_during_wait = false
	_write_ios_command({"action": "restore", "product_id": StoreConfig.remove_ads_id()})
	return await _await_store(StoreConfig.PURCHASE_TIMEOUT_SEC)


func _purchase_android() -> Dictionary:
	if _android == null:
		return _fail_result("unavailable")
	if not await _ensure_android_product_ready():
		return _fail_result("product_unavailable")
	_busy = true
	_wait_kind = "purchase"
	_wait_result = {}
	var product_id := StoreConfig.remove_ads_id()
	if not _android.has_method("purchase"):
		_busy = false
		_wait_kind = ""
		return _fail_result("unavailable")
	var option_id := _android_purchase_option_id
	if option_id.is_empty():
		option_id = StoreConfig.PRODUCT_OPTION_ANDROID
	print("[IAP] purchase ", product_id, " option=", option_id, " offer=", _android_offer_id)
	var launch_result: Variant = _android.purchase(
		product_id,
		option_id,
		""
	)
	if launch_result is Dictionary:
		var code := int((launch_result as Dictionary).get(
			"response_code",
			BillingClient.BillingResponseCode.OK
		))
		if code == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
			_query_android_purchases()
		elif code != BillingClient.BillingResponseCode.OK:
			_busy = false
			_wait_kind = ""
			return _fail_result(str((launch_result as Dictionary).get(
				"debug_message",
				"purchase_failed"
			)))
	return await _await_store(StoreConfig.PURCHASE_TIMEOUT_SEC)


func _restore_android() -> Dictionary:
	if _android == null:
		return _fail_result("unavailable")
	_busy = true
	_wait_kind = "restore"
	_wait_result = {}
	if _android.has_method("is_ready") and _android.is_ready():
		_query_android_purchases()
	elif _android.has_method("start_connection"):
		_android.start_connection()
	else:
		_busy = false
		_wait_kind = ""
		if GameManager.restore_full_game():
			return _ok_result()
		return _fail_result("none")
	return await _await_store(StoreConfig.QUERY_TIMEOUT_SEC)


func _ensure_android_product_ready() -> bool:
	if _android_product_ready:
		return true
	if not _querying:
		_start_android_query()
	var started_at := Time.get_ticks_msec()
	var max_ms := int(StoreConfig.QUERY_TIMEOUT_SEC * 1000.0)
	while not _android_product_ready and _querying:
		await get_tree().process_frame
		if Time.get_ticks_msec() - started_at >= max_ms:
			break
	return _android_product_ready


func _query_android_purchases() -> void:
	if _android != null and _android.has_method("query_purchases"):
		_android.query_purchases(BillingClient.ProductType.INAPP)
	elif _wait_kind == "restore":
		_finish_wait(_fail_result("unavailable"))


func _await_store(timeout_sec: float) -> Dictionary:
	var started_at := Time.get_ticks_msec()
	var sheet_limit_ms := int(StoreConfig.SHEET_WAIT_SEC * 1000.0)
	var max_ms := int(timeout_sec * 1000.0)
	while _wait_kind != "":
		if OS.get_name() == "iOS":
			_poll_ios_events()
		if _wait_kind == "purchase" and GameManager.has_full_game():
			_finish_wait(_ok_result())
			break
		await get_tree().process_frame
		if OS.get_name() == "iOS":
			_poll_ios_events()
		var elapsed := Time.get_ticks_msec() - started_at
		if _got_progress or _left_app_during_wait:
			if elapsed >= max_ms:
				_finish_wait(_fail_result("timeout"))
				break
		elif elapsed >= sheet_limit_ms:
			_finish_wait(_fail_result("timeout"))
			break
	if OS.get_name() == "iOS":
		_bridge_seen.clear()
		_poll_ios_events()
	_busy = false
	if GameManager.has_full_game():
		return _ok_result()
	var result: Dictionary = _wait_result
	_wait_result = {}
	if result.is_empty():
		return _fail_result("timeout")
	return result


func _finish_wait(result: Dictionary) -> void:
	if _wait_kind == "":
		return
	_wait_kind = ""
	_wait_result = result
	purchase_settled.emit(result)


func _grant_full_game() -> void:
	GameManager.unlock_full_game()


func _ok_result() -> Dictionary:
	return {"ok": true, "cancelled": false, "error": "", "owned": true}


func _fail_result(code: String) -> Dictionary:
	return {"ok": false, "cancelled": code == "cancelled", "error": code, "owned": GameManager.has_full_game()}


func _start_timeout() -> void:
	var timer := get_tree().create_timer(StoreConfig.QUERY_TIMEOUT_SEC)
	timer.timeout.connect(func() -> void:
		if _querying:
			_finish_query(_price)
	)


func _finish_query(price: String) -> void:
	_querying = false
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
	for key in ["formatted_price", "formattedPrice", "localized_price", "localizedPrice", "price"]:
		var value := str(data.get(key, "")).strip_edges()
		if value != "" and not _looks_like_product_id(value):
			return value
	var offer: Variant = data.get("one_time_purchase_offer_details", data.get("oneTimePurchaseOfferDetails", {}))
	if offer is Dictionary:
		var formatted := str(offer.get("formatted_price", "")).strip_edges()
		if formatted != "":
			return formatted
	for key in [
		"localized_prices",
		"prices",
		"products",
		"product_details",
		"purchaseOptions",
		"one_time_purchase_offer_details",
		"oneTimePurchaseOfferDetails",
		"one_time_purchase_offer_details_list",
		"oneTimePurchaseOfferDetailsList",
	]:
		var found := _extract_price(data.get(key, null))
		if found != "":
			return found
	return ""


func _payload_has_remove_ads(payload: Variant) -> bool:
	var needle := StoreConfig.remove_ads_id()
	var raw := str(payload)
	if raw.contains(needle):
		return true
	if payload is Dictionary:
		return _extract_price(payload) != "" or str(payload.get("product_id", "")) == needle
	if payload is Array:
		for item in payload:
			if _payload_has_remove_ads(item):
				return true
	return false


func _looks_like_product_id(value: String) -> bool:
	return value == StoreConfig.remove_ads_id() or value.begins_with("com.")


func _connect_if_present(host: Object, signal_name: String, cb: Callable) -> void:
	if host == null or not host.has_signal(signal_name):
		return
	if host.is_connected(signal_name, cb):
		return
	host.connect(signal_name, cb)
