# Generates TutorialTipsPage.tscn (page 3/5).
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "scenes" / "Tutorial" / "TutorialTipsPage.tscn"
uid = 1377334000


def nid() -> int:
    global uid
    uid += 1
    return uid


def tile(parent: str, name: str, number: str, letter: str, unique: bool, style: str = "Style_tile") -> str:
    u = f" unique_id={nid()}"
    uniq = "\nunique_name_in_owner = true" if unique else ""
    letter_line = f'\ntext = "{letter}"' if letter else ""
    return f"""
[node name="{name}" type="VBoxContainer" parent="{parent}"{u}]{uniq}
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 4

[node name="Panel" type="Panel" parent="{parent}/{name}" unique_id={nid()}]
custom_minimum_size = Vector2(0, 160)
layout_mode = 2
size_flags_horizontal = 3
theme_override_styles/panel = SubResource("{style}")

[node name="HBoxContainer" type="VBoxContainer" parent="{parent}/{name}/Panel" unique_id={nid()}]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
alignment = 1

[node name="Number" type="Label" parent="{parent}/{name}/Panel/HBoxContainer" unique_id={nid()}]
layout_mode = 2
theme_override_colors/font_color = Color(0.28, 0.16, 0.09, 1)
theme_override_fonts/font = ExtResource("3_heavy")
theme_override_font_sizes/font_size = 30
text = "{number}"
horizontal_alignment = 1

[node name="Letter" type="Label" parent="{parent}/{name}/Panel/HBoxContainer" unique_id={nid()}]
layout_mode = 2
theme_override_colors/font_color = Color(0.28, 0.16, 0.09, 1)
theme_override_fonts/font = ExtResource("3_heavy")
theme_override_font_sizes/font_size = 60{letter_line}
horizontal_alignment = 1
vertical_alignment = 1
"""


def gap(parent: str, name: str, size: str = "Vector2(5, 5)") -> str:
    return f"""
[node name="{name}" type="Control" parent="{parent}"]
custom_minimum_size = {size}
layout_mode = 2
"""


def chip(parent: str, name: str, number: str, unique: bool) -> str:
    uniq = "\nunique_name_in_owner = true" if unique else ""
    return f"""
[node name="{name}" type="Panel" parent="{parent}" unique_id={nid()}]{uniq}
custom_minimum_size = Vector2(130, 100)
layout_mode = 2
theme_override_styles/panel = SubResource("Style_{name.lower()}")

[node name="Label" type="Label" parent="{parent}/{name}" unique_id={nid()}]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(1, 1, 1, 0.95)
theme_override_fonts/font = ExtResource("3_heavy")
theme_override_font_sizes/font_size = 36
text = "{number}"
horizontal_alignment = 1
vertical_alignment = 1
"""


def key(parent: str, letter: str, used: bool, unique: bool) -> str:
    uniq = "\nunique_name_in_owner = true" if unique else ""
    style = "Style_key_used" if used else "Style_key_normal"
    font_color = "Color(0.99, 0.94, 0.86, 1)" if used else "Color(0.28, 0.16, 0.09, 1)"
    return f"""
[node name="Key{letter}" type="Panel" parent="{parent}" unique_id={nid()}]{uniq}
custom_minimum_size = Vector2(0, 58)
layout_mode = 2
size_flags_horizontal = 3
theme_override_styles/panel = SubResource("{style}")

[node name="Letter" type="Label" parent="{parent}/Key{letter}" unique_id={nid()}]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = {font_color}
theme_override_fonts/font = ExtResource("3_heavy")
theme_override_font_sizes/font_size = 36
text = "{letter}"
horizontal_alignment = 1
vertical_alignment = 1
"""


USED = {"C", "F", "T"}
UNIQUE_KEYS = {"A", "I", "C", "F", "R", "T"}
ROW1 = list("ABCDEFGHI")
ROW2 = ["J", "K", "L", "M", "N", "Ñ", "O", "P", "Q"]
ROW3 = list("RSTUVWXYZ")

parts: list[str] = []
parts.append("""[gd_scene format=3 uid="uid://btuttipspage3"]

[ext_resource type="Script" uid="uid://ctuttipspagegd" path="res://scenes/Tutorial/tutorial_tips_page.gd" id="1_script"]
[ext_resource type="FontFile" uid="uid://bk7opybx7ghxv" path="res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf" id="2_title"]
[ext_resource type="FontFile" uid="uid://e2b2srd7kyon" path="res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf" id="3_body"]
[ext_resource type="FontFile" uid="uid://bebntxq4vx1kq" path="res://fonts/Fonts/Montserrat/static/Montserrat-SemiBold.ttf" id="3_heavy"]
[ext_resource type="Texture2D" uid="uid://bhandpointerpng1" path="res://images/tutorial/hand_pointer.png" id="4_hand"]
[ext_resource type="Texture2D" uid="uid://6u7c6kanthrg" path="res://images/ui_icon_eraser.svg" id="5_eraser"]
[ext_resource type="Texture2D" path="res://images/tutorial/tut_ballena.jpg" id="7_whale"]

[sub_resource type="StyleBoxFlat" id="Style_tile"]
bg_color = Color(1, 1, 1, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.55, 0.42, 0.28, 0.78)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[sub_resource type="StyleBoxFlat" id="Style_tile_selected"]
bg_color = Color(1, 0.92, 0.38, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.86, 0.62, 0.08, 1)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[sub_resource type="StyleBoxFlat" id="Style_green"]
bg_color = Color(0.62, 0.86, 0.62, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.28, 0.58, 0.28, 0.85)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[sub_resource type="StyleBoxFlat" id="Style_key_normal"]
bg_color = Color(0.996, 0.973, 0.91, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.55, 0.42, 0.28, 0.78)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[sub_resource type="StyleBoxFlat" id="Style_key_used"]
bg_color = Color(0.7, 0.48, 0.26, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.42, 0.26, 0.12, 0.9)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[sub_resource type="StyleBoxFlat" id="Style_key_pressed"]
bg_color = Color(0.95, 0.55, 0.18, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.72, 0.36, 0.08, 1)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[sub_resource type="StyleBoxFlat" id="Style_card"]
content_margin_left = 22.0
content_margin_top = 18.0
content_margin_right = 22.0
content_margin_bottom = 18.0
bg_color = Color(1, 0.984, 0.94, 1)
border_width_left = 3
border_width_top = 3
border_width_right = 3
border_width_bottom = 3
border_color = Color(0.78, 0.61, 0.36, 0.45)
corner_radius_top_left = 28
corner_radius_top_right = 28
corner_radius_bottom_right = 28
corner_radius_bottom_left = 28
shadow_color = Color(0.25, 0.14, 0.06, 0.14)
shadow_size = 8
shadow_offset = Vector2(0, 5)

[sub_resource type="StyleBoxFlat" id="Style_badge"]
bg_color = Color(0.93, 0.48, 0.12, 1)
corner_radius_top_left = 32
corner_radius_top_right = 32
corner_radius_bottom_right = 32
corner_radius_bottom_left = 32

[sub_resource type="StyleBoxFlat" id="Style_chip1"]
bg_color = Color(0.95, 0.28, 0.28, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.55, 0.12, 0.12, 0.7)
corner_radius_top_left = 14
corner_radius_top_right = 14
corner_radius_bottom_right = 14
corner_radius_bottom_left = 14

[sub_resource type="StyleBoxFlat" id="Style_chip2"]
bg_color = Color(0.22, 0.48, 0.95, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.1, 0.22, 0.55, 0.7)
corner_radius_top_left = 14
corner_radius_top_right = 14
corner_radius_bottom_right = 14
corner_radius_bottom_left = 14

[sub_resource type="StyleBoxFlat" id="Style_chip3"]
bg_color = Color(0.18, 0.78, 0.28, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.08, 0.42, 0.12, 0.7)
corner_radius_top_left = 14
corner_radius_top_right = 14
corner_radius_bottom_right = 14
corner_radius_bottom_left = 14

[sub_resource type="StyleBoxFlat" id="Style_chip4"]
bg_color = Color(0.98, 0.52, 0.12, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.62, 0.28, 0.05, 0.7)
corner_radius_top_left = 14
corner_radius_top_right = 14
corner_radius_bottom_right = 14
corner_radius_bottom_left = 14

[sub_resource type="StyleBoxFlat" id="Style_chip5"]
bg_color = Color(0.9, 0.22, 0.55, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.52, 0.08, 0.28, 0.7)
corner_radius_top_left = 14
corner_radius_top_right = 14
corner_radius_bottom_right = 14
corner_radius_bottom_left = 14

[sub_resource type="StyleBoxEmpty" id="Style_pause_empty"]

[sub_resource type="StyleBoxFlat" id="Style_bar_bg"]
bg_color = Color(0.82, 0.72, 0.52, 0.42)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12

[sub_resource type="StyleBoxFlat" id="Style_bar_fill"]
bg_color = Color(0.93, 0.48, 0.12, 1)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[node name="TutorialTipsPage" type="VBoxContainer" unique_id=1377333400]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 18
script = ExtResource("1_script")
style_tile_normal = SubResource("Style_tile")
style_tile_selected = SubResource("Style_tile_selected")
style_color1 = SubResource("Style_chip1")
style_color2 = SubResource("Style_chip2")
style_key_normal = SubResource("Style_key_normal")
style_key_used = SubResource("Style_key_used")
style_key_pressed = SubResource("Style_key_pressed")

[node name="PageTitle" type="Label" parent="." unique_id=1377333401]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.28, 0.16, 0.09, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 52
text = "CÓMO JUGAR"
horizontal_alignment = 1

[node name="Card1" type="PanelContainer" parent="." unique_id=1377333402]
layout_mode = 2
size_flags_vertical = 3
size_flags_stretch_ratio = 1.25
theme_override_styles/panel = SubResource("Style_card")

[node name="Box" type="VBoxContainer" parent="Card1" unique_id=1377333403]
layout_mode = 2
theme_override_constants/separation = 10

[node name="Header" type="HBoxContainer" parent="Card1/Box" unique_id=1377333404]
layout_mode = 2
theme_override_constants/separation = 14

[node name="Badge" type="Label" parent="Card1/Box/Header" unique_id=1377333405]
custom_minimum_size = Vector2(64, 64)
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 30
theme_override_styles/normal = SubResource("Style_badge")
text = "5."
horizontal_alignment = 1
vertical_alignment = 1

[node name="Title1" type="Label" parent="Card1/Box/Header" unique_id=1377333406]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0.28, 0.16, 0.09, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 34
text = "BUSCA PATRONES"
autowrap_mode = 3

[node name="SpacerH" type="Control" parent="Card1/Box" unique_id=1377333407]
custom_minimum_size = Vector2(12, 8)
layout_mode = 2

[node name="Body1" type="Label" parent="Card1/Box" unique_id=1377333408]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.38, 0.26, 0.18, 0.94)
theme_override_fonts/font = ExtResource("3_body")
theme_override_font_sizes/font_size = 32
text = "Utiliza los botones de colores para identificar más claramente posibles posiciones de letras o vocales."
horizontal_alignment = 1
autowrap_mode = 3

[node name="Demo" type="Control" parent="Card1/Box" unique_id=1377333409]
unique_name_in_owner = true
clip_contents = true
layout_mode = 2
size_flags_vertical = 3

[node name="Col" type="VBoxContainer" parent="Card1/Box/Demo" unique_id=1377333410]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 12

[node name="Phrase" type="HBoxContainer" parent="Card1/Box/Demo/Col" unique_id=1377333411]
layout_mode = 2
theme_override_constants/separation = 6
alignment = 1
""")

phrase_parent = "Card1/Box/Demo/Col/Phrase"
parts.append(gap(phrase_parent, "GapStart", "Vector2(20, 10)"))
phrase = [
    ("C", "3", "C", True),
    ("I", "9", "", True),
    ("F", "6", "F", True),
    ("R1", "18", "", True),
    ("A1", "1", "", True),
    ("L", "12", "", True),
    ("E", "5", "", True),
    ("T", "20", "T", True),
    ("R2", "18", "", True),
    ("A2", "1", "", True),
]
for i, (name, number, letter, unique) in enumerate(phrase):
    if i:
        parts.append(gap(phrase_parent, f"Gap{i}"))
    parts.append(tile(phrase_parent, name, number, letter, unique))
parts.append(gap(phrase_parent, "GapEnd", "Vector2(20, 20)"))

parts.append("""
[node name="Colors" type="HBoxContainer" parent="Card1/Box/Demo/Col" unique_id=1377333500]
layout_mode = 2
theme_override_constants/separation = 10
alignment = 1
""")
colors_parent = "Card1/Box/Demo/Col/Colors"
for i in range(1, 6):
    parts.append(chip(colors_parent, f"Chip{i}", str(i), i in (1, 2)))
parts.append(f"""
[node name="Eraser" type="TextureRect" parent="{colors_parent}" unique_id={nid()}]
custom_minimum_size = Vector2(100, 100)
layout_mode = 2
texture = ExtResource("5_eraser")
expand_mode = 1
stretch_mode = 5

[node name="Keyboard" type="VBoxContainer" parent="Card1/Box/Demo/Col" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 8
""")

for row_name, letters in (("Row1", ROW1), ("Row2", ROW2), ("Row3", ROW3)):
    parent = "Card1/Box/Demo/Col/Keyboard"
    parts.append(f"""
[node name="{row_name}" type="HBoxContainer" parent="{parent}" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 6
alignment = 1
""")
    row_parent = f"{parent}/{row_name}"
    for letter in letters:
        parts.append(key(row_parent, letter, letter in USED, letter in UNIQUE_KEYS))

parts.append(f"""
[node name="Hand" type="TextureRect" parent="Card1/Box/Demo" unique_id={nid()}]
unique_name_in_owner = true
z_index = 20
custom_minimum_size = Vector2(258, 330)
layout_mode = 0
offset_right = 258.0
offset_bottom = 330.0
mouse_filter = 2
texture = ExtResource("4_hand")
expand_mode = 1
stretch_mode = 5

[node name="AnimRow5" type="HBoxContainer" parent="Card1/Box" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 8

[node name="AnimBar5" type="ProgressBar" parent="Card1/Box/AnimRow5" unique_id={nid()}]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 16)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 4
mouse_filter = 2
max_value = 1.0
step = 0.001
show_percentage = false
theme_override_styles/background = SubResource("Style_bar_bg")
theme_override_styles/fill = SubResource("Style_bar_fill")

[node name="Pause5" type="Button" parent="Card1/Box/AnimRow5" unique_id={nid()}]
unique_name_in_owner = true
custom_minimum_size = Vector2(90, 90)
layout_mode = 2
size_flags_vertical = 4
focus_mode = 0
mouse_default_cursor_shape = 2
theme_override_colors/font_color = Color(0.4, 0.26, 0.14, 0.5)
theme_override_colors/font_hover_color = Color(0.4, 0.26, 0.14, 0.82)
theme_override_colors/font_pressed_color = Color(0.4, 0.26, 0.14, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 48
theme_override_styles/normal = SubResource("Style_pause_empty")
theme_override_styles/pressed = SubResource("Style_pause_empty")
theme_override_styles/hover = SubResource("Style_pause_empty")
theme_override_styles/focus = SubResource("Style_pause_empty")
text = "⏸"

[node name="Card2" type="PanelContainer" parent="." unique_id={nid()}]
layout_mode = 2
size_flags_vertical = 3
theme_override_styles/panel = SubResource("Style_card")

[node name="Box" type="VBoxContainer" parent="Card2" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 10

[node name="Header" type="HBoxContainer" parent="Card2/Box" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 14

[node name="Badge" type="Label" parent="Card2/Box/Header" unique_id={nid()}]
custom_minimum_size = Vector2(64, 64)
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 30
theme_override_styles/normal = SubResource("Style_badge")
text = "6."
horizontal_alignment = 1
vertical_alignment = 1

[node name="Title2" type="Label" parent="Card2/Box/Header" unique_id={nid()}]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0.28, 0.16, 0.09, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 34
text = "OBSERVA LA IMAGEN"
autowrap_mode = 3

[node name="Body2" type="Label" parent="Card2/Box" unique_id={nid()}]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.38, 0.26, 0.18, 0.94)
theme_override_fonts/font = ExtResource("3_body")
theme_override_font_sizes/font_size = 32
text = "La imagen te da pistas sobre el tema del puzle y puede ayudarte a pensar en alguna palabra."
horizontal_alignment = 1
autowrap_mode = 3

[node name="Picture" type="TextureRect" parent="Card2/Box" unique_id={nid()}]
custom_minimum_size = Vector2(400, 400)
layout_mode = 2
size_flags_horizontal = 4
size_flags_vertical = 3
texture = ExtResource("7_whale")
expand_mode = 1
stretch_mode = 5

[node name="Phrase" type="HBoxContainer" parent="Card2/Box" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 6
alignment = 1
""")

whale_parent = "Card2/Box/Phrase"
parts.append(gap(whale_parent, "GapStart", "Vector2(20, 10)"))
whale_tiles = [
    ("B", "4", "", "Style_tile"),
    ("WA1", "1", "A", "Style_green"),
    ("WL1", "8", "", "Style_tile"),
    ("WL2", "8", "", "Style_tile"),
    ("WE", "5", "E", "Style_green"),
    ("WN", "2", "N", "Style_green"),
    ("WA2", "1", "A", "Style_green"),
]
for i, (name, number, letter, style) in enumerate(whale_tiles):
    if i:
        parts.append(gap(whale_parent, f"Gap{i}"))
    parts.append(tile(whale_parent, name, number, letter, False, style))
parts.append(gap(whale_parent, "GapEnd", "Vector2(20, 20)"))

OUT.write_text("".join(parts).lstrip() + "\n", encoding="utf-8")
print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")
