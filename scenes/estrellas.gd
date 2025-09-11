extends Label
class_name FeedbackStars

@onready var texture_rect_star_full_1 = $Button1/TextureRectStarFull1
@onready var texture_rect_star_full_2 = $Button2/TextureRectStarFull2
@onready var texture_rect_star_full_3 = $Button3/TextureRectStarFull3
@onready var texture_rect_star_full_4 = $Button4/TextureRectStarFull4
@onready var texture_rect_star_full_5 = $Button5/TextureRectStarFull5

@onready var question_stars:int= 0


func _ready():
	texture_rect_star_full_1.visible = false
	texture_rect_star_full_2.visible = false
	texture_rect_star_full_3.visible = false
	texture_rect_star_full_4.visible = false
	texture_rect_star_full_5.visible = false
	
	
func _on_button_1_pressed():
	texture_rect_star_full_1.visible = true
	texture_rect_star_full_2.visible = false
	texture_rect_star_full_3.visible = false
	texture_rect_star_full_4.visible = false
	texture_rect_star_full_5.visible = false
	question_stars = 1
	
func _on_button_2_pressed():
	texture_rect_star_full_1.visible = true
	texture_rect_star_full_2.visible = true
	texture_rect_star_full_3.visible = false
	texture_rect_star_full_4.visible = false
	texture_rect_star_full_5.visible = false
	question_stars = 2
	
func _on_button_3_pressed():
	texture_rect_star_full_1.visible = true
	texture_rect_star_full_2.visible = true
	texture_rect_star_full_3.visible = true
	texture_rect_star_full_4.visible = false
	texture_rect_star_full_5.visible = false
	question_stars = 3
	
func _on_button_4_pressed():
	texture_rect_star_full_1.visible = true
	texture_rect_star_full_2.visible = true
	texture_rect_star_full_3.visible = true
	texture_rect_star_full_4.visible = true
	texture_rect_star_full_5.visible = false
	question_stars = 4
	
func _on_button_5_pressed():
	texture_rect_star_full_1.visible = true
	texture_rect_star_full_2.visible = true
	texture_rect_star_full_3.visible = true
	texture_rect_star_full_4.visible = true
	texture_rect_star_full_5.visible = true
	question_stars = 5
