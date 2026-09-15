extends VBoxContainer

@export var title_a_key := ""
@export var body_a_key := ""
@export var title_b_key := ""
@export var body_b_key := ""
@export var image_a: Texture2D
@export var image_b: Texture2D
@export var cover_a := true
@export var cover_b := true

@onready var _title_a: Label = $BlockA/Box/Title
@onready var _body_a: Label = $BlockA/Box/Body
@onready var _image_a: TextureRect = $BlockA/Box/Frame/Image
@onready var _title_b: Label = $BlockB/Box/Title
@onready var _body_b: Label = $BlockB/Box/Body
@onready var _image_b: TextureRect = $BlockB/Box/Frame/Image


func apply_locale() -> void:
	_title_a.text = tr(title_a_key)
	_body_a.text = tr(body_a_key)
	_title_b.text = tr(title_b_key)
	_body_b.text = tr(body_b_key)
	_image_a.texture = image_a
	_image_b.texture = image_b
	_image_a.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover_a else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	_image_b.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover_b else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
