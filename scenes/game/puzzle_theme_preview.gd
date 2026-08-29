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

const STAR_ON := Color(1.0, 0.82, 0.12, 1.0)
const STAR_OFF := Color(0.7, 0.62, 0.5, 0.32)


func _ready() -> void:
	add_to_group("PuzzleThemePreview")
	category_label.text = GameManager.category_display_name()
	id_label.text = "ID %d" % GameManager.id_frase
	_update_difficulty_stars()
	_load_image()
	start_button.visible = true


func _update_difficulty_stars() -> void:
	var filled: int = clampi(GameManager.dificultad_actual, 1, difficulty_stars.size())
	for index in range(difficulty_stars.size()):
		difficulty_stars[index].self_modulate = STAR_ON if index < filled else STAR_OFF


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
