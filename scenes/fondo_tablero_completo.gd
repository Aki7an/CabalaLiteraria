extends ColorRect

const FADE_IN_SEC := 1.0
const ICON_REVIEW: Texture2D = preload("res://images/ui_icon_review_notes.svg")
const ICON_FINISH: Texture2D = preload("res://images/ui_icon_send_plane.svg")

const COPY := {
	"BoardCompleteTitle": {
		"es": "¿TABLERO COMPLETO?",
		"en": "BOARD COMPLETE?",
		"de": "SPIELFELD VOLL?",
		"fr": "GRILLE COMPLÈTE ?",
		"eu": "TAULA OSOA?",
		"it": "TABELLONE COMPLETO?",
		"pt": "TABULEIRO COMPLETO?",
	},
	"BoardCompleteSubtitle": {
		"es": "Has completado todas las casillas del puzle",
		"en": "You have filled every cell in the puzzle",
		"de": "Du hast alle Felder des Rätsels ausgefüllt",
		"fr": "Tu as rempli toutes les cases du puzzle",
		"eu": "Puzzlearen gelaxka denak bete dituzu",
		"it": "Hai completato tutte le caselle del puzzle",
		"pt": "Completaste todas as casas do puzzle",
	},
	"BoardCompleteBut": {
		"es": "pero...",
		"en": "but...",
		"de": "aber...",
		"fr": "mais...",
		"eu": "baina...",
		"it": "però...",
		"pt": "mas...",
	},
	"BoardCompleteBody": {
		"es": "¿Quieres comprobar si todas las letras que has puesto están bien y terminar el puzle o prefieres repasarlo?",
		"en": "Do you want to check if all the letters you placed are correct and finish the puzzle, or would you rather review it?",
		"de": "Möchtest du prüfen, ob alle gesetzten Buchstaben stimmen, und das Rätsel beenden, oder lieber noch einmal durchgehen?",
		"fr": "Veux-tu vérifier si toutes les lettres que tu as placées sont correctes et terminer le puzzle, ou préfères-tu le relire ?",
		"eu": "Jarri dituzun letra denak zuzenak diren egiaztatu eta puzzlea amaitu nahi duzu ala berrikusi nahiago duzu?",
		"it": "Vuoi controllare se tutte le lettere che hai messo sono corrette e terminare il puzzle, o preferisci ripassarlo?",
		"pt": "Queres verificar se todas as letras que puseste estão corretas e terminar o puzzle, ou preferes repassá-lo?",
	},
	"BoardCompleteRevealNote": {
		"es": "También puedes comprobarlo luego pulsando %s.",
		"en": "You can also check it later by pressing %s.",
		"de": "Du kannst sie auch später mit %s prüfen.",
		"fr": "Tu peux aussi la vérifier plus tard en appuyant sur %s.",
		"eu": "Geroago %s sakatuta ere egiazta dezakezu.",
		"it": "Puoi anche verificarla più tardi premendo %s.",
		"pt": "Também podes verificá-la mais tarde premendo %s.",
	},
	"BoardCompleteReview": {
		"es": "REPASAR",
		"en": "REVIEW",
		"de": "DURCHSEHEN",
		"fr": "REVOIR",
		"eu": "BERRIKUSI",
		"it": "RIVEDI",
		"pt": "REVER",
	},
	"BoardCompleteFinish": {
		"es": "TERMINAR",
		"en": "FINISH",
		"de": "BEENDEN",
		"fr": "TERMINER",
		"eu": "AMAITU",
		"it": "TERMINA",
		"pt": "TERMINAR",
	},
	"TutReveal": {
		"es": "COMPROBAR",
		"en": "CHECK",
		"de": "PRÜFEN",
		"fr": "VÉRIFIER",
		"eu": "EGIAZTATU",
		"it": "VERIFICA",
		"pt": "VERIFICAR",
	},
}


func _ready() -> void:
	add_to_group("BoardFillPrompt")
	_apply_locale()
	_fade_in()
	if Distribution.is_horizontal():
		call_deferred("_layout_horizontal")


func _layout_horizontal() -> void:
	var layer := _game_canvas()
	if layer == null or layer.size.x < 2.0 or layer.size.y < 2.0:
		return
	if get_parent() != layer:
		reparent(layer)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 2000
	color = Color(0.68, 0.54, 0.36, 1.0)
	var card := get_node_or_null("Card") as Control
	if card == null:
		return
	var canvas_size := layer.size
	var margin := 28.0
	var card_size := Vector2(
		minf(canvas_size.x - margin * 2.0, 1180.0),
		minf(canvas_size.y - margin * 2.0, 640.0)
	)
	var origin := (canvas_size - card_size) * 0.5
	_place(card, Rect2(origin, card_size))
	_place_horizontal_card(card, card_size)


func _place_horizontal_card(card: Control, card_size: Vector2) -> void:
	var icon := card.get_node_or_null("CompleteIcon") as Control
	var title := card.get_node_or_null("Title") as Label
	var subtitle := card.get_node_or_null("Subtitle") as Label
	var but_line := card.get_node_or_null("ButLine") as Label
	var info := card.get_node_or_null("InfoCard") as Control
	var review_icon := card.get_node_or_null("ReviewIcon") as Control
	var finish_icon := card.get_node_or_null("FinishIcon") as Control
	var review := card.get_node_or_null("ButtonReview") as Button
	var finish := card.get_node_or_null("ButtonFinish") as Button
	if icon == null or title == null or subtitle == null or but_line == null:
		return
	if info == null or review_icon == null or finish_icon == null or review == null or finish == null:
		return
	var pad := 18.0
	var gap := 4.0
	var icon_size := 70.0
	var title_h := 44.0
	var sub_h := 30.0
	var but_h := 32.0
	var info_h := 186.0
	var badge := 62.0
	var button_h := 74.0
	var stack := icon_size + gap + title_h + sub_h + but_h + 8.0 + info_h + 10.0 + badge + 6.0 + button_h
	var fit := 1.0
	if stack + pad * 2.0 > card_size.y:
		fit = (card_size.y - pad * 2.0) / stack
	icon_size *= fit
	title_h *= fit
	sub_h *= fit
	but_h *= fit
	info_h *= fit
	badge *= fit
	button_h *= fit
	gap *= fit
	stack *= fit
	var y := maxf(pad, (card_size.y - stack) * 0.5)
	_place(icon, Rect2((card_size.x - icon_size) * 0.5, y, icon_size, icon_size))
	var check := icon.get_node_or_null("Check") as Label
	if check:
		check.add_theme_font_size_override("font_size", int(round(40.0 * fit)))
	y += icon_size + gap
	_place_label(title, Rect2(pad, y, card_size.x - pad * 2.0, title_h), int(round(34.0 * fit)))
	y += title_h
	_place_label(subtitle, Rect2(pad, y, card_size.x - pad * 2.0, sub_h), int(round(20.0 * fit)))
	y += sub_h
	_place_label(but_line, Rect2(pad, y, card_size.x - pad * 2.0, but_h), int(round(24.0 * fit)))
	y += but_h + 8.0 * fit
	var info_rect := Rect2(pad, y, card_size.x - pad * 2.0, info_h)
	_place(info, info_rect)
	var body := info.get_node_or_null("Body") as Label
	var note := info.get_node_or_null("RevealNote") as Label
	var inset := 22.0
	if body:
		_place_label(body, Rect2(inset, 12.0 * fit, info_rect.size.x - inset * 2.0, info_h * 0.56), int(round(24.0 * fit)))
	if note:
		_place_label(note, Rect2(inset, info_h * 0.60, info_rect.size.x - inset * 2.0, info_h * 0.32), int(round(20.0 * fit)))
	y += info_h + 10.0 * fit
	var button_w := (card_size.x - pad * 2.0 - 16.0) * 0.5
	var review_x := pad
	var finish_x := pad + button_w + 16.0
	_place(review_icon, Rect2(review_x + (button_w - badge) * 0.5, y, badge, badge))
	_place(finish_icon, Rect2(finish_x + (button_w - badge) * 0.5, y, badge, badge))
	y += badge + 6.0 * fit
	_place(review, Rect2(review_x, y, button_w, button_h))
	_place(finish, Rect2(finish_x, y, button_w, button_h))
	review.add_theme_font_size_override("font_size", int(round(28.0 * fit)))
	finish.add_theme_font_size_override("font_size", int(round(28.0 * fit)))


func _place(node: Control, rect: Rect2) -> void:
	node.layout_mode = 1
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0
	node.offset_left = rect.position.x
	node.offset_top = rect.position.y
	node.offset_right = rect.end.x
	node.offset_bottom = rect.end.y


func _place_label(label: Label, rect: Rect2, font_size: int) -> void:
	_place(label, rect)
	label.add_theme_font_size_override("font_size", font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _game_canvas() -> Control:
	var host := get_parent()
	if host != null and host.get_parent() is Control:
		return host.get_parent() as Control
	return null


func _apply_locale() -> void:
	$Card/Title.text = _t("BoardCompleteTitle")
	$Card/Subtitle.text = _t("BoardCompleteSubtitle")
	$Card/ButLine.text = _t("BoardCompleteBut")
	$Card/InfoCard/Body.text = _t("BoardCompleteBody")
	$Card/InfoCard/RevealNote.text = _t("BoardCompleteRevealNote") % _t("TutReveal")
	$Card/ButtonReview.text = _t("BoardCompleteReview")
	$Card/ButtonFinish.text = _t("BoardCompleteFinish")
	$Card/ReviewIcon.texture = ICON_REVIEW
	$Card/FinishIcon.texture = ICON_FINISH


func _t(key: String) -> String:
	var locale := TranslationServer.get_locale().left(2).to_lower()
	var by_locale: Dictionary = COPY.get(key, {})
	if not by_locale.is_empty():
		return str(by_locale.get(locale, by_locale.get("es", key)))
	var translated := tr(key)
	if translated != "" and translated != key:
		return translated
	return key


func _fade_in() -> void:
	modulate.a = 0.0
	var fade := create_tween()
	fade.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade.tween_property(self, "modulate:a", 1.0, FADE_IN_SEC)


func _on_review_pressed() -> void:
	SoundManager.play("ButtonClick")
	queue_free()


func _on_finish_pressed() -> void:
	SoundManager.play("ButtonClick")
	queue_free()
	GameManager.reveal_assignment_errors()
