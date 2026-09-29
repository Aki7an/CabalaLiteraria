extends Object

const ES := {
	"TRAILER_QUESTION": "¿Puedes descifrarlo?",
	"TRAILER_MIRA": "MIRA",
	"TRAILER_DESCIFRA": "DESCIFRA",
	"TRAILER_DEDUCE": "DEDUCE",
	"TRAILER_DESCUBRE": "DESCUBRE",
	"TRAILER_TRY": "PRUEBA",
	"TRAILER_MARK": "MARCA",
	"TRAILER_FIX": "CORRIGE",
	"TRAILER_QUOTE": "El 20 de julio de 1969,\nApolo 11 dejó su huella en la Luna.",
	"TRAILER_PEOPLE": "PERSONAJES",
	"TRAILER_CURIO": "CURIOSIDADES",
	"TRAILER_DATES": "EFEMÉRIDES",
	"TRAILER_BOOKS": "LITERATURA",
	"TRAILER_PUZZLES": "+100 PUZLES",
	"TRAILER_SIX_LANGS": "6 IDIOMAS",
	"TRAILER_LANGS": "ES  ·  EN  ·  FR  ·  DE  ·  PT  ·  EU",
	"TRAILER_MINUTES": "2–5 MINUTOS",
	"TRAILER_RANK": "CLASIFICACIÓN ONLINE",
	"TRAILER_TAGLINE": "MIRA  ·  DESCIFRA  ·  DESCUBRE",
	"TRAILER_AVAILABLE": "YA DISPONIBLE",
	"TRAILER_STORES": "App Store   ·   Google Play",
}


static func text(key: String) -> String:
	var translated := TranslationServer.translate(key)
	if translated != key:
		return translated
	return str(ES.get(key, key))
