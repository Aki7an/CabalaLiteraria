extends Control
class_name PuzzleThemePreview

const PATH_APP := "res://scenes/App.tscn"

@export var launch_game_on_start: bool = false
@export var image_path: String = ""

@onready var image: TextureRect = $Card/ImageFrame/Image
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

const STAR_EMPTY := Color(0.7, 0.62, 0.5, 0.32)


func _ready() -> void:
	add_to_group("PuzzleThemePreview")
	category_label.text = GameManager.category_display_name()
	id_label.text = "ID %d" % GameManager.id_frase
	_update_difficulty_stars()
	_load_image()
	start_button.visible = true
	var saved := PuzzleSaveManager.get_puzzle_summary(GameManager.id_frase)
	var in_progress := str(saved.get("status", "new")) == "in_progress"
	if launch_game_on_start:
		start_button.text = "CONTINUAR" if in_progress else "EMPEZAR"
	else:
		start_button.text = "CONTINUAR"
	if in_progress:
		_show_continue_progress(saved)


func _update_difficulty_stars() -> void:
	var maximum := GameManager.get_puzzle_difficulty_stars()
	var saved := PuzzleSaveManager.get_puzzle_summary(GameManager.id_frase)
	var remaining := clampi(
		int(saved.get("stars_remaining", maximum)),
		0,
		maximum
	)
	for index in range(difficulty_stars.size()):
		difficulty_stars[index].visible = index < maximum
		difficulty_stars[index].self_modulate = (
			GameManager.star_fill_color() if index < remaining else STAR_EMPTY
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
	SignalManager.partida_iniciada.emit()
	get_tree().change_scene_to_file(PATH_APP)


func _on_back_pressed() -> void:
	SoundManager.play("ButtonClick")
	queue_free()


static func find_image_path(image_number: int, index_number: int) -> String:
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
