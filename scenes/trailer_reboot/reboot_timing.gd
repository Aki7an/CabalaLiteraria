extends Object

const TOTAL_SEC := 55.0
const FPS := 30
const MOVIE_TAIL := 0.4

const SEC_RETO := 4.0
const SEC_MIRA := 5.0
const SEC_DESCIFRA := 9.0
const SEC_DEDUCE := 9.0
const SEC_DESCUBRE := 7.0
const SEC_VARIEDAD := 9.0
const SEC_MOSAIC := 6.0
const SEC_CTA := 6.0

const HOOK_ZOOM := 0.55
const TITLE_IN := 0.22
const TITLE_OUT := 0.16
const LETTER := 0.28
const WORD_ZOOM := 0.45
const IMAGE_IN := 0.28
const FOOT_ZOOM := 1.6
const FLASH := 0.7
const MOSAIC_FILL := 1.1
const CTA_IN := 0.45
const CTA_HOLD := 3.6
const QUOTE_HOLD := 1.8
const MOON_REWARD := 1.3


static func movie_frames() -> int:
	return int(round((TOTAL_SEC + MOVIE_TAIL) * float(FPS)))
