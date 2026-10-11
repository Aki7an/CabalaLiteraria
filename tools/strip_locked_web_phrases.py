"""Blank phrase text of puzzles the web demo does not unlock.

Keeps index, image, category and the rest of the card metadata.
Clears the phrase and its hints in every language file.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
IMAGES = DATA / "images"
LANGS = ("es", "en", "de", "fr", "eu", "it", "pt")
TEXT_KEYS = (
	"text",
	"letters_init",
	"description_init",
	"description_end",
	"hint_1",
	"hint_2",
	"hint_3",
	"hint_4",
	"source",
)
EXTENSIONS = (".png", ".PNG", ".jpg", ".jpeg", ".webp")


def normalize_category(raw: str) -> str:
	key = raw.strip().lower()
	for src, dst in (
		("á", "a"), ("é", "e"), ("è", "e"), ("ë", "e"),
		("í", "i"), ("ó", "o"), ("ú", "u"), ("ñ", "n"),
		("ä", "a"), ("ö", "o"), ("ü", "u"),
	):
		key = key.replace(src, dst)
	if key in {"efemeride", "efemerides", "event", "events", "ereignis", "gertaera", "evenement", "evento"}:
		return "efemeride"
	if key in {
		"cita", "citas", "cita celebre", "personajes", "personaje", "personalidades",
		"personalidad", "ilustres", "ilustre", "personen", "beruhmtheiten", "characters",
		"appointment", "famous quote", "famous quotes", "citation", "citation celebre",
		"zitat", "aipu", "aipu ospetsua", "citazione", "citazione celebre", "citacao",
		"citacao celebre",
	}:
		return "cita"
	if key in {"curiosidades", "curiosities", "curiosites", "kuriositaten", "kuriositateak", "curiosita"}:
		return "curiosidades"
	if key in {
		"fragmento", "fragment", "fragmentos", "fragmento literario", "literatura",
		"literature", "literary fragment", "literary fragments", "fragment litteraire",
		"literarisches fragment", "fragmentu literarioa", "frammento letterario",
	}:
		return "fragmento"
	if key in {"daily", "reto diario", "daily challenge", "taglich", "defi du jour", "eguneko erronka", "sfida del giorno", "desafio diario"}:
		return "daily"
	return key


def game_mode(item: dict) -> str:
	raw = str(item.get("game_mode", "")).strip().lower().replace("á", "a").replace("é", "e")
	if raw in {"cryptogram", "criptograma", "crypto", "desafio", "desafío", "challenge"}:
		return "cryptogram"
	if raw in {"quick", "rapido", "fast"}:
		return "quick"
	return "cryptogram" if int(item.get("difficulty", 1) or 1) >= 3 else "quick"


def has_image(image_number: int) -> bool:
	if image_number < 0:
		return False
	for stem in (f"image{image_number}", f"Image{image_number}"):
		for ext in EXTENSIONS:
			if (IMAGES / f"{stem}{ext}").is_file():
				return True
	return False


def is_daily(item: dict) -> bool:
	return str(item.get("pack", "")).strip().lower() == "daily"


def free_sort_key(item: dict):
	return (
		0 if game_mode(item) == "quick" else 1,
		int(item.get("image_number", 0) or 0),
		int(item.get("difficulty", 1) or 1),
		int(item.get("index", 0) or 0),
	)


def free_ids(items: list) -> set[int]:
	groups: dict[str, list] = {}
	for item in items:
		if not isinstance(item, dict) or is_daily(item):
			continue
		if "text" not in item:
			continue
		if not has_image(int(item.get("image_number", -1) or -1)):
			continue
		key = normalize_category(str(item.get("category", "")))
		if not key or key == "daily":
			continue
		groups.setdefault(key, []).append(item)
	chosen = set()
	for arr in groups.values():
		arr.sort(key=free_sort_key)
		chosen.add(int(arr[0].get("index", -1)))
	return chosen


def main() -> int:
	write = "--write" in sys.argv
	for lang in LANGS:
		path = DATA / f"frases_{lang}.json"
		items = json.loads(path.read_text(encoding="utf-8"))
		chosen = free_ids(items)
		cleared = 0
		kept_preview = []
		for item in items:
			if not isinstance(item, dict):
				continue
			index = int(item.get("index", -1) or -1)
			if index in chosen:
				kept_preview.append(
					f"{index} {normalize_category(str(item.get('category', '')))} {game_mode(item)} img={item.get('image_number')}"
				)
				continue
			had_text = any(str(item.get(key, "")).strip() for key in TEXT_KEYS)
			if not had_text:
				continue
			for key in TEXT_KEYS:
				if key in item:
					item[key] = ""
			cleared += 1
		print(f"{lang}: keep {sorted(chosen)} clear {cleared}")
		for line in kept_preview:
			print(f"  {line}")
		if write:
			path.write_text(json.dumps(items, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
