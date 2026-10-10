extends Node

## On the main menu, compares the installed version with the one published
## on the store. iOS reads Apple's lookup. Android reads docs/version.json
## on the support site. A failed request leaves the game as it is.

const IOS_LOOKUP := "https://itunes.apple.com/lookup?id=6807821718"
const ANDROID_VERSION_URL := "https://aki7an.github.io/CabalaLiteraria/version.json"
const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const ShareConfig := preload("res://store/share_config.gd")

var _dismissed := false
var _attempted := false
var _latest_version := ""
var _request: HTTPRequest
var _host: Node


func prompt(host: Node) -> void:
	if _dismissed or host == null or not is_instance_valid(host):
		return
	if Engine.has_meta("store_screenshot"):
		return
	var os_name := OS.get_name()
	if os_name != "iOS" and os_name != "Android":
		return
	_host = host
	if _latest_version != "":
		_present()
		return
	if _request != null or _attempted:
		return
	_attempted = true
	_request = HTTPRequest.new()
	_request.timeout = 8.0
	_request.request_completed.connect(_on_completed)
	add_child(_request)
	if _request.request(_url_for(os_name)) != OK:
		_clear_request()


func _url_for(os_name: String) -> String:
	if os_name == "iOS":
		return IOS_LOOKUP
	return ANDROID_VERSION_URL


func _on_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var latest := ""
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		latest = _parse_latest(body.get_string_from_utf8())
	_clear_request()
	if latest.is_empty() or not _is_newer(latest, _installed_version()):
		return
	_latest_version = latest
	_present()


func _clear_request() -> void:
	if _request != null and is_instance_valid(_request):
		_request.queue_free()
	_request = null


func _parse_latest(raw: String) -> String:
	var parsed: Variant = JSON.parse_string(raw.strip_edges())
	if OS.get_name() == "iOS":
		if parsed is Dictionary:
			var results: Variant = parsed.get("results", [])
			if results is Array and not results.is_empty() and results[0] is Dictionary:
				return str(results[0].get("version", "")).strip_edges()
		return ""
	if parsed is Dictionary:
		return str(parsed.get("android", "")).strip_edges()
	return ""


func _installed_version() -> String:
	return PlayerPrefs.version_name().strip_edges()


func _is_newer(latest: String, current: String) -> bool:
	var published := _parts(latest)
	var installed := _parts(current)
	if published.is_empty() or installed.is_empty():
		return false
	var count := maxi(published.size(), installed.size())
	for index in count:
		var next_part := published[index] if index < published.size() else 0
		var have_part := installed[index] if index < installed.size() else 0
		if next_part > have_part:
			return true
		if next_part < have_part:
			return false
	return false


func _parts(version: String) -> Array[int]:
	var parts: Array[int] = []
	for piece in version.strip_edges().split(".", false):
		var digits := ""
		for ch in piece:
			if ch >= "0" and ch <= "9":
				digits += ch
			else:
				break
		if digits.is_empty():
			return []
		parts.append(int(digits))
	return parts


func _present() -> void:
	if _dismissed or _latest_version.is_empty():
		return
	if _host == null or not is_instance_valid(_host) or not _host.is_inside_tree():
		return
	if _host.get_node_or_null("UpdateAvailableDialog") != null:
		return
	var overlay := ColorRect.new()
	overlay.name = "UpdateAvailableDialog"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.08, 0.04, 0.02, 0.58)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 120
	_host.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(980, 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 0.965, 0.86, 1)
	card_style.border_color = Color(0.62, 0.4, 0.16, 0.46)
	card_style.set_border_width_all(4)
	card_style.border_width_bottom = 9
	card_style.set_corner_radius_all(48)
	card_style.shadow_color = Color(0.14, 0.08, 0.03, 0.34)
	card_style.shadow_size = 24
	card_style.shadow_offset = Vector2(0, 17)
	card_style.content_margin_left = 48
	card_style.content_margin_right = 48
	card_style.content_margin_top = 40
	card_style.content_margin_bottom = 36
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 22)
	card.add_child(inner)
	inner.add_child(_label(_text("title"), 46, Color(0.24, 0.14, 0.08, 1), HORIZONTAL_ALIGNMENT_CENTER))
	inner.add_child(_label(_text("body"), 34, Color(0.28, 0.17, 0.1, 1), HORIZONTAL_ALIGNMENT_LEFT))

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	inner.add_child(buttons)
	var store := _button(_text("store"), Color(0.18, 0.65, 0.46, 1), Color(0.1, 0.42, 0.3, 1), Color.WHITE)
	store.pressed.connect(_open_store)
	buttons.add_child(store)
	var later := _button(_text("later"), Color(1, 0.982, 0.92, 1), Color(0.66, 0.44, 0.2, 0.7), Color(0.32, 0.18, 0.08, 1))
	later.pressed.connect(_keep_playing)
	buttons.add_child(later)


func _label(text: String, size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, fill: Color, border: Color, font_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 120)
	button.add_theme_font_override("font", FONT_UI)
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", font_color)
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.border_width_bottom = 8
	style.set_corner_radius_all(30)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	return button


func _open_store() -> void:
	SoundManager.play("ButtonClick")
	OS.shell_open(ShareConfig.store_url())


func _keep_playing() -> void:
	SoundManager.play("ButtonClick")
	_dismissed = true
	if _host != null and is_instance_valid(_host):
		var overlay := _host.get_node_or_null("UpdateAvailableDialog")
		if overlay != null:
			overlay.queue_free()


func _text(key: String) -> String:
	var lookup := "UpdateAvailable" + key.capitalize()
	var translated := tr(lookup)
	if translated != lookup and not translated.is_empty():
		return translated
	var lang := TranslationServer.get_locale().substr(0, 2).to_lower()
	var table: Dictionary = _COPY.get(lang, _COPY["en"])
	return str(table.get(key, _COPY["en"][key]))


const _COPY := {
	"es": {
		"title": "Hay una actualización",
		"body": "Hay una versión nueva de CifraLetra en la tienda. Puedes actualizar ahora o seguir jugando con esta.",
		"store": "Ir a la tienda",
		"later": "Seguir jugando",
	},
	"en": {
		"title": "An update is available",
		"body": "A newer version of CifraLetra is on the store. You can update now or keep playing with this one.",
		"store": "Go to the store",
		"later": "Keep playing",
	},
	"de": {
		"title": "Ein Update ist verfügbar",
		"body": "Eine neuere Version von CifraLetra liegt im Store. Du kannst jetzt aktualisieren oder mit dieser Version weiterspielen.",
		"store": "Zum Store",
		"later": "Weiterspielen",
	},
	"fr": {
		"title": "Une mise à jour est disponible",
		"body": "Une nouvelle version de CifraLetra est en boutique. Tu peux la télécharger maintenant ou continuer avec celle-ci.",
		"store": "Aller à la boutique",
		"later": "Continuer à jouer",
	},
	"eu": {
		"title": "Eguneratze bat dago",
		"body": "CifraLetraren bertsio berri bat dago dendan. Orain egunera dezakezu edo honekin jolasten jarraitu.",
		"store": "Joan dendara",
		"later": "Jarraitu jolasten",
	},
	"it": {
		"title": "C'è un aggiornamento",
		"body": "C'è una nuova versione di CifraLetra sullo store. Puoi aggiornare ora o continuare a giocare con questa.",
		"store": "Vai allo store",
		"later": "Continua a giocare",
	},
	"pt": {
		"title": "Há uma atualização",
		"body": "Há uma versão nova do CifraLetra na loja. Podes atualizar agora ou continuar a jogar com esta.",
		"store": "Ir para a loja",
		"later": "Continuar a jogar",
	},
}
