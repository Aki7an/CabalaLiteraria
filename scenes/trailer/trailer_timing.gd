extends Object

## Reloj único del tráiler V3. Los bloques leen de aquí.

const TOTAL_SEC := 56.5

const SEC_01 := 3.0
const SEC_02 := 5.0
const SEC_03 := 6.0
const SEC_04 := 12.0
const SEC_05 := 10.0
const SEC_06 := 6.0
const SEC_07 := 4.0
const SEC_08 := 7.0
const SEC_09 := 3.5

const HOOK_IN := 0.45
const QUESTION_HOLD := 1.35
const QUESTION_OUT := 0.4

const PHONE_MOVE := 0.7
const CIPHER_CAPTION_IN := 0.22
const CIPHER_CAPTION_HOLD := 2.4
const CIPHER_CAPTION_OUT := 0.22

const MIRA_IN := 0.45
const MIRA_HOLD := 0.7
const MIRA_OUT := 0.55
const THEME_IN := 0.4
const FOOTPRINT_IN := 0.2
const LINK_SEC := 0.22
const HUELLA_STEP := 0.06
const HUELLA_FINISH := 0.22
const HAND_QUICK := 0.16
const CAM_SEC := 0.5

const BANNER_IN := 0.45
const BANNER_OUT := 0.35
const CAPTION_IN := 0.16
const REVEAL_GAP := 0.18
const ERROR_HOLD := 0.55
const QUOTE_HOLD := 1.7
const CARDS_HOLD := 3.15
const MOSAIC_HOLD := 3.2
const FEATURES_HOLD := 2.4
const LOGO_HOLD := 3.1
const MOVIE_TAIL := 0.35


static func block_sec(index: int) -> float:
	match index:
		1: return SEC_01
		2: return SEC_02
		3: return SEC_03
		4: return SEC_04
		5: return SEC_05
		6: return SEC_06
		7: return SEC_07
		8: return SEC_08
		9: return SEC_09
		_: return 1.0
