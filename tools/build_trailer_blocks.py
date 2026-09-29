from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "scenes" / "trailer" / "blocks"
FONT = "res://fonts/Fonts/Nunito/static/Nunito-ExtraBold.ttf"
BG = "res://scenes/trailer/parts/trailer_backdrop.tscn"
BOARD = "res://scenes/trailer/parts/trailer_board.tscn"
HUD = "res://scenes/trailer/parts/trailer_hud.tscn"
THEME = "res://scenes/trailer/parts/trailer_theme_card.tscn"
HAND = "res://scenes/trailer/parts/trailer_hand.tscn"
STAR = "res://scenes/trailer/parts/trailer_star.tscn"

HEADER = """[gd_scene load_steps={steps} format=3]

{ext}

[node name="{name}" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
clip_contents = true
mouse_filter = 2
script = ExtResource("{script_id}")
"""


def ext_lines(items):
    out = []
    for i, (kind, path, eid) in enumerate(items, 1):
        out.append('[ext_resource type="%s" path="%s" id="%s"]' % (kind, path, eid))
    return "\n".join(out)


def label(name, parent, text, x, y, w, h, size, extra=""):
    return f"""
[node name="{name}" parent="{parent}"]
unique_name_in_owner = true
layout_mode = 0
offset_left = {x}
offset_top = {y}
offset_right = {x + w}
offset_bottom = {y + h}
theme_override_colors/font_color = Color(0.48, 0.24, 0.1, 1)
theme_override_fonts/font = ExtResource("font")
theme_override_font_sizes/font_size = {size}
text = "{text}"
horizontal_alignment = 1
vertical_alignment = 1
{extra}"""


def write(name, text):
    path = ROOT / name
    path.write_text(text.replace("\n\n\n", "\n\n").strip() + "\n", encoding="utf-8")
    print("wrote", path.name)


# --- 01 ---
write("01_pregunta.tscn", HEADER.format(
    steps=5, name="Block01Pregunta", script_id="script",
    ext=ext_lines([
        ("Script", "res://scenes/trailer/blocks/01_pregunta.gd", "script"),
        ("PackedScene", BG, "bg"),
        ("PackedScene", BOARD, "board"),
        ("FontFile", FONT, "font"),
    ]),
) + """
[node name="Backdrop" parent="." instance=ExtResource("bg")]

[node name="BoardRig" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 416.0
offset_top = 171.0
offset_right = 1503.0
offset_bottom = 844.0
scale = Vector2(1.85, 1.85)
pivot_offset = Vector2(543.5, 336.5)
mouse_filter = 2

[node name="Board" parent="BoardRig" instance=ExtResource("board")]
unique_name_in_owner = true

[node name="BoardEnd" type="Node2D" parent="."]
unique_name_in_owner = true
position = Vector2(416, 268)
scale = Vector2(0.94, 0.94)

[node name="QuestionStart" type="Node2D" parent="."]
unique_name_in_owner = true
position = Vector2(-1400, 460)

[node name="QuestionCenter" type="Node2D" parent="."]
unique_name_in_owner = true
position = Vector2(0, 460)

[node name="QuestionExit" type="Node2D" parent="."]
unique_name_in_owner = true
position = Vector2(2100, 460)

[node name="Question" type="Label" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = -1400.0
offset_top = 460.0
offset_right = 520.0
offset_bottom = 600.0
theme_override_colors/font_color = Color(0.48, 0.24, 0.1, 1)
theme_override_colors/font_outline_color = Color(0.96, 0.9, 0.82, 0.9)
theme_override_constants/outline_size = 10
theme_override_fonts/font = ExtResource("font")
theme_override_font_sizes/font_size = 78
text = "¿PUEDES DESCIFRARLO?"
horizontal_alignment = 1
vertical_alignment = 1
""")

# --- 02 ---
write("02_espera.tscn", HEADER.format(
    steps=6, name="Block02Espera", script_id="script",
    ext=ext_lines([
        ("Script", "res://scenes/trailer/blocks/02_espera.gd", "script"),
        ("PackedScene", BG, "bg"),
        ("PackedScene", BOARD, "board"),
        ("PackedScene", HUD, "hud"),
        ("FontFile", FONT, "font"),
    ]),
) + """
[node name="Backdrop" parent="." instance=ExtResource("bg")]

[node name="BoardRig" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 416.0
offset_top = 268.0
offset_right = 1503.0
offset_bottom = 941.0
scale = Vector2(0.94, 0.94)
pivot_offset = Vector2(543.5, 336.5)
mouse_filter = 2

[node name="Board" parent="BoardRig" instance=ExtResource("board")]
unique_name_in_owner = true

[node name="Dim" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.08, 0.05, 0.03, 0)

[node name="HudHidden" type="Node2D" parent="."]
position = Vector2(0, -40)

[node name="HudShown" type="Node2D" parent="."]
unique_name_in_owner = true
position = Vector2(0, 0)

[node name="Hud" parent="." instance=ExtResource("hud")]
unique_name_in_owner = true
modulate = Color(1, 1, 1, 0)
offset_top = -40.0
offset_bottom = 140.0

[node name="TitleEspera" type="Label" parent="."]
unique_name_in_owner = true
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 0.0
offset_top = 820.0
offset_right = 1920.0
offset_bottom = 950.0
theme_override_colors/font_color = Color(0.48, 0.24, 0.1, 1)
theme_override_fonts/font = ExtResource("font")
theme_override_font_sizes/font_size = 92
text = "ESPERA…"
horizontal_alignment = 1
vertical_alignment = 1
""")

# --- 03 ---
write("03_mira.tscn", HEADER.format(
    steps=8, name="Block03Mira", script_id="script",
    ext=ext_lines([
        ("Script", "res://scenes/trailer/blocks/03_mira.gd", "script"),
        ("PackedScene", BG, "bg"),
        ("PackedScene", BOARD, "board"),
        ("PackedScene", HUD, "hud"),
        ("PackedScene", THEME, "theme"),
        ("PackedScene", HAND, "hand"),
        ("FontFile", FONT, "font"),
    ]),
) + """
[node name="Backdrop" parent="." instance=ExtResource("bg")]

[node name="Dim" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
color = Color(0.08, 0.05, 0.03, 0)

[node name="BoardRig" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 416.0
offset_top = 268.0
offset_right = 1503.0
offset_bottom = 941.0
scale = Vector2(0.94, 0.94)
pivot_offset = Vector2(543.5, 336.5)

[node name="Board" parent="BoardRig" instance=ExtResource("board")]
unique_name_in_owner = true

[node name="BoardSlid" type="Node2D" parent="."]
unique_name_in_owner = true
position = Vector2(1036, 268)

[node name="Hud" parent="." instance=ExtResource("hud")]
unique_name_in_owner = true

[node name="HudSlid" type="Node2D" parent="."]
unique_name_in_owner = true
position = Vector2(520, 0)

[node name="ThemeCard" parent="." instance=ExtResource("theme")]
unique_name_in_owner = true
modulate = Color(1, 1, 1, 0)
offset_left = -720.0
offset_top = 210.0
offset_right = -100.0
offset_bottom = 830.0

[node name="ThemeShown" type="Node2D" parent="."]
unique_name_in_owner = true
position = Vector2(80, 210)

[node name="TitleMira" type="Label" parent="."]
unique_name_in_owner = true
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 80.0
offset_top = 36.0
offset_right = 480.0
offset_bottom = 108.0
theme_override_colors/font_color = Color(0.48, 0.24, 0.1, 1)
theme_override_fonts/font = ExtResource("font")
theme_override_font_sizes/font_size = 68
text = "MIRA"
vertical_alignment = 1

[node name="Caption" type="Label" parent="."]
unique_name_in_owner = true
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 80.0
offset_top = 992.0
offset_right = 1840.0
offset_bottom = 1052.0
theme_override_colors/font_color = Color(0.48, 0.24, 0.1, 1)
theme_override_fonts/font = ExtResource("font")
theme_override_font_sizes/font_size = 36
text = "La imagen te da contexto y una primera pista."
horizontal_alignment = 1
vertical_alignment = 1

[node name="Hand" parent="." instance=ExtResource("hand")]
unique_name_in_owner = true
visible = false
""")

# --- 04 ---
write("04_descifra.tscn", HEADER.format(
    steps=7, name="Block04Descifra", script_id="script",
    ext=ext_lines([
        ("Script", "res://scenes/trailer/blocks/04_descifra.gd", "script"),
        ("PackedScene", BG, "bg"),
        ("PackedScene", BOARD, "board"),
        ("PackedScene", HUD, "hud"),
        ("PackedScene", HAND, "hand"),
        ("FontFile", FONT, "font"),
    ]),
) + """
[node name="Backdrop" parent="." instance=ExtResource("bg")]

[node name="BoardRig" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 416.0
offset_top = 268.0
offset_right = 1503.0
offset_bottom = 941.0
scale = Vector2(0.94, 0.94)
pivot_offset = Vector2(543.5, 336.5)

[node name="Board" parent="BoardRig" instance=ExtResource("board")]
unique_name_in_owner = true

[node name="Hud" parent="." instance=ExtResource("hud")]
unique_name_in_owner = true

[node name="TitleDescifra" type="Label" parent="."]
unique_name_in_owner = true
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 0.0
offset_top = 172.0
offset_right = 1920.0
offset_bottom = 244.0
theme_override_colors/font_color = Color(0.48, 0.24, 0.1, 1)
theme_override_fonts/font = ExtResource("font")
theme_override_font_sizes/font_size = 68
text = "DESCIFRA"
horizontal_alignment = 1

[node name="Caption" type="Label" parent="."]
unique_name_in_owner = true
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 80.0
offset_top = 992.0
offset_right = 1840.0
offset_bottom = 1052.0
theme_override_colors/font_color = Color(0.48, 0.24, 0.1, 1)
theme_override_fonts/font = ExtResource("font")
theme_override_font_sizes/font_size = 36
text = "HAZ HIPÓTESIS"
horizontal_alignment = 1

[node name="Hand" parent="." instance=ExtResource("hand")]
unique_name_in_owner = true
visible = false
""")

# --- 05 ---
write("05_deduce.tscn", HEADER.format(
    steps=7, name="Block05Deduce", script_id="script",
    ext=ext_lines([
        ("Script", "res://scenes/trailer/blocks/05_deduce.gd", "script"),
        ("PackedScene", BG, "bg"),
        ("PackedScene", BOARD, "board"),
        ("PackedScene", HUD, "hud"),
        ("PackedScene", HAND, "hand"),
        ("FontFile", FONT, "font"),
    ]),
) + """
[node name="Backdrop" parent="." instance=ExtResource("bg")]

[node name="BoardRig" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 416.0
offset_top = 268.0
offset_right = 1503.0
offset_bottom = 941.0
scale = Vector2(0.94, 0.94)
pivot_offset = Vector2(543.5, 336.5)

[node name="Board" parent="BoardRig" instance=ExtResource("board")]
unique_name_in_owner = true

[node name="Hud" parent="." instance=ExtResource("hud")]
unique_name_in_owner = true

[node name="Caption" type="Label" parent="."]
unique_name_in_owner = true
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 80.0
offset_top = 992.0
offset_right = 1840.0
offset_bottom = 1052.0
theme_override_colors/font_color = Color(0.48, 0.24, 0.1, 1)
theme_override_fonts/font = ExtResource("font")
theme_override_font_sizes/font_size = 36
text = "PRUEBA  →  EQUIVÓCATE  →  CORRIGE"
horizontal_alignment = 1

[node name="Cross" type="Label" parent="."]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_right = 90.0
offset_bottom = 80.0
theme_override_colors/font_color = Color(0.81, 0.08, 0.08, 1)
theme_override_fonts/font = ExtResource("font")
theme_override_font_sizes/font_size = 72
text = "X"
horizontal_alignment = 1

[node name="Hand" parent="." instance=ExtResource("hand")]
unique_name_in_owner = true
visible = false
""")

# --- 06 ---
stars = "\n".join(
    '[node name="Star%d" parent="Stars" instance=ExtResource("star")]\nvisible = false\noffset_left = 960.0\noffset_top = 560.0\noffset_right = 1016.0\noffset_bottom = 616.0\n' % i
    for i in range(18)
)
write("06_descubre.tscn", HEADER.format(
    steps=8, name="Block06Descubre", script_id="script",
    ext=ext_lines([
        ("Script", "res://scenes/trailer/blocks/06_descubre.gd", "script"),
        ("PackedScene", BG, "bg"),
        ("PackedScene", BOARD, "board"),
        ("PackedScene", HUD, "hud"),
        ("PackedScene", HAND, "hand"),
        ("PackedScene", STAR, "star"),
        ("FontFile", FONT, "font"),
    ]),
) + """
[node name="Backdrop" parent="." instance=ExtResource("bg")]

[node name="BoardRig" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 416.0
offset_top = 268.0
offset_right = 1503.0
offset_bottom = 941.0
scale = Vector2(0.94, 0.94)
pivot_offset = Vector2(543.5, 336.5)

[node name="Board" parent="BoardRig" instance=ExtResource("board")]
unique_name_in_owner = true

[node name="Hud" parent="." instance=ExtResource("hud")]
unique_name_in_owner = true

[node name="TitleDescubre" type="Label" parent="."]
unique_name_in_owner = true
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 0.0
offset_top = 172.0
offset_right = 1920.0
offset_bottom = 244.0
theme_override_colors/font_color = Color(0.48, 0.24, 0.1, 1)
theme_override_fonts/font = ExtResource("font")
theme_override_font_sizes/font_size = 68
text = "DESCUBRE"
horizontal_alignment = 1

[node name="Caption" type="Label" parent="."]
unique_name_in_owner = true
modulate = Color(1, 1, 1, 0)
layout_mode = 0
offset_left = 80.0
offset_top = 992.0
offset_right = 1840.0
offset_bottom = 1052.0
theme_override_colors/font_color = Color(0.48, 0.24, 0.1, 1)
theme_override_fonts/font = ExtResource("font")
theme_override_font_sizes/font_size = 36
text = "Volverán las oscuras golondrinas…"
horizontal_alignment = 1

[node name="Stars" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2

""" + stars + """
[node name="Hand" parent="." instance=ExtResource("hand")]
unique_name_in_owner = true
visible = false
""")

print("blocks 01-06 done")
