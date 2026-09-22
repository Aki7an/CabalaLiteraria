#!/usr/bin/env python3
"""Rebuild the stars canvas including original difficulty comments."""

from __future__ import annotations

import json
from pathlib import Path

from align_stars_by_category import (
    CANVAS,
    DATA,
    LANGS,
    category_id,
    is_daily,
    is_quick,
    level_id,
    load_lang,
)

REVIEW = Path(__file__).resolve().parents[1] / "tools" / "star_review.json"


def main() -> None:
    review = json.loads(REVIEW.read_text(encoding="utf-8"))
    why = {}
    orig = {}
    preview = {}
    for row in review:
        key = (row["lang"], int(row["index"]))
        why[key] = str(row.get("why", ""))
        orig[key] = int(row.get("stars", 0))
        preview[key] = str(row.get("preview", ""))

    files = {lang: load_lang(lang) for lang in LANGS}
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
            row["w" + lang] = why.get((lang, idx), "")
            row["o" + lang] = orig.get((lang, idx), int(item["difficulty"]))
            row["t" + lang] = preview.get((lang, idx), "")

    rows = [by_index[idx] for idx in sorted(by_index)]
    es_groups = {}
    for item in files["es"]:
        key = (level_id(item), category_id(item))
        es_groups[key] = es_groups.get(key, 0) + int(item["difficulty"])

    report_path = Path(__file__).resolve().parents[1] / "tools" / "star_adjust_report.json"
    if report_path.exists():
        report = json.loads(report_path.read_text(encoding="utf-8"))
    else:
        report = []
        # Rebuild a minimal report from current equality with ES targets.
        for lang in LANGS:
            if lang == "es":
                continue
            grouped: dict[tuple[str, str], int] = {}
            for item in files[lang]:
                key = (level_id(item), category_id(item))
                grouped[key] = grouped.get(key, 0) + int(item["difficulty"])
            for key, after in grouped.items():
                target = es_groups[key]
                report.append(
                    {
                        "lang": lang,
                        "level": key[0],
                        "category": key[1],
                        "target": target,
                        "before": after,
                        "ajuste": 0,
                        "after": after,
                        "final_index": None,
                    }
                )

    write_canvas(rows, es_groups, report)
    print("rows", len(rows), "canvas", CANVAS.stat().st_size)


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
  wes: string;
  wen: string;
  wde: string;
  wfr: string;
  wit: string;
  wpt: string;
  weu: string;
  oes: number;
  oen: number;
  ode: number;
  ofr: number;
  oit: number;
  opt: number;
  oeu: number;
  tes: string;
  ten: string;
  tde: string;
  tfr: string;
  tit: string;
  tpt: string;
  teu: string;
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

function starOf(r: PuzzleRow, code: string) {{
  const map: Record<string, number> = {{
    es: r.es, en: r.en, de: r.de, fr: r.fr, it: r.it, pt: r.pt, eu: r.eu,
  }};
  return map[code] ?? r.es;
}}

function whyOf(r: PuzzleRow, code: string) {{
  const map: Record<string, string> = {{
    es: r.wes, en: r.wen, de: r.wde, fr: r.wfr, it: r.wit, pt: r.wpt, eu: r.weu,
  }};
  return map[code] ?? r.wes;
}}

function origOf(r: PuzzleRow, code: string) {{
  const map: Record<string, number> = {{
    es: r.oes, en: r.oen, de: r.ode, fr: r.ofr, it: r.oit, pt: r.opt, eu: r.oeu,
  }};
  return map[code] ?? r.oes;
}}

function textOf(r: PuzzleRow, code: string) {{
  const map: Record<string, string> = {{
    es: r.tes, en: r.ten, de: r.tde, fr: r.tfr, it: r.tit, pt: r.tpt, eu: r.teu,
  }};
  return map[code] ?? r.tes;
}}

export default function PuzzleStars() {{
  const [lang, setLang] = useCanvasState("lang", "es");
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
  const current = puzzles.reduce((n, r) => n + starOf(r, lang), 0);
  const changed = puzzles.filter((r) => starOf(r, lang) !== r.es).length;

  const table = puzzles.map((r) => {{
    const value = starOf(r, lang);
    const scored = origOf(r, lang);
    const note = value === scored
      ? whyOf(r, lang)
      : whyOf(r, lang) + " Ajuste posterior para cuadrar totales (" + scored + " -> " + value + ").";
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
      note,
      textOf(r, lang),
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
          Motivo original: analisis del texto (palabras cortas, fechas, dobles
          LL/RR/CC en espanol, plurales). Si el numero final no coincide con
          ese analisis, el comentario anade el ajuste para cuadrar totales.
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

      <Callout tone="info" title="Como leer el motivo">
        El motivo es del idioma seleccionado. Explica por que salio 1-5 en el
        analisis. El ajuste de totales (si lo hubo) va al final del mismo texto.
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
          headers={{["Index", "Nivel", "Categoria", "ES", "EN", "DE", "FR", "IT", "PT", "EU", "Ajuste", "Motivo original", "Texto"]}}
          rows={{table}}
          columnAlign={{["right", "left", "left", "right", "right", "right", "right", "right", "right", "right", "right", "left", "left"]}}
        />
      </Stack>
    </Stack>
  );
}}
"""
    CANVAS.write_text(tsx, encoding="utf-8")


if __name__ == "__main__":
    main()
