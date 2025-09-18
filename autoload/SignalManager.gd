extends Node

# Game Canvas
signal update_canvas_grid(progress: int)

signal deselect_all_cells_in_canvas

signal insert_letter_in_number (letter: String, number: int)

signal update_resting_characters

signal move_canvas(wide: int)

signal update_cambios

signal on_transition_finished

signal game_finished

signal game_finished_to_results

signal update_stars(diff:int)

signal fit_text

signal update_score

signal erase_letter

signal erase_letter_open_dialog

signal erase_selected_letter

signal player_name_for_records

signal update_rubber

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
