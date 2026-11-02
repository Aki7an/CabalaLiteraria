extends Control

const CREDITS_SCENE := preload("res://scenes/MenuCredits.tscn")
const LANGUAGE_NOTICE := preload("res://scenes/puzzle_language_notice.gd")
const CREDITS_BLINK_EVERY := 3.0

@onready var button_español: Button = $Panel/LanguageCard/ButtonEspañol
@onready var button_credits: Button = $Panel/Header/ButtonCredits
@onready var button_euskera: Button = $Panel/LanguageCard/ButtonEuskera
@onready var button_ingles: Button = $Panel/LanguageCard/ButtonIngles
@onready var button_frances: Button = $Panel/LanguageCard/ButtonFrances
@onready var button_aleman: Button = $Panel/LanguageCard/ButtonAleman
@onready var button_portugues: Button = $Panel/LanguageCard/ButtonPortugues
@onready var button_italiano: Button = $Panel/LanguageCard/ButtonItaliano

@onready var check_button_music: Button = $Panel/SoundCard/SoundRows/CheckButtonMusic
@onready var check_button_fx: Button = $Panel/SoundCard/SoundRows/CheckButtonFx
@onready var h_slider_sound: HSlider = $Panel/SoundCard/SoundRows/HSliderSound
@onready var h_slider_fx: HSlider = $Panel/SoundCard/SoundRows/HSliderFx
@onready var music_icon_texture: TextureRect = $Panel/SoundCard/SoundRows/MusicIcon/Texture
@onready var music_icon_slash: TextureRect = $Panel/SoundCard/SoundRows/MusicIcon/Slash
@onready var fx_icon_texture: TextureRect = $Panel/SoundCard/SoundRows/FxIcon/Texture
@onready var fx_icon_slash: TextureRect = $Panel/SoundCard/SoundRows/FxIcon/Slash
@onready var nombre: LineEdit = $Panel/OnlineCard/Nombre
@onready var name_slots: HBoxContainer = $Panel/OnlineCard/NameSlots
@onready var title_label: Label = $Panel/Header/Title
@onready var online_title_label: Label = $Panel/OnlineCard/Title
@onready var reset_label: Label = $Panel/Footer/ButtonReset/Text
@onready var game_title_label: Label = $Panel/GameCard/Title
@onready var tutorial_label: Label = $Panel/GameCard/GameRows/TutorialLabel
@onready var reveal_label: Label = $Panel/GameCard/GameRows/RevealLabel
@onready var share_label: Label = $Panel/GameCard/GameRows/ShareLabel
@onready var check_button_tutorial: Button = $Panel/GameCard/GameRows/CheckButtonTutorial
@onready var check_button_reveal: Button = $Panel/GameCard/GameRows/CheckButtonReveal
@onready var check_button_share: Button = $Panel/GameCard/GameRows/CheckButtonShare

var _language_buttons: Dictionary = {}
var _normal_language_styles: Dictionary = {}
var _name_slot_style: StyleBoxFlat
var _name_slot_style_active: StyleBoxFlat
var _updating_name := false
var _updating_audio := false
var _name_before_edit := ""
var _name_typed := ""
var _name_user_edited := false
var _name_commit_running := false
var _name_commit_ok := true

const NAME_MAX_LENGTH := 10

const LOCALIZED_COPY := {
	"es": {
		"title": "Opciones",
		"online_title": "NOMBRE ONLINE",
		"reset": "RESTABLECER VALORES",
		"game_title": "JUEGO",
		"tutorial": "Mostrar tutorial antes de jugar.",
		"reveal": "Mostrar explicación botón COMPROBAR.",
		"share": "Compartir datos de resolución con el desarrollador.",
	},
	"en": {
		"title": "Options",
		"online_title": "ONLINE NAME",
		"reset": "RESET VALUES",
		"game_title": "GAME",
		"tutorial": "Show tutorial before playing.",
		"reveal": "Show CHECK button explanation.",
		"share": "Share puzzle solve data with the developer.",
	},
	"eu": {
		"title": "Aukerak",
		"online_title": "LINEAKO IZENA",
		"reset": "BERREZARRI BALIOAK",
		"game_title": "JOKOA",
		"tutorial": "Erakutsi tutoriala jokatu aurretik.",
		"reveal": "Erakutsi EGIAZTATU botoiaren azalpena.",
		"share": "Partekatu puzzlearen ebazpen-datuak garatzailearekin.",
	},
	"de": {
		"title": "Optionen",
		"online_title": "ONLINE-NAME",
		"reset": "WERTE ZURÜCKSETZEN",
		"game_title": "SPIEL",
		"tutorial": "Tutorial vor dem Spielen anzeigen.",
		"reveal": "Erklärung der PRÜFEN-Taste anzeigen.",
		"share": "Lösedaten mit dem Entwickler teilen.",
	},
	"fr": {
		"title": "Options",
		"online_title": "NOM EN LIGNE",
		"reset": "RÉINITIALISER",
		"game_title": "JEU",
		"tutorial": "Afficher le tutoriel avant de jouer.",
		"reveal": "Afficher l'explication du bouton VÉRIFIER.",
		"share": "Partager les données de résolution avec le développeur.",
	},
	"it": {
		"title": "Opzioni",
		"online_title": "NOME ONLINE",
		"reset": "RIPRISTINA VALORI",
		"game_title": "GIOCO",
		"tutorial": "Mostra il tutorial prima di giocare.",
		"reveal": "Mostra la spiegazione del pulsante VERIFICA.",
		"share": "Condividi i dati di risoluzione con lo sviluppatore.",
	},
	"pt": {
		"title": "Opções",
		"online_title": "NOME ONLINE",
		"reset": "REPOR VALORES",
		"game_title": "JOGO",
		"tutorial": "Mostrar tutorial antes de jogar.",
		"reveal": "Mostrar explicação do botão VERIFICAR.",
		"share": "Partilhar dados de resolução com o programador.",
	},
}


func _ready() -> void:
	_language_buttons = {
		"es": button_español,
		"eu": button_euskera,
		"en": button_ingles,
		"fr": button_frances,
		"de": button_aleman,
		"pt": button_portugues,
		"it": button_italiano,
	}
	for code in _language_buttons:
		var button: Button = _language_buttons[code]
		_normal_language_styles[code] = button.get_theme_stylebox("normal").duplicate()

	nombre.max_length = NAME_MAX_LENGTH
	nombre.focus_entered.connect(_on_nombre_focus_entered)
	nombre.focus_exited.connect(_on_nombre_focus_exited)
	_build_name_slots()
	_set_nombre_text(_sanitize_player_name(GameManager.chosen_online_name_or_empty()))
	_name_before_edit = nombre.text
	_name_typed = nombre.text
	nombre.placeholder_text = ""
	h_slider_fx.set_value_no_signal(PlayerPrefs.volumen_fx)
	h_slider_sound.set_value_no_signal(PlayerPrefs.volumen_musica)
	_refresh_audio_controls()
	if not SignalManager.audio_prefs_changed.is_connected(_refresh_audio_controls):
		SignalManager.audio_prefs_changed.connect(_refresh_audio_controls)
	check_button_tutorial.button_pressed = not PlayerPrefs.onboarding_completed
	check_button_reveal.button_pressed = not PlayerPrefs.skip_reveal_dialog
	check_button_share.button_pressed = PlayerPrefs.share_solve_data
	_update_language_selection()
	_start_credits_blink()
	if typeof(PlayFabTools) != TYPE_NIL and not PlayFabTools.display_name_taken.is_connected(_on_display_name_taken):
		PlayFabTools.display_name_taken.connect(_on_display_name_taken)
	if Distribution.is_horizontal():
		if not resized.is_connected(_apply_horizontal_layout):
			resized.connect(_apply_horizontal_layout)
		call_deferred("_apply_horizontal_layout")


func _on_button_back_pressed() -> void:
	if not await _commit_online_name():
		return
	SoundManager.play("ButtonClick")
	if _is_overlay():
		queue_free()
		return
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	var next_scene := Distribution.home_scene()
	if get_tree().has_meta("cifra_return_scene"):
		var stored := str(get_tree().get_meta("cifra_return_scene")).strip_edges()
		get_tree().remove_meta("cifra_return_scene")
		if stored != "":
			next_scene = stored
	get_tree().change_scene_to_file(next_scene)


func _on_button_credits_pressed() -> void:
	if not await _commit_online_name():
		return
	SoundManager.play("ButtonClick")
	if _is_overlay():
		var credits := CREDITS_SCENE.instantiate()
		if credits.has_method("present_as_overlay"):
			credits.call("present_as_overlay")
		get_parent().add_child(credits)
		if credits is Control:
			var overlay := credits as Control
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overlay.mouse_filter = Control.MOUSE_FILTER_STOP
			overlay.z_index = 20
		return
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	get_tree().change_scene_to_file("res://scenes/MenuCredits.tscn")


func _start_credits_blink() -> void:
	if button_credits == null:
		return
	if not await GameManager.await_process_frame(self):
		return
	if not is_instance_valid(button_credits):
		return
	button_credits.pivot_offset = button_credits.size * 0.5
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(0.7).timeout
	while is_instance_valid(button_credits):
		await _pulse_credits_button()
		if not is_instance_valid(button_credits):
			return
		tree = get_tree()
		if tree == null:
			return
		await tree.create_timer(CREDITS_BLINK_EVERY).timeout


func _pulse_credits_button() -> void:
	if not is_instance_valid(button_credits):
		return
	button_credits.pivot_offset = button_credits.size * 0.5
	var resting := button_credits.scale
	var blink := create_tween()
	blink.tween_property(button_credits, "scale", resting * 1.16, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	blink.parallel().tween_property(button_credits, "modulate", Color(1.12, 0.9, 0.45, 1), 0.16)
	blink.tween_property(button_credits, "scale", resting, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	blink.parallel().tween_property(button_credits, "modulate", Color.WHITE, 0.22)
	blink.tween_property(button_credits, "scale", resting * 1.08, 0.12).set_trans(Tween.TRANS_SINE)
	blink.tween_property(button_credits, "scale", resting, 0.16).set_trans(Tween.TRANS_SINE)
	await blink.finished


func _apply_horizontal_layout() -> void:
	var screen := size
	if screen.x < 64.0 or screen.y < 64.0:
		return
	var margin := 14.0
	var header_h := 68.0
	var footer_h := 86.0
	var gap := 12.0
	var col_gap := 16.0
	var top := margin + header_h + 8.0
	var content_h := screen.y - top - footer_h - margin - 8.0
	if content_h < 80.0:
		return
	var col_w := (screen.x - margin * 2.0 - col_gap) * 0.5
	var left := [$Panel/LanguageCard as Control, $Panel/OnlineCard as Control]
	var right := [$Panel/SoundCard as Control, $Panel/GameCard as Control]
	var stack_h := maxf(_stack_height(left), _stack_height(right))
	if stack_h < 2.0:
		return
	var factor := (content_h - gap) / stack_h
	var width_factor := col_w / maxf(_control_size(left[0]).x, _control_size(right[0]).x)
	factor = minf(factor, width_factor)
	_place_header(Rect2(margin, margin, screen.x - margin * 2.0, header_h))
	_place_column(left, Rect2(margin, top, col_w, content_h), gap, factor)
	_place_column(right, Rect2(margin + col_w + col_gap, top, col_w, content_h), gap, factor)
	_place_footer(Rect2(margin, screen.y - margin - footer_h, screen.x - margin * 2.0, footer_h), factor)


func _stack_height(cards: Array) -> float:
	var total := 0.0
	for card in cards:
		total += _control_size(card as Control).y
	return total


func _place_column(cards: Array, area: Rect2, gap: float, factor: float) -> void:
	var used := 0.0
	for index in cards.size():
		used += _control_size(cards[index] as Control).y * factor
		if index < cards.size() - 1:
			used += gap
	var y := area.position.y + maxf(area.size.y - used, 0.0) * 0.5
	for card in cards:
		var control := card as Control
		var box := _control_size(control)
		var visual := box * factor
		var x := area.position.x + (area.size.x - visual.x) * 0.5
		_set_uniform_scale(control, factor, Vector2(x, y))
		y += visual.y + gap


func _place_header(area: Rect2) -> void:
	var header := $Panel/Header as Control
	header.scale = Vector2.ONE
	header.pivot_offset = Vector2.ZERO
	header.position = area.position
	header.size = area.size
	var back := header.get_node("ButtonBack") as Control
	var credits := header.get_node("ButtonCredits") as Control
	var title := header.get_node("Title") as Label
	var back_box := _control_size(back)
	var credits_box := _control_size(credits)
	if back_box.y < 2.0 or credits_box.y < 2.0:
		return
	var back_factor := area.size.y / back_box.y
	_set_uniform_scale(back, back_factor, Vector2.ZERO)
	var credits_factor := area.size.y / credits_box.y
	var credits_w := credits_box.x * credits_factor
	_set_uniform_scale(credits, credits_factor, Vector2(area.size.x - credits_w, 0.0))
	var inset := back_box.x * back_factor + 8.0
	title.scale = Vector2.ONE
	title.pivot_offset = Vector2.ZERO
	title.position = Vector2(inset, 0.0)
	title.size = Vector2(maxf(area.size.x - inset * 2.0, 40.0), area.size.y)
	title.add_theme_font_size_override("font_size", int(area.size.y * 0.5))


func _place_footer(area: Rect2, factor: float) -> void:
	var footer := $Panel/Footer as Control
	footer.scale = Vector2.ONE
	footer.pivot_offset = Vector2.ZERO
	footer.position = area.position
	footer.size = area.size
	var reset := footer.get_node("ButtonReset") as Control
	var ok := footer.get_node("ButtonOk") as Control
	var gap := 18.0
	var reset_box := _control_size(reset)
	var ok_box := _control_size(ok)
	var button_factor := minf(factor, area.size.y / maxf(reset_box.y, ok_box.y))
	var pair := reset_box.x * button_factor + gap + ok_box.x * button_factor
	if pair > area.size.x:
		button_factor *= area.size.x / pair
		pair = area.size.x
	var x := (area.size.x - pair) * 0.5
	_set_uniform_scale(reset, button_factor, Vector2(x, (area.size.y - reset_box.y * button_factor) * 0.5))
	x += reset_box.x * button_factor + gap
	_set_uniform_scale(ok, button_factor, Vector2(x, (area.size.y - ok_box.y * button_factor) * 0.5))


func _set_uniform_scale(node: Control, factor: float, visual_top_left: Vector2) -> void:
	var box := _control_size(node)
	node.pivot_offset = box * 0.5
	node.scale = Vector2(factor, factor)
	node.position = visual_top_left - box * 0.5 * (1.0 - factor)


func _control_size(node: Control) -> Vector2:
	var box := node.size
	if box.x > 2.0 and box.y > 2.0:
		return box
	box = Vector2(node.offset_right - node.offset_left, node.offset_bottom - node.offset_top)
	if box.x > 2.0 and box.y > 2.0:
		return box
	return node.custom_minimum_size


func _is_overlay() -> bool:
	return get_tree() != null and get_tree().current_scene != self


func _select_language(code: String, button: Button) -> void:
	GameManager.button_blink(button)
	SoundManager.play("ButtonClick")
	var locked := GameManager.locked_puzzle_language()
	if locked != "":
		if code != locked:
			_show_language_notice(locked, code)
		return
	GameManager.apply_language(code)
	_update_language_selection()


func _on_button_español_pressed() -> void:
	_select_language("es", button_español)


func _on_button_ingles_pressed() -> void:
	_select_language("en", button_ingles)


func _on_button_euskera_pressed() -> void:
	_select_language("eu", button_euskera)


func _on_button_aleman_pressed() -> void:
	_select_language("de", button_aleman)


func _on_button_portugues_pressed() -> void:
	_select_language("pt", button_portugues)


func _on_button_italiano_pressed() -> void:
	_select_language("it", button_italiano)


func _on_button_frances_pressed() -> void:
	_select_language("fr", button_frances)


func _on_check_button_fx_toggled(enabled: bool) -> void:
	if _updating_audio:
		return
	var enabling := enabled and not SoundManager.is_fx_enabled()
	if not enabling:
		SoundManager.play("ButtonClick")
	SoundManager.set_fx_enabled(enabled)
	if enabling:
		SoundManager.play("ButtonClick")


func _on_check_button_music_toggled(enabled: bool) -> void:
	if _updating_audio:
		return
	SoundManager.play("ButtonClick")
	SoundManager.set_music_enabled(enabled)


func _on_h_slider_fx_value_changed(value: float) -> void:
	PlayerPrefs.volumen_fx = value
	SoundManager.apply_audio_prefs()
	PlayerPrefs.save_prefs()


func _on_h_slider_sound_value_changed(value: float) -> void:
	PlayerPrefs.volumen_musica = value
	SoundManager.apply_audio_prefs()
	PlayerPrefs.save_prefs()


func _refresh_audio_controls(_unused: Variant = null) -> void:
	_updating_audio = true
	check_button_music.set_pressed_no_signal(SoundManager.is_music_enabled())
	check_button_fx.set_pressed_no_signal(SoundManager.is_fx_enabled())
	check_button_music.queue_redraw()
	check_button_fx.queue_redraw()
	_updating_audio = false
	_set_audio_icon_state(music_icon_texture, music_icon_slash, SoundManager.is_music_enabled())
	_set_audio_icon_state(fx_icon_texture, fx_icon_slash, SoundManager.is_fx_enabled())


func _set_audio_icon_state(icon: TextureRect, slash: TextureRect, enabled: bool) -> void:
	if icon:
		var color := icon.modulate
		color.a = 1.0 if enabled else 0.38
		icon.modulate = color
	if slash:
		slash.visible = not enabled


func _on_nombre_focus_entered() -> void:
	if not _name_user_edited:
		_name_before_edit = nombre.text
		_name_typed = nombre.text
	_refresh_name_slots()


func _on_nombre_text_changed(new_text: String) -> void:
	if _updating_name:
		return
	var caret := nombre.caret_column
	var sanitized := _sanitize_player_name(new_text)
	if _is_spurious_name_restore(sanitized):
		_set_nombre_text(_name_typed)
		nombre.caret_column = _name_typed.length()
		_commit_online_name()
		return
	if sanitized != _name_before_edit:
		_name_user_edited = true
	_name_typed = sanitized
	if sanitized != new_text:
		var removed := new_text.length() - sanitized.length()
		_set_nombre_text(sanitized)
		nombre.caret_column = clampi(caret - removed, 0, sanitized.length())
	else:
		_refresh_name_slots()
	_save_online_name()


func _on_nombre_text_submitted(new_text: String) -> void:
	_set_nombre_text(_sanitize_player_name(new_text))
	_name_typed = nombre.text
	_commit_online_name()
	nombre.release_focus()
	_refresh_name_slots()


func _on_nombre_focus_exited() -> void:
	_commit_online_name()
	_refresh_name_slots()


func _on_button_edit_pressed() -> void:
	nombre.grab_focus()
	if nombre.text.is_empty():
		nombre.caret_column = 0
	else:
		nombre.select_all()
	_refresh_name_slots()


func _is_spurious_name_restore(sanitized: String) -> bool:
	if not _name_user_edited:
		return false
	if sanitized != _name_before_edit or sanitized == _name_typed:
		return false
	return absi(sanitized.length() - _name_typed.length()) > 1


func _on_button_reset_pressed() -> void:
	SoundManager.play("ButtonClick")
	h_slider_sound.set_value_no_signal(0.8)
	h_slider_fx.set_value_no_signal(0.8)
	PlayerPrefs.volumen_musica = 0.8
	PlayerPrefs.volumen_fx = 0.8
	SoundManager.set_music_enabled(true)
	SoundManager.set_fx_enabled(true)
	SoundManager.apply_audio_prefs()
	PlayerPrefs.save_prefs()
	var locked := GameManager.locked_puzzle_language()
	if locked == "":
		GameManager.apply_language("es")
	elif locked != "es":
		_show_language_notice(locked, "es")
	check_button_tutorial.button_pressed = true
	check_button_reveal.button_pressed = true
	check_button_share.button_pressed = false
	PlayerPrefs.set_mostrar_tutorial(true)
	PlayerPrefs.set_show_reveal_explanation(true)
	PlayerPrefs.set_share_solve_data(false)
	PlayerPrefs.set_hide_share_solve_dialog(false)
	_refresh_audio_controls()
	_update_language_selection()


func _on_check_button_tutorial_pressed() -> void:
	SoundManager.play("ButtonClick")
	PlayerPrefs.set_mostrar_tutorial(check_button_tutorial.button_pressed)


func _on_check_button_reveal_pressed() -> void:
	SoundManager.play("ButtonClick")
	PlayerPrefs.set_show_reveal_explanation(check_button_reveal.button_pressed)


func _on_check_button_share_pressed() -> void:
	SoundManager.play("ButtonClick")
	PlayerPrefs.set_share_solve_data(check_button_share.button_pressed)


func _save_online_name() -> void:
	var cleaned := _sanitize_player_name(nombre.text)
	if not GameManager.looks_like_chosen_online_name(cleaned):
		return
	var changed := cleaned != GameManager.player_name or not GameManager.online_name_chosen
	if changed:
		GameManager.set_player_name(cleaned)
		PlayerPrefs.save_prefs()


func _commit_online_name() -> bool:
	if _name_commit_running:
		while _name_commit_running:
			if not await GameManager.await_process_frame(self):
				return false
		return _name_commit_ok
	_name_commit_running = true
	_name_commit_ok = await _commit_online_name_now()
	_name_commit_running = false
	return _name_commit_ok


func _commit_online_name_now() -> bool:
	var cleaned := _sanitize_player_name(nombre.text)
	if not GameManager.looks_like_chosen_online_name(cleaned):
		return true
	var previous := _name_before_edit
	var same_owner := (
		previous != ""
		and cleaned.to_lower() == previous.to_lower()
		and GameManager.has_chosen_online_name()
	)
	if same_owner:
		if cleaned != GameManager.player_name:
			GameManager.set_player_name(cleaned)
			PlayerPrefs.save_prefs()
		_accept_online_name(cleaned)
		if typeof(PlayFabTools) != TYPE_NIL:
			PlayFabTools.sync_player_display_name(cleaned)
		return true
	if cleaned.length() >= 3 and typeof(PlayFabTools) != TYPE_NIL:
		var code := await PlayFabTools.claim_player_display_name(cleaned)
		if code == PlayFabTools.DISPLAY_NAME_TAKEN:
			_restore_online_name(previous)
			PlayFabTools.show_name_taken_dialog()
			return false
		if code == 200:
			GameManager.set_player_name(cleaned)
			PlayerPrefs.save_prefs()
			_accept_online_name(cleaned)
			return true
	if cleaned != GameManager.player_name or not GameManager.online_name_chosen:
		GameManager.set_player_name(cleaned)
		PlayerPrefs.save_prefs()
	if typeof(PlayFabTools) != TYPE_NIL:
		PlayFabTools.sync_player_display_name(cleaned)
	_accept_online_name(cleaned)
	return true


func _accept_online_name(cleaned: String) -> void:
	_name_user_edited = false
	_name_before_edit = cleaned
	_name_typed = cleaned


func _restore_online_name(previous: String) -> void:
	_name_user_edited = false
	_name_typed = previous
	_name_before_edit = previous
	_set_nombre_text(previous)
	if GameManager.looks_like_chosen_online_name(previous):
		GameManager.set_player_name(previous)
	else:
		GameManager.set_player_name("")
	PlayerPrefs.save_prefs()


func _on_display_name_taken(rejected_name: String) -> void:
	if _sanitize_player_name(nombre.text).to_lower() != rejected_name.strip_edges().to_lower():
		return
	var previous := _name_before_edit
	if previous.to_lower() == rejected_name.strip_edges().to_lower():
		previous = ""
	_restore_online_name(previous)


func _sanitize_player_name(text: String) -> String:
	var out := ""
	for i in text.length():
		var ch := text.substr(i, 1)
		if not _is_alphanumeric_char(ch):
			continue
		out += ch
		if out.length() >= NAME_MAX_LENGTH:
			break
	return out


func _is_alphanumeric_char(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code := ch.unicode_at(0)
	var is_upper := code >= 65 and code <= 90
	var is_lower := code >= 97 and code <= 122
	var is_digit := code >= 48 and code <= 57
	return is_upper or is_lower or is_digit


func _set_nombre_text(value: String) -> void:
	_updating_name = true
	nombre.text = value
	_updating_name = false
	_refresh_name_slots()


func _build_name_slots() -> void:
	_name_slot_style = StyleBoxFlat.new()
	_name_slot_style.bg_color = Color(1.0, 0.984, 0.925, 0.92)
	_name_slot_style.border_color = Color(0.77, 0.62, 0.40, 0.55)
	_name_slot_style.set_border_width_all(2)
	_name_slot_style.border_width_bottom = 6
	_name_slot_style.set_corner_radius_all(14)
	_name_slot_style_active = _name_slot_style.duplicate()
	_name_slot_style_active.border_color = Color(0.04, 0.65, 0.64, 0.95)
	_name_slot_style_active.set_border_width_all(3)
	_name_slot_style_active.border_width_bottom = 7
	while name_slots.get_child_count() > 0:
		name_slots.get_child(0).free()
	for _i in NAME_MAX_LENGTH:
		var slot := Panel.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("panel", _name_slot_style)
		var letter := Label.new()
		letter.name = "Letter"
		letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter.set_anchors_preset(Control.PRESET_FULL_RECT)
		letter.add_theme_font_override("font", nombre.get_theme_font("font"))
		letter.add_theme_font_size_override("font_size", 46)
		letter.add_theme_color_override("font_color", Color(0.34, 0.22, 0.15, 1))
		slot.add_child(letter)
		name_slots.add_child(slot)
	_refresh_name_slots()


func _refresh_name_slots() -> void:
	if name_slots == null:
		return
	var value := nombre.text
	var caret := nombre.caret_column if nombre.has_focus() else -1
	var replace_all := (
		nombre.has_focus()
		and nombre.has_selection()
		and not value.is_empty()
		and nombre.get_selected_text() == value
	)
	for i in name_slots.get_child_count():
		var slot := name_slots.get_child(i) as Panel
		if slot == null:
			continue
		var letter := slot.get_node_or_null("Letter") as Label
		if letter:
			if i < value.length():
				letter.text = value.substr(i, 1)
				letter.modulate.a = 1.0
			else:
				letter.text = "_"
				letter.modulate.a = 0.28
		var is_active := nombre.has_focus() and (
			replace_all and i < value.length()
			or (not replace_all and i == mini(caret, NAME_MAX_LENGTH - 1))
		)
		slot.add_theme_stylebox_override(
			"panel",
			_name_slot_style_active if is_active else _name_slot_style
		)


func _process(_delta: float) -> void:
	if is_instance_valid(nombre) and nombre.has_focus():
		_refresh_name_slots()


func _show_language_notice(puzzle_lang: String, other_lang: String) -> void:
	if get_node_or_null("PuzzleLanguageNotice") != null:
		return
	var notice := LANGUAGE_NOTICE.new()
	add_child(notice)
	notice.open(puzzle_lang, other_lang, false)


func _update_language_selection() -> void:
	var locked := GameManager.locked_puzzle_language()
	var current_locale := locked if locked != "" else TranslationServer.get_locale().left(2).to_lower()
	for code in _language_buttons:
		var button: Button = _language_buttons[code]
		var is_selected: bool = code == current_locale
		var blocked: bool = locked != "" and code != locked
		button.modulate = Color(1, 1, 1, 0.38) if blocked else Color.WHITE
		button.get_node("Selected").visible = is_selected
		button.add_theme_stylebox_override(
			"normal",
			_make_selected_language_style() if is_selected else _normal_language_styles[code]
		)
	_update_localized_copy(current_locale)


func _update_localized_copy(_locale: String = "") -> void:
	title_label.text = tr("Options")
	online_title_label.text = tr("OnlineName")
	reset_label.text = tr("ResetValues")
	game_title_label.text = tr("GameSection")
	tutorial_label.text = tr("ShowTutorialBefore")
	reveal_label.text = tr("ShowRevealExplain")
	if share_label:
		var share_text := tr("ShareSolveOption")
		share_label.text = "Compartir datos de resolución con el desarrollador." if share_text == "ShareSolveOption" else share_text
	nombre.placeholder_text = ""
	$Panel/SoundCard/Title.text = tr("SOUND")
	$Panel/SoundCard/SoundRows/MusicLabel.text = tr("Music")
	$Panel/SoundCard/SoundRows/FxLabel.text = tr("Fx")
	$Panel/LanguageCard/Title.text = tr("LANGUAGE")


func _make_selected_language_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#FFFBEF")
	style.border_color = Color("#0AA5A4")
	style.set_border_width_all(7)
	style.set_corner_radius_all(30)
	style.shadow_color = Color(0.04, 0.50, 0.50, 0.16)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 7)
	return style
