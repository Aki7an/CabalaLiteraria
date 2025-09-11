extends Node2D

@onready var label_longitud = $LabelLongitud
@onready var frase = $Frase
@onready var label_longitud_adivinar = $LabelLongitudAdivinar
@onready var letras_eliminar = $LetrasEliminar

func _on_button_pressed():
	if frase.text !="":
		label_longitud.text = str(contar_letras(frase.text))
		label_longitud_adivinar.text = str(letras_a_adivinar(frase.text, letras_eliminar.text))

func contar_letras(frase: String) -> int:
	var re := RegEx.new()
	# Elimina todo lo que NO sea letra (propiedad Unicode \p{L})
	re.compile(r"[^\p{L}]")
	var solo_letras: String = re.sub(frase, "", true) # true => reemplaza en todas las ocurrencias
	return solo_letras.length()

# Normaliza únicamente las vocales acentuadas a su versión simple
const _VOWEL_MAP := {
	"á":"a","à":"a","ä":"a","â":"a","ã":"a","å":"a",
	"Á":"A","À":"A","Ä":"A","Â":"A","Ã":"A","Å":"A",
	"é":"e","è":"e","ë":"e","ê":"e",
	"É":"E","È":"E","Ë":"E","Ê":"E",
	"í":"i","ì":"i","ï":"i","î":"i",
	"Í":"I","Ì":"I","Ï":"I","Î":"I",
	"ó":"o","ò":"o","ö":"o","ô":"o","õ":"o",
	"Ó":"O","Ò":"O","Ö":"O","Ô":"O","Õ":"O",
	"ú":"u","ù":"u","ü":"u","û":"u",
	"Ú":"U","Ù":"U","Ü":"U","Û":"U"
}

func _normalize_vowels(s: String) -> String:
	var out := PackedStringArray()
	for ch in s:
		out.append(_VOWEL_MAP.get(ch, ch))
	return "".join(out)

# Cuenta letras restantes de la frase tras eliminar las dadas (ignorando signos/espacios)
func letras_a_adivinar(frase_original: String, letras_eliminar: String) -> int:
	# 1) Deja solo letras (Unicode)
	var re := RegEx.new()
	re.compile("[^\\p{L}]")  # quita todo lo que NO sea letra
	var solo_letras := re.sub(frase_original, "", true)

	# 2) Normaliza vocales acentuadas y pasa a mayúsculas para comparar sin casos
	var frase_norm := _normalize_vowels(solo_letras).to_upper()
	var eliminar_norm := _normalize_vowels(letras_eliminar).to_upper()

	# 3) Conjunto de letras a eliminar
	var quitar := {}
	for ch in eliminar_norm:
		quitar[ch] = true

	# 4) Cuenta las letras que NO están en el conjunto a eliminar
	var count := 0
	for ch in frase_norm:
		if not quitar.has(ch):
			count += 1
	return count
