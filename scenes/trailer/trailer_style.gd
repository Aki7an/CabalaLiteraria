extends Object

const FONT_TITLE := preload("res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf")
const FONT_BODY := preload("res://fonts/Fonts/Montserrat/static/Montserrat-SemiBold.ttf")
const FONT_BODY_MED := preload("res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf")

const INK := Color(0.10, 0.22, 0.28, 1)
const INK_SOFT := Color(0.32, 0.18, 0.10, 1)
const ACCENT := Color(0.92, 0.48, 0.08, 1)
const CREAM := Color(0.96, 0.90, 0.82, 1)
const SHADOW := Color(0.08, 0.05, 0.03, 0.28)
const NOTE := Color(0.92, 0.48, 0.08, 0.92)
const MARK := Color(1.0, 0.8, 0.6, 1)

const SIZE_BEAT := 88
const SIZE_QUESTION := 74
const SIZE_CTA := 50
const SIZE_QUOTE := 38
const SIZE_BODY := 36
const SIZE_FEATURE := 34
const SIZE_SMALL := 28


static func apply_title(label: Label, size: int = SIZE_BEAT) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", FONT_TITLE)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", INK)
	label.add_theme_color_override("font_shadow_color", SHADOW)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.add_theme_constant_override("shadow_outline_size", 6)


static func apply_body(label: Label, size: int = SIZE_BODY, color: Color = INK_SOFT) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", FONT_BODY)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	label.add_theme_constant_override("outline_size", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)


static func apply_accent(label: Label, size: int = SIZE_CTA) -> void:
	apply_body(label, size, ACCENT)
