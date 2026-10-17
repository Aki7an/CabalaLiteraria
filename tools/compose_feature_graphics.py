"""Crop illustrated store banners to 1024x500. Do not paste screenshots."""
from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(r"C:\Users\aki7a\Documents\Godot\CifraLetra")
ASSETS = Path(r"C:\Users\aki7a\.cursor\projects\c-Users-aki7a-Documents-Godot-CifraLetra\assets")
STORE = ROOT / "Capturas Store" / "v0.25"
W, H = 1024, 500

LOCALES = ("en", "de", "fr", "eu", "it", "pt")


def to_1024x500(im: Image.Image) -> Image.Image:
    im = im.convert("RGB")
    src_w, src_h = im.size
    scale = W / src_w
    nh = int(round(src_h * scale))
    resized = im.resize((W, nh), Image.Resampling.LANCZOS)
    if nh == H:
        return resized
    if nh > H:
        top = (nh - H) // 2
        return resized.crop((0, top, W, top + H))
    canvas = Image.new("RGB", (W, H), (244, 232, 208))
    canvas.paste(resized, (0, (H - nh) // 2))
    return canvas


def main() -> None:
    for loc in LOCALES:
        src = ASSETS / f"Graficodefunciones_{loc}_ui.png"
        if not src.exists():
            raise FileNotFoundError(src)
        out = to_1024x500(Image.open(src))
        dest = STORE / loc / "Graficodefunciones.png"
        dest.parent.mkdir(parents=True, exist_ok=True)
        out.save(dest, "PNG")
        print("saved", dest, out.size)

    es_src = STORE / "es" / "Graficodefunciones_ES.png"
    shutil.copy2(es_src, STORE / "es" / "Graficodefunciones.png")
    print("copied ES")


if __name__ == "__main__":
    main()
