from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "scenes" / "Tutorial" / "TutorialModesHintsPage.tscn"
uid = 1577334000


def nid() -> int:
    global uid
    uid += 1
    return uid


def tile(parent: str, name: str, number: str, letter: str, height: int, num_size: int, let_size: int, letter_color: str) -> str:
    letter_line = f'\ntext = "{letter}"' if letter else ""
    return f"""
[node name="{name}" type="VBoxContainer" parent="{parent}" unique_id={nid()}]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 1

[node name="Panel" type="Panel" parent="{parent}/{name}" unique_id={nid()}]
custom_minimum_size = Vector2(0, {height})
layout_mode = 2
size_flags_horizontal = 3
theme_override_styles/panel = SubResource("Style_tile")

[node name="Col" type="VBoxContainer" parent="{parent}/{name}/Panel" unique_id={nid()}]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 0
alignment = 1

[node name="Number" type="Label" parent="{parent}/{name}/Panel/Col" unique_id={nid()}]
layout_mode = 2
theme_override_colors/font_color = Color(0.28, 0.16, 0.09, 1)
theme_override_fonts/font = ExtResource("3_heavy")
theme_override_font_sizes/font_size = {num_size}
text = "{number}"
horizontal_alignment = 1

[node name="Letter" type="Label" parent="{parent}/{name}/Panel/Col" unique_id={nid()}]
layout_mode = 2
theme_override_colors/font_color = {letter_color}
theme_override_fonts/font = ExtResource("3_heavy")
theme_override_font_sizes/font_size = {let_size}{letter_line}
horizontal_alignment = 1
vertical_alignment = 1
"""


def dots(parent: str, filled: int, total: int, style_on: str) -> str:
    parts = []
    for i in range(total):
        style = style_on if i < filled else "Style_dot_off"
        parts.append(f"""
[node name="Dot{i+1}" type="Panel" parent="{parent}" unique_id={nid()}]
custom_minimum_size = Vector2(16, 16)
layout_mode = 2
size_flags_vertical = 4
theme_override_styles/panel = SubResource("{style}")
""")
    return "".join(parts)


TEAL = "Color(0.12, 0.55, 0.5, 1)"
INK = "Color(0.28, 0.16, 0.09, 1)"
INVISIBLE = "Color(1, 1, 1, 0)"

parts: list[str] = []
parts.append(f'''[gd_scene format=3 uid="uid://cghrisutiflvx"]

[ext_resource type="Script" uid="uid://ctutmodeshintsgd" path="res://scenes/Tutorial/tutorial_modes_hints_page.gd" id="1_script"]
[ext_resource type="FontFile" uid="uid://bk7opybx7ghxv" path="res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf" id="2_title"]
[ext_resource type="FontFile" uid="uid://e2b2srd7kyon" path="res://fonts/Fonts/Montserrat/static/Montserrat-Medium.ttf" id="3_body"]
[ext_resource type="FontFile" uid="uid://bebntxq4vx1kq" path="res://fonts/Fonts/Montserrat/static/Montserrat-SemiBold.ttf" id="3_heavy"]
[ext_resource type="Texture2D" uid="uid://duj5gi84s5bqf" path="res://images/mode_quick.svg" id="4_bolt"]
[ext_resource type="Texture2D" uid="uid://c3sofhyrdkn54" path="res://images/CriptogramaIcono.png" id="5_brain"]
[ext_resource type="Script" path="res://scenes/Tutorial/tutorial_char_grid.gd" id="9_grid"]
[ext_resource type="Texture2D" uid="uid://cikisooltnvf8" path="res://images/tutorial/tut_bulb.svg" id="6_bulb"]
[ext_resource type="Texture2D" uid="uid://jw8c34iex18f" path="res://images/estrella_plano.png" id="7_star"]
[ext_resource type="Texture2D" uid="uid://bmxb0omorndri" path="res://images/contorno_estrella.png" id="8_star_off"]

[sub_resource type="StyleBoxFlat" id="Style_card"]
content_margin_left = 22.0
content_margin_top = 16.0
content_margin_right = 22.0
content_margin_bottom = 16.0
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

[sub_resource type="StyleBoxFlat" id="Style_rapido"]
content_margin_left = 16.0
content_margin_top = 12.0
content_margin_right = 16.0
content_margin_bottom = 12.0
bg_color = Color(0.9, 0.97, 0.95, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.55, 0.82, 0.78, 0.55)
corner_radius_top_left = 22
corner_radius_top_right = 22
corner_radius_bottom_right = 22
corner_radius_bottom_left = 22

[sub_resource type="StyleBoxFlat" id="Style_desafio"]
content_margin_left = 16.0
content_margin_top = 12.0
content_margin_right = 16.0
content_margin_bottom = 12.0
bg_color = Color(1, 0.97, 0.9, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.9, 0.78, 0.5, 0.5)
corner_radius_top_left = 22
corner_radius_top_right = 22
corner_radius_bottom_right = 22
corner_radius_bottom_left = 22

[sub_resource type="StyleBoxFlat" id="Style_tile"]
bg_color = Color(1, 1, 1, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.55, 0.42, 0.28, 0.78)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8

[sub_resource type="StyleBoxFlat" id="Style_num"]
bg_color = Color(0.93, 0.48, 0.12, 1)
corner_radius_top_left = 32
corner_radius_top_right = 32
corner_radius_bottom_right = 32
corner_radius_bottom_left = 32

[sub_resource type="StyleBoxFlat" id="Style_dot_teal"]
bg_color = Color(0.22, 0.78, 0.75, 1)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[sub_resource type="StyleBoxFlat" id="Style_dot_orange"]
bg_color = Color(0.93, 0.52, 0.18, 1)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[sub_resource type="StyleBoxFlat" id="Style_dot_off"]
bg_color = Color(1, 1, 1, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.75, 0.68, 0.58, 0.7)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[node name="TutorialModesHintsPage" type="VBoxContainer" unique_id=1577333401]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 14
script = ExtResource("1_script")

[node name="PageTitle" type="Label" parent="." unique_id=1577333402]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.28, 0.16, 0.09, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 60
text = "CÓMO JUGAR"
horizontal_alignment = 1

[node name="Card1" type="PanelContainer" parent="." unique_id=1577333403]
layout_mode = 2
size_flags_vertical = 3
theme_override_styles/panel = SubResource("Style_card")

[node name="Box" type="VBoxContainer" parent="Card1" unique_id=1577333404]
layout_mode = 2
theme_override_constants/separation = 12

[node name="Header" type="HBoxContainer" parent="Card1/Box" unique_id=1577333405]
layout_mode = 2
theme_override_constants/separation = 14

[node name="Badge" type="Label" parent="Card1/Box/Header" unique_id=1577333406]
custom_minimum_size = Vector2(64, 64)
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 38
theme_override_styles/normal = SubResource("Style_badge")
text = "7."
horizontal_alignment = 1
vertical_alignment = 1

[node name="Title1" type="Label" parent="Card1/Box/Header" unique_id=1577333407]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0.28, 0.16, 0.09, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 44
text = "DOS TIPOS DE PARTIDA"
autowrap_mode = 3

[node name="Modes" type="VBoxContainer" parent="Card1/Box" unique_id=1577333410]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/separation = 12
''')

# --- Rápido row ---
parts.append(f'''
[node name="Rapido" type="PanelContainer" parent="Card1/Box/Modes" unique_id=1577333411]
layout_mode = 2
size_flags_vertical = 3
theme_override_styles/panel = SubResource("Style_rapido")

[node name="Row" type="HBoxContainer" parent="Card1/Box/Modes/Rapido" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 16

[node name="Info" type="VBoxContainer" parent="Card1/Box/Modes/Rapido/Row" unique_id={nid()}]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 4
alignment = 1

[node name="Head" type="HBoxContainer" parent="Card1/Box/Modes/Rapido/Row/Info" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 10

[node name="Icon" type="TextureRect" parent="Card1/Box/Modes/Rapido/Row/Info/Head" unique_id={nid()}]
custom_minimum_size = Vector2(56, 64)
layout_mode = 2
mouse_filter = 2
texture = ExtResource("4_bolt")
expand_mode = 1
stretch_mode = 5

[node name="ModeQuickTitle" type="Label" parent="Card1/Box/Modes/Rapido/Row/Info/Head" unique_id=1577333415]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0.04, 0.45, 0.5, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 40
text = "RÁPIDO"
vertical_alignment = 1

[node name="BodyRapido" type="RichTextLabel" parent="Card1/Box/Modes/Rapido/Row/Info" unique_id=1577333408]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/default_color = Color(0.38, 0.26, 0.18, 0.94)
theme_override_fonts/normal_font = ExtResource("3_body")
theme_override_fonts/bold_font = ExtResource("3_heavy")
theme_override_font_sizes/normal_font_size = 36
theme_override_font_sizes/bold_font_size = 36
bbcode_enabled = true
fit_content = true
scroll_active = false
text = "Frases cortas · Con letras de pista"

[node name="TimeRow" type="HBoxContainer" parent="Card1/Box/Modes/Rapido/Row/Info" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 8

[node name="Clock" type="Label" parent="Card1/Box/Modes/Rapido/Row/Info/TimeRow" unique_id={nid()}]
layout_mode = 2
theme_override_colors/font_color = Color(0.04, 0.58, 0.61, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 38
text = "◷"
vertical_alignment = 1

[node name="TimeQuick" type="Label" parent="Card1/Box/Modes/Rapido/Row/Info/TimeRow" unique_id=1577333652]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.04, 0.5, 0.52, 1)
theme_override_fonts/font = ExtResource("3_heavy")
theme_override_font_sizes/font_size = 34
text = "MÁS BREVE"
vertical_alignment = 1

[node name="Side" type="VBoxContainer" parent="Card1/Box/Modes/Rapido/Row" unique_id=1577333416]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 1.2
theme_override_constants/separation = 6
alignment = 1

[node name="Grid" type="Control" parent="Card1/Box/Modes/Rapido/Row/Side" unique_id={nid()}]
custom_minimum_size = Vector2(280, 200)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
mouse_filter = 2
script = ExtResource("9_grid")
cell_count = 150
columns = 25
layout_count = 300

[node name="CharsQuick" type="Label" parent="Card1/Box/Modes/Rapido/Row/Side" unique_id={nid()}]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.38, 0.26, 0.18, 0.86)
theme_override_fonts/font = ExtResource("3_body")
theme_override_font_sizes/font_size = 32
text = "(sobre 150 caracteres por puzle)"
horizontal_alignment = 1
autowrap_mode = 3
''')
parts.append(dots("Card1/Box/Modes/Rapido/Row/Info/TimeRow", 2, 3, "Style_dot_teal"))

# --- Desafío row ---
parts.append(f'''
[node name="Desafio" type="PanelContainer" parent="Card1/Box/Modes" unique_id=1577333600]
layout_mode = 2
size_flags_vertical = 3
theme_override_styles/panel = SubResource("Style_desafio")

[node name="Row" type="HBoxContainer" parent="Card1/Box/Modes/Desafio" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 16

[node name="Info" type="VBoxContainer" parent="Card1/Box/Modes/Desafio/Row" unique_id={nid()}]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 4
alignment = 1

[node name="Head" type="HBoxContainer" parent="Card1/Box/Modes/Desafio/Row/Info" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 10

[node name="Icon" type="TextureRect" parent="Card1/Box/Modes/Desafio/Row/Info/Head" unique_id={nid()}]
custom_minimum_size = Vector2(56, 64)
layout_mode = 2
mouse_filter = 2
texture = ExtResource("5_brain")
expand_mode = 1
stretch_mode = 5

[node name="ModeDesafioTitle" type="Label" parent="Card1/Box/Modes/Desafio/Row/Info/Head" unique_id=1577333604]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0.42, 0.24, 0.1, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 40
text = "DESAFÍO"
vertical_alignment = 1

[node name="BodyDesafio" type="RichTextLabel" parent="Card1/Box/Modes/Desafio/Row/Info" unique_id=1577333409]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/default_color = Color(0.38, 0.26, 0.18, 0.94)
theme_override_fonts/normal_font = ExtResource("3_body")
theme_override_fonts/bold_font = ExtResource("3_heavy")
theme_override_font_sizes/normal_font_size = 36
theme_override_font_sizes/bold_font_size = 36
bbcode_enabled = true
fit_content = true
scroll_active = false
text = "Frases más largas · Sin letras de pista"

[node name="TimeRow" type="HBoxContainer" parent="Card1/Box/Modes/Desafio/Row/Info" unique_id={nid()}]
layout_mode = 2
theme_override_constants/separation = 8

[node name="Clock" type="Label" parent="Card1/Box/Modes/Desafio/Row/Info/TimeRow" unique_id={nid()}]
layout_mode = 2
theme_override_colors/font_color = Color(0.66, 0.34, 0.08, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 38
text = "◷"
vertical_alignment = 1

[node name="TimeDesafio" type="Label" parent="Card1/Box/Modes/Desafio/Row/Info/TimeRow" unique_id=1577333655]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.66, 0.34, 0.08, 1)
theme_override_fonts/font = ExtResource("3_heavy")
theme_override_font_sizes/font_size = 34
text = "MÁS COMPLEJO"
vertical_alignment = 1

[node name="Side" type="VBoxContainer" parent="Card1/Box/Modes/Desafio/Row" unique_id=1577333605]
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 1.2
theme_override_constants/separation = 6
alignment = 1

[node name="Grid" type="Control" parent="Card1/Box/Modes/Desafio/Row/Side" unique_id={nid()}]
custom_minimum_size = Vector2(280, 200)
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
mouse_filter = 2
script = ExtResource("9_grid")
cell_count = 300
columns = 25
layout_count = 300

[node name="CharsDesafio" type="Label" parent="Card1/Box/Modes/Desafio/Row/Side" unique_id={nid()}]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.38, 0.26, 0.18, 0.86)
theme_override_fonts/font = ExtResource("3_body")
theme_override_font_sizes/font_size = 32
text = "(sobre 300 caracteres por puzle)"
horizontal_alignment = 1
autowrap_mode = 3
''')
parts.append(dots("Card1/Box/Modes/Desafio/Row/Info/TimeRow", 3, 3, "Style_dot_orange"))

# --- Card 8 ---
parts.append(f'''
[node name="Card2" type="PanelContainer" parent="." unique_id=1577333700]
layout_mode = 2
size_flags_vertical = 3
size_flags_stretch_ratio = 1.15
theme_override_styles/panel = SubResource("Style_card")

[node name="Box" type="VBoxContainer" parent="Card2" unique_id=1577333701]
layout_mode = 2
theme_override_constants/separation = 10

[node name="Header" type="HBoxContainer" parent="Card2/Box" unique_id=1577333702]
layout_mode = 2
theme_override_constants/separation = 14

[node name="Badge" type="Label" parent="Card2/Box/Header" unique_id=1577333703]
custom_minimum_size = Vector2(64, 64)
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 38
theme_override_styles/normal = SubResource("Style_badge")
text = "8."
horizontal_alignment = 1
vertical_alignment = 1

[node name="Title2" type="Label" parent="Card2/Box/Header" unique_id=1577333704]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0.28, 0.16, 0.09, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 44
text = "UTILIZA LAS PISTAS"
autowrap_mode = 3

[node name="Body2" type="Label" parent="Card2/Box" unique_id=1577333705]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.38, 0.26, 0.18, 0.94)
theme_override_fonts/font = ExtResource("3_body")
theme_override_font_sizes/font_size = 34
text = "Hay tres pistas disponibles. Cada pista utilizada cuesta una estrella."
autowrap_mode = 3

[node name="Hints" type="VBoxContainer" parent="Card2/Box" unique_id=1577333706]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/separation = 10
''')

hints = [
    ("1", "HintBody1", "Revela una palabra del puzle.",
     [("3", "A", TEAL), ("1", "L", TEAL), ("7", "M", TEAL), ("3", "A", TEAL), ("1", "R", TEAL)]),
    ("2", "HintBody2", "Revela la letra más repetida de las que quedan.",
     [("5", "E", TEAL), ("22", "", INK), ("5", "E", TEAL), ("17", "", INK), ("5", "E", TEAL)]),
    ("3", "HintBody3", "Revela los números de las vocales, sin indicar su orden.",
     [("3", "", INK), ("7", "", INK), ("12", "", INK), ("18", "", INK), ("25", "", INK)]),
]
hint_ids = [1577333712, 1577333805, 1577333905]
for idx, (num, body_name, body_text, tiles) in enumerate(hints):
    row = f"Card2/Box/Hints/Hint{idx+1}"
    parts.append(f'''
[node name="Hint{idx+1}" type="HBoxContainer" parent="Card2/Box/Hints" unique_id={nid()}]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/separation = 10

[node name="Bulb" type="TextureRect" parent="{row}" unique_id={nid()}]
custom_minimum_size = Vector2(48, 56)
layout_mode = 2
size_flags_vertical = 4
mouse_filter = 2
texture = ExtResource("6_bulb")
expand_mode = 1
stretch_mode = 5

[node name="Num" type="Label" parent="{row}" unique_id={nid()}]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
size_flags_vertical = 4
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_fonts/font = ExtResource("2_title")
theme_override_font_sizes/font_size = 28
theme_override_styles/normal = SubResource("Style_num")
text = "{num}."
horizontal_alignment = 1
vertical_alignment = 1

[node name="{body_name}" type="Label" parent="{row}" unique_id={hint_ids[idx]}]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 4
theme_override_colors/font_color = Color(0.38, 0.26, 0.18, 0.94)
theme_override_fonts/font = ExtResource("3_body")
theme_override_font_sizes/font_size = 32
text = "{body_text}"
autowrap_mode = 3
vertical_alignment = 1

[node name="Phrase" type="HBoxContainer" parent="{row}" unique_id={nid()}]
custom_minimum_size = Vector2(280, 0)
layout_mode = 2
size_flags_horizontal = 3
size_flags_stretch_ratio = 0.95
size_flags_vertical = 4
theme_override_constants/separation = 3
alignment = 2
''')
    for i, (n, let, col) in enumerate(tiles):
        parts.append(tile(f"{row}/Phrase", f"T{i}", n, let, 76, 16, 28, col))

parts.append(f'''
[node name="Stars" type="HBoxContainer" parent="Card2/Box" unique_id=1577333990]
layout_mode = 2
theme_override_constants/separation = 8
alignment = 1
''')
for i in range(1, 6):
    tex = 'ExtResource("7_star")' if i < 5 else 'ExtResource("8_star_off")'
    mod = "Color(1, 0.86, 0.2, 1)" if i < 5 else "Color(1, 1, 1, 1)"
    parts.append(f'''
[node name="Star{i}" type="TextureRect" parent="Card2/Box/Stars" unique_id={nid()}]
modulate = {mod}
custom_minimum_size = Vector2(52, 52)
layout_mode = 2
texture = {tex}
expand_mode = 1
stretch_mode = 5
''')

parts.append(f'''
[node name="HintCost" type="Label" parent="Card2/Box" unique_id=1577333996]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.42, 0.26, 0.12, 1)
theme_override_fonts/font = ExtResource("3_heavy")
theme_override_font_sizes/font_size = 30
text = "UNA PISTA = –1 ESTRELLA"
horizontal_alignment = 1
''')

OUT.write_text("".join(parts).lstrip() + "\n", encoding="utf-8")
print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")
