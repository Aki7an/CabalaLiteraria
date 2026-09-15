extends ColorRect

const FONT_TITLE: Font = preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const COLOR_RED := Color("8B1E1E")
const COLOR_INK := Color("3D2B1F")
const COLOR_CHECK_ON := Color(0.93, 0.84, 0.68, 1)
const COLOR_CHECK_OFF := Color(1, 0.98, 0.93, 1)
const COPY := {
	"TutReveal": {
		"es": "REVELAR", "en": "REVEAL", "de": "AUFDECKEN",
		"fr": "RÉVÉLER", "eu": "AGERTU", "it": "RIVELA", "pt": "REVELAR",
	},
	"RevealDlgIntro": {
		"es": "Se comprobará si las [b]LETRAS[/b] puestas en negro en la frase están bien o no.",
		"en": "It will check whether the [b]LETTERS[/b] written in black in the phrase are correct.",
		"de": "Es wird geprüft, ob die [b]BUCHSTABEN[/b] in Schwarz im Satz richtig sind.",
		"fr": "On vérifiera si les [b]LETTRES[/b] écrites en noir dans la phrase sont correctes.",
		"eu": "Egiaztatuko da esaldian beltzez jarritako [b]LETRAK[/b] ondo dauden.",
		"it": "Si controllerà se le [b]LETTERE[/b] scritte in nero nella frase sono corrette.",
		"pt": "Verificar-se-á se as [b]LETRAS[/b] escritas a preto na frase estão certas.",
	},
	"RevealDlgNone": {
		"es": "NINGUNA LETRA NUEVA A COMPROBAR",
		"en": "NO NEW LETTERS TO CHECK",
		"de": "KEINE NEUEN BUCHSTABEN ZU PRÜFEN",
		"fr": "AUCUNE NOUVELLE LETTRE À VÉRIFIER",
		"eu": "EZ DAGO LETRA BERRIRIK EGIAZTATZEKO",
		"it": "NESSUNA NUOVA LETTERA DA CONTROLLARE",
		"pt": "NENHUMA LETRA NOVA A VERIFICAR",
	},
	"RevealDlgOne": {
		"es": "Letra a comprobar:",
		"en": "Letter to check:",
		"de": "Buchstabe zu prüfen:",
		"fr": "Lettre à vérifier :",
		"eu": "Egiaztatu beharreko letra:",
		"it": "Lettera da controllare:",
		"pt": "Letra a verificar:",
	},
	"RevealDlgMany": {
		"es": "Letras a comprobar:",
		"en": "Letters to check:",
		"de": "Buchstaben zu prüfen:",
		"fr": "Lettres à vérifier :",
		"eu": "Egiaztatu beharreko letrak:",
		"it": "Lettere da controllare:",
		"pt": "Letras a verificar:",
	},
	"RevealDlgOkTitle": {
		"es": "Letra ACERTADA", "en": "CORRECT letter", "de": "RICHTIGER Buchstabe",
		"fr": "Lettre CORRECTE", "eu": "Letra ZUZENA", "it": "Lettera CORRETTA", "pt": "Letra CERTA",
	},
	"RevealDlgOkBody": {
		"es": "Pasarán a color [b]VERDE[/b] y no tendrá coste.",
		"en": "They will turn [b]GREEN[/b] and there is no cost.",
		"de": "Sie werden [b]GRÜN[/b] und es kostet nichts.",
		"fr": "Elles passeront au [b]VERT[/b] et cela n'aura aucun coût.",
		"eu": "[b]BERDE[/b] kolorea hartuko dute eta ez du kosturik.",
		"it": "Diventeranno [b]VERDI[/b] e non avrà costo.",
		"pt": "Passarão a [b]VERDE[/b] e não terá custo.",
	},
	"RevealDlgFailTitle": {
		"es": "Letra FALLADA", "en": "WRONG letter", "de": "FALSCHER Buchstabe",
		"fr": "Lettre FAUSSE", "eu": "Letra OKERRA", "it": "Lettera SBAGLIATA", "pt": "Letra ERRADA",
	},
	"RevealDlgFailBody": {
		"es": "Se restará una estrella por cada [b]LETRA[/b] fallada y la letra aparecerá en [b]ROJO[/b].",
		"en": "One star will be subtracted for each wrong [b]LETTER[/b] and it will appear in [b]RED[/b].",
		"de": "Für jeden falschen [b]BUCHSTABEN[/b] wird ein Stern abgezogen und er erscheint [b]ROT[/b].",
		"fr": "Une étoile sera retirée pour chaque [b]LETTRE[/b] fausse et elle apparaîtra en [b]ROUGE[/b].",
		"eu": "Huts egindako [b]LETRA[/b] bakoitzeko izar bat kenduko da eta [b]GORRIZ[/b] agertuko da.",
		"it": "Verrà sottratta una stella per ogni [b]LETTERA[/b] sbagliata e apparirà in [b]ROSSO[/b].",
		"pt": "Será retirada uma estrela por cada [b]LETRA[/b] errada e aparecerá a [b]VERMELHO[/b].",
	},
	"RevealDlgSkip": {
		"es": "No mostrar este cuadro en el futuro y revelar directamente",
		"en": "Don't show this dialog again and reveal directly",
		"de": "Dieses Fenster künftig nicht mehr anzeigen und direkt aufdecken",
		"fr": "Ne plus afficher cette fenêtre et révéler directement",
		"eu": "Ez erakutsi berriro koadro hau eta agertu zuzenean",
		"it": "Non mostrare più questa finestra e rivela direttamente",
		"pt": "Não voltar a mostrar este quadro e revelar diretamente",
	},
	"RevealDlgCancel": {
		"es": "CANCELAR", "en": "CANCEL", "de": "ABBRECHEN",
		"fr": "ANNULER", "eu": "UTZI", "it": "ANNULLA", "pt": "CANCELAR",
	},
}

@onready var card: PanelContainer = $Center/Card
@onready var letters_label: RichTextLabel = %Letters
@onready var skip_button: Button = %SkipRow
@onready var skip_mark: Label = %SkipMark
@onready var skip_box: Panel = %SkipBox
@onready var _title: Label = $Center/Card/Margin/Content/Title
@onready var _intro: RichTextLabel = $Center/Card/Margin/Content/Intro
@onready var _ok_title: Label = $Center/Card/Margin/Content/GreenCard/Margin/Row/Texts/Heading
@onready var _ok_body: RichTextLabel = $Center/Card/Margin/Content/GreenCard/Margin/Row/Texts/Body
@onready var _fail_title: Label = $Center/Card/Margin/Content/RedCard/Margin/Row/Texts/Heading
@onready var _fail_body: RichTextLabel = $Center/Card/Margin/Content/RedCard/Margin/Row/Texts/Body
@onready var _skip_text: Label = $Center/Card/Margin/Content/SkipRow/Row/SkipText
@onready var _cancel: Button = $Center/Card/Margin/Content/Buttons/ButtonCancel
@onready var _reveal_title: Label = $Center/Card/Margin/Content/Buttons/ButtonReveal/Title


func _ready() -> void:
	add_to_group("RevealOverlay")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_locale()
	_update_letters()
	gui_input.connect(_on_background_input)


func _apply_locale() -> void:
	_title.text = _t("TutReveal")
	_intro.text = _t("RevealDlgIntro")
	_ok_title.text = _t("RevealDlgOkTitle")
	_ok_body.text = _t("RevealDlgOkBody")
	_fail_title.text = _t("RevealDlgFailTitle")
	_fail_body.text = _t("RevealDlgFailBody")
	_skip_text.text = _t("RevealDlgSkip")
	_cancel.text = _t("RevealDlgCancel")
	_reveal_title.text = _t("TutReveal")


func _update_letters() -> void:
	var pending := _letters_to_check()
	if pending.is_empty():
		letters_label.add_theme_color_override("default_color", COLOR_RED)
		letters_label.add_theme_font_override("normal_font", FONT_TITLE)
		letters_label.text = _t("RevealDlgNone")
		return
	var prefix := _t("RevealDlgOne") if pending.size() == 1 else _t("RevealDlgMany")
	letters_label.add_theme_color_override("default_color", COLOR_INK)
	letters_label.text = "%s [b][font_size=56]%s[/font_size][/b]" % [
		prefix,
		", ".join(pending)
	]


func _t(key: String) -> String:
	var translated := tr(key)
	if translated != "" and translated != key:
		return translated
	var locale := TranslationServer.get_locale().left(2).to_lower()
	var by_locale: Dictionary = COPY.get(key, {})
	return str(by_locale.get(locale, by_locale.get("es", key)))


func _letters_to_check() -> PackedStringArray:
	var seen: Dictionary = {}
	var cells: Array[Celda] = []
	for node: Node in get_tree().get_nodes_in_group("Celda"):
		if not node is Celda:
			continue
		var cell := node as Celda
		if cell.numero >= 100 or cell.letter_user == "" or cell.bloqueada:
			continue
		var letter := cell.letter_user.to_upper()
		if seen.has(letter):
			continue
		seen[letter] = true
		cells.append(cell)
	cells.sort_custom(func(a: Celda, b: Celda) -> bool:
		return a.orden < b.orden
	)
	var letters: PackedStringArray = []
	for cell in cells:
		letters.append(cell.letter_user.to_upper())
	return letters


func _on_background_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if card.get_global_rect().has_point((event as InputEventMouseButton).global_position):
		return
	SoundManager.play("ButtonClick")
	queue_free()


func _on_skip_pressed(_pressed: bool) -> void:
	SoundManager.play("ButtonClick")
	var checked := skip_button.button_pressed
	skip_mark.text = "✓" if checked else ""
	var style := skip_box.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style != null:
		style.bg_color = COLOR_CHECK_ON if checked else COLOR_CHECK_OFF
		skip_box.add_theme_stylebox_override("panel", style)


func _on_cancel_pressed() -> void:
	SoundManager.play("ButtonClick")
	queue_free()


func _on_reveal_pressed() -> void:
	SoundManager.play("ButtonClick")
	if skip_button.button_pressed:
		PlayerPrefs.skip_reveal_dialog = true
		PlayerPrefs.save_prefs()
	queue_free()
	GameManager.reveal_assignment_errors()
