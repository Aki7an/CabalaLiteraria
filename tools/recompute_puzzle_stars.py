#!/usr/bin/env python3
"""Recompute puzzle star ratings per language and write frases_*.json."""

from __future__ import annotations

import json
import re
import unicodedata
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
REVIEW_OUT = ROOT / "tools" / "star_review.json"

MONTHS = {
    "es": [
        "ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO", "JULIO",
        "AGOSTO", "SEPTIEMBRE", "SETIEMBRE", "OCTUBRE", "NOVIEMBRE", "DICIEMBRE",
    ],
    "en": [
        "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY",
        "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER",
    ],
    "de": [
        "JANUAR", "FEBRUAR", "MARZ", "APRIL", "MAI", "JUNI", "JULI",
        "AUGUST", "SEPTEMBER", "OKTOBER", "NOVEMBER", "DEZEMBER",
    ],
    "fr": [
        "JANVIER", "FEVRIER", "MARS", "AVRIL", "MAI", "JUIN", "JUILLET",
        "AOUT", "SEPTEMBRE", "OCTOBRE", "NOVEMBRE", "DECEMBRE",
    ],
    "it": [
        "GENNAIO", "FEBBRAIO", "MARZO", "APRILE", "MAGGIO", "GIUGNO", "LUGLIO",
        "AGOSTO", "SETTEMBRE", "OTTOBRE", "NOVEMBRE", "DICEMBRE",
    ],
    "pt": [
        "JANEIRO", "FEVEREIRO", "MARCO", "ABRIL", "MAIO", "JUNHO", "JULHO",
        "AGOSTO", "SETEMBRO", "OUTUBRO", "NOVEMBRO", "DEZEMBRO",
    ],
    "eu": [
        "URTARRIL", "OTSAIL", "MARTXO", "APIRIL", "MAIATZ", "EKAIN", "UZTAIL",
        "ABUZT", "IRAIL", "URRI", "AZARO", "ABENDU",
    ],
}

DATE_PREFIX = {
    "es": re.compile(r"\bEL\s+\d{1,2}\s+DE\s+[A-ZÑ]+\b"),
    "en": re.compile(r"\b(ON\s+)?((THE\s+)?\d{1,2}(ST|ND|RD|TH)?\s+OF\s+[A-Z]+|IN\s+[A-Z]+\s+\d{4})\b"),
    "de": re.compile(r"\bAM\s+\d{1,2}\.?\s+[A-Z]+\b"),
    "fr": re.compile(r"\bLE\s+\d{1,2}\s+[A-Z]+\b"),
    "it": re.compile(r"\bIL\s+\d{1,2}\s+[A-Z]+\b"),
    "pt": re.compile(r"\b(EM|NO DIA)\s+\d{1,2}\s+DE\s+[A-Z]+\b"),
    "eu": re.compile(r"\b\d{4}\s*KO\b"),
}

NUMERIC_DATE = re.compile(r"\b\d{1,2}[-./]\d{1,2}[-./]\d{2,4}\b")

VOWELS = set("AEIOU")

# Short-word bands relative to each language (Romance texts naturally have more EL/LA/DE).
SHORT_EASY = {"es": 0.47, "en": 0.45, "de": 0.40, "fr": 0.50, "it": 0.46, "pt": 0.47, "eu": 0.28}
SHORT_HARD = {"es": 0.33, "en": 0.30, "de": 0.26, "fr": 0.36, "it": 0.32, "pt": 0.33, "eu": 0.12}


def fold(text: str) -> str:
    up = text.upper().replace("ß", "SS").replace("Ñ", "\u0001")
    norm = unicodedata.normalize("NFD", up)
    out = []
    for ch in norm:
        if unicodedata.category(ch) == "Mn":
            continue
        out.append("Ñ" if ch == "\u0001" else ch)
    return "".join(out)


def tokens(text: str) -> list[str]:
    return re.findall(r"[A-ZÑ]+", fold(text))


def letter_len(text: str) -> int:
    return sum(1 for ch in fold(text) if ch.isalpha() or ch == "Ñ")


def short_words(words: list[str]) -> list[str]:
    return [w for w in words if 1 <= len(w) <= 3]


def double_es(words: list[str]) -> list[str]:
    found = []
    for w in words:
        if "LL" in w:
            found.append("LL")
        if "RR" in w:
            found.append("RR")
        if "CC" in w:
            found.append("CC")
    return found


def date_hits(lang: str, text: str, words: list[str]) -> list[str]:
    folded = fold(text)
    hits = []
    if NUMERIC_DATE.search(folded):
        hits.append("fecha numérica")
    rx = DATE_PREFIX.get(lang)
    if rx and rx.search(folded):
        hits.append("artículo + número + mes")
    months = MONTHS.get(lang, [])
    month_found = [m for m in months if m in words or any(w.startswith(m[:5]) for w in words if len(m) >= 5)]
    if month_found and any(w.isdigit() or w in {"EL", "THE", "LE", "IL", "AM", "DE", "ON"} for w in words):
        if "mes" not in " ".join(hits):
            hits.append("mes del calendario")
    return hits


def plural_s_es(words: list[str]) -> tuple[bool, int]:
    articles = {"LOS", "LAS"}
    ending = [w for w in words if len(w) >= 4 and w.endswith("S")]
    strong = bool(articles & set(words)) and len(ending) >= 5
    return strong, len(ending)


def gift_reveals_shorts(words: list[str], shorts: list[str], level: int) -> bool:
    if level >= 3 or not shorts:
        return False
    letters = [ch for w in words for ch in w]
    freq = Counter(letters)
    vowels = [ch for ch, _ in freq.most_common() if ch in VOWELS]
    cons = [ch for ch, _ in freq.most_common() if ch not in VOWELS]
    gifted = set(vowels[: 2 if level == 1 else 1] + cons[: 5 if level == 1 else 3])
    if not gifted:
        return False
    opened = sum(1 for w in shorts if set(w) <= gifted)
    return opened >= max(3, int(round(len(shorts) * 0.4)))


def clamp(value: int, lo: int, hi: int) -> int:
    return max(lo, min(hi, value))


def score_puzzle(lang: str, item: dict) -> dict:
    text = str(item.get("text", ""))
    mode = "cryptogram" if str(item.get("game_mode", "")).lower() == "cryptogram" else "quick"
    words = tokens(text)
    shorts = short_words(words)
    short_ratio = len(shorts) / max(len(words), 1)
    length = letter_len(text)
    doubles = double_es(words) if lang == "es" else []
    dates = date_hits(lang, text, words)
    plural_strong, plural_n = plural_s_es(words) if lang == "es" else (False, 0)
    old = int(item.get("difficulty", 2))

    reasons: list[str] = []
    easy = 0
    hard = 0

    easy_cut = SHORT_EASY.get(lang, 0.45)
    hard_cut = SHORT_HARD.get(lang, 0.30)
    if short_ratio >= easy_cut:
        easy += 1
        reasons.append(f"muchas palabras de 1–3 letras para este idioma ({len(shorts)}/{len(words)}, {short_ratio:.0%})")
    elif short_ratio <= hard_cut:
        hard += 1
        reasons.append(f"pocas palabras cortas para este idioma ({short_ratio:.0%})")
    else:
        reasons.append(f"palabras cortas en la media del idioma ({short_ratio:.0%})")

    if lang == "es" and len(doubles) >= 3:
        easy += 1
        reasons.append("varias dobles LL/RR/CC (suelen delimitar vocales)")
    elif lang == "es" and doubles:
        reasons.append("alguna doble LL/RR/CC: pista menor")

    if lang == "es" and plural_strong:
        easy += 1
        reasons.append(f"plurales en S identificables ({plural_n} palabras)")

    if dates:
        easy += 1
        reasons.append("patrón de fecha claro (" + ", ".join(dates) + ")")

    if mode == "quick":
        trial = 3 if easy <= 0 else (2 if easy == 1 else 1)
        if gift_reveals_shorts(words, shorts, trial):
            easy += 1
            reasons.append("las letras regaladas destaparían muchas palabras cortas")
        if easy <= 0:
            stars = 3
        elif easy == 1:
            stars = 2
        else:
            stars = 1
        stars = clamp(stars, 1, 3)
    else:
        if 200 <= length <= 250:
            hard += 1
            reasons.append(f"longitud {length} en la franja 200–250: más difícil")
        elif length > 400:
            easy += 1
            reasons.append(f"texto largo ({length} letras): más contexto")
        elif length < 170:
            easy += 1
            reasons.append(f"texto corto ({length} letras)")
        else:
            reasons.append(f"longitud {length}: neutra")
        delta = hard - easy
        if delta >= 2:
            stars = 5
        elif delta == 1:
            stars = 5
        elif delta == 0:
            stars = 4
        elif delta == -1:
            stars = 3
        else:
            stars = 3
        if dates:
            stars = min(stars, 4)
        stars = clamp(stars, 3, 5)

    preview = re.sub(r"\s+", " ", text).strip()
    if len(preview) > 90:
        preview = preview[:87] + "…"
    return {
        "lang": lang,
        "index": int(item.get("index", 0)),
        "mode": mode,
        "pack": "diario" if str(item.get("pack", "")).lower() == "daily" else "catálogo",
        "category": str(item.get("category", "")),
        "old": old,
        "stars": stars,
        "changed": stars != old,
        "length": length,
        "words": len(words),
        "shorts": len(shorts),
        "short_ratio": round(short_ratio, 3),
        "doubles": "".join(sorted(set(doubles))) if doubles else "",
        "dates": ", ".join(dates),
        "why": "; ".join(reasons),
        "preview": preview,
    }


def main() -> None:
    files = sorted(DATA.glob("frases_*.json"))
    review: list[dict] = []
    dist: dict[str, Counter] = {}
    for path in files:
        lang = path.stem.split("_")[1]
        data = json.loads(path.read_text(encoding="utf-8"))
        lang_rows = []
        for item in data:
            row = score_puzzle(lang, item)
            item["difficulty"] = row["stars"]
            lang_rows.append(row)
            review.append(row)
        path.write_text(json.dumps(data, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
        dist[lang] = Counter((r["mode"], r["stars"]) for r in lang_rows)
        print(path.name, "changed", sum(1 for r in lang_rows if r["changed"]), "/", len(lang_rows), dict(dist[lang]))

    REVIEW_OUT.write_text(json.dumps(review, ensure_ascii=False, indent=2), encoding="utf-8")
    print("wrote", REVIEW_OUT, "rows", len(review))


if __name__ == "__main__":
    main()
