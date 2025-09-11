extends Label

@export var min_font_size := 150
@export var max_font_size := 220
@export var vertical_fit := false       # si true también comprueba altura
@export var available_x : int = 628     # ancho fijo contra el que comparar
@export var display_text := text

func _ready() -> void:
	_fit_text()
	resized.connect(_fit_text)
	
	SignalManager.fit_text.connect(_fit_text)

func _fit_text() -> void:
	if Engine.is_editor_hint() == false:
			display_text = TranslationServer.translate(text)
	
	#print("Display text : ", display_text)
	if text.is_empty():
		return

	var font: Font = get_theme_font("font")
	if font == null:
		push_warning("No hay fuente asignada al Label")
		return
	
	# ancho fijo en vez del size actual del Label
	var available := Vector2(available_x, size.y)

	#print("\n=== NUEVO AJUSTE DE TEXTO ===")
	#print("Texto: ", display_text)
	#print("Ancho disponible (available_x): ", available.x)
	#print("Alto disponible: ", available.y)

	var lo := min_font_size
	var hi := max_font_size
	var best := lo

	while lo <= hi:
		var mid := (lo + hi) / 2
		var ok := _fits_with_font_size(font, mid, available)

		#print("Iteración -> probado font_size: ", mid)

		if ok:
			best = mid
			#print("   ✅ Cabe. Nuevo best: ", best)
			lo = mid + 1   # probar más grande
		else:
			#print("   ❌ No cabe con este tamaño")
			hi = mid - 1   # probar más pequeño

	#print("Tamaño FINAL elegido: ", best, "\n")
	add_theme_font_size_override("font_size", best)

func _fits_with_font_size(font: Font, fs: int, available: Vector2) -> bool:
	if autowrap_mode == TextServer.AUTOWRAP_OFF:
		var line := TextLine.new()

		line.add_string(display_text, font, fs)
		var s := line.get_size()
		var outline := get_theme_constant("outline_size", "Label")
		s.x += float(outline) * 2.0
		s.y += float(outline) * 2.0

		#print("   Ancho calculado: ", s.x, " / Alto calculado: ", s.y)

		return s.x <= available.x and (not vertical_fit or s.y <= available.y)

	# Con autowrap
	var para := TextParagraph.new()
	para.width = available.x
	para.add_string(text, font, fs)
	var psize := para.get_size()
	var outline := get_theme_constant("outline_size", "Label")
	psize.x += float(outline) * 2.0
	psize.y += float(outline) * 2.0

	#print("   Ancho calculado (wrap): ", psize.x, " / Alto calculado: ", psize.y)

	return psize.x <= available.x and (not vertical_fit or psize.y <= available.y)
