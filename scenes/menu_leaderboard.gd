extends Control

@onready var leaderboard: Tree = $Leaderboard

func _ready() -> void:
	_config_tree()
	_cargar_ranking("Adivinanza")  # categoría deseada

func _config_tree() -> void:
	leaderboard.set_column_titles_visible(true)
	leaderboard.set_column_title(0, "Pos")
	leaderboard.set_column_title(1, "Jugador")
	leaderboard.set_column_title(2, "Fecha")
	leaderboard.set_column_title(3, "Puntuación")

	# Expansión y anchos mínimos (usar set_column_custom_minimum_width)
	leaderboard.set_column_expand(0, false) # Pos
	leaderboard.set_column_custom_minimum_width(0, 48)

	leaderboard.set_column_expand(1, true)  # Jugador
	leaderboard.set_column_expand_ratio(1, 4)  # opcional: darle más espacio

	leaderboard.set_column_expand(2, false) # Fecha
	leaderboard.set_column_custom_minimum_width(2, 120)

	leaderboard.set_column_expand(3, false) # Puntuación
	leaderboard.set_column_custom_minimum_width(3, 120)

func _cargar_ranking(categoria: String, dificultad: int = -1) -> void:
	var resultados: Array = HistoryManager.get_results_filtered(categoria, dificultad)

	# Limpia el árbol antes de volver a crear items
	leaderboard.clear()
	var root: TreeItem = leaderboard.create_item()

	var max_items: int = min(10, resultados.size())
	for i in range(max_items):
		var e: Dictionary = resultados[i]
		var item: TreeItem = leaderboard.create_item(root)

		# Posición
		item.set_text(0, str(i + 1))

		# Jugador
		item.set_text(1, str(e.get("jugador_nombre", "-")))

		# Fecha
		var fecha: Dictionary = e.get("fecha", {})
		var fecha_txt := ""
		if fecha.has("iso"):
			fecha_txt = str(fecha["iso"])          # "YYYY-MM-DD"
		else:
			var d := int(fecha.get("dia", 0))
			var m := int(fecha.get("mes", 0))
			var y := int(fecha.get("anio", 0))
			fecha_txt = "%02d/%02d/%04d" % [d, m, y]
		item.set_text(2, fecha_txt)

		# Puntuación con separador de miles
		var score := int(e.get("score", 0))
		item.set_text(3, _formatear_numero(score))

		# Alineaciones
		item.set_text_alignment(0, HORIZONTAL_ALIGNMENT_CENTER)
		item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)
		item.set_text_alignment(3, HORIZONTAL_ALIGNMENT_RIGHT)

func _formatear_numero(n: int) -> String:
	var s := str(n)
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "." + out
	return out
