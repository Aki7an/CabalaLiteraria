#!/usr/bin/env python3
"""Align non-ES stars to Spanish totals per category and level, then rebuild the canvas."""

from __future__ import annotations

import json
import unicodedata
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CANVAS = Path(
    r"C:\Users\aki7a\.cursor\projects\c-Users-aki7a-Documents-Godot-CifraLetra\canvases\estrellas-puzles.canvas.tsx"
)
LANGS = ["es", "en", "de", "fr", "it", "pt", "eu"]
OTHERS = [lang for lang in LANGS if lang != "es"]

CAT_LABEL = {
    "efemeride": "Efeméride",
    "cita": "Cita",
    "curiosidades": "Curiosidades",
    "fragmento": "Fragmento",
    "daily": "Diario",
}
LEVEL_LABEL = {
    "rapido": "Rápido",
    "desafio": "Desafío",
    "diario-rapido": "Diario rápido",
    "diario-desafio": "Diario desafío",
}


def fold(text: str) -> str:
    raw = unicodedata.normalize("NFD", text.strip().lower())
    return "".join(ch for ch in raw if unicodedata.category(ch) != "Mn")


def is_daily(item: dict) -> bool:
    return str(item.get("pack", "")).lower() == "daily"


def is_quick(item: dict) -> bool:
    return str(item.get("game_mode", "")).lower() == "quick"


def category_id(item: dict) -> str:
    if is_daily(item):
        return "daily"
    key = fold(str(item.get("category", "")))
    key = key.replace("ß", "ss")
    if key in {"efemeride", "efemerides", "event", "events", "ereignis", "gertaera", "evenement", "evento"}:
        return "efemeride"
    if "cita" in key or "quote" in key or "zitat" in key or "aipu" in key or "citaz" in key or "personaj" in key:
        return "cita"
    if "curios" in key or "kurios" in key:
        return "curiosidades"
    if "fragment" in key or "framment" in key or "literatur" in key:
        return "fragmento"
    raise ValueError("unknown category %r" % item.get("category"))


def level_id(item: dict) -> str:
    if is_daily(item):
        return "diario-rapido" if is_quick(item) else "diario-desafio"
    return "rapido" if is_quick(item) else "desafio"


def group_key(item: dict) -> tuple[str, str]:
    return (level_id(item), category_id(item))


def star_range(item: dict) -> tuple[int, int]:
    return (1, 3) if is_quick(item) else (3, 5)


def clamp(value: int, lo: int, hi: int) -> int:
    return max(lo, min(hi, value))


def apply_decimal_rule(raw: float) -> int:
    whole = int(raw)
    frac = raw - whole
    if frac > 0.5:
        return whole + 1
    return whole


def adjust_group(items: list[dict], target: int) -> dict:
    current = [int(p.get("difficulty", 1)) for p in items]
    total = sum(current)
    before = total
    if total == target:
        return {"before": before, "after": total, "final_index": None}

    desired = [c * target / total for c in current]
    rounded = [clamp(apply_decimal_rule(raw), *star_range(item)) for item, raw in zip(items, desired)]

    leftover = target - sum(rounded)
    final_index = None
    while leftover != 0:
        step = 1 if leftover > 0 else -1
        candidates = []
        for i, item in enumerate(items):
            lo, hi = star_range(item)
            if lo <= rounded[i] + step <= hi:
                candidates.append(i)
        if not candidates:
            raise RuntimeError("cannot reach %s from %s" % (target, sum(rounded)))

        def score(i: int) -> tuple:
            frac = desired[i] - int(desired[i])
            closeness = frac if step > 0 else 1.0 - frac
            return (closeness, -int(items[i].get("index", 0)))

        pick = max(candidates, key=score)
        rounded[pick] += step
        leftover -= step
        final_index = int(items[pick].get("index", 0))

    for item, stars in zip(items, rounded):
        item["difficulty"] = stars
    return {"before": before, "after": sum(rounded), "final_index": final_index}


def load_lang(lang: str) -> list[dict]:
    return json.loads((DATA / f"frases_{lang}.json").read_text(encoding="utf-8"))


def save_lang(lang: str, data: list[dict]) -> None:
    (DATA / f"frases_{lang}.json").write_text(
        json.dumps(data, ensure_ascii=False, indent="\t") + "\n",
        encoding="utf-8",
    )


def main() -> None:
    files = {lang: load_lang(lang) for lang in LANGS}
    es_groups: dict[tuple[str, str], int] = defaultdict(int)
    for item in files["es"]:
        es_groups[group_key(item)] += int(item["difficulty"])

    report = []
    for lang in OTHERS:
        groups: dict[tuple[str, str], list[dict]] = defaultdict(list)
        for item in files[lang]:
            groups[group_key(item)].append(item)
        for key, target in sorted(es_groups.items()):
            info = adjust_group(groups[key], target)
            report.append(
                {
                    "lang": lang,
                    "level": key[0],
                    "category": key[1],
                    "target": target,
                    "before": info["before"],
                    "ajuste": target - info["before"],
                    "after": info["after"],
                    "final_index": info["final_index"],
                }
            )
        save_lang(lang, files[lang])

    by_index: dict[int, dict] = {}
    for lang in LANGS:
        for item in files[lang]:
            idx = int(item["index"])
            row = by_index.setdefault(
                idx,
                {
                    "i": idx,
                    "m": "q" if is_quick(item) else "c",
                    "p": "d" if is_daily(item) else "c",
                    "c": category_id(item),
                    "lv": level_id(item),
                },
            )
            row[lang] = int(item["difficulty"])

    rows = [by_index[idx] for idx in sorted(by_index)]
    write_canvas(rows, es_groups, report)
    print("groups", dict(es_groups))
    for row in report:
        print(
            row["lang"],
            row["level"],
            row["category"],
            "obj",
            row["target"],
            "antes",
            row["before"],
            "ajuste",
            row["ajuste"],
            "final",
            row["after"],
            "idx",
            row["final_index"],
        )


def write_canvas(rows: list[dict], targets: dict, report: list[dict]) -> None:
    data_json = json.dumps(rows, ensure_ascii=False, separators=(",", ":"))
    report_json = json.dumps(report, ensure_ascii=False, separators=(",", ":"))
    targets_json = json.dumps(
        [{"lv": lv, "c": cat, "t": total} for (lv, cat), total in sorted(targets.items())],
        ensure_ascii=False,
        separators=(",", ":"),
    )
    tsx = f"""import {{
  Callout,
  Grid,
  H1,
  H2,
  Pill,
  Row,
  Select,
  Stack,
  Stat,
  Table,
  Text,
  useCanvasState,
}} from "cursor/canvas";

type PuzzleRow = {{
  i: number;
  m: string;
  p: string;
  c: string;
  lv: string;
  es: number;
  en: number;
  de: number;
  fr: number;
  it: number;
  pt: number;
  eu: number;
}};

type AdjRow = {{
  lang: string;
  level: string;
  category: string;
  target: number;
  before: number;
  ajuste: number;
  after: number;
  final_index: number | null;
}};

const PUZZLES: PuzzleRow[] = {data_json};
const ADJUST: AdjRow[] = {report_json};
const TARGETS = {targets_json};

const LANGS = [
  {{ value: "es", label: "ES" }},
  {{ value: "en", label: "EN" }},
  {{ value: "de", label: "DE" }},
  {{ value: "fr", label: "FR" }},
  {{ value: "it", label: "IT" }},
  {{ value: "pt", label: "PT" }},
  {{ value: "eu", label: "EU" }},
];

const CAT: Record<string, string> = {{
  efemeride: "Efemeride",
  cita: "Cita",
  curiosidades: "Curiosidades",
  fragmento: "Fragmento",
  daily: "Diario",
}};

const LEVEL: Record<string, string> = {{
  rapido: "Rapido",
  desafio: "Desafio",
  "diario-rapido": "Diario rapido",
  "diario-desafio": "Diario desafio",
}};

function signed(n: number) {{
  return n > 0 ? "+" + n : String(n);
}}

export default function PuzzleStars() {{
  const [lang, setLang] = useCanvasState("lang", "en");
  const [level, setLevel] = useCanvasState("level", "all");
  const [cat, setCat] = useCanvasState("cat", "all");

  const puzzles = PUZZLES.filter((r) => {{
    if (level !== "all" && r.lv !== level) return false;
    if (cat !== "all" && r.c !== cat) return false;
    return true;
  }});

  const adj = ADJUST.filter((r) => {{
    if (r.lang !== lang) return false;
    if (level !== "all" && r.level !== level) return false;
    if (cat !== "all" && r.category !== cat) return false;
    return true;
  }});

  const target = puzzles.reduce((n, r) => n + r.es, 0);
  const current = puzzles.reduce((n, r) => n + Number(r[lang as keyof PuzzleRow]), 0);
  const changed = puzzles.filter((r) => Number(r[lang as keyof PuzzleRow]) !== r.es).length;

  const table = puzzles.map((r) => {{
    const value = Number(r[lang as keyof PuzzleRow]);
    return [
      String(r.i),
      LEVEL[r.lv],
      CAT[r.c],
      String(r.es),
      String(r.en),
      String(r.de),
      String(r.fr),
      String(r.it),
      String(r.pt),
      String(r.eu),
      signed(value - r.es),
    ];
  }});

  const summary = (lang === "es"
    ? TARGETS.filter((t) => {{
        if (level !== "all" && t.lv !== level) return false;
        if (cat !== "all" && t.c !== cat) return false;
        return true;
      }}).map((t) => [LEVEL[t.lv], CAT[t.c], String(t.t), "0", String(t.t)])
    : adj.map((r) => [
        LEVEL[r.level],
        CAT[r.category],
        String(r.target),
        signed(r.ajuste),
        String(r.after),
      ]));

  return (
    <Stack gap={{20}}>
      <Stack gap={{6}}>
        <H1>Estrellas por puzle por idioma</H1>
        <Text tone="secondary">
          Referencia ES. Totales iguales por nivel y categoria. Ajuste = idioma
          seleccionado menos espanol. Objetivo de bloque: 160 rapidos, 123
          desafios, 81 diarios (364 en total).
        </Text>
      </Stack>

      <Row gap={{12}} wrap>
        <Select value={{lang}} onChange={{setLang}} options={{LANGS}} />
        <Select
          value={{level}}
          onChange={{setLevel}}
          options={{[
            {{ value: "all", label: "Todos los niveles" }},
            {{ value: "rapido", label: "Rapido" }},
            {{ value: "desafio", label: "Desafio" }},
            {{ value: "diario-rapido", label: "Diario rapido" }},
            {{ value: "diario-desafio", label: "Diario desafio" }},
          ]}}
        />
        <Select
          value={{cat}}
          onChange={{setCat}}
          options={{[
            {{ value: "all", label: "Todas las categorias" }},
            {{ value: "efemeride", label: "Efemeride" }},
            {{ value: "cita", label: "Cita" }},
            {{ value: "curiosidades", label: "Curiosidades" }},
            {{ value: "fragmento", label: "Fragmento" }},
            {{ value: "daily", label: "Diario" }},
          ]}}
        />
      </Row>

      <Grid columns={{4}} gap={{12}}>
        <Stat value={{String(target)}} label="Estrellas a cuadrar (ES)" />
        <Stat value={{String(current)}} label={{"Estrellas " + lang.toUpperCase()}} />
        <Stat value={{signed(current - target)}} label="Ajuste del filtro" />
        <Stat value={{String(changed)}} label="Puzles distintos de ES" />
      </Grid>

      <Callout tone="info" title="Totales por nivel y categoria">
        Tras el ajuste, cada idioma suma lo mismo que ES en cada bloque.
        La columna Ajuste de la tabla grande es por puzle (idioma - ES).
      </Callout>

      <Stack gap={{8}}>
        <Row gap={{8}} align="center">
          <H2>Objetivo y ajuste por bloque</H2>
          <Pill>{{lang.toUpperCase()}}</Pill>
        </Row>
        <Table
          striped
          headers={{["Nivel", "Categoria", "Estrellas a cuadrar", "Ajuste", "Final"]}}
          rows={{summary}}
          columnAlign={{["left", "left", "right", "right", "right"]}}
        />
      </Stack>

      <Stack gap={{8}}>
        <Row gap={{8}} align="center">
          <H2>Estrellas por puzle por idioma</H2>
          <Pill>{{puzzles.length}} puzles</Pill>
        </Row>
        <Table
          stickyHeader
          striped
          headers={{["Index", "Nivel", "Categoria", "ES", "EN", "DE", "FR", "IT", "PT", "EU", "Ajuste " + lang.toUpperCase()]}}
          rows={{table}}
          columnAlign={{["right", "left", "left", "right", "right", "right", "right", "right", "right", "right", "right"]}}
        />
      </Stack>
    </Stack>
  );
}}
"""
    CANVAS.write_text(tsx, encoding="utf-8")
    print("canvas", CANVAS, CANVAS.stat().st_size)


if __name__ == "__main__":
    main()
