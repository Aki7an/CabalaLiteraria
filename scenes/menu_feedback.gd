extends Control

const SCENE_MENU_MAIN := "res://scenes/MenuMain.tscn"
const DRAG_THRESHOLD := 14.0

@onready var title_label: Label = $Card/Header/Title
@onready var subtitle_label: Label = $Card/Header/LevelId
@onready var card: Panel = $Card
@onready var scroll: ScrollContainer = $Card/Scroll
@onready var hint1_row: Control = $Card/Scroll/Rows/RowHint1
@onready var hint2_row: Control = $Card/Scroll/Rows/RowHint2
@onready var hint3_row: Control = $Card/Scroll/Rows/RowHint3
@onready var hint1_disabled: Label = $Card/Scroll/Rows/RowHint1/Content/Disabled
@onready var hint2_disabled: Label = $Card/Scroll/Rows/RowHint2/Content/Disabled
@onready var hint3_disabled: Label = $Card/Scroll/Rows/RowHint3/Content/Disabled
@onready var comment_edit: TextEdit = $Card/Scroll/Rows/RowComment/Content/Comment
@onready var button_omit: Button = $Card/Buttons/ButtonCancel
@onready var button_send: Button = $Card/Buttons/ButtonSend

@onready var estrellas1: FeedbackStarRow = $Card/Scroll/Rows/RowGlobal/Content/Stars
@onready var estrellas2: FeedbackStarRow = $Card/Scroll/Rows/RowDifficulty/Content/Stars
@onready var estrellas3: FeedbackStarRow = $Card/Scroll/Rows/RowDuration/Content/Stars
@onready var estrellas4: FeedbackStarRow = $Card/Scroll/Rows/RowHint1/Content/Stars
@onready var estrellas5: FeedbackStarRow = $Card/Scroll/Rows/RowHint2/Content/Stars
@onready var estrellas6: FeedbackStarRow = $Card/Scroll/Rows/RowHint3/Content/Stars
@onready var estrellas7: FeedbackStarRow = $Card/Scroll/Rows/RowTheme/Content/Stars

const FONT_CHIP := preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")
const COLOR_CHIP_OFF := Color(0.953, 0.906, 0.855, 1)
const COLOR_CHIP_ON := Color(0.9608, 0.5098, 0.1255, 1)
const COLOR_CHIP_TEXT := Color(0.325, 0.2, 0.125, 1)

var _busy := false
var _drag_held := false
var _drag_active := false
var _drag_origin := Vector2.ZERO
var _drag_scroll_origin := 0
var _card_bottom_rest := -48.0
var _applied_keyboard_h := -1.0
var _diff_issue := ""
var _time_issue := ""
var _issue_buttons: Array[Button] = []
var _chip_off: StyleBoxFlat
var _chip_on: StyleBoxFlat


func _ready() -> void:
	_card_bottom_rest = card.offset_bottom
	_apply_copy()
	_reorder_questions()
	_apply_locks()
	_build_issue_chips()
	scroll.scroll_deadzone = 16
	ScrollOverflowHint.attach(scroll)
	_make_rows_drag_through($Card/Scroll/Rows)
	comment_edit.focus_entered.connect(_on_comment_focus_entered)
	comment_edit.focus_exited.connect(_on_comment_focus_exited)
	set_process(true)


func _process(_delta: float) -> void:
	_apply_keyboard_inset()


func _reorder_questions() -> void:
	var rows := $Card/Scroll/Rows
	var theme := rows.get_node("RowTheme") as Node
	var hint1 := rows.get_node("RowHint1") as Node
	if theme and hint1:
		rows.move_child(theme, hint1.get_index())


func _make_rows_drag_through(node: Node) -> void:
	for child in node.get_children():
		_make_rows_drag_through(child)
	if node == comment_edit:
		return
	if node is FeedbackStarRow or node is Button:
		return
	if node is Label or node is PanelContainer or node is VBoxContainer or node is HBoxContainer:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not is_instance_valid(scroll):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_drag_press(event.pressed, event.position)
	elif event is InputEventMouseMotion and _drag_held:
		_handle_drag_motion(event.position)
	elif event is InputEventScreenTouch:
		_handle_drag_press(event.pressed, event.position)
	elif event is InputEventScreenDrag and _drag_held:
		_handle_drag_motion(event.position)


func _handle_drag_press(pressed: bool, position: Vector2) -> void:
	if pressed:
		_dismiss_keyboard_if_outside(position)
		if not scroll.get_global_rect().has_point(position):
			return
		if comment_edit.get_global_rect().has_point(position):
			return
		if _is_on_slider(position) or _is_on_issue_chip(position):
			return
		_drag_held = true
		_drag_active = false
		_drag_origin = position
		_drag_scroll_origin = scroll.scroll_vertical
		return
	if _drag_active:
		get_viewport().set_input_as_handled()
	call_deferred("_end_drag")


func _handle_drag_motion(position: Vector2) -> void:
	if comment_edit.has_focus() and comment_edit.get_global_rect().has_point(_drag_origin):
		return
	var delta := position.y - _drag_origin.y
	if not _drag_active and absf(delta) >= DRAG_THRESHOLD:
		_drag_active = true
	if not _drag_active:
		return
	scroll.scroll_vertical = _drag_scroll_origin - int(delta)
	get_viewport().set_input_as_handled()


func _end_drag() -> void:
	_drag_held = false
	_drag_active = false


func _t(key: String, fallback: String) -> String:
	var text := tr(key)
	if text.is_empty() or text == key:
		return fallback
	return text


func _apply_copy() -> void:
	title_label.text = _t("FeedbackTitle", "¿QUÉ TE PARECIÓ?")
	subtitle_label.text = _t("FeedbackSubtitle", "Tu opinión nos ayuda a mejorar el nivel %s") % str(GameManager.id_frase)
	_set_row_title($Card/Scroll/Rows/RowGlobal, _t("FeedbackGlobal", "Valoración general del nivel"))
	_set_row_title($Card/Scroll/Rows/RowDifficulty, _t("FeedbackDifficultyQ", "¿La dificultad te ha parecido adecuada?"))
	_set_row_title($Card/Scroll/Rows/RowDuration, _t("FeedbackDurationQ", "¿El tiempo de resolución te ha parecido adecuado?"))
	_set_row_title($Card/Scroll/Rows/RowHint1, _t("FeedbackHintQ1", "¿La primera pista ha sido útil en este nivel?"))
	_set_row_title($Card/Scroll/Rows/RowHint2, _t("FeedbackHintQ2", "¿La segunda pista ha sido útil en este nivel?"))
	_set_row_title($Card/Scroll/Rows/RowHint3, _t("FeedbackHintQ3", "¿La tercera pista ha sido útil en este nivel?"))
	_set_row_title($Card/Scroll/Rows/RowTheme, _t("FeedbackThemeQ", "¿El tema del puzle es interesante?"))
	_set_row_title($Card/Scroll/Rows/RowComment, _t("FeedbackComment", "Deja un comentario sobre el nivel (opcional):"))
	var score_scale := PackedStringArray([
		_t("FeedbackScore1", "Fatal"),
		_t("FeedbackScore2", "Mal"),
		_t("FeedbackScore3", "Aceptable"),
		_t("FeedbackScore4", "Bien"),
		_t("FeedbackScore5", "Excelente"),
	])
	_set_scale($Card/Scroll/Rows/RowGlobal, score_scale)
	_set_scale($Card/Scroll/Rows/RowDifficulty, score_scale)
	_set_scale($Card/Scroll/Rows/RowDuration, score_scale)
	var hint_scale := PackedStringArray([
		_t("FeedbackHint1", "Prácticamente inútil"),
		_t("FeedbackHint2", "Poco útil"),
		_t("FeedbackHint3", "Bien, ayuda pero no resuelve"),
		_t("FeedbackHint4", "Bastante útil"),
		_t("FeedbackHint5", "Demasiada pista"),
	])
	_set_scale($Card/Scroll/Rows/RowHint1, hint_scale)
	_set_scale($Card/Scroll/Rows/RowHint2, hint_scale)
	_set_scale($Card/Scroll/Rows/RowHint3, hint_scale)
	_set_scale($Card/Scroll/Rows/RowTheme, score_scale)
	hint3_disabled.text = _t("FeedbackUnused", "No usada en esta partida")
	comment_edit.placeholder_text = _t("FeedbackCommentHint", "Escribe aquí…")
	button_omit.text = _t("FeedbackOmit", "OMITIR")
	button_send.text = _t("FeedbackSend", "ENVIAR")


func _is_on_slider(position: Vector2) -> bool:
	for slider in [estrellas1, estrellas2, estrellas3, estrellas4, estrellas5, estrellas6, estrellas7]:
		if slider and slider.visible and slider.get_global_rect().grow(8.0).has_point(position):
			return true
	return false


func _is_on_issue_chip(position: Vector2) -> bool:
	for chip in _issue_buttons:
		if chip and chip.visible and chip.get_global_rect().grow(4.0).has_point(position):
			return true
	return false


func _build_issue_chips() -> void:
	_chip_off = _make_chip_style(COLOR_CHIP_OFF, Color(0.77, 0.62, 0.4, 0.55))
	_chip_on = _make_chip_style(COLOR_CHIP_ON, Color(0.72, 0.34, 0.06, 1))
	_add_issue_row(
		$Card/Scroll/Rows/RowDifficulty/Content,
		"diff",
		_t("FeedbackIssueDiff", "Dificultad"),
		"too_easy",
		_t("FeedbackIssueTooEasy", "Demasiado fácil"),
		"too_hard",
		_t("FeedbackIssueTooHard", "Demasiado difícil")
	)
	_add_issue_row(
		$Card/Scroll/Rows/RowDuration/Content,
		"time",
		_t("FeedbackIssueTime", "Tiempo"),
		"too_short",
		_t("FeedbackIssueTooShort", "Demasiado corto"),
		"too_long",
		_t("FeedbackIssueTooLong", "Demasiado largo")
	)


func _add_issue_row(
		parent: Node,
		kind: String,
		caption: String,
		left_value: String,
		left_text: String,
		right_value: String,
		right_text: String
	) -> void:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 4)
	var title := Label.new()
	title.text = caption
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.45, 0.32, 0.22, 0.86))
	title.add_theme_font_override("font", FONT_CHIP)
	title.add_theme_font_size_override("font_size", 42)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var left := _make_chip_button(left_text)
	var right := _make_chip_button(right_text)
	left.pressed.connect(func() -> void:
		_select_issue(kind, left_value, left, right)
	)
	right.pressed.connect(func() -> void:
		_select_issue(kind, right_value, right, left)
	)
	row.add_child(left)
	row.add_child(right)
	wrap.add_child(title)
	wrap.add_child(row)
	parent.add_child(wrap)


func _make_chip_button(text: String) -> Button:
	var chip := Button.new()
	chip.text = text
	chip.toggle_mode = true
	chip.focus_mode = Control.FOCUS_NONE
	chip.custom_minimum_size = Vector2(0, 68)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_font_override("font", FONT_CHIP)
	chip.add_theme_font_size_override("font_size", 34)
	chip.add_theme_color_override("font_color", COLOR_CHIP_TEXT)
	chip.add_theme_color_override("font_pressed_color", Color.WHITE)
	chip.add_theme_color_override("font_hover_color", COLOR_CHIP_TEXT)
	chip.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	chip.add_theme_stylebox_override("normal", _chip_off)
	chip.add_theme_stylebox_override("hover", _chip_off)
	chip.add_theme_stylebox_override("pressed", _chip_on)
	chip.add_theme_stylebox_override("focus", _chip_off)
	_issue_buttons.append(chip)
	return chip


func _make_chip_style(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box


func _select_issue(kind: String, value: String, chosen: Button, other: Button) -> void:
	var current := _diff_issue if kind == "diff" else _time_issue
	var next := "" if current == value else value
	if kind == "diff":
		_diff_issue = next
	else:
		_time_issue = next
	chosen.set_pressed_no_signal(next == value)
	other.set_pressed_no_signal(false)
	_style_chip(chosen, next == value)
	_style_chip(other, false)


func _style_chip(chip: Button, on: bool) -> void:
	var box := _chip_on if on else _chip_off
	var color := Color.WHITE if on else COLOR_CHIP_TEXT
	chip.add_theme_stylebox_override("normal", box)
	chip.add_theme_stylebox_override("hover", box)
	chip.add_theme_stylebox_override("pressed", box)
	chip.add_theme_color_override("font_color", color)
	chip.add_theme_color_override("font_hover_color", color)


func _set_row_title(row: Node, text: String) -> void:
	var title := row.get_node_or_null("Content/Title") as Label
	if title:
		title.text = text


func _set_scale(row: Node, labels: PackedStringArray) -> void:
	var scale := row.get_node_or_null("Content/Scale") as HBoxContainer
	if scale == null:
		return
	for child in scale.get_children():
		scale.remove_child(child)
		child.free()
	for i in labels.size():
		var label := Label.new()
		label.text = labels[i]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(0, 88)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		if i == 0:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		elif i == labels.size() - 1:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		else:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.45, 0.32, 0.22, 0.9))
		label.add_theme_font_override("font", FONT_CHIP)
		label.add_theme_font_size_override("font_size", 38)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scale.add_child(label)


func _apply_locks() -> void:
	hint1_row.visible = GameManager.pista_1
	hint2_row.visible = GameManager.pista_2
	hint3_row.visible = GameManager.pista_3


func _on_button_send_pressed() -> void:
	if _busy:
		return
	_hide_keyboard()
	_busy = true
	button_send.disabled = true
	button_omit.disabled = true
	button_send.text = tr("FeedbackSending")
	var ratings := {
		"global": estrellas1.question_stars,
		"difficulty": estrellas2.question_stars,
		"duration": estrellas3.question_stars,
		"hint1": estrellas4.question_stars if GameManager.pista_1 else 0,
		"hint2": estrellas5.question_stars if GameManager.pista_2 else 0,
		"hint3": estrellas6.question_stars if GameManager.pista_3 else 0,
		"interest": estrellas7.question_stars,
		"difficulty_issue": _diff_issue,
		"duration_issue": _time_issue,
	}
	var comment := comment_edit.text.strip_edges()
	await PlayFabTools.send_phrase_feedback(GameManager.id_frase, ratings, comment, true)
	await _go_main_menu()


func _on_button_cancel_pressed() -> void:
	if _busy:
		return
	_hide_keyboard()
	await _go_main_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and comment_edit.has_focus():
		_hide_keyboard()
		get_viewport().set_input_as_handled()


func _on_comment_focus_entered() -> void:
	_apply_keyboard_inset()
	await get_tree().create_timer(0.18).timeout
	if is_instance_valid(self) and comment_edit.has_focus():
		_apply_keyboard_inset()
		scroll.ensure_control_visible(comment_edit)


func _on_comment_focus_exited() -> void:
	_hide_keyboard()


func _dismiss_keyboard_if_outside(position: Vector2) -> void:
	if not comment_edit.has_focus():
		return
	if comment_edit.get_global_rect().grow(8.0).has_point(position):
		return
	if button_send.get_global_rect().has_point(position):
		return
	if button_omit.get_global_rect().has_point(position):
		return
	_hide_keyboard()


func _hide_keyboard() -> void:
	if comment_edit.has_focus():
		comment_edit.release_focus()
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		DisplayServer.virtual_keyboard_hide()
	_apply_keyboard_inset(true)


func _apply_keyboard_inset(force := false) -> void:
	var kb := _virtual_keyboard_height()
	if not force and is_equal_approx(kb, _applied_keyboard_h):
		return
	_applied_keyboard_h = kb
	var target := _card_bottom_rest
	if kb > 1.0:
		target = -(kb + 16.0)
	card.offset_bottom = target
	if kb > 1.0 and comment_edit.has_focus():
		scroll.ensure_control_visible(comment_edit)


func _virtual_keyboard_height() -> float:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return 0.0
	var kb := float(DisplayServer.virtual_keyboard_get_height())
	if kb <= 0.0:
		return 0.0
	var win_h := float(DisplayServer.window_get_size().y)
	if win_h <= 1.0:
		return kb
	return kb * get_viewport_rect().size.y / win_h


func _go_main_menu() -> void:
	SoundManager.play("ButtonClick")
	TransitionScreen.transition_to_black()
	await SignalManager.on_transition_finished
	get_tree().change_scene_to_file(SCENE_MENU_MAIN)
