extends ColorRect

const ShareConfig := preload("res://store/share_config.gd")
const STAR_FILL := preload("res://images/estrella_plano.png")
const STAR_EMPTY := preload("res://images/contorno_estrella.png")
const APP_ICON := preload("res://images/Icono.png")

@onready var brand_label: Label = %Brand
@onready var mode_label: Label = %Mode
@onready var category_label: Label = %Category
@onready var id_label: Label = %PuzzleId
@onready var theme_image: TextureRect = %ThemeImage
@onready var stars_row: HBoxContainer = %StarsRow
@onready var time_label: Label = %TimeLabel
@onready var hints_label: Label = %HintsLabel
@onready var challenge_label: Label = %Challenge
@onready var studio_label: Label = %Studio
@onready var app_icon: TextureRect = %AppIcon


func apply_payload(data: Dictionary) -> void:
	brand_label.text = str(data.get("brand", "CifraLetra"))
	mode_label.text = str(data.get("mode", ""))
	category_label.text = str(data.get("category", ""))
	id_label.text = str(data.get("puzzle_id_text", ""))
	time_label.text = str(data.get("time_text", ""))
	hints_label.text = str(data.get("hints_text", ""))
	challenge_label.text = str(data.get("challenge", ""))
	studio_label.text = str(data.get("studio", ShareConfig.STUDIO))
	if app_icon and APP_ICON:
		app_icon.texture = APP_ICON
	_apply_theme_image(str(data.get("image_path", "")))
	_apply_stars(int(data.get("stars_earned", 0)), int(data.get("stars_max", 0)), data.get("star_color", Color(1, 0.82, 0.12)))


func _apply_theme_image(path: String) -> void:
	var texture: Texture2D = null
	if path != "" and (ResourceLoader.exists(path) or FileAccess.file_exists(path)):
		texture = load(path) as Texture2D
	if texture == null:
		texture = APP_ICON
	theme_image.texture = texture


func _apply_stars(earned: int, maximum: int, star_color: Variant) -> void:
	var fill := STAR_FILL
	var empty := STAR_EMPTY if STAR_EMPTY else STAR_FILL
	var color := star_color as Color if star_color is Color else Color(1, 0.82, 0.12)
	var shown := clampi(maximum, 1, stars_row.get_child_count())
	for i in range(stars_row.get_child_count()):
		var star := stars_row.get_child(i) as TextureRect
		if star == null:
			continue
		star.visible = i < shown
		if i < earned:
			star.texture = fill
			star.self_modulate = color
		else:
			star.texture = empty
			star.self_modulate = Color(0.72, 0.58, 0.38, 0.7)
