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


THEME_STOP = {
    "EL", "LA", "LOS", "LAS", "DE", "DEL", "AL", "Y", "E", "O", "U", "EN", "UN", "UNA",
    "THE", "OF", "AND", "A", "AN", "OR", "TO", "IN", "ON", "FOR", "BY",
    "LE", "LES", "DU", "DES", "ET", "OU", "AU", "AUX",
    "IL", "LO", "GLI", "DI", "DA", "DEL", "DELLA", "DELLO", "DALLE",
    "DER", "DIE", "DAS", "UND", "EIN", "EINE", "IM", "AM", "VON", "VAN",
    "O", "A", "OS", "AS", "DO", "DA", "DOS", "DAS", "EM", "NO", "NA",
    "DON", "DONA", "DOÑA", "SAN", "SANTA", "SAINT", "ST", "SIR",
    "CITA", "FRASE", "SOBRE", "ATRIBUIDA", "FRAGMENTO", "APERTURA",
    "ROMANCE", "ANONIMO", "ANÓNIMO", "TRATADO", "CANTO", "RIMAS", "COPLAS",
    "POEMA", "NOVELA", "LIBRO", "OBRA", "AUTOR", "AUTORA",
    "QUOTE", "FROM", "BY", "CHAPTER", "BOOK", "CANTO",
    "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "LIII",
}

# Hint prefixes that introduce a person or a work, not a generic topic.
HINT_NAME_PREFIXES = (
    "CITA DE ", "CITA ATRIBUIDA A ", "FRASE DE ",
    "FRAGMENTO DE ", "APERTURA DE ", "POEMA DE ", "DISCURSO DE ",
    "ROMANCE DE ", "ROMANCE DEL ", "QUOTE BY ", "QUOTE FROM ",
    "ZITAT VON ", "CITATION DE ", "CITAZIONE DI ",
)
NAME_CUT = (
    " SOBRE ", " ABOUT ", " UBER ", " ÜBER ", " SUR ", " Y ", " AND ", " UND ", " ET ",
    " SULLA ",
)
SENTENCE_STARTERS = {
    "ADEMAS", "TAMBIEN", "COMO", "CUANDO", "DESDE", "AQUELLA", "AQUEL", "AQUELLOS",
    "ESTAS", "ESTOS", "ESTE", "ESTA", "ESTO", "TODA", "TODO", "TODOS", "TODAS",
    "SU", "SUS", "DE", "EN", "EL", "LA", "LOS", "LAS", "UN", "UNA", "PARA", "POR",
    "CON", "SI", "NO", "YA", "ASI", "MAS", "PERO", "TRAS", "DURANTE", "SEGUN",
    "HAY", "ERA", "FUE", "SER", "SON", "THAT", "THIS", "THESE", "THOSE", "THERE",
    "THEN", "WITH", "FOR", "AND", "BUT", "HIS", "HER", "THEIR", "AFTER", "BEFORE",
    "ALTHOUGH", "HOWEVER", "TODAVIA", "LUEGO", "ASI", "THE", "THESE",
    "DIESE", "CETTE", "QUESTO", "QUESTA", "DIESES", "AUSSERDEM", "AUSSI",
}
GENERIC_NOUNS = {
    "MUERTE", "VIDA", "PADRE", "MADRE", "AMOR", "MAR", "TIERRA", "MUNDO", "MUNDOS",
    "TIEMPO", "HISTORIA", "GUERRA", "PAZ", "ARTE", "CANCION", "PIRATA", "HABITACION",
    "PROPIA", "LIEBRE", "TORTUGA", "CIGARRA", "HORMIGA", "VIAJE", "SUBMARINO",
    "LEGUAS", "NOCHES", "GRANJA", "REBELION", "ESTUDIOS", "MEDITACIONES",
    "BREVEDAD", "METODO", "DISCURSO", "CIENCIA", "SCIENCE", "FACTS", "HISTORY",
    "NASA", "IBM", "UNESCO", "PATRONATO", "JUNTA", "CENTRO", "MUSEO", "CAPACIDAD",
    "CARACTERISTICAS", "INCREIBLES", "ASOMBROSA", "ORIGEN", "VICTORIA", "CONSTRUCCION",
    "COLOCACION", "INAUGURACION", "EXPLOSION", "VACIO", "ESPACIO", "MEMORIA",
    "HABITOS", "PERSONAS", "OPCIONES", "AFIRMACION", "IMPRESIONES", "OPINION",
    "CONTEXTO", "RECOMPENSA", "BENEFICIO", "CODIGO", "FABRICAS", "AUTOMOVILES",
    "ANILLOS", "LUNA", "CIELO", "TELESCOPIO", "UNIVERSO", "EXPANSION", "ESTRELLA",
    "ESTRELLAS", "ELEMENTOS", "CUERPO", "ANTIGUAS", "PRIMERA", "PIEDRA", "CATEDRAL",
    "CLERECIA", "TARDA", "LLEGAR", "ALEJA", "MIRAR", "OBSERVAR", "PASADO",
    "RECONSTRUYE", "SESGO", "CONFIRMACION", "PRESTAR", "ATENCION", "DEMASIADAS",
    "DIFICULTAR", "DESCUENTO", "TEMPORAL", "REPETIR", "PUEDE", "REDUCEN",
    "ESFUERZO", "CONSCIENTE", "CADA", "RAPIDEZ", "FORMAN", "PRIMERAS", "CAMBIAR",
    "PUEDEN", "RECORDAR", "MISMO", "INMEDIATA", "FUTURO", "DENSO", "WAVE",
    "RECONOCER", "ABEJAS", "PULPOS", "TIENEN", "VOLCANES", "LUCIERNAGAS",
    "PASTORCILLO", "MENTIROSO", "MIL", "UNA",
    "UNDER", "OVER", "THOUSAND", "LEAGUES", "TWENTY", "SEAS", "SEA", "MEER",
    "ROOM", "ZIMMER", "CHAMBRE", "NACHT", "NIGHT", "NIGHTS", "TIERE", "ANIMALS",
    "HASE", "HARE", "TORTOISE", "SCHILDKROTE", "GRILLE", "AMEISE", "GRASSHOPPER",
    "ANT", "CIGALE", "FOURMI", "WOLF", "LOUP", "BERGER", "SHEPHERD", "PASTOR",
    "ELEMENTE", "ELEMENTS", "ELEMENT", "UNSERE", "BASIS", "TEMPEL", "TEMPLE",
    "SOLEIL", "GIRAFFEN", "GIRAFFE", "JIRAFA", "TORTUE", "SAVOIR", "CONVERSATION",
    "ELLES", "THEY", "WHEN", "THEIR", "GENERAL", "PRINCE", "PRINZ", "PRINCIPE",
    "CAPTAIN", "CAPITAN", "INSPECTOR", "INSPEKTOR", "FESTIVAL", "MUSEUM",
    "CATHEDRAL", "CATEDRAL", "CATHEDRALE", "CATTEDRALE", "COLEGIO", "KALENDER",
    "BANKEN", "KIND", "ZEIT", "ARMEEN", "ZWEIFEL", "STERNE", "MENSCHEN",
    "GOTHIC", "FRENCH", "VIEILLE", "HANDIA", "JEDES", "DEINE", "ERSTE",
    "ZWEI",
}


def _is_name_token(word: str) -> bool:
    if word == "CID":
        return True
    if len(word) < 4:
        return False
    if word in THEME_STOP or word in SENTENCE_STARTERS or word in GENERIC_NOUNS:
        return False
    return True


def _cut_name_phrase(raw: str) -> str:
    text = raw.strip()
    if not text:
        return ""
    text = re.split(r"[.:;,|]", text, maxsplit=1)[0].strip()
    cut = re.search(
        r"\s+(sobre|about|über|uber|sur|sulla|y|and|und|et)\b",
        text,
        flags=re.IGNORECASE,
    )
    if cut and cut.start() > 0:
        text = text[: cut.start()].strip()
    return text


def _hint_theme_label(item: dict) -> str:
    hint = str(item.get("hint_1", "")).strip()
    folded = fold(hint)
    if not hint or folded in {"FRASE 1", "HINT 1", "HINWEIS 1", "NOTA 1", "DICA 1", "PISTA 1"}:
        return ""
    for prefix in HINT_NAME_PREFIXES:
        if folded.startswith(prefix):
            return _cut_name_phrase(hint[len(prefix):])
    return ""


def _capitalized_tokens(text: str) -> list[str]:
    names: list[str] = []
    for word in re.findall(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ'.-]+", text):
        if not word[:1].isupper():
            continue
        folded = fold(word)
        if _is_name_token(folded):
            names.append(folded)
    return names


def _desc_theme_names(item: dict) -> list[str]:
    desc = str(item.get("description_end", "")).strip()
    if not desc:
        return []
    first = desc.split("\n", 1)[0].strip()
    first = re.split(r"\s*\(\d", first, 1)[0].strip()
    folded = fold(first)
    if any(folded.startswith(skip) for skip in (
        "ESTE ", "ESTA ", "ESTO ", "THIS ", "DIESE ", "CETTE ", "QUESTO ", "QUESTA ",
        "ESTE EPISODIO", "LA FRASE", "EL EPISODIO", "ROMANCE ANONIMO", "LA CANCION",
    )):
        return []
    names: list[str] = []
    for word in re.findall(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ'.-]+", first):
        folded_w = fold(word)
        if not folded_w:
            continue
        if word[:1].islower():
            break
        if folded_w in THEME_STOP:
            continue
        if folded_w in SENTENCE_STARTERS:
            if names:
                break
            return []
        if _is_name_token(folded_w):
            names.append(folded_w)
        if len(names) >= 4:
            break
    if len(names) < 2:
        return []
    return names


def _blurb_tokens(item: dict) -> set[str]:
    desc = str(item.get("description_end", "")).strip().split("\n", 1)[0]
    desc = " ".join(desc.split()[:12])
    blob = " ".join(
        (
            str(item.get("source", "")).split("|", 1)[0],
            desc,
            _hint_theme_label(item),
        )
    )
    return set(tokens(blob))


def _person_in_text(item: dict, text: str) -> list[str]:
    if str(item.get("pack", "")).lower() == "daily":
        return []
    blurb = _blurb_tokens(item)
    if not blurb:
        return []
    found: list[str] = []
    for match in re.finditer(
        r"\b([A-ZÁÉÍÓÚÜÑ][A-Za-zÁÉÍÓÚÜÑáéíóúüñ'.-]*)\s+([A-ZÁÉÍÓÚÜÑ][A-Za-zÁÉÍÓÚÜÑáéíóúüñ'.-]*)\b",
        text,
    ):
        left, right = fold(match.group(1)), fold(match.group(2))
        if not (_is_name_token(left) and _is_name_token(right)):
            continue
        if left in blurb and right in blurb:
            found.extend([left, right])
        elif right in blurb and len(right) >= 6:
            found.append(right)
    return found


WORK_TITLE_TOKENS = {
    "HAMLET", "AMLETO", "QUIJOTE", "MANCHA", "ROBINSON", "CRUSOE", "SANDOKAN",
    "FRANKENSTEIN", "DRACULA", "DRACULA", "MOBY", "DICK", "WALDEN", "HOLMES",
    "SHERLOCK", "LAZARILLO", "ODISEA", "ODYSSEY", "DECAMERON", "DECAMERON",
    "TENORIO", "BABIECA",
}


def _source_theme_names(item: dict) -> list[str]:
    raw = str(item.get("source", "")).strip().split("|", 1)[0].strip()
    if not raw:
        return []
    for sep in (" — ", " – ", " - "):
        if sep in raw:
            raw = raw.split(sep, 1)[0]
            break
    raw = raw.strip()
    if not raw:
        return []
    folded = fold(raw)
    if any(key in folded for key in ("NASA", "IBM", "UNESCO", "DENSO", "PATRONATO", "JUNTA DE", "CENTRO DEL")):
        return []
    if "," in raw:
        author, title = raw.split(",", 1)
        title_hits = [w for w in _capitalized_tokens(title) if w in WORK_TITLE_TOKENS]
        return _capitalized_tokens(author) + title_hits
    return _capitalized_tokens(raw)


def theme_name_hits(item: dict, text: str) -> tuple[list[str], bool]:
    source_raw = str(item.get("source", ""))
    if str(item.get("pack", "")).lower() == "daily":
        return [], False
    if "|" in source_raw or "http" in source_raw.lower():
        return [], False
        return [], False
    names: list[str] = []
    seen: set[str] = set()
    for word in (
        _source_theme_names(item)
        + _capitalized_tokens(_hint_theme_label(item))
        + _desc_theme_names(item)
        + _person_in_text(item, text)
    ):
        if word in seen or not _is_name_token(word):
            continue
        seen.add(word)
        names.append(word)
    if not names:
        return [], False
    text_set = set(tokens(text))
    hits = [w for w in names if w in text_set]
    if not hits:
        return [], False
    long_hits = [w for w in hits if len(w) >= 6]
    obvious = bool(long_hits) or len(hits) >= 2
    return hits, obvious


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

    theme_hits, theme_obvious = theme_name_hits(item, text)
    if theme_hits:
        easy += 1
        reasons.append("el texto nombra el tema (" + ", ".join(theme_hits) + ")")

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

    if theme_obvious:
        stars -= 1
        stars = clamp(stars, 1, 3) if mode == "quick" else clamp(stars, 3, 5)
        reasons.append("nombre del tema muy evidente: se baja una estrella")

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


# Do not lower these just because the name appears in the cipher.
SKIP_THEME_IDS = {118, 3077}
# Name is a hint, but not enough to drop two stars.
ONE_STAR_THEME_IDS = {1019, 3105}


def apply_theme_stars(item: dict) -> dict:
    """Lower stored stars when the cipher text names the person or work."""
    old = int(item.get("difficulty", 2))
    mode = "cryptogram" if str(item.get("game_mode", "")).lower() == "cryptogram" else "quick"
    index = int(item.get("index", 0))
    hits, obvious = theme_name_hits(item, str(item.get("text", "")))
    stars = old
    why: list[str] = []
    if hits and index not in SKIP_THEME_IDS:
        stars -= 1
        why.append("el texto nombra el tema (" + ", ".join(hits) + ")")
        if obvious and index not in ONE_STAR_THEME_IDS:
            stars -= 1
            why.append("nombre del tema muy evidente: se baja una estrella extra")
    lo, hi = (1, 3) if mode == "quick" else (3, 5)
    stars = clamp(stars, lo, hi)
    preview = re.sub(r"\s+", " ", str(item.get("text", ""))).strip()
    if len(preview) > 90:
        preview = preview[:87] + "…"
    return {
        "index": int(item.get("index", 0)),
        "mode": mode,
        "category": str(item.get("category", "")),
        "old": old,
        "stars": stars,
        "changed": stars != old,
        "hits": hits,
        "obvious": obvious,
        "why": "; ".join(why),
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
            row = apply_theme_stars(item)
            row["lang"] = lang
            item["difficulty"] = row["stars"]
            lang_rows.append(row)
            if row["hits"] or row["changed"]:
                review.append(row)
        path.write_text(json.dumps(data, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
        dist[lang] = Counter((r["mode"], r["stars"]) for r in lang_rows)
        print(path.name, "changed", sum(1 for r in lang_rows if r["changed"]), "/", len(lang_rows), dict(dist[lang]))

    REVIEW_OUT.write_text(json.dumps(review, ensure_ascii=False, indent=2), encoding="utf-8")
    print("wrote", REVIEW_OUT, "rows", len(review))


if __name__ == "__main__":
    main()
