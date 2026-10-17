from pathlib import Path

LINES = [
    "EL 20 DE JULIO",
    "DE 1969,",
    "APOLO 11",
    "DEJO SU HUELLA",
    "EN LA LUNA",
]
CIPHER = {
    "A": 4,
    "D": 11,
    "E": 7,
    "H": 16,
    "I": 2,
    "J": 19,
    "L": 18,
    "N": 9,
    "O": 12,
    "P": 21,
    "S": 23,
    "U": 3,
}
CELL_W, CELL_H, GAP = 86.0, 108.0, 5.0
COLS = max(len(line) for line in LINES)
ROWS = len(LINES)
W = COLS * CELL_W + (COLS - 1) * GAP
H = ROWS * CELL_H + (ROWS - 1) * GAP

out = Path(__file__).resolve().parents[1] / "scenes" / "trailer" / "parts" / "trailer_board.tscn"
lines = [
    "[gd_scene load_steps=3 format=3]",
    "",
    '[ext_resource type="PackedScene" path="res://scenes/trailer/parts/trailer_cell.tscn" id="1_cell"]',
    '[ext_resource type="Script" path="res://scenes/trailer/parts/trailer_board.gd" id="2_script"]',
    "",
    '[node name="Board" type="Control"]',
    "custom_minimum_size = Vector2(%.1f, %.1f)" % (W, H),
    "offset_right = %.1f" % W,
    "offset_bottom = %.1f" % H,
    "mouse_filter = 2",
    "script = ExtResource(\"2_script\")",
    "",
]
idx = 0
for r, line in enumerate(LINES):
    for c, ch in enumerate(line):
        name = "R%dC%d" % (r, c)
        x = c * (CELL_W + GAP)
        y = r * (CELL_H + GAP)
        is_space = ch == " "
        is_fixed = ch.isdigit() or ch in ",.;:"
        lines.append('[node name="%s" parent="." instance=ExtResource("1_cell")]' % name)
        lines.append("offset_left = %.1f" % x)
        lines.append("offset_top = %.1f" % y)
        lines.append("offset_right = %.1f" % (x + CELL_W))
        lines.append("offset_bottom = %.1f" % (y + CELL_H))
        if is_space:
            lines.append('cipher_letter = " "')
            lines.append("is_space = true")
        elif is_fixed:
            lines.append('cipher_letter = "%s"' % ch)
            lines.append("cipher_number = 0")
            lines.append('start_letter = "%s"' % ch)
            lines.append("is_fixed = true")
        else:
            lines.append('cipher_letter = "%s"' % ch)
            lines.append("cipher_number = %d" % CIPHER[ch])
        lines.append("")
        idx += 1

out.write_text("\n".join(lines), encoding="utf-8")
print("wrote", out, "cells", idx, "size", W, H, "pivot", W / 2, H / 2)
