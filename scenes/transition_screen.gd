extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	color_rect.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)
	
func _on_animation_finished(anim_name: String, anim_speed:float) -> void:
	if anim_name == "fade_to_black":
		SignalManager.on_transition_finished.emit()
		animation_player.speed_scale = anim_speed
		animation_player.play("fade_to_normal")
	elif anim_name == "fade_to_normal":
		animation_player.speed_scale = anim_speed
		color_rect.visible = false
	
func transition_to_black() -> void:
	color_rect.visible = true
	animation_player.play("fade_to_black")
	
func transition_to_normal() -> void:
	color_rect.visible = true
	animation_player.play("fade_to_normal")
