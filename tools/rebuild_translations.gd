extends SceneTree

const CSV_PATH := "res://data/Traducciones.csv"
const OUT_DIR := "res://data"


func _init() -> void:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s" % CSV_PATH)
		quit(1)
		return
	var header: PackedStringArray = file.get_csv_line()
	if header.size() < 2 or header[0] != "Key":
		push_error("Unexpected CSV header")
		quit(1)
		return
	var translations: Dictionary = {}
	for i in range(1, header.size()):
		var locale := str(header[i]).strip_edges()
		if locale.is_empty():
			continue
		var trn := Translation.new()
		trn.locale = locale
		translations[i] = trn
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 2:
			continue
		var key := str(row[0]).strip_edges()
		if key.is_empty() or key == "Key":
			continue
		for i in translations.keys():
			var idx := int(i)
			var text := str(row[idx]) if idx < row.size() else ""
			(translations[idx] as Translation).add_message(key, text)
	for i in translations.keys():
		var trn: Translation = translations[i]
		var out_path := "%s/Traducciones.%s.translation" % [OUT_DIR, trn.locale]
		var err := ResourceSaver.save(trn, out_path)
		if err != OK:
			push_error("Failed to save %s (%s)" % [out_path, err])
			quit(1)
			return
		print("Wrote ", out_path, " messages=", trn.get_message_count())
	quit(0)
