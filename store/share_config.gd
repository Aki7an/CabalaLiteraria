extends RefCounted

## Store links used in the share text.
const STORE_URL_ANDROID := "https://play.google.com/store/apps/details?id=com.akidev.cifraletra"
const STORE_URL_IOS := "https://apps.apple.com/app/id6807821718"
const PUZZLE_URL := "cifraletra://p/%s"
## 32 symbols, 6 characters. puzzle_code() mixes the id before encoding so
## the link does not show the number and nearby puzzles do not look related.
const CODE_ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LEN := 6
const CODE_MASK := 0x3FFFFFFF
const CODE_MUL_A := 0x015D2C3B
const CODE_INV_A := 0x1AF0CCF3
const CODE_MUL_B := 0x0001E5A7
const CODE_INV_B := 0x2DF07217
const CODE_XOR_A := 0x16A4C35D
const CODE_XOR_B := 0x2C91B735
const CODE_ROT := 11
const TWITTER_PACKAGE_ANDROID := "com.twitter.android"
const INSTAGRAM_PACKAGE_ANDROID := "com.instagram.android"
const FACEBOOK_PACKAGE_ANDROID := "com.facebook.katana"
const TIKTOK_PACKAGE_ANDROID := "com.zhiliaoapp.musically"
const CARD_WIDTH := 1080
const CARD_HEIGHT := 1350
const PNG_NAME := "cifraletra_share.png"
const IOS_INBOX := "cifraletra_share_inbox.json"
const STUDIO := "Arima Play"
const FILE_PROVIDER_SUFFIX := ".fileprovider"


static func puzzle_url(puzzle_id: int) -> String:
	var code := puzzle_code(puzzle_id)
	if code.is_empty():
		return ""
	return PUZZLE_URL % code


## Builds the 6-character code for cifraletra://p/{code}.
## Accepts ids 0 .. 1_073_741_823 (30 bits). 5000 becomes XMXPCP.
##
## Every arithmetic step keeps only the lowest 30 bits (mask 0x3FFFFFFF):
## 1. XOR 0x16A4C35D.
## 2. Multiply by 0x015D2C3B.
## 3. Rotate those 30 bits left by 11.
## 4. Multiply by 0x0001E5A7.
## 5. XOR 0x2C91B735.
## 6. Split the result into six groups of 5 bits, most significant first.
##    Each group is an index in CODE_ALPHABET (no 0/O and no 1/I).
##
## For 5000 the mixed value is 0x2ABAB44D, and the groups 21,11,21,13,2,13
## read X, M, X, P, C, P.
## Decoding repeats the steps in reverse. CODE_INV_A and CODE_INV_B are the
## multipliers' inverses modulo 2^30, and the rotation goes 11 bits right.
static func puzzle_code(puzzle_id: int) -> String:
	if puzzle_id < 0 or puzzle_id > CODE_MASK:
		return ""
	var value := (puzzle_id ^ CODE_XOR_A) & CODE_MASK
	value = (value * CODE_MUL_A) & CODE_MASK
	value = _rotl30(value, CODE_ROT)
	value = (value * CODE_MUL_B) & CODE_MASK
	value = (value ^ CODE_XOR_B) & CODE_MASK
	var chars := ""
	for _i in CODE_LEN:
		chars = CODE_ALPHABET[(value & 31)] + chars
		value >>= 5
	return chars


static func puzzle_id_from_code(raw: String) -> int:
	var code := raw.strip_edges().to_upper()
	if code.length() != CODE_LEN:
		return -1
	var mixed := 0
	for index in CODE_LEN:
		var digit := CODE_ALPHABET.find(code[index])
		if digit < 0:
			return -1
		mixed = ((mixed << 5) | digit)
	mixed = (mixed ^ CODE_XOR_B) & CODE_MASK
	mixed = (mixed * CODE_INV_B) & CODE_MASK
	mixed = _rotr30(mixed, CODE_ROT)
	mixed = (mixed * CODE_INV_A) & CODE_MASK
	mixed = (mixed ^ CODE_XOR_A) & CODE_MASK
	return mixed


static func _rotl30(value: int, bits: int) -> int:
	var n := bits % 30
	return ((value << n) | (value >> (30 - n))) & CODE_MASK


static func _rotr30(value: int, bits: int) -> int:
	return _rotl30(value, 30 - (bits % 30))


static func store_url() -> String:
	if OS.get_name() == "iOS":
		return STORE_URL_IOS
	return STORE_URL_ANDROID


static func android_package(network: String) -> String:
	match network:
		"x":
			return TWITTER_PACKAGE_ANDROID
		"instagram":
			return INSTAGRAM_PACKAGE_ANDROID
		"facebook":
			return FACEBOOK_PACKAGE_ANDROID
		"tiktok":
			return TIKTOK_PACKAGE_ANDROID
		_:
			return ""
