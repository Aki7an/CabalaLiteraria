"""CifraLetra trailer v2 — Full HD. Resuelve la Guerra de los mundos letra a letra."""
from __future__ import annotations

import math
import shutil
import subprocess
from collections import Counter
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = Path(r"C:\Users\aki7a\Documents\Godot\CifraLetra")
IMG = ROOT / "data" / "images"
CAPS = ROOT / "Capturas Store" / "v0.25" / "es"
OUT = ROOT / "Capturas Store" / "v0.25" / "trailer"
GEN = Path(r"C:\Users\aki7a\.cursor\projects\c-Users-aki7a-Documents-Godot-CifraLetra\assets")
W, H = 1920, 1080
FPS = 30
CREAM = (244, 232, 208)
INK = (72, 48, 32)
TEAL = (32, 140, 148)
ORANGE = (232, 122, 32)
WHITE = (255, 255, 255)
GOLD = (232, 186, 72)
DARK = (18, 10, 6)

FONT_DIR = Path(r"C:\Windows\Fonts")

# Primera frase de La guerra de los mundos, partida en 3 filas equilibradas.
PHRASE = "UNOS INVASORES PROCEDENTES DE MARTE PARECEN IMPARABLES ANTE LAS ARMAS HUMANAS"
ROWS_WORDS = [
    ["UNOS", "INVASORES", "PROCEDENTES", "DE"],
    ["MARTE", "PARECEN", "IMPARABLES"],
    ["ANTE", "LAS", "ARMAS", "HUMANAS"],
]
WORDS = [w for row in ROWS_WORDS for w in row]


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_DIR / name), size)


def F_title(size=92):
    return font("georgia.ttf", size)


def F_bold(size=72):
    return font("georgiab.ttf", size)


def F_italic(size=48):
    return font("georgiai.ttf", size)


def F_ui(size=36):
    return font("calibri.ttf", size)


def ease_out_cubic(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return 1.0 - (1.0 - t) ** 3


def ease_in_cubic(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t ** 3


def ease_out_quart(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return 1.0 - (1.0 - t) ** 4


_IMG_CACHE: dict[str, Image.Image] = {}


def load(path: Path) -> Image.Image:
    key = str(path)
    if key not in _IMG_CACHE:
        _IMG_CACHE[key] = Image.open(path).convert("RGBA")
    return _IMG_CACHE[key]


def canvas(color=CREAM) -> Image.Image:
    return Image.new("RGBA", (W, H), color + (255,))


def cover(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    return ImageOps.fit(img.convert("RGBA"), size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.45))


def contain_h(img: Image.Image, height: int) -> Image.Image:
    img = img.convert("RGBA")
    w = int(img.width * (height / img.height))
    return img.resize((w, height), Image.Resampling.LANCZOS)


def paste_c(dst: Image.Image, src: Image.Image, xy) -> None:
    x, y = int(xy[0]), int(xy[1])
    dst.alpha_composite(src, (x, y))


def shadow_text(draw, xy, text, font, fill, shadow=(0, 0, 0, 180), offset=3):
    x, y = xy
    draw.text((x + offset, y + offset), text, font=font, fill=shadow)
    draw.text((x, y), text, font=font, fill=fill)


def centered_text(draw, y, text, font, fill=WHITE, shadow=True):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    x = (W - tw) // 2
    if shadow:
        shadow_text(draw, (x, y), text, font, fill)
    else:
        draw.text((x, y), text, font=font, fill=fill)


def apply_alpha(layer: Image.Image, a: float) -> Image.Image:
    a = max(0.0, min(1.0, a))
    if a >= 0.999:
        return layer
    out = layer.copy()
    out.putalpha(out.getchannel("A").point(lambda p: int(p * a)))
    return out


def vignette(img: Image.Image, strength=0.40) -> Image.Image:
    arr = np.array(img.convert("RGBA")).astype(np.float32)
    yy, xx = np.mgrid[0:H, 0:W]
    r = np.sqrt(((xx - W / 2) / (W * 0.64)) ** 2 + ((yy - H / 2) / (H * 0.64)) ** 2)
    r = np.clip(r, 0, 1)
    arr[..., :3] *= (1.0 - strength * (r ** 2))[..., None]
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


def ken_burns(img: Image.Image, t: float, zoom_from=1.0, zoom_to=1.05, pan=(0.0, -0.03)) -> Image.Image:
    """Gentle pan/zoom. Source is already 16:9 HD art — do not over-zoom."""
    t = max(0.0, min(1.0, t))
    max_z = max(zoom_from, zoom_to)
    base = cover(img.convert("RGBA"), (int(W * max_z), int(H * max_z)))
    z = zoom_from + (zoom_to - zoom_from) * t
    cw, ch = max(2, int(W / z)), max(2, int(H / z))
    cw, ch = min(cw, base.width), min(ch, base.height)
    max_x = max(0, base.width - cw)
    max_y = max(0, base.height - ch)
    x = int(max_x * (0.5 + pan[0] * t))
    y = int(max_y * (0.5 + pan[1] * t))
    crop = base.crop((x, y, x + cw, y + ch)).resize((W, H), Image.Resampling.LANCZOS)
    return vignette(crop, 0.32)


def bottom_gradient(strength=0.78) -> Image.Image:
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    arr = np.array(overlay)
    yy = np.linspace(0, 1, H, dtype=np.float32)
    a = np.clip((yy - 0.34) / 0.52, 0, 1) ** 1.15 * (255 * strength)
    arr[..., 0] = DARK[0]
    arr[..., 1] = DARK[1]
    arr[..., 2] = DARK[2]
    arr[..., 3] = a.astype(np.uint8)[:, None]
    return Image.fromarray(arr, "RGBA")


def phone_on_cream(shot: Image.Image, height=1000) -> Image.Image:
    frame = canvas()
    ph = contain_h(shot, height)
    x = (W - ph.width) // 2
    y = (H - ph.height) // 2
    sh = Image.new("RGBA", (ph.width + 48, ph.height + 48), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    sd.rounded_rectangle((14, 18, ph.width + 22, ph.height + 26), 32, fill=(0, 0, 0, 80))
    sh = sh.filter(ImageFilter.GaussianBlur(14))
    paste_c(frame, sh, (x - 18, y - 10))
    paste_c(frame, ph, (x, y))
    return frame


def fade(a: Image.Image, b: Image.Image, t: float) -> Image.Image:
    return Image.blend(a.convert("RGBA"), b.convert("RGBA"), max(0.0, min(1.0, t)))


def to_bgr(im: Image.Image) -> np.ndarray:
    rgb = np.array(im.convert("RGB"))
    return cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)


def cipher_map(text: str) -> dict[str, int]:
    mapping: dict[str, int] = {}
    n = 1
    for ch in text:
        if ch.isalpha() and ch not in mapping:
            mapping[ch] = n
            n += 1
    return mapping


def reveal_order(text: str) -> list[str]:
    counts = Counter(ch for ch in text if ch.isalpha())
    return [ch for ch, _ in counts.most_common()]


def wrap_rows(words: list[str], tile: int, gap: int, word_gap: int, max_w: int) -> list[list[str]]:
    rows: list[list[str]] = []
    cur: list[str] = []
    cur_w = 0

    def ww(w: str) -> int:
        return len(w) * (tile + gap) - gap

    for w in words:
        extra = 0 if not cur else word_gap
        width = ww(w)
        if cur and cur_w + extra + width > max_w:
            rows.append(cur)
            cur = [w]
            cur_w = width
        else:
            cur.append(w)
            cur_w += extra + width
    if cur:
        rows.append(cur)
    return rows


def draw_phrase_tiles(
    mapping: dict[str, int],
    rows: list[list[str]],
    solved: set[str],
    current: str | None,
    pop: float = 1.0,
    pulse: float = 0.0,
    tile: int = 52,
    gap: int = 6,
    word_gap: int = 22,
) -> Image.Image:
    row_h = tile + 8
    row_gap = 14
    widths = []
    for row in rows:
        n = sum(len(w) for w in row)
        widths.append(n * (tile + gap) - gap + (len(row) - 1) * word_gap)
    total_w = max(widths) + 20
    total_h = len(rows) * row_h + (len(rows) - 1) * row_gap + 10
    img = Image.new("RGBA", (total_w, total_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    nf = font("calibri.ttf", 22)
    nf_tiny = font("calibri.ttf", 13)
    lf = font("georgiab.ttf", 30)
    lf_pop = font("georgiab.ttf", max(22, int(30 * pop)))

    y = 4
    for ri, row in enumerate(rows):
        row_w = widths[ri]
        x = (total_w - row_w) // 2
        for wi, w in enumerate(row):
            if wi:
                x += word_gap
            for ch in w:
                num = mapping[ch]
                is_cur = current is not None and ch == current
                is_sol = ch in solved and not is_cur
                glow = int(12 + 10 * pulse) if is_cur else 0
                box = (x - glow // 2, y + 6 - glow // 2, x + tile + glow // 2, y + 6 + tile + glow // 2)
                fill = (252, 246, 232, 240)
                outline = (196, 168, 120, 255)
                ow = 2
                if is_cur:
                    fill = (255, 232, 180, 255)
                    outline = ORANGE + (255,)
                    ow = 4
                elif is_sol:
                    fill = (248, 244, 230, 240)
                    outline = (40, 150, 150, 255)
                d.rounded_rectangle(box, 11, fill=fill, outline=outline, width=ow)
                if is_cur or is_sol:
                    fnt = lf_pop if is_cur else lf
                    col = ORANGE + (255,) if is_cur else TEAL + (255,)
                    lb = d.textbbox((0, 0), ch, font=fnt)
                    lw, lh = lb[2] - lb[0], lb[3] - lb[1]
                    d.text(
                        (x + (tile - lw) // 2, y + 6 + (tile - lh) // 2 - 4),
                        ch,
                        font=fnt,
                        fill=col,
                    )
                    if is_cur:
                        ns = str(num)
                        nb = d.textbbox((0, 0), ns, font=nf_tiny)
                        d.text((x + 5, y + 8), ns, font=nf_tiny, fill=(140, 90, 40, 255))
                else:
                    ns = str(num)
                    nb = d.textbbox((0, 0), ns, font=nf)
                    nw, nh = nb[2] - nb[0], nb[3] - nb[1]
                    d.text(
                        (x + (tile - nw) // 2, y + 6 + (tile - nh) // 2 - 2),
                        ns,
                        font=nf,
                        fill=(110, 80, 50, 255),
                    )
                x += tile + gap
        y += row_h + row_gap
    return img


def title_motion(local_t: float, enter=0.75, hold=3.2, exit_t=0.65) -> tuple[float, float, float]:
    """Returns scale, y_offset, alpha. Enters decelerating, holds, exits."""
    if local_t < enter:
        p = ease_out_quart(local_t / enter)
        return 1.38 - 0.38 * p, 90 * (1 - p), p
    if local_t < enter + hold:
        return 1.0, 0.0, 1.0
    p = ease_in_cubic((local_t - enter - hold) / max(0.05, exit_t))
    return 1.0 + 0.10 * p, -110 * p, 1.0 - p


def fit_title_font(text: str, max_w=1680, start=186) -> ImageFont.FreeTypeFont:
    for sz in range(start, 96, -4):
        f = F_bold(sz)
        if f.getlength(text) <= max_w:
            return f
    return F_bold(96)


def render_hero_title(text: str, scale: float, alpha: float, y_off: float, y_base: int | None = None) -> Image.Image:
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    if alpha <= 0.01:
        return layer
    d = ImageDraw.Draw(layer)
    f = fit_title_font(text)
    bbox = d.textbbox((0, 0), text, font=f)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    y = (H - th) // 2 + int(y_off) if y_base is None else y_base + int(y_off)
    x = (W - tw) // 2
    # gold underline
    d.rectangle((x, y + th + 18, x + tw, y + th + 24), fill=GOLD + (int(220 * alpha),))
    shadow_text(d, (x, y), text, f, WHITE, shadow=(0, 0, 0, 200), offset=5)
    if abs(scale - 1.0) > 0.01:
        nw, nh = max(2, int(W * scale)), max(2, int(H * scale))
        scaled = layer.resize((nw, nh), Image.Resampling.LANCZOS)
        out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        paste_c(out, scaled, ((W - nw) // 2, (H - nh) // 2))
        layer = out
    return apply_alpha(layer, alpha)


def rounded_icon(path: Path, size=220) -> Image.Image:
    icon = load(path).copy().resize((size, size), Image.Resampling.LANCZOS)
    mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), 48, fill=255)
    icon.putalpha(mask)
    return icon


SHOT = {
    "gir_theme": CAPS / "09_jirafa_antes.png",
    "gir_play": CAPS / "10_jirafa_juego.png",
    "cur_play": CAPS / "03_juego_rapido.png",
    "cur_deep": CAPS / "05_juego_vocales_reveladas.png",
    "victory": CAPS / "08_victoria.png",
    "library": CAPS / "06_coleccion.png",
    "menu": CAPS / "01_principal.png",
    "types": CAPS / "02_tipo_partida.png",
}
ICON = ROOT / "images" / "Icono.png"
BG_NAMES = {
    "wotw": "trailer_wotw.png",
    "giraffe": "trailer_giraffe.png",
    "ice": "trailer_ice.png",
    "cosmos": "trailer_cosmos.png",
    "cleopatra": "trailer_cleopatra.png",
    "nautilus": "trailer_nautilus.png",
}
FALLBACK = {
    "wotw": IMG / "image3099.png",
    "giraffe": IMG / "image1060.png",
    "ice": IMG / "image1023.png",
    "cosmos": IMG / "image4001.png",
    "cleopatra": IMG / "image3085.png",
    "nautilus": IMG / "image3102.png",
}


def ensure_backgrounds() -> dict[str, Path]:
    dest = OUT / "bg"
    dest.mkdir(parents=True, exist_ok=True)
    paths = {}
    for key, name in BG_NAMES.items():
        src = GEN / name
        dst = dest / name
        if src.exists():
            shutil.copy2(src, dst)
            paths[key] = dst
        elif dst.exists():
            paths[key] = dst
        else:
            paths[key] = FALLBACK[key]
            print(f"WARN missing {name}, fallback {paths[key]}")
    return paths


def still_deduce_scene(t: float, bg: Image.Image, phone: Image.Image) -> Image.Image:
    frame = ken_burns(bg, t, 1.0, 1.04, (0.0, 0.02))
    dim = Image.new("RGBA", (W, H), (12, 8, 6, 70))
    frame = Image.alpha_composite(frame, dim)
    ph = contain_h(phone, 980)
    # slide in from right after a beat
    slide = ease_out_cubic(min(1.0, max(0.0, (t * 5.2 - 0.55) / 0.7)))
    x = int(W - ph.width - 70 + (1 - slide) * 420)
    y = (H - ph.height) // 2 + 40
    if slide > 0:
        sh = Image.new("RGBA", (ph.width + 40, ph.height + 40), (0, 0, 0, 0))
        ImageDraw.Draw(sh).rounded_rectangle((10, 14, ph.width + 18, ph.height + 22), 28, fill=(0, 0, 0, 90))
        sh = sh.filter(ImageFilter.GaussianBlur(12))
        paste_c(frame, apply_alpha(sh, slide), (x - 12, y - 6))
        paste_c(frame, apply_alpha(ph, slide), (x, y))
    return frame


def still_descifra_scene(t: float, bg: Image.Image) -> Image.Image:
    frame = ken_burns(bg, t, 1.0, 1.04, (-0.02, 0.0))
    dim = Image.new("RGBA", (W, H), (16, 10, 6, 90))
    frame = Image.alpha_composite(frame, dim)
    card_a = ease_out_cubic(min(1.0, max(0.0, (t * 5.2 - 0.45) / 0.6)))
    card_w, card_h = 1280, 360
    card = Image.new("RGBA", (card_w, card_h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle((0, 0, card_w - 1, card_h - 1), 36, fill=(252, 246, 234, 235), outline=(210, 180, 130, 255), width=3)
    quote = "Las jirafas son los mamíferos\nque menos duermen…"
    cd.multiline_text((70, 48), quote, font=F_italic(50), fill=INK, spacing=12)
    cd.text((70, 200), "— Curiosidad —", font=F_ui(32), fill=TEAL)

    def star(cx, cy, r):
        pts = []
        for i in range(10):
            ang = math.radians(-90 + i * 36)
            rad = r if i % 2 == 0 else r * 0.42
            pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
        cd.polygon(pts, fill=GOLD)

    star(110, 290, 26)
    star(178, 290, 26)
    star(246, 290, 26)
    cd.text((320, 272), "Frase resuelta", font=F_ui(34), fill=(110, 90, 70, 255))
    paste_c(frame, apply_alpha(card, card_a), ((W - card_w) // 2, 560))
    return frame


def still_end(t: float, bg: Image.Image) -> Image.Image:
    frame = ken_burns(bg, min(1.0, t), 1.0, 1.05, (0.0, 0.02))
    dim = Image.new("RGBA", (W, H), (16, 10, 8, 150))
    frame = Image.alpha_composite(frame, dim)
    icon = rounded_icon(ICON, 220)
    paste_c(frame, icon, ((W - 220) // 2, 180))
    d = ImageDraw.Draw(frame)
    centered_text(d, 430, "CifraLetra", F_bold(96), fill=WHITE)
    centered_text(d, 560, "Observa  ·  Deduce  ·  Descifra", F_italic(44), fill=(255, 230, 190, 255))
    return frame


def overlay_caption(frame: Image.Image, text: str, a: float) -> Image.Image:
    if a <= 0.01:
        return frame
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rectangle((0, H - 170, W, H), fill=(12, 8, 6, 150))
    centered_text(d, 940, text, F_italic(42), fill=WHITE)
    return Image.alpha_composite(frame, apply_alpha(layer, a))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    qa = OUT / "qa"
    qa.mkdir(exist_ok=True)
    tmp = OUT / "trailer_raw.mp4"
    final = OUT / "CifraLetra_ObservaDeduceDescifra.mp4"
    BG = ensure_backgrounds()

    mapping = cipher_map(PHRASE)
    order = reveal_order(PHRASE)
    rows = ROWS_WORDS
    print("Reveal order:", "".join(order), "rows:", rows)

    print("Rendering stills…")
    menu = phone_on_cream(load(SHOT["menu"]))
    types = phone_on_cream(load(SHOT["types"]))
    library = phone_on_cream(load(SHOT["library"]))
    deep = phone_on_cream(load(SHOT["cur_deep"]))
    victory = phone_on_cream(load(SHOT["victory"]))
    gir_play = load(SHOT["gir_play"])

    # --- WotW timeline (one continuous shot) ---
    F_IMG = 90
    F_QIN = 20
    F_QHOLD = 100
    F_TIN = 28
    F_THOLD = 48
    F_LET = 30  # 1.0s per letter — time to see the highlight
    F_SOL = 90
    wotw_n = F_IMG + F_QIN + F_QHOLD + F_TIN + F_THOLD + F_LET * len(order) + F_SOL

    def wotw_frame(i: int, n: int) -> Image.Image:
        t_kb = i / max(1, n - 1)
        frame = ken_burns(load(BG["wotw"]), t_kb, 1.0, 1.045, (0.05, -0.025))
        g_str = 0.42
        if i >= F_IMG:
            g_str = 0.82
        frame = Image.alpha_composite(frame, bottom_gradient(g_str))

        q_a = 0.0
        if i >= F_IMG:
            q_a = ease_out_cubic(min(1.0, (i - F_IMG) / F_QIN))
        # fade question slightly after solve starts holding, keep readable
        sol_start = n - F_SOL
        if i >= sol_start + 24:
            q_a *= 1.0 - ease_in_cubic(min(1.0, (i - sol_start - 24) / 30))

        tiles_a = 0.0
        solved: set[str] = set()
        current = None
        pop = 1.0
        pulse = 0.0
        tile_start = F_IMG + F_QIN + F_QHOLD
        if i >= tile_start:
            tiles_a = ease_out_cubic(min(1.0, (i - tile_start) / F_TIN))
            after = i - (tile_start + F_TIN + F_THOLD)
            if after >= 0:
                li = min(len(order) - 1, after // F_LET)
                local = (after % F_LET) / F_LET
                if after >= F_LET * len(order):
                    solved = set(order)
                    current = None
                else:
                    solved = set(order[:li])
                    current = order[li]
                    pop = 0.25 + 0.75 * ease_out_cubic(min(1.0, local / 0.38))
                    pulse = 0.5 + 0.5 * math.sin(local * math.pi * 4)
                    if local > 0.12:
                        solved = set(order[: li + 1])

        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        if q_a > 0.01:
            q = "¿Qué frase se esconde en esta imagen?"
            f = F_italic(48)
            tmp_q = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            tq = ImageDraw.Draw(tmp_q)
            bbox = tq.textbbox((0, 0), q, font=f)
            tw = bbox[2] - bbox[0]
            qy = 400 if tiles_a > 0.05 else 470
            shadow_text(tq, ((W - tw) // 2, qy), q, f, WHITE)
            layer = Image.alpha_composite(layer, apply_alpha(tmp_q, q_a))
        if tiles_a > 0.01:
            tiles = draw_phrase_tiles(mapping, rows, solved, current, pop, pulse)
            tmp_t = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            paste_c(tmp_t, tiles, ((W - tiles.width) // 2, 500))
            layer = Image.alpha_composite(layer, apply_alpha(tmp_t, tiles_a))
        if i >= sol_start + 20:
            cred_a = ease_out_cubic(min(1.0, (i - sol_start - 20) / 24))
            tmp_c = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            tc = ImageDraw.Draw(tmp_c)
            cred = "H. G. Wells  ·  La guerra de los mundos"
            f = F_ui(34)
            bbox = tc.textbbox((0, 0), cred, font=f)
            tw = bbox[2] - bbox[0]
            shadow_text(tc, ((W - tw) // 2, 990), cred, f, GOLD + (255,))
            layer = Image.alpha_composite(layer, apply_alpha(tmp_c, cred_a))
        return Image.alpha_composite(frame, layer)

    TITLE_N = 156  # 5.2s
    ENTER, HOLD, EXIT_T = 0.75, 3.35, 0.70

    def giraffe_observa(i, n):
        t = i / max(1, n - 1)
        frame = ken_burns(load(BG["giraffe"]), t, 1.0, 1.04, (0.0, -0.02))
        sec = i / FPS
        sc, yo, a = title_motion(sec, ENTER, HOLD, EXIT_T)
        return Image.alpha_composite(frame, render_hero_title("OBSERVA", sc, a, yo))

    def giraffe_deduce(i, n):
        t = i / max(1, n - 1)
        frame = still_deduce_scene(t, load(BG["giraffe"]), gir_play)
        sec = i / FPS
        sc, yo, a = title_motion(sec, ENTER, HOLD, EXIT_T)
        title = render_hero_title("DEDUCE", sc, a, yo, y_base=56)
        return Image.alpha_composite(frame, title)

    def giraffe_descifra(i, n):
        t = i / max(1, n - 1)
        frame = still_descifra_scene(t, load(BG["giraffe"]))
        sec = i / FPS
        sc, yo, a = title_motion(sec, ENTER, HOLD, EXIT_T)
        title = render_hero_title("DESCIFRA", sc, a, yo, y_base=28)
        return Image.alpha_composite(frame, title)

    montage = [
        ("ice", "Groenlandia guarda un océano", (0.03, -0.02)),
        ("cosmos", "La luz del Sol tarda ocho minutos", (-0.02, 0.0)),
        ("cleopatra", "Conservar la dignidad de reina", (0.04, 0.0)),
        ("nautilus", "El capitán Nemo recorre los océanos", (0.0, 0.02)),
    ]

    def montage_fn(key, caption, pan):
        def fn(i, n):
            t = i / max(1, n - 1)
            frame = ken_burns(load(BG[key]), t, 1.0, 1.045, pan)
            # caption after 0.5s, hold until 0.4s before end
            sec = i / FPS
            dur = n / FPS
            if sec < 0.45:
                a = 0.0
            elif sec < 1.1:
                a = ease_out_cubic((sec - 0.45) / 0.65)
            elif sec > dur - 0.45:
                a = 1.0 - ease_in_cubic((sec - (dur - 0.45)) / 0.45)
            else:
                a = 1.0
            return overlay_caption(frame, caption, a)

        return fn

    beats: list[tuple[int, object]] = []
    beats.append((wotw_n, wotw_frame))
    beats.append((TITLE_N, giraffe_observa))
    beats.append((TITLE_N, giraffe_deduce))
    beats.append((TITLE_N, giraffe_descifra))
    for key, cap, pan in montage:
        beats.append((100, montage_fn(key, cap, pan)))  # 3.33s each
    beats.append((105, lambda i, n: deep))
    beats.append((90, lambda i, n: victory))
    beats.append((70, lambda i, n: menu))
    beats.append((70, lambda i, n: types))
    beats.append((70, lambda i, n: library))
    beats.append((120, lambda i, n: still_end(i / max(1, n - 1), load(BG["nautilus"]))))

    total = sum(n for n, _ in beats)
    print(f"Writing {total} frames ({total / FPS:.1f}s)…")

    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(str(tmp), fourcc, FPS, (W, H))
    if not writer.isOpened():
        raise RuntimeError("VideoWriter failed")

    prev = None
    written = 0
    qa_saved = set()
    for bi, (n, fn) in enumerate(beats):
        fade_n = 10 if bi > 0 else 0
        for i in range(n):
            im = fn(i, n)
            if prev is not None and i < fade_n:
                im = fade(prev, im, (i + 1) / fade_n)
            writer.write(to_bgr(im))
            written += 1
            # QA stills
            tag = None
            if bi == 0 and i == F_IMG + F_QIN + 40:
                tag = "01_pregunta"
            elif bi == 0 and i == F_IMG + F_QIN + F_QHOLD + F_TIN + 20:
                tag = "02_numeros"
            elif bi == 0 and i == F_IMG + F_QIN + F_QHOLD + F_TIN + F_THOLD + F_LET * 3 + 10:
                tag = "03_resolviendo"
            elif bi == 0 and i == n - 20:
                tag = "04_resuelto"
            elif bi == 1 and i == 50:
                tag = "05_observa"
            elif bi == 2 and i == 70:
                tag = "06_deduce"
            elif bi == 3 and i == 70:
                tag = "07_descifra"
            elif bi == 4 and i == 50:
                tag = "08_hielo"
            elif bi == len(beats) - 1 and i == 40:
                tag = "09_final"
            if tag and tag not in qa_saved:
                im.convert("RGB").save(qa / f"{tag}.png")
                qa_saved.add(tag)
        prev = fn(n - 1, n)
        print(f"  {written}/{total}")
    writer.release()

    import imageio_ffmpeg

    ff = imageio_ffmpeg.get_ffmpeg_exe()
    music = ROOT / "audio" / "music" / "07_exploration.ogg"
    dur = total / FPS
    fade_out_at = max(0.5, dur - 2.5)
    cmd = [
        ff,
        "-y",
        "-i",
        str(tmp),
        "-i",
        str(music),
        "-t",
        f"{dur:.3f}",
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-crf",
        "18",
        "-preset",
        "medium",
        "-c:a",
        "aac",
        "-b:a",
        "192k",
        "-af",
        f"afade=t=in:st=0:d=0.8,afade=t=out:st={fade_out_at:.2f}:d=2.4,volume=0.52",
        "-movflags",
        "+faststart",
        "-shortest",
        str(final),
    ]
    print("Muxing…")
    subprocess.check_call(cmd)
    print("DONE", final, f"{final.stat().st_size / 1e6:.1f} MB", f"{dur:.1f}s")


if __name__ == "__main__":
    main()
