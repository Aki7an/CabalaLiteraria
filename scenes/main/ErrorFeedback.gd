# ErrorFeedback.gd (Godot 4.x)
extends CanvasLayer
# opcional: class_name ErrorFeedback

@export var shake_duration := 0.35     # s
@export var shake_strength := 18.0     # px (amplitud inicial)
@export var shake_falloff := 0.85      # 0..1 (decaimiento por golpe)
@export var flash_cycles := 3          # nº de parpadeos rojo↔transparente
@export var flash_time := 0.06         # s por semicírculo (rojo o transparente)
@export var flash_color := Color(1,0,0,0.55)  # rojo con alpha

var _shake_tween: Tween
var _flash_tween: Tween
var _rng := RandomNumberGenerator.new()

@onready var overlay := ColorRect.new()

func _ready() -> void:
	add_to_group("ErrorFeedback")
	_rng.randomize()
	# Capa superpuesta para el flash rojo
	overlay.color = Color(1,0,0,0.0) # transparente al inicio
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	SignalManager.decrease_live.connect(trigger_error_feedback)

func trigger_error_feedback() -> void:
	_do_shake()
	_do_flash()
	_vibrate(220, 1.0)


func trigger_soft_shake() -> void:
	_do_shake_with(0.22, 7.0)
	_vibrate(55, 0.28)


func trigger_reveal_error_shake() -> void:
	_do_shake_with(0.48, 24.0)
	_vibrate(280, 1.0)


func _vibrate(duration_ms: int, amplitude: float) -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	Input.vibrate_handheld(duration_ms, clampf(amplitude, 0.0, 1.0))


# --- SHAKE -------------------------------------------------
func _do_shake() -> void:
	_do_shake_with(shake_duration, shake_strength)


func _do_shake_with(duration: float, start_strength: float) -> void:
	if is_instance_valid(_shake_tween):
		_shake_tween.kill()

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
	for _i in steps.size():
		_shake_tween.tween_property(self, "offset", steps[_i], 0.03)
	_shake_tween.finished.connect(func(): offset = Vector2.ZERO)

# --- FLASH -------------------------------------------------
func _do_flash() -> void:
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()

	_flash_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in range(flash_cycles):
		# a rojo
		_flash_tween.tween_property(overlay, "color", flash_color, flash_time)
		# a transparente
		_flash_tween.tween_property(overlay, "color", Color(flash_color.r, flash_color.g, flash_color.b, 0.0), flash_time)
