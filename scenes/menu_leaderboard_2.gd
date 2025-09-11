extends Control

# Estructura de datos de ejemplo
var records := [
 {"pos":1, "nombre":"Laura", "puntos":1500, "fecha":"05/04/2024"},
 {"pos":2, "nombre":"David", "puntos":1370, "fecha":"17/02/2024"},
 {"pos":3, "nombre":"Ana", "puntos":1250, "fecha":"26/02/2024"},
 {"pos":4, "nombre":"Javier", "puntos":1190, "fecha":"21/03/2024"},
 {"pos":5, "nombre":"María", "puntos":1120, "fecha":"03/01/2024"},
 {"pos":6, "nombre":"Sofía", "puntos":1080, "fecha":"12/03/2024"},
 {"pos":7, "nombre":"Pedro", "puntos":1030, "fecha":"28/03/2024"},
 {"pos":8, "nombre":"Elena", "puntos":1010, "fecha":"16/04/2024"},
 {"pos":9, "nombre":"Rubén", "puntos":950, "fecha":"07/03/2024"},
 {"pos":10, "nombre":"Manuel", "puntos":890, "fecha":"30/01/2024"},
]

@onready var lista := $MarginContainer/VBoxContainer

func _ready():
 _poblar_tabla()

func _poblar_tabla():
 # Limpia la lista
 for child in lista.get_children():
  child.queue_free()
 
 # Genera cada fila
 for r in records:
  var fila := HBoxContainer.new()
  fila.add_theme_constant_override("separation", 20)
  
  # Número posición
  var pos_lbl := Label.new()
  pos_lbl.text = str(r.pos)
  pos_lbl.custom_minimum_size = Vector2(40, 0)
  pos_lbl.add_theme_color_override("font_color", Color.WHITE)
  
  # Nombre
  var nombre_lbl := Label.new()
  nombre_lbl.text = r.nombre
  nombre_lbl.custom_minimum_size = Vector2(120, 0)
  
  # Puntos
  var puntos_lbl := Label.new()
  puntos_lbl.text = str(r.puntos)
  puntos_lbl.custom_minimum_size = Vector2(80, 0)
  puntos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  
  # Fecha
  var fecha_lbl := Label.new()
  fecha_lbl.text = r.fecha
  fecha_lbl.custom_minimum_size = Vector2(100, 0)
  fecha_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  
  # Añadir a fila
  fila.add_child(pos_lbl)
  fila.add_child(nombre_lbl)
  fila.add_child(puntos_lbl)
  fila.add_child(fecha_lbl)
  
  # Fondo alterno (tipo lista)
  var color_rect := ColorRect.new()
  color_rect.color = Color(1, 0.85, 0.5, 0.3) if int(r.get("pos", 0)) % 2 == 0 else Color(1, 0.7, 0.2, 0.3)

  color_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  color_rect.custom_minimum_size = Vector2(0, 40)
  color_rect.add_child(fila)
  
  lista.add_child(color_rect)
