extends Control

func _ready() -> void:
	if GameManager.locale_code() != "en":
		return
	var cipher := get_node_or_null("Cifra") as Label
	var letter := get_node_or_null("Letra") as Label
	if cipher:
		cipher.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		cipher.text = "Cipher"
	if letter:
		letter.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		letter.text = "Words"
