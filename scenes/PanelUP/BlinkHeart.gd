# SpriteBlinkOneCycle.gd — Godot 4.4.x
extends Sprite2D
# opcional: class_name SpriteBlinkOneCycle

signal blink_finished

@export var scale_up: float = 1.08     # pico superior (relativo a escala base)
@export var scale_down: float = 0.96   # valle (relativo a escala base)
@export var total_duration: float = 0.6
@export var trans_type: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
@export var start_on_ready: bool = false

# Reparto del tiempo (deben sumar 1.0)
@export var up_ratio: float = 0.33     # base -> up
@export var down_ratio: float = 0.33   # up -> down
@export var back_ratio: float = 0.34   # down -> base

var _tween: Tween
var _base_scale := Vector2.ONE
var _running := false

func _ready() -> void:
	centered = true
	_base_scale = scale
	if start_on_ready:
		start_blink()

func _exit_tree() -> void:
	if is_instance_valid(_tween):
		_tween.kill()

func start_blink() -> void:
	if _running:
		return
	_running = true
	_run_cycle_total_time()

func stop_blink(reset: bool = true) -> void:
	_running = false
	if is_instance_valid(_tween):
		_tween.kill()
	if reset:
		scale = _base_scale

func _run_cycle_total_time() -> void:
	# Seguridad: normaliza ratios si no suman 1
	var sum := up_ratio + down_ratio + back_ratio
	if sum <= 0.0:
		up_ratio = 0.33; down_ratio = 0.33; back_ratio = 0.34
		sum = 1.0
	up_ratio /= sum
	down_ratio /= sum
	back_ratio /= sum

	var dur_up :float= max(0.0, total_duration * up_ratio)
	var dur_down :float= max(0.0, total_duration * down_ratio)
	var dur_back :float= max(0.0, total_duration * back_ratio)

	if is_instance_valid(_tween):
		_tween.kill()

	_tween = create_tween()
	_tween.set_trans(trans_type).set_ease(ease_type)

	# Base -> Up
	_tween.tween_property(self, "scale", _base_scale * scale_up, dur_up)
	# Up -> Down
	_tween.tween_property(self, "scale", _base_scale * scale_down, dur_down)
	# Down -> Base
	_tween.tween_property(self, "scale", _base_scale, dur_back)

	_tween.finished.connect(func ():
		_running = false
		emit_signal("blink_finished")
	)
