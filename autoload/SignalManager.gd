extends Node

# Game Canvas
signal update_canvas_grid(progress: int)

signal deselect_all_cells_in_canvas

signal insert_letter_in_number (letter: String, number: int)

signal update_resting_characters

signal board_filled

signal move_canvas(wide: int)

signal update_cambios

signal on_transition_finished

signal game_finished

signal game_finished_to_results

signal update_stars(diff:int)
signal update_puzzle_stars(stars:int)

signal fit_text

signal app_version_changed(version_text: String)
signal audio_prefs_changed
signal full_game_changed
signal store_price_changed
signal daily_puzzle_changed

signal update_score

signal erase_letter

signal erase_letter_open_dialog

signal erase_selected_letter

signal player_name_for_records

signal update_rubber

signal rubber_feedback

signal añade_las_letras_iniciales

signal update_coins 

signal letra_seleccionada_para_comprar(letra_seleccionada: String)

signal update_difficulty(frase: String, reveladas: String)


signal compra_vocal_ae(t_game_ms:int)
signal compra_vocal_iou(t_game_ms:int)
signal compra_consonante(t_game_ms:int)
signal compra_pista_2(t_game_ms:int)
signal compra_pista_3(t_game_ms:int)
signal borrar_letra(t_game_ms:int, celda:int, letra:String)
signal asignar_letra(t_game_ms:int, celda:int, letra:String) 
signal partida_iniciada()
signal partida_finalizada(resultado:String) # "win" / "lose" / "abort"
signal puzzle_input(action: String, meta: Dictionary)

signal mueve_filas(rows: int, time: float)

signal update_lives(lives:int)

signal decrease_live

signal game_finished_lost

signal update_size_celdas

signal game_start

signal intro_canvas_juego_tween
