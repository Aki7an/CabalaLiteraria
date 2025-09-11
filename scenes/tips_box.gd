extends Control

@export var interval_seconds := 10
@export var fade_time := 0.35

@onready var timer: Timer = $Timer
@onready var texture_progress_bar: TextureProgressBar = $TextureProgressBar

var slides: Array[CanvasItem] = []
var idx := 0
var rng := RandomNumberGenerator.new()
var _progress_tween: Tween
var _advancing := false

func _ready() -> void:
	# Solo hijos que estén en el grupo "Tip" y sean CanvasItem
	for c in get_children():
		if c is CanvasItem and c.is_in_group("Tip"):
			slides.append(c)

	if slides.is_empty():
		return

	# Inicializa alphas (solo el primero visible)
	for i in range(slides.size()):
		var col := slides[i].modulate
		col.a = 1.0 if i == 0 else 0.0
		slides[i].modulate = col

	rng.randomize()

	# Timer en ciclo por slide (sincronizado con el progress)
	timer.wait_time = interval_seconds
	timer.one_shot = true
	timer.timeout.connect(_next_slide)

	_restart_progress()
	timer.start()

func _restart_progress() -> void:
	# 0 → 100 en interval_seconds
	texture_progress_bar.min_value = 0
	texture_progress_bar.max_value = 100
	texture_progress_bar.value = 0

	if is_instance_valid(_progress_tween):
		_progress_tween.kill()

	_progress_tween = create_tween()
	_progress_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_progress_tween.tween_property(texture_progress_bar, "value", 100.0, interval_seconds)
	_progress_tween.finished.connect(_on_progress_finished)

func _on_progress_finished() -> void:
	# Evita doble disparo si el Timer también acaba
	if not timer.is_stopped():
		timer.stop()
	_next_slide()

func _next_slide() -> void:
	if slides.is_empty() or _advancing:
		return
	_advancing = true

	var prev := idx
	var next_idx := prev
	if slides.size() > 1:
		while next_idx == prev:
			next_idx = rng.randi_range(0, slides.size() - 1)
	idx = next_idx

	# Fade cruzado
	var t := create_tween()
	t.tween_property(slides[prev], "modulate:a", 0.0, fade_time)
	t.parallel().tween_property(slides[idx], "modulate:a", 1.0, fade_time)
	await t.finished

	_restart_progress()
	timer.start()
	_advancing = false
