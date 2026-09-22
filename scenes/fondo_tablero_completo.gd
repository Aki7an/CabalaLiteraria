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
		"de": "PRÜFEN",
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
		"es": "REVELAR",
		"en": "REVEAL",
		"de": "LÖSEN",
		"fr": "RÉVÉLER",
		"eu": "AGERTU",
		"it": "RIVELA",
		"pt": "REVELAR",
	},
}


func _ready() -> void:
	add_to_group("BoardFillPrompt")
	_apply_locale()
	_fade_in()


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
