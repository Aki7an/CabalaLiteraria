#!/usr/bin/env python3
"""Scale non-Spanish star totals to match Spanish bucket totals."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
LANGS = ["en", "de", "fr", "it", "pt", "eu"]


def is_daily(item: dict) -> bool:
    return str(item.get("pack", "")).lower() == "daily"


def is_quick(item: dict) -> bool:
    return str(item.get("game_mode", "")).lower() == "quick"


def bucket_of(item: dict) -> str:
    if is_daily(item):
        return "daily"
    return "quick" if is_quick(item) else "challenge"


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


def adjust_bucket(items: list[dict], target: int) -> dict:
    current = [int(p.get("difficulty", 1)) for p in items]
    total = sum(current)
    if total == target:
        return {"changed": 0, "final_index": None, "raw_sum": total, "final_sum": total}

    desired = [c * target / total for c in current]
    rounded = []
    for item, raw in zip(items, desired):
        lo, hi = star_range(item)
        rounded.append(clamp(apply_decimal_rule(raw), lo, hi))

    def can_move(i: int, delta: int) -> bool:
        lo, hi = star_range(items[i])
        return lo <= rounded[i] + delta <= hi

    leftover = target - sum(rounded)
    final_index = None
    while leftover != 0:
        step = 1 if leftover > 0 else -1
        candidates = [i for i in range(len(items)) if can_move(i, step)]
        if not candidates:
            raise RuntimeError("cannot reach target %s from %s" % (target, sum(rounded)))
        # Prefer the puzzle whose scaled value was closest to .5 in this direction.
        def score(i: int) -> tuple:
            frac = desired[i] - int(desired[i])
            if step > 0:
                closeness = frac
            else:
                closeness = 1.0 - frac
            return (closeness, -int(items[i].get("index", 0)))

        pick = max(candidates, key=score)
        rounded[pick] += step
        leftover -= step
        final_index = int(items[pick].get("index", 0))

    changed = 0
    for item, stars in zip(items, rounded):
        if int(item.get("difficulty", 0)) != stars:
            changed += 1
        item["difficulty"] = stars
    return {
        "changed": changed,
        "final_index": final_index,
        "raw_sum": total,
        "final_sum": sum(rounded),
    }


def main() -> None:
    es = json.loads((DATA / "frases_es.json").read_text(encoding="utf-8"))
    targets = {
        "quick": sum(int(p["difficulty"]) for p in es if bucket_of(p) == "quick"),
        "challenge": sum(int(p["difficulty"]) for p in es if bucket_of(p) == "challenge"),
        "daily": sum(int(p["difficulty"]) for p in es if bucket_of(p) == "daily"),
    }
    print("ES targets", targets)

    for lang in LANGS:
        path = DATA / f"frases_{lang}.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        by_bucket = {"quick": [], "challenge": [], "daily": []}
        for item in data:
            by_bucket[bucket_of(item)].append(item)
        print(lang)
        for name, group in by_bucket.items():
            info = adjust_bucket(group, targets[name])
            print(
                " ",
                name,
                "from",
                info["raw_sum"],
                "to",
                info["final_sum"],
                "changed",
                info["changed"],
                "ajuste_final",
                info["final_index"],
            )
        path.write_text(json.dumps(data, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
