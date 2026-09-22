from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
DATA = Path(ROOT / "tools" / "star_review_compact.json").read_text(encoding="utf-8")
OUT = Path(
    r"C:\Users\aki7a\.cursor\projects\c-Users-aki7a-Documents-Godot-CifraLetra\canvases\estrellas-puzles.canvas.tsx"
)

tsx = f'''import {{
  BarChart,
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
  useHostTheme,
}} from "cursor/canvas";

type RowData = {{
  l: string;
  i: number;
  m: string;
  p: string;
  c: string;
  o: number;
  s: number;
  w: string;
  t: string;
  n: number;
}};

const ROWS: RowData[] = {DATA};

const LANGS = [
  {{ value: "es", label: "Espanol" }},
  {{ value: "en", label: "Ingles" }},
  {{ value: "de", label: "Aleman" }},
  {{ value: "fr", label: "Frances" }},
  {{ value: "it", label: "Italiano" }},
  {{ value: "pt", label: "Portugues" }},
  {{ value: "eu", label: "Euskera" }},
];

const KEYS: Record<string, string> = {{
  es: "EL/LA/DE/QUE y LOS/LAS + S final; dobles LL/RR/CC (vocal al lado); fechas EL N DE MES o dd-mm-aaaa.",
  en: "THE/AND/OF/TO; -ING y posesivos. Sin regla de consonantes dobles.",
  de: "DER/DIE/DAS/UND/EIN. Palabras compuestas largas: menos pistas cortas, suele ser mas dificil.",
  fr: "LE/LA/LES/DE/DES/ET/QUE. Articulos y LE N MOIS en efemerides.",
  it: "IL/LO/LA/DI/CHE. IL N MESE en fechas.",
  pt: "DE/DA/DO/OS/AS/QUE. Fechas EM N DE MES.",
  eu: "ETA, sufijos -A/-AK. Pocas palabras de 1-3 letras: de media mas dificil. Algunos textos siguen en ingles.",
}};

function modeLabel(m: string) {{
  return m === "c" ? "Desafio" : "Rapido";
}}

function packLabel(p: string) {{
  return p === "d" ? "Diario" : "Catalogo";
}}

export default function PuzzleStars() {{
  const theme = useHostTheme();
  const [lang, setLang] = useCanvasState("lang", "es");
  const [mode, setMode] = useCanvasState("mode", "all");
  const [pack, setPack] = useCanvasState("pack", "all");

  const filtered = ROWS.filter((r) => {{
    if (r.l !== lang) return false;
    if (mode !== "all" && r.m !== mode) return false;
    if (pack !== "all" && r.p !== pack) return false;
    return true;
  }});

  const quick = filtered.filter((r) => r.m === "q");
  const crypto = filtered.filter((r) => r.m === "c");
  const changed = filtered.filter((r) => r.s !== r.o);

  function countStars(list: RowData[], star: number) {{
    return list.filter((r) => r.s === star).length;
  }}

  const bar = [1, 2, 3, 4, 5].map((star) => ({{
    label: String(star),
    value: countStars(filtered, star),
  }}));

  const rows = filtered.map((r) => [
    String(r.i),
    modeLabel(r.m),
    packLabel(r.p),
    r.c,
    r.o === r.s ? String(r.s) : r.o + " -> " + r.s,
    r.w,
    r.t,
  ]);

  return (
    <Stack gap={{20}}>
      <Stack gap={{6}}>
        <H1>Estrellas por puzle e idioma</H1>
        <Text tone="secondary">
          Rapidos 1-3. Desafios 3-5. Criterio: palabras cortas respecto a la media
          del idioma, fechas, y en espanol dobles LL/RR/CC y plurales LOS/LAS + S.
          letters_init vacio: el juego regala letras solo en rapidos de 1-2 estrellas.
        </Text>
      </Stack>

      <Row gap={{12}} wrap>
        <Select value={{lang}} onChange={{setLang}} options={{LANGS}} />
        <Select
          value={{mode}}
          onChange={{setMode}}
          options={{[
            {{ value: "all", label: "Todos los modos" }},
            {{ value: "q", label: "Rapidos" }},
            {{ value: "c", label: "Desafios" }},
          ]}}
        />
        <Select
          value={{pack}}
          onChange={{setPack}}
          options={{[
            {{ value: "all", label: "Catalogo + diarios" }},
            {{ value: "c", label: "Solo catalogo" }},
            {{ value: "d", label: "Solo diarios" }},
          ]}}
        />
      </Row>

      <Grid columns={{4}} gap={{12}}>
        <Stat value={{String(filtered.length)}} label="Puzles en vista" />
        <Stat value={{String(quick.length)}} label="Rapidos" />
        <Stat value={{String(crypto.length)}} label="Desafios" />
        <Stat value={{String(changed.length)}} label="Estrellas cambiadas" tone="accent" />
      </Grid>

      <Callout tone="info" title={{"Claves de " + (LANGS.find((x) => x.value === lang)?.label ?? lang)}}>
        {{KEYS[lang]}}
      </Callout>

      <Stack gap={{8}}>
        <H2>Distribucion de estrellas</H2>
        <BarChart
          categories={{bar.map((b) => b.label + " est.")}}
          series={{[{{ name: "Puzles", data: bar.map((b) => b.value) }}]}}
          height={{180}}
        />
        <Text tone="secondary">
          Fuente: data/frases_*.json. Recalculo 2026-09-22. {{filtered.length}} puzles en el filtro.
        </Text>
      </Stack>

      <Stack gap={{8}}>
        <Row gap={{8}} align="center">
          <H2>Justificacion</H2>
          <Pill>{{filtered.length}} filas</Pill>
        </Row>
        <Table
          stickyHeader
          striped
          headers={{["Index", "Modo", "Pack", "Tema", "Estrellas", "Por que", "Texto"]}}
          rows={{rows}}
          columnAlign={{["right", "left", "left", "left", "left", "left", "left"]}}
        />
      </Stack>

      <Text tone="secondary" style={{{{ color: theme.textSecondary }}}}>
        Un desafio en 3 no regala letras. Un rapido en 1 o 2 si revela vocales o consonantes.
      </Text>
    </Stack>
  );
}}
'''

OUT.write_text(tsx, encoding="utf-8")
print("wrote", OUT, OUT.stat().st_size)
