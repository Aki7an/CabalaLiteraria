extends Object

const ES := {
	"TRAILER_QUESTION": "¿Puedes descifrarlo?",
	"TRAILER_CIPHER": "Cada cifra corresponde a una letra, pero…",
	"TRAILER_MIRA": "MIRA",
	"TRAILER_DESCIFRA": "DESCIFRA",
	"TRAILER_DEDUCE": "DEDUCE",
	"TRAILER_DESCUBRE": "DESCUBRE",
	"TRAILER_HYPOTHESIS": "HAZ HIPÓTESIS",
	"TRAILER_WORDS": "RECONOCE PALABRAS",
	"TRAILER_TRY": "PRUEBA  ·  MARCA  ·  CORRIGE",
	"TRAILER_QUOTE": "El 20 de julio de 1969,\nApolo 11 dejó su huella en la Luna.",
	"TRAILER_FEATURES": "+100 PUZLES   ·   2–5 MIN   ·   CLASIFICACIÓN ONLINE",
	"TRAILER_LANGS": "ES  ·  EN  ·  FR  ·  DE  ·  PT  ·  EU",
	"TRAILER_SIX_LANGS": "6 IDIOMAS",
	"TRAILER_AVAILABLE": "YA DISPONIBLE",
	"TRAILER_STORES": "App Store   ·   Google Play",
	"TRAILER_TAGLINE": "MIRA  ·  DESCIFRA  ·  DESCUBRE",
}


static func text(key: String) -> String:
	var translated := TranslationServer.translate(key)
	if translated != key:
		return translated
	return str(ES.get(key, key))
