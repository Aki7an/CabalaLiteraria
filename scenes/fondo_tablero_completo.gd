extends ColorRect


func _ready() -> void:
	add_to_group("BoardFillPrompt")


func _on_review_pressed() -> void:
	SoundManager.play("ButtonClick")
	queue_free()


func _on_finish_pressed() -> void:
	SoundManager.play("ButtonClick")
	queue_free()
	GameManager.reveal_assignment_errors()
