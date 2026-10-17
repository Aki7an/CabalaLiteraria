# ErrorFeedback.gd (Godot 4.x)
extends CanvasLayer

@export var shake_duration := 0.18
@export var shake_strength := 4.0
@export var shake_falloff := 0.72

var _shake_tween: Tween
var _shake_target: Control
var _shake_rest := Vector2.ZERO
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("ErrorFeedback")
	_rng.randomize()
	SignalManager.decrease_live.connect(trigger_error_feedback)


func trigger_error_feedback() -> void:
	_do_board_shake(shake_duration, shake_strength)


func trigger_soft_shake() -> void:
	_do_board_shake(0.14, 2.5)


func trigger_reveal_error_shake() -> void:
	_do_board_shake(0.2, 5.0)


func _board_target() -> Control:
	var board := get_node_or_null("BoardFrame/CanvasJuego") as Control
	if board != null:
		return board
	var nodes := get_tree().get_nodes_in_group("PuzzleCanvas")
	for node in nodes:
		if node is Control:
			return node as Control
	return null


func _restore_board() -> void:
	if is_instance_valid(_shake_target):
		_shake_target.position = _shake_rest
	_shake_target = null


func _do_board_shake(duration: float, start_strength: float) -> void:
	var target := _board_target()
	if target == null:
		return
	if is_instance_valid(_shake_tween):
		_shake_tween.kill()
		_restore_board()

	_shake_target = target
	_shake_rest = target.position

	var total_time := 0.0
	var current_strength := start_strength
	var steps: Array[Vector2] = []
	while total_time < duration:
		var raw := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
		var dir := raw if raw.length() < 0.001 else raw.normalized()
		steps.append(dir * current_strength)
		current_strength *= shake_falloff
		total_time += 0.03
	steps.append(Vector2.ZERO)

	_shake_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for step in steps:
		_shake_tween.tween_property(target, "position", _shake_rest + step, 0.03)
	_shake_tween.finished.connect(_restore_board)
