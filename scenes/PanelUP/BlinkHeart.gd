# SpriteBlinkTwoPulses.gd — Godot 4.4.x
extends Sprite2D
# opcional: class_name SpriteBlinkTwoPulses

signal blink_finished

@export var scale_up: float = 1.08     # pico superior del primer ciclo (relativo a escala base)
@export var scale_down: float = 0.96   # valle del primer ciclo (relativo a escala base)
@export var step_duration: float = 0.12
@export var pause_between: float = 0.05
@export var affect_alpha: bool = false
@export var alpha_min: float = 0.65    # alpha en valle del primer ciclo
@export var trans_type: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
@export var start_on_ready: bool = false

var _tween: Tween
var _base_scale := Vector2.ONE
var _base_modulate := Color(1, 1, 1, 1)
var _running := false

func _ready() -> void:
	centered = true
	_base_scale = scale
	_base_modulate = modulate
	if start_on_ready:
		start_blink()

func _exit_tree() -> void:
	if is_instance_valid(_tween):
		_tween.kill()

func start_blink() -> void:
	if _running:
		return
	_running = true
	_run_two_cycles()

func stop_blink(reset: bool = true) -> void:
	_running = false
	if is_instance_valid(_tween):
		_tween.kill()
	if reset:
		scale = _base_scale
		modulate = _base_modulate

func _run_two_cycles() -> void:
	# Calcula amplitud reducida al 50% para el segundo ciclo
	var up2   := 1.0 + (scale_up  - 1.0) * 0.5   # mitad entre base (1.0) y scale_up
	var down2 := 1.0 - (1.0 - scale_down) * 0.5  # mitad entre base (1.0) y scale_down
	var alpha_min2 := _base_modulate.a + (alpha_min - _base_modulate.a) * 0.5

	_tween = create_tween()
	_tween.set_parallel(false)

	# ---- Ciclo 1 (amplitud completa) ----
	_cycle_to_tween(_tween, scale_up, scale_down, alpha_min)

	# ---- Ciclo 2 (amplitud al 50%) ----
	_cycle_to_tween(_tween, up2, down2, alpha_min2)

	# Fin
	_tween.finished.connect(func ():
		_running = false
		emit_signal("blink_finished")
	)

func _cycle_to_tween(tw: Tween, up: float, down: float, a_min: float) -> void:
	# Subida
	tw.tween_property(self, "scale", _base_scale * up, step_duration)\
		.set_trans(trans_type).set_ease(ease_type)
	if affect_alpha:
		tw.set_parallel(true)
		tw.tween_property(self, "modulate:a", 1.0, step_duration)\
			.set_trans(trans_type).set_ease(ease_type)
		tw.set_parallel(false)
	if pause_between > 0.0:
		tw.tween_interval(pause_between)

	# Bajada (por debajo de 1)
	tw.tween_property(self, "scale", _base_scale * down, step_duration)\
		.set_trans(trans_type).set_ease(ease_type)
	if affect_alpha:
		tw.set_parallel(true)
		tw.tween_property(self, "modulate:a", a_min, step_duration)\
			.set_trans(trans_type).set_ease(ease_type)
		tw.set_parallel(false)
	if pause_between > 0.0:
		tw.tween_interval(pause_between)

	# Vuelta a la base
	tw.tween_property(self, "scale", _base_scale, step_duration)\
		.set_trans(trans_type).set_ease(ease_type)
	if affect_alpha:
		tw.set_parallel(true)
		tw.tween_property(self, "modulate:a", _base_modulate.a, step_duration)\
			.set_trans(trans_type).set_ease(ease_type)
		tw.set_parallel(false)
