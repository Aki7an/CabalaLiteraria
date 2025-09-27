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

# --- SHAKE -------------------------------------------------
func _do_shake() -> void:
	if is_instance_valid(_shake_tween):
		_shake_tween.kill()
	
	var total_time := 0.0
	var strength := shake_strength
	var steps: Array[Vector2] = []
	
	# Genera offsets aleatorios que decaen
	while total_time < shake_duration:
		var dir := Vector2(_rng.randf_range(-1,1), _rng.randf_range(-1,1)).normalized()
		var off := dir * strength
		steps.append(off)
		strength *= shake_falloff
		total_time += 0.03 # paso temporal fijo ~33 Hz
	
	# Vuelve al origen al final
	steps.append(Vector2.ZERO)

	_shake_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var t := 0.03
	for i in steps.size():
		_shake_tween.tween_property(self, "offset", steps[i], t)
	# Asegura que al terminar quedamos centrados
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
