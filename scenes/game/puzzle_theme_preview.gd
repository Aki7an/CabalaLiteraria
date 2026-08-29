extends Control
class_name PuzzleThemePreview

const PATH_APP := "res://scenes/App.tscn"

@export var launch_game_on_start: bool = false
@export var image_path: String = ""

@onready var image: TextureRect = $Card/ImageFrame/Image
@onready var category_label: Label = $Card/Category
@onready var id_label: Label = $Card/Id
@onready var start_button: Button = $Card/ButtonStart


func _ready() -> void:
	add_to_group("PuzzleThemePreview")
	category_label.text = GameManager.category_display_name()
	id_label.text = "ID %d" % GameManager.id_frase
	_load_image()
	start_button.visible = true


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
