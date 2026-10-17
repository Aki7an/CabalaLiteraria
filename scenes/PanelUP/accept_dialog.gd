extends AcceptDialog

@onready var dialog: AcceptDialog = $"."
@onready var name_edit: LineEdit   = $"../LineEdit"


func pedir_nombre_record(puntos: int) -> void:
	dialog.title = "¡Nuevo récord! " + str(puntos)
	name_edit.text = ""
	name_edit.placeholder_text = "Tu nombre (3–12)"
	dialog.get_ok_button().disabled = true
	dialog.popup_centered()
	await get_tree().process_frame
	name_edit.grab_focus()  # muestra teclado en móvil

func _on_NameEdit_text_changed(t: String) -> void:
	# valida y habilita OK
	dialog.get_ok_button().disabled = t.strip_edges().length() < 3

func _on_RecordDialog_confirmed() -> void:
	var nombre := name_edit.text.strip_edges().substr(0, 10)
	GameManager.set_player_name(nombre)
	PlayerPrefs.save_prefs()
	# guarda/continúa flujo…
