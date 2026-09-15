extends ColorRect

const COPY := {
	"BoardCompleteTitle": {
		"es": "TABLERO COMPLETO",
		"en": "BOARD COMPLETE",
		"de": "SPIELFELD VOLL",
		"fr": "GRILLE COMPLÈTE",
		"eu": "TAULA OSOA",
		"it": "TABELLONE COMPLETO",
		"pt": "TABULEIRO COMPLETO",
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
	"BoardCompleteBody": {
		"es": "¿Quieres terminar la partida o prefieres revisar alguna letra?",
		"en": "Do you want to finish the game or review a letter?",
		"de": "Möchtest du die Partie beenden oder noch einen Buchstaben prüfen?",
		"fr": "Veux-tu terminer la partie ou revoir une lettre ?",
		"eu": "Partida amaitu nahi duzu ala letra bat berrikusi?",
		"it": "Vuoi terminare la partita o preferisci rivedere qualche lettera?",
		"pt": "Queres terminar a partida ou preferes rever alguma letra?",
	},
	"BoardCompleteRevealNote": {
		"es": "También puedes comprobarla pulsando %s.",
		"en": "You can also check it by pressing %s.",
		"de": "Du kannst sie auch mit %s prüfen.",
		"fr": "Tu peux aussi la vérifier en appuyant sur %s.",
		"eu": "%s sakatuta ere egiazta dezakezu.",
		"it": "Puoi anche verificarla premendo %s.",
		"pt": "Também podes verificá-la premendo %s.",
	},
	"BoardCompleteReview": {
		"es": "←  REPASAR",
		"en": "←  REVIEW",
		"de": "←  PRÜFEN",
		"fr": "←  REVOIR",
		"eu": "←  BERRIKUSI",
		"it": "←  RIVEDI",
		"pt": "←  REVER",
	},
	"BoardCompleteFinish": {
		"es": "✓  TERMINAR",
		"en": "✓  FINISH",
		"de": "✓  BEENDEN",
		"fr": "✓  TERMINER",
		"eu": "✓  AMAITU",
		"it": "✓  TERMINA",
		"pt": "✓  TERMINAR",
	},
	"TutReveal": {
		"es": "REVELAR",
		"en": "REVEAL",
		"de": "AUFDECKEN",
		"fr": "RÉVÉLER",
		"eu": "AGERTU",
		"it": "RIVELA",
		"pt": "REVELAR",
	},
}


func _ready() -> void:
	add_to_group("BoardFillPrompt")
	_apply_locale()


func _apply_locale() -> void:
	$Card/Title.text = _t("BoardCompleteTitle")
	$Card/Subtitle.text = _t("BoardCompleteSubtitle")
	$Card/InfoCard/Body.text = _t("BoardCompleteBody")
	$Card/InfoCard/RevealNote.text = _t("BoardCompleteRevealNote") % _t("TutReveal")
	$Card/ButtonReview.text = _t("BoardCompleteReview")
	$Card/ButtonFinish.text = _t("BoardCompleteFinish")


func _t(key: String) -> String:
	var translated := tr(key)
	if translated != "" and translated != key:
		return translated
	var locale := TranslationServer.get_locale().left(2).to_lower()
	var by_locale: Dictionary = COPY.get(key, {})
	return str(by_locale.get(locale, by_locale.get("es", key)))


func _on_review_pressed() -> void:
	SoundManager.play("ButtonClick")
	queue_free()


func _on_finish_pressed() -> void:
	SoundManager.play("ButtonClick")
	queue_free()
	GameManager.reveal_assignment_errors()
