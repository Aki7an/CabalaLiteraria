extends Control

const FX = preload("res://scenes/trailer/trailer_anim.gd")
const T = preload("res://scenes/trailer/trailer_timing.gd")
const STYLE = preload("res://scenes/trailer/trailer_style.gd")
const COPY = preload("res://scenes/trailer/trailer_copy.gd")

@export var puzzle_id: int = 116
@export_multiline var moon_phrase: String = "El 20 de julio de 1969, Apolo 11 dejó su huella en la Luna."
@export var moon_image_number: int = 5


func _enter_tree() -> void:
	_prepare_puzzle()
	if owner == null:
		FX.apply_fullhd(self)


func _ready() -> void:
	if owner == null:
		FX.apply_fullhd(self)
		await play_block()


func play_block() -> void:
	var started := Time.get_ticks_msec()
	var phone := %Phone
	var question := %Question as Label
	clip_contents = false
	_prepare_puzzle()
	await phone.reload_board()
	phone.show_game_background()
	phone.hide_chrome()
	phone.show_board_numbers()
	await get_tree().process_frame
	await get_tree().process_frame
	phone.show_board_numbers()
	phone.pin_board_canvas()
	phone.z_as_relative = false
	phone.z_index = 20
	phone.pivot_offset = Vector2.ZERO
	phone.visible = true
	phone.modulate = Color.WHITE
	var dest: Dictionary = phone.hook_xform()
	phone.scale = dest["scale"]
	phone.position = dest["position"]
	phone.modulate.a = 0.0
	phone.set_meta("cam_rest_scale", dest["scale"])
	phone.set_meta("cam_rest_pos", dest["position"])
	STYLE.apply_title(question, STYLE.SIZE_QUESTION)
	question.text = COPY.text("TRAILER_QUESTION")
	question.z_as_relative = false
	question.z_index = 24
	question.size = Vector2(1760.0, 120.0)
	question.position = Vector2(80.0, 932.0)
	question.visible = false
	question.modulate.a = 0.0
	FX.cue("hook")
	var inn := create_tween()
	inn.tween_property(phone, "modulate:a", 1.0, T.HOOK_IN)
	await inn.finished
	phone.pin_board_canvas()
	await FX.fade_in(self, question, T.CAPTION_IN)
	await FX.wait(self, T.QUESTION_HOLD)
	await FX.fade_out(self, question, T.QUESTION_OUT)
	question.visible = false
	await FX.wait_remaining(self, started, T.SEC_01)


func keep_on_stage() -> bool:
	return true


func get_phone() -> Control:
	return %Phone as Control


func _prepare_puzzle() -> void:
	if GameManager == null:
		return
	GameManager.reset_game_paremeters()
	GameManager.resetear_partida_terminada()
	GameManager.session_source = GameManager.SOURCE_NONE
	GameManager.set_game_mode_actual(GameManager.MODE_QUICK)
	GameManager.seleccionar_frase_por_indice_db(puzzle_id)
	GameManager.frase_original_til = moon_phrase
	GameManager.frase_original = GameManager.normalizar_frase_idioma(moon_phrase, "es")
	GameManager.id_image = moon_image_number
	GameManager.id_frase = puzzle_id
	GameManager._inicializar_datos()
	GameManager._inicializar_lista_numeros_original()
	GameManager.set_calculo_letras_iniciales()
	GameManager.puzzle_enter_pending = true
	GameManager.tiempo_partida = 0
