# SpriteBlink.gd — PÉGALO EN EL NODO Sprite2D
extends Sprite2D

@export var scale_up: float = 1.08
@export var scale_down: float = 0.96
@export var step_duration: float = 0.12
@export var pause_between: float = 0.05
@export var loop: bool = true
@export var affect_alpha: bool = false
@export var alpha_min: float = 0.65
@export var trans_type: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT

var _tween: Tween
var _base_scale := Vector2.ONE
var _base_self_modulate := Color(1, 1, 1, 1)
@export var _running := false

func _ready() -> void:
	# En Node2D el pivote es el origen; con centered=true la textura queda centrada.
	# Asegúrate en el inspector de que "Centered" está activado (suele estarlo por defecto).
	_base_scale = scale
	_base_self_modulate = self_modulate
	_running = false

func _exit_tree() -> void:
	if is_instance_valid(_tween):
		_tween.kill()

func start_blink() -> void:
	if _running:
		return
	_running = true
	_run_cycle()

func stop_blink(reset: bool = true) -> void:
	_running = false
	if is_instance_valid(_tween):
		_tween.kill()
	if reset:
		scale = _base_scale
		self_modulate = _base_self_modulate

func _run_cycle() -> void:
	_tween = create_tween()
	_tween.set_parallel(false)

	# Sube
	_tween.tween_property(self, "scale", _base_scale * scale_up, step_duration)\
		.set_trans(trans_type).set_ease(ease_type)
	if affect_alpha:
		_tween.set_parallel(true)
		_tween.tween_property(self, "self_modulate:a", 1.0, step_duration)\
			.set_trans(trans_type).set_ease(ease_type)
		_tween.set_parallel(false)
	if pause_between > 0: _tween.tween_interval(pause_between)

	# Baja por debajo de 1
	_tween.tween_property(self, "scale", _base_scale * scale_down, step_duration)\
		.set_trans(trans_type).set_ease(ease_type)
	if affect_alpha:
		_tween.set_parallel(true)
		_tween.tween_property(self, "self_modulate:a", alpha_min, step_duration)\
			.set_trans(trans_type).set_ease(ease_type)
		_tween.set_parallel(false)
	if pause_between > 0: _tween.tween_interval(pause_between)

	# Vuelve a 1
	_tween.tween_property(self, "scale", _base_scale, step_duration)\
		.set_trans(trans_type).set_ease(ease_type)
	if affect_alpha:
		_tween.set_parallel(true)
		_tween.tween_property(self, "self_modulate:a", _base_self_modulate.a, step_duration)\
			.set_trans(trans_type).set_ease(ease_type)
		_tween.set_parallel(false)

	_tween.finished.connect(func ():
		if loop and _running:
			_run_cycle()
	)
