extends Control
class_name PuzzleThemePreview

@export var launch_game_on_start: bool = false
@export var image_path: String = ""

@onready var image: TextureRect = $Card/ImageFrame/Image
@onready var title_label: Label = $Card/Title
@onready var category_label: Label = $Card/Category
@onready var id_label: Label = $Card/Id
@onready var start_button: Button = $Card/ButtonStart
@onready var difficulty_stars: Array[TextureRect] = [
	$Card/DifficultyStars/Star1,
	$Card/DifficultyStars/Star2,
	$Card/DifficultyStars/Star3,
	$Card/DifficultyStars/Star4,
	$Card/DifficultyStars/Star5
]

const STAR_ON: Texture2D = preload("res://images/estrella_plano.png")
const STAR_OFF: Texture2D = preload("res://images/contorno_estrella.png")
const STAR_EMPTY := Color(0.7, 0.62, 0.5, 0.32)
const COLOR_STAR_EMPTY_OUTLINE := Color(0.50, 0.38, 0.24, 0.78)
const COPY := {
	"PuzzleThemeTitle": {
		"es": "TEMA DEL PUZLE",
		"en": "PUZZLE THEME",
		"de": "RÄTSELTHEMA",
		"fr": "THÈME DU PUZZLE",
		"eu": "PUZZLEAREN GAIA",
		"it": "TEMA DEL PUZZLE",
		"pt": "TEMA DO PUZZLE",
	},
	"StartPuzzle": {
		"es": "EMPEZAR",
		"en": "START",
		"de": "STARTEN",
		"fr": "COMMENCER",
		"eu": "HASI",
		"it": "INIZIA",
		"pt": "COMEÇAR",
	},
	"ContinuePuzzle": {
		"es": "CONTINUAR",
		"en": "CONTINUE",
		"de": "FORTSETZEN",
		"fr": "CONTINUER",
		"eu": "JARRAITU",
		"it": "CONTINUA",
		"pt": "CONTINUAR",
	},
	"ObserveTheme": {
		"es": "Observa la imagen del tema",
		"en": "Look at the theme image",
		"de": "Sieh dir das Themenbild an",
		"fr": "Regarde l'image du thème",
		"eu": "Begiratu gaiaren irudia",
		"it": "Guarda l'immagine del tema",
		"pt": "Olha a imagem do tema",
	},
}


func _ready() -> void:
	add_to_group("PuzzleThemePreview")
	title_label.text = _t("PuzzleThemeTitle")
	category_label.text = GameManager.category_display_name()
	id_label.text = "ID %d" % GameManager.id_frase
	_update_difficulty_stars()
	_load_image()
	start_button.visible = true
	var saved := PuzzleSaveManager.get_puzzle_summary(GameManager.id_frase)
	var in_progress := str(saved.get("status", "new")) == "in_progress"
	if launch_game_on_start:
		start_button.text = _t("ContinuePuzzle") if in_progress else _t("StartPuzzle")
	else:
		start_button.text = _t("ContinuePuzzle")
	if in_progress:
		_show_continue_progress(saved)
	else:
		var wait_text := get_node_or_null("Card/WaitText") as Label
		if wait_text:
			wait_text.text = _t("ObserveTheme")
	if Distribution.is_horizontal():
		call_deferred("_layout_horizontal_theme")


func _layout_horizontal_theme() -> void:
	var layer := _game_canvas()
	var card := get_node_or_null("Card") as Control
	var frame := get_node_or_null("Card/ImageFrame") as Control
	var back := get_node_or_null("Card/ButtonBack") as Control
	if layer == null or card == null or frame == null or back == null or start_button == null:
		return
	if get_parent() != layer:
		reparent(layer)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = layer.size
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 2000
	var backdrop := get_node_or_null("Backdrop") as ColorRect
	if backdrop:
		backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
		backdrop.offset_left = 0.0
		backdrop.offset_top = 0.0
		backdrop.offset_right = 0.0
		backdrop.offset_bottom = 0.0
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	card.visible = false
	frame.reparent(self)
	frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	frame.clip_contents = true
	image.set_anchors_preset(Control.PRESET_FULL_RECT)
	image.offset_left = 0.0
	image.offset_top = 0.0
	image.offset_right = 0.0
	image.offset_bottom = 0.0
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back.reparent(self)
	start_button.reparent(self)
	var margin := 22.0
	var back_size := Vector2(88.0, 88.0)
	var start_size := Vector2(300.0, 84.0)
	back.custom_minimum_size = back_size
	back.z_index = 5
	back.position = Vector2(margin, margin)
	back.size = back_size
	start_button.custom_minimum_size = start_size
	start_button.z_index = 5
	start_button.add_theme_font_size_override("font_size", 40)
	start_button.position = Vector2(size.x - start_size.x - margin, size.y - start_size.y - margin)
	start_button.size = start_size
	var reserved := [
		Rect2(back.position, back.size).grow(12.0),
		Rect2(start_button.position, start_button.size).grow(12.0),
	]
	var aspect := _image_aspect()
	var image_rect := _centered_image_rect(size, aspect, size.y * 0.92, reserved)
	frame.position = image_rect.position
	frame.size = image_rect.size


func _game_canvas() -> Control:
	var host := get_parent()
	if host != null and host.get_parent() is Control:
		return host.get_parent() as Control
	return null


func _image_aspect() -> float:
	if image != null and image.texture != null:
		var tex_size := image.texture.get_size()
		if tex_size.y > 1.0:
			return tex_size.x / tex_size.y
	return 1.0


func _centered_image_rect(screen: Vector2, aspect: float, height: float, blocked: Array) -> Rect2:
	var fitted := height
	var rect := Rect2()
	for _i in 24:
		var width := fitted * aspect
		rect = Rect2((screen.x - width) * 0.5, (screen.y - fitted) * 0.5, width, fitted)
		var overlaps := false
		for area in blocked:
			if rect.intersects(area):
				overlaps = true
				break
		if not overlaps and rect.position.x >= 8.0 and rect.end.x <= screen.x - 8.0:
			return rect
		fitted *= 0.94
	return rect


func _t(key: String) -> String:
	var translated := tr(key)
	if translated != "" and translated != key:
		return translated
	var locale := TranslationServer.get_locale().left(2).to_lower()
	var by_locale: Dictionary = COPY.get(key, {})
	return str(by_locale.get(locale, by_locale.get("es", key)))


func _update_difficulty_stars() -> void:
	var maximum := GameManager.get_puzzle_difficulty_stars()
	var saved := PuzzleSaveManager.get_puzzle_summary(GameManager.id_frase)
	var remaining := clampi(
		int(saved.get("stars_remaining", maximum)),
		0,
		maximum
	)
	var onboarding := GameManager.is_onboarding_session()
	if onboarding:
		remaining = 0
	for index in range(difficulty_stars.size()):
		difficulty_stars[index].visible = index < maximum
		var is_filled := index < remaining
		if onboarding:
			difficulty_stars[index].texture = STAR_ON if is_filled else STAR_OFF
			difficulty_stars[index].self_modulate = (
				GameManager.star_fill_color() if is_filled else COLOR_STAR_EMPTY_OUTLINE
			)
		else:
			difficulty_stars[index].texture = STAR_ON
			difficulty_stars[index].self_modulate = (
				GameManager.star_fill_color() if is_filled else STAR_EMPTY
			)


func _show_continue_progress(saved: Dictionary) -> void:
	var wait_text := get_node_or_null("Card/WaitText") as Label
	if wait_text == null:
		return
	var filled := int(saved.get("letters_filled", 0))
	var total := int(saved.get("letters_total", 0))
	var letters := tr("LettersProgress") % [filled, total]
	var seconds := maxi(int(saved.get("tiempo_partida", 0)), 0)
	var hours := seconds / 3600
	var minutes := (seconds % 3600) / 60
	var rest := seconds % 60
	var elapsed := "%d:%02d:%02d" % [hours, minutes, rest] if hours > 0 else "%d:%02d" % [minutes, rest]
	var template := tr("TimeTaken")
	var time_text := template % elapsed if "%s" in template else "%s: %s" % [tr("Time"), elapsed]
	wait_text.text = "%s   ·   %s" % [letters, time_text]


func setup(should_launch_game: bool, path: String = "") -> void:
	launch_game_on_start = should_launch_game
	image_path = path
	if is_node_ready():
		_load_image()


func _load_image() -> void:
	var resolved_path := image_path
	if resolved_path == "":
		resolved_path = find_image_path(GameManager.id_image, GameManager.id_frase)
	if resolved_path == "":
		return
	var texture := load(resolved_path) as Texture2D
	if texture != null:
		image.texture = texture


func _on_start_pressed() -> void:
	SoundManager.play("ButtonClick")
	if not launch_game_on_start:
		queue_free()
		return
	start_button.disabled = true
	TransitionScreen.transition_to_black()
	await TransitionScreen._on_animation_finished("fade_to_black", 1)
	GameManager.launch_prepared_game()


func _on_back_pressed() -> void:
	SoundManager.play("ButtonClick")
	queue_free()


static func find_image_path(image_number: int, index_number: int) -> String:
	var from_manager := GameManager.find_level_image_path(image_number)
	if from_manager != "":
		return from_manager
	var numbers: Array[int] = [image_number]
	if index_number != image_number:
		numbers.append(index_number)
	for number in numbers:
		if number < 0:
			continue
		var uppercase_png := "res://data/images/image%d.PNG" % number
		if number == 1 and ResourceLoader.exists(uppercase_png):
			return uppercase_png
		for extension in [".png", ".jpg", ".jpeg", ".webp"]:
			var candidate := "res://data/images/image%d%s" % [number, extension]
			if ResourceLoader.exists(candidate):
				return candidate
	return ""
