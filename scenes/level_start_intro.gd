extends ColorRect

signal finished

const FONT_UI: Font = preload("res://GUI/new_font_Rubik_semibold.tres")
const STAR_TEXTURE: Texture2D = preload("res://images/estrella_plano.png")
const ICON_BULB: Texture2D = preload("res://images/ui_icon_bulb_white.svg")
const ICON_EYE: Texture2D = preload("res://GUI/Library/Demo/Demo_ItemIcon_(OriginalSize)/itemicon_eye.png")
const CHIME_SFX: AudioStream = preload("res://audio/MultimediaChime_SFXB.2894.wav")

const COLOR_INK := Color(0.24, 0.14, 0.08, 1)
const COLOR_BODY := Color(0.32, 0.2, 0.12, 1)
const CARD_WIDTH := 1120.0
const FADE_IN_SEC := 0.35
const FADE_OUT_SEC := 1.0
const LINE_DELAY := 0.12
const STAR_STAGGER := 0.18
const FLY_SEC := 0.42
const TRAIL_GAP := 0.03
const TRAIL_LIFE := 0.45
const COPY := {
	"LevelStartTitle": {
		"es": "Nivel con %d estrellas",
		"en": "Level with %d stars",
		"de": "Level mit %d Sternen",
		"fr": "Niveau à %d étoiles",
		"eu": "Maila %d izarrekin",
		"it": "Livello da %d stelle",
		"pt": "Nível com %d estrelas",
	},
	"LevelStartHintsBefore": {
		"es": "Recuerda que si tienes dificultades puedes utilizar las",
		"en": "Remember that if you get stuck you can use",
		"de": "Denk daran: Wenn du nicht weiterkommst, kannst du",
		"fr": "Souviens-toi que si tu as des difficultés tu peux utiliser",
		"eu": "Gogoratu zailtasunak badituzu erabil ditzakezula",
		"it": "Ricorda che se hai difficoltà puoi usare",
		"pt": "Lembra-te de que se tiveres dificuldades podes usar",
	},
	"LevelStartHintsAfter": {
		"es": "Cada pista vale una estrella, pero te ayudan a terminar el puzle.",
		"en": "Each hint costs one star, but they help you finish the puzzle.",
		"de": "Jeder Hinweis kostet einen Stern, hilft dir aber, das Rätsel zu beenden.",
		"fr": "Chaque indice coûte une étoile, mais ils t'aident à terminer le puzzle.",
		"eu": "Pista bakoitzak izar bat balio du, baina puzzlea amaitzen laguntzen dizute.",
		"it": "Ogni indizio costa una stella, ma ti aiutano a finire il puzzle.",
		"pt": "Cada dica vale uma estrela, mas ajudam-te a terminar o puzzle.",
	},
	"LevelStartRevealBefore": {
		"es": "Recuerda que puedes usar el botón",
		"en": "Remember you can use the",
		"de": "Denk daran, dass du die Taste",
		"fr": "Souviens-toi que tu peux utiliser le bouton",
		"eu": "Gogoratu botoi hau erabil dezakezula",
		"it": "Ricorda che puoi usare il pulsante",
		"pt": "Lembra-te de que podes usar o botão",
	},
	"LevelStartRevealAfter": {
		"es": "para comprobar si las letras que has puesto son correctas.",
		"en": "button to check whether the letters you placed are correct.",
		"de": "nutzen kannst, um zu prüfen, ob die gesetzten Buchstaben stimmen.",
		"fr": "pour vérifier si les lettres que tu as placées sont correctes.",
		"eu": "jarri dituzun letrak zuzenak diren egiaztatzeko.",
		"it": "per controllare se le lettere che hai messo sono corrette.",
		"pt": "para verificar se as letras que puseste estão corretas.",
	},
}

var _card: PanelContainer
var _play_button: Button
var _lines: Array[Control] = []
var _star_slots: Array[TextureRect] = []
var _closing := false
var _play_blink: Tween


func _ready() -> void:
	add_to_group("LevelStartIntro")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(1, 1, 1, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	_build()
	_hide_animated_bits()
	_pause_clock(true)
	_play_sequence()


func _exit_tree() -> void:
	if is_instance_valid(_play_blink):
		_play_blink.kill()
	_pause_clock(false)


func _t(key: String) -> String:
	var translated := tr(key)
	if translated != "" and translated != key:
		return translated
	var locale := TranslationServer.get_locale().left(2).to_lower()
	var by_locale: Dictionary = COPY.get(key, {})
	return str(by_locale.get(locale, by_locale.get("es", key)))


func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.add_theme_stylebox_override("panel", _card_style())
	center.add_child(_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 44)
	_card.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 26)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(col)

	var stars := GameManager.get_puzzle_difficulty_stars()
	var title := _body(_t("LevelStartTitle") % stars, 56, COLOR_INK)
	col.add_child(title)
	_lines.append(title)

	var star_row := _star_row(stars)
	col.add_child(star_row)

	_add_line(col, _body(_t("LevelStartHintsBefore")))
	_add_line(col, _hud_action_button(
		tr("TutHint"),
		ICON_BULB,
		Vector2(345, 188),
		Color(1, 0.72, 0.08, 1),
		Color(0.82, 0.42, 0.02, 1),
		Color(0.45, 0.2, 0.02, 0.45),
		Vector2(76, 76)
	))
	_add_line(col, _body(_t("LevelStartHintsAfter")))
	_add_line(col, _body(_t("LevelStartRevealBefore")))
	_add_line(col, _hud_action_button(
		tr("TutReveal"),
		ICON_EYE,
		Vector2(372, 188),
		Color(0.38, 0.25, 0.72, 1),
		Color(0.22, 0.13, 0.49, 1),
		Color(0.12, 0.06, 0.27, 0.58),
		Vector2(64, 64)
	))
	_add_line(col, _body(_t("LevelStartRevealAfter")))

	_play_button = Button.new()
	_play_button.text = tr("StartPuzzle")
	if _play_button.text == "StartPuzzle":
		_play_button.text = "EMPEZAR"
	_play_button.focus_mode = Control.FOCUS_NONE
	_play_button.custom_minimum_size = Vector2(520, 130)
	_play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_play_button.add_theme_font_override("font", FONT_UI)
	_play_button.add_theme_font_size_override("font_size", 48)
	_play_button.add_theme_color_override("font_color", Color.WHITE)
	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Color(0.08, 0.63, 0.64, 1)
	play_style.border_color = Color(0.04, 0.42, 0.43, 1)
	play_style.set_border_width_all(4)
	play_style.border_width_bottom = 10
	play_style.set_corner_radius_all(32)
	_play_button.add_theme_stylebox_override("normal", play_style)
	_play_button.add_theme_stylebox_override("hover", play_style)
	_play_button.add_theme_stylebox_override("pressed", play_style)
	_play_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_play_button.pressed.connect(_on_play_pressed)
	var play_wrap := CenterContainer.new()
	play_wrap.add_child(_play_button)
	_add_line(col, play_wrap)


func _add_line(parent: Node, line: Control) -> void:
	parent.add_child(line)
	_lines.append(line)


func _star_row(count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size = Vector2(0, 86)
	var fill := GameManager.star_fill_color()
	for _i in range(count):
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(78, 78)
		icon.texture = STAR_TEXTURE
		icon.self_modulate = fill
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		_star_slots.append(icon)
	return row


func _hud_action_button(
	title: String,
	icon: Texture2D,
	size: Vector2,
	fill: Color,
	border: Color,
	shadow: Color,
	icon_size: Vector2 = Vector2(72, 72)
) -> CenterContainer:
	var wrap := CenterContainer.new()
	var button := Button.new()
	button.custom_minimum_size = size
	button.size = size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_theme_stylebox_override("normal", _hud_button_style(fill, border, false))
	button.add_theme_stylebox_override("hover", _hud_button_style(fill, border, false))
	button.add_theme_stylebox_override("pressed", _hud_button_style(fill, border, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var content := CenterContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(row)

	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = icon_size
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_rect)

	var label := Label.new()
	label.text = title
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", Color(1, 1, 0.96, 1))
	label.add_theme_color_override("font_shadow_color", shadow)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	wrap.add_child(button)
	return wrap


func _hud_button_style(fill: Color, border: Color, pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 4
	style.border_width_right = 4
	if pressed:
		style.border_width_top = 10
		style.border_width_bottom = 4
	else:
		style.border_width_top = 4
		style.border_width_bottom = 10
	style.set_corner_radius_all(28)
	style.shadow_color = Color(border.r, border.g, border.b, 0.26)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 8)
	return style


func _body(text: String, size: int = 38, color: Color = COLOR_BODY) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(CARD_WIDTH - 112.0, 0)
	label.add_theme_font_override("font", FONT_UI)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.955, 0.82, 1)
	style.border_color = Color(0.8, 0.62, 0.34, 0.62)
	style.set_border_width_all(4)
	style.border_width_bottom = 9
	style.set_corner_radius_all(42)
	style.shadow_color = Color(0.19, 0.11, 0.04, 0.34)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 16)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _hide_animated_bits() -> void:
	_card.modulate.a = 0.0
	for line in _lines:
		line.modulate.a = 0.0
	for star in _star_slots:
		star.modulate.a = 0.0
	_play_button.modulate.a = 0.0
	_play_button.disabled = true


func _play_sequence() -> void:
	var fade := create_tween()
	fade.set_parallel(true)
	fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade.tween_property(self, "color", Color(1, 1, 1, 0.78), FADE_IN_SEC)
	fade.tween_property(_card, "modulate:a", 1.0, FADE_IN_SEC)
	await fade.finished
	if not is_instance_valid(self):
		return
	await get_tree().process_frame
	await get_tree().process_frame
	await _fly_stars()
	if not is_instance_valid(self):
		return
	for line in _lines:
		await _reveal_node(line)
		if not is_instance_valid(self):
			return
		await get_tree().create_timer(LINE_DELAY).timeout
	await _reveal_node(_play_button)
	if is_instance_valid(_play_button):
		_play_button.disabled = false
		_start_play_blink()


func _reveal_node(node: Control) -> void:
	if not is_instance_valid(node):
		return
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)


func _fly_stars() -> void:
	for index in range(_star_slots.size()):
		if index > 0:
			await get_tree().create_timer(STAR_STAGGER).timeout
		if not is_instance_valid(self):
			return
		await _fly_star_to(_star_slots[index], index)


func _fly_star_to(slot: TextureRect, index: int) -> void:
	if not is_instance_valid(slot):
		return
	var end_rect := slot.get_global_rect()
	var end_center := end_rect.get_center()
	var end_size := end_rect.size
	var start_size := Vector2(132, 132)
	var start_center := Vector2(-90.0, end_center.y + (20.0 if index % 2 == 0 else -24.0))
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.z_index = 20
	holder.size = start_size
	holder.pivot_offset = start_size * 0.5
	holder.global_position = start_center - start_size * 0.5
	var ghost := TextureRect.new()
	ghost.texture = STAR_TEXTURE
	ghost.self_modulate = GameManager.star_fill_color()
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(ghost)
	add_child(holder)

	var delta := end_center - start_center
	var perp := Vector2(-delta.y, delta.x)
	if perp.length_squared() < 1.0:
		perp = Vector2(0, -120)
	else:
		perp = perp.normalized() * clampf(delta.length() * 0.22, 70.0, 180.0)
	var control := (start_center + end_center) * 0.5 + perp
	var trail := {"at": 0.0}
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			_update_fly(holder, start_center, control, end_center, start_size, end_size, trail, t),
		0.0,
		1.0,
		FLY_SEC
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	if is_instance_valid(holder):
		holder.queue_free()
	if is_instance_valid(slot):
		slot.modulate.a = 1.0
		slot.pivot_offset = slot.size * 0.5
		var pop := create_tween()
		pop.tween_property(slot, "scale", Vector2(1.28, 1.28), 0.10)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(slot, "scale", Vector2.ONE, 0.14)
	_play_chime()


func _update_fly(
	holder: Control,
	start_center: Vector2,
	control: Vector2,
	end_center: Vector2,
	start_size: Vector2,
	end_size: Vector2,
	trail: Dictionary,
	t: float
) -> void:
	if not is_instance_valid(holder):
		return
	var eased := t * t
	var center := _quad_bezier(start_center, control, end_center, eased)
	var size := start_size.lerp(end_size, eased)
	holder.size = size
	holder.pivot_offset = size * 0.5
	holder.global_position = center - size * 0.5
	if t < 0.001 or t - float(trail.get("at", 0.0)) >= TRAIL_GAP:
		trail["at"] = t
		_spawn_trail(holder)


func _quad_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2


func _spawn_trail(holder: Control) -> void:
	if not is_instance_valid(holder):
		return
	var spark := TextureRect.new()
	spark.texture = STAR_TEXTURE
	spark.self_modulate = GameManager.star_fill_color()
	spark.modulate = Color(1, 1, 1, 0.55)
	spark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spark.size = holder.size * 0.62
	spark.pivot_offset = spark.size * 0.5
	spark.global_position = holder.global_position + (holder.size - spark.size) * 0.5
	spark.z_index = 15
	add_child(spark)
	var fade := create_tween()
	fade.tween_property(spark, "modulate:a", 0.0, TRAIL_LIFE).set_trans(Tween.TRANS_QUAD)
	fade.parallel().tween_property(spark, "scale", Vector2(0.7, 0.7), TRAIL_LIFE)
	fade.finished.connect(spark.queue_free)


func _play_chime() -> void:
	if CHIME_SFX == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = "SoundFx"
	player.stream = CHIME_SFX
	player.volume_db = -6.0
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func _start_play_blink() -> void:
	if not is_instance_valid(_play_button):
		return
	_play_button.pivot_offset = _play_button.size * 0.5
	if is_instance_valid(_play_blink):
		_play_blink.kill()
	_play_blink = create_tween()
	_play_blink.set_loops()
	_play_blink.set_trans(Tween.TRANS_SINE)
	_play_blink.set_ease(Tween.EASE_IN_OUT)
	_play_blink.tween_property(_play_button, "scale", Vector2(1.06, 1.06), 0.45)
	_play_blink.parallel().tween_property(_play_button, "modulate", Color(1.12, 1.08, 0.92, 1), 0.45)
	_play_blink.tween_property(_play_button, "scale", Vector2.ONE, 0.45)
	_play_blink.parallel().tween_property(_play_button, "modulate", Color.WHITE, 0.45)


func _hud_star_slots() -> Array[TextureRect]:
	var hud := get_tree().get_first_node_in_group("GameHUD")
	if hud != null and hud.has_method("puzzle_star_slots"):
		return hud.puzzle_star_slots()
	return []


func _on_play_pressed() -> void:
	if _closing:
		return
	_closing = true
	SoundManager.play("ButtonClick")
	if is_instance_valid(_play_blink):
		_play_blink.kill()
	if is_instance_valid(_play_button):
		_play_button.disabled = true
	var hud_slots := _hud_star_slots()
	StarCollectOverlay.capture_earned(_star_slots, _star_slots.size(), "")
	for star in _star_slots:
		if is_instance_valid(star):
			star.modulate.a = 0.0
	for slot in hud_slots:
		if is_instance_valid(slot):
			slot.modulate.a = 0.0
	var fade := create_tween()
	fade.set_parallel(true)
	fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade.tween_property(self, "color:a", 0.0, FADE_OUT_SEC)
	fade.tween_property(_card, "modulate:a", 0.0, FADE_OUT_SEC)
	await fade.finished
	if not is_instance_valid(self):
		return
	if not hud_slots.is_empty() and StarCollectOverlay.has_pending():
		await StarCollectOverlay.play_to_slots(hud_slots)
	else:
		StarCollectOverlay.clear()
		for slot in hud_slots:
			if is_instance_valid(slot):
				slot.modulate.a = 1.0
	if not is_instance_valid(self):
		return
	finished.emit()
	queue_free()


func _pause_clock(paused: bool) -> void:
	var hud := get_tree().get_first_node_in_group("GameHUD")
	if hud == null:
		return
	if paused and hud.has_method("pause_play_clock"):
		hud.call("pause_play_clock")
	elif not paused and hud.has_method("resume_play_clock"):
		hud.call("resume_play_clock")
