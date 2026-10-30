class_name Callbacks

signal sdk_initialized
signal adblock_detection_result(has_adblock: bool)
signal ad_status_change
signal ad_started
signal ad_finished
signal ad_error(error: Dictionary)
signal auth_listener_complete(user: Dictionary)
signal show_auth_prompt_complete(user: Dictionary)
signal show_account_link_prompt_complete(response: Dictionary)
signal get_user_complete(user: Dictionary)
signal get_user_token_complete(token: String)
signal get_xsolla_user_token_complete(token: String)

var onSdkInitialized: JavaScriptObject
var onAdblockDetectionResult: JavaScriptObject
var onAuthListener: JavaScriptObject
var adStatusChange: JavaScriptObject
var adStarted: JavaScriptObject
var adFinished: JavaScriptObject
var adError: JavaScriptObject
var showAuthPrompt: JavaScriptObject
var showAccountLinkPrompt: JavaScriptObject
var getUser: JavaScriptObject
var getUserToken: JavaScriptObject
var getXsollaUserToken: JavaScriptObject

func init():
	onSdkInitialized = JavaScriptBridge.create_callback(_on_sdk_initialized)
	onAdblockDetectionResult = JavaScriptBridge.create_callback(_on_adblock_detection_result)
	onAuthListener = JavaScriptBridge.create_callback(_on_auth_listener)
	adStatusChange = JavaScriptBridge.create_callback(_on_ad_status_change)
	adStarted = JavaScriptBridge.create_callback(_on_ad_started)
	adFinished = JavaScriptBridge.create_callback(_on_ad_finished)
	adError = JavaScriptBridge.create_callback(_on_ad_error)
	showAuthPrompt = JavaScriptBridge.create_callback(_on_show_auth_prompt_callback)
	showAccountLinkPrompt = JavaScriptBridge.create_callback(_on_show_account_link_prompt_callback)
	getUser = JavaScriptBridge.create_callback(_on_get_user_callback)
	getUserToken = JavaScriptBridge.create_callback(_on_get_user_token_callback)
	getXsollaUserToken = JavaScriptBridge.create_callback(_on_get_xsolla_user_token_callback)
	var window = JavaScriptBridge.get_interface("window")
	
	window.onSdkInitialized = onSdkInitialized	
	window.onAdblockDetectionResult = onAdblockDetectionResult
	window.onAuthListener = onAuthListener
	window.onAdStatusChange = adStatusChange
	window.onAdStarted = adStarted
	window.onAdFinished = adFinished
	window.onAdError = adError
	window.onShowAuthPrompt = showAuthPrompt
	window.onShowAccountLinkPrompt = showAccountLinkPrompt
	window.onGetUser = getUser
	window.onGetUserToken = getUserToken
	window.onGetXsollaUserToken = getXsollaUserToken
	

func _on_sdk_initialized(_args):
	emit_signal("sdk_initialized")

func _on_adblock_detection_result(args):
	emit_signal("adblock_detection_result", args[0])

func _on_ad_status_change(args):
	var data = JSON.parse_string(args[0])
	
	if "state" in data:
		ad_status_change.emit(data)
		if (data["state"] == "started"):
			emit_signal("ad_started")
		elif (data["state"] == "finished"):
			emit_signal("ad_finished")
		else:
			emit_signal("ad_error", JSON.parse_string(data["error"]))
	else:
		emit_signal("ad_error", JSON.parse_string("{ \"error\": \"invalid JSON\" }"))

func _on_ad_started(_args):
	emit_signal("ad_started")

func _on_ad_finished(_args):
	emit_signal("ad_finished")

func _on_ad_error(args):
	var error_dict = JSON.parse_string(args[0])
	emit_signal("ad_error", error_dict)

func _on_auth_listener(args):
	emit_signal("auth_listener_complete", _user_from_payload(args))

func _on_show_auth_prompt_callback(args):
	emit_signal("show_auth_prompt_complete", _user_from_payload(args))

func _on_show_account_link_prompt_callback(args):
	emit_signal("show_account_link_prompt_complete", _object_from_payload(args, "response"))

func _on_get_user_callback(args):
	emit_signal("get_user_complete", _user_from_payload(args))


func _user_from_payload(args: Array) -> Dictionary:
	return _object_from_payload(args, "user")


func _object_from_payload(args: Array, key: String) -> Dictionary:
	if args.is_empty():
		return {}
	var data := _as_dictionary(args[0])
	if data.is_empty():
		return {}
	if data.has("error"):
		return _as_dictionary(data["error"])
	if data.has(key):
		return _as_dictionary(data[key])
	if data.has("username"):
		return data
	return {}


func _as_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	if value is String and not value.is_empty():
		var parsed: Variant = JSON.parse_string(value)
		if parsed is Dictionary:
			return parsed
	return {}

func _on_get_user_token_callback(args):
	var data := _as_dictionary(args[0] if not args.is_empty() else "")
	var token := str(data.get("token", "")).strip_edges()
	emit_signal("get_user_token_complete", token)

func _on_get_xsolla_user_token_callback(args):
	var data = args[0]
	if data.has("token"):
		emit_signal("get_xsolla_user_token_complete", data["token"])
	elif data.has("error"):
		emit_signal("get_xsolla_user_token_complete", data["error"])
