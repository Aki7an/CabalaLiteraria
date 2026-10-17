#!/usr/bin/env python3
"""Rewrite CompetitiveV2_* PlayFab stats to the new packed ranking.

Reads the secret from PLAYFAB_SECRET_KEY or tools/playfab_secret.txt.
Does not print the secret.
"""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

TITLE_ID = "1BC2FD"
STAR_PLACE = 1_000_000
PUZZLE_PLACE = 10_000
AID_PLACE = 100
COUNT_MAX = 99
STAR_MAX = 2047
TEST_STAR_CAP = 10
LEGACY_AVERAGE_BASE = 151
LEGACY_AID_BASE = 50
LEGACY_FAILED_BASE = 50

STATS = [
    "CompetitiveV2_Global_All",
    "CompetitiveV2_Global_Quick",
    "CompetitiveV2_Global_Cryptogram",
    "CompetitiveV2_Cita_All",
    "CompetitiveV2_Cita_Quick",
    "CompetitiveV2_Cita_Cryptogram",
    "CompetitiveV2_Efemeride_All",
    "CompetitiveV2_Efemeride_Quick",
    "CompetitiveV2_Efemeride_Cryptogram",
    "CompetitiveV2_Curiosidades_All",
    "CompetitiveV2_Curiosidades_Quick",
    "CompetitiveV2_Curiosidades_Cryptogram",
    "CompetitiveV2_Fragmento_All",
    "CompetitiveV2_Fragmento_Quick",
    "CompetitiveV2_Fragmento_Cryptogram",
]


def load_secret() -> str:
    env = os.environ.get("PLAYFAB_SECRET_KEY", "").strip()
    if env:
        return env
    secret_path = Path(__file__).resolve().parent / "playfab_secret.txt"
    if secret_path.is_file():
        return secret_path.read_text(encoding="utf-8").strip()
    return ""


def playfab(path: str, secret: str, body: dict) -> dict:
    url = f"https://{TITLE_ID}.playfabapi.com{path}"
    request = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers={
            "Content-Type": "application/json",
            "X-SecretKey": secret,
            "X-ReportErrorAsSuccess": "true",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.loads(response.read().decode())
    if int(payload.get("code", 0)) != 200:
        raise RuntimeError(
            f"{path} failed: {payload.get('error')} {payload.get('errorMessage')}"
        )
    return payload.get("data") or {}


def decode_legacy(value: int) -> dict:
    remaining = max(int(value), 0)
    fewer_failed = remaining % LEGACY_FAILED_BASE
    remaining //= LEGACY_FAILED_BASE
    fewer_aids = remaining % LEGACY_AID_BASE
    remaining //= LEGACY_AID_BASE
    average_tenths = remaining % LEGACY_AVERAGE_BASE
    stars = remaining // LEGACY_AVERAGE_BASE
    completed = 0
    if average_tenths > 0:
        completed = int(round(stars * 10 / average_tenths))
    return {
        "stars": stars,
        "completed": completed,
        "aids": LEGACY_AID_BASE - 1 - fewer_aids,
        "failed": LEGACY_FAILED_BASE - 1 - fewer_failed,
    }


def encode(stars: int, puzzles: int, aids: int, failed: int) -> int:
    stars = max(0, min(STAR_MAX, int(stars)))
    puzzles = max(0, min(COUNT_MAX, int(puzzles)))
    aids = max(0, min(COUNT_MAX, int(aids)))
    failed = max(0, min(COUNT_MAX, int(failed)))
    return (
        stars * STAR_PLACE
        + (COUNT_MAX - puzzles) * PUZZLE_PLACE
        + (COUNT_MAX - aids) * AID_PLACE
        + (COUNT_MAX - failed)
    )


def scaled(value: int, factor: float) -> int:
    return max(0, int(round(value * factor)))


def fetch_stat_entries(secret: str, stat: str) -> list[dict]:
    entries: list[dict] = []
    start = 0
    while True:
        data = playfab(
            "/Admin/GetLeaderboard",
            secret,
            {
                "StatisticName": stat,
                "StartPosition": start,
                "MaxResultsCount": 100,
            },
        )
        page = data.get("Leaderboard") or []
        if not page:
            break
        entries.extend(page)
        if len(page) < 100:
            break
        start += len(page)
        time.sleep(0.12)
    return entries


def main() -> int:
    secret = load_secret()
    if not secret:
        print(
            "Missing PlayFab secret. Set PLAYFAB_SECRET_KEY or create "
            "tools/playfab_secret.txt (gitignored)."
        )
        return 1

    players: dict[str, dict] = {}
    for stat in STATS:
        print(f"fetch {stat}")
        try:
            entries = fetch_stat_entries(secret, stat)
        except RuntimeError as error:
            print(f"  skip: {error}")
            continue
        for entry in entries:
            playfab_id = str(entry.get("PlayFabId") or "")
            if not playfab_id:
                continue
            player = players.setdefault(
                playfab_id,
                {"name": str(entry.get("DisplayName") or ""), "stats": {}},
            )
            if not player["name"]:
                player["name"] = str(entry.get("DisplayName") or "")
            player["stats"][stat] = decode_legacy(int(entry.get("StatValue") or 0))
        time.sleep(0.12)

    renamed = 0
    updated = 0
    for playfab_id, player in players.items():
        name = player["name"]
        is_test_bot = "_CL26" in name
        stats = player["stats"]
        global_stars = int((stats.get("CompetitiveV2_Global_All") or {}).get("stars") or 0)
        total_stars = max(
            [global_stars]
            + [int(record.get("stars") or 0) for record in stats.values()]
        )
        factor = 1.0
        if is_test_bot and total_stars > TEST_STAR_CAP:
            factor = TEST_STAR_CAP / float(total_stars)

        new_name = name.replace("_CL26", "_TEST") if is_test_bot else name
        if new_name != name and new_name.strip():
            try:
                playfab(
                    "/Admin/UpdateUserTitleDisplayName",
                    secret,
                    {"PlayFabId": playfab_id, "DisplayName": new_name[:25]},
                )
                renamed += 1
                print(f"rename {name} -> {new_name}")
            except RuntimeError as error:
                print(f"rename failed {name}: {error}")
            time.sleep(0.12)

        statistics = []
        for stat, record in stats.items():
            stars = scaled(int(record["stars"]), factor)
            puzzles = scaled(int(record["completed"]), factor)
            aids = scaled(int(record["aids"]), factor)
            failed = scaled(int(record["failed"]), factor)
            if stars > 0 and puzzles < 1:
                puzzles = 1
            statistics.append(
                {
                    "StatisticName": stat,
                    "Value": encode(stars, puzzles, aids, failed),
                }
            )
        if not statistics:
            continue
        playfab(
            "/Server/UpdatePlayerStatistics",
            secret,
            {
                "PlayFabId": playfab_id,
                "ForceUpdate": True,
                "Statistics": statistics,
            },
        )
        updated += 1
        time.sleep(0.15)

    print(f"done players={len(players)} renamed={renamed} updated={updated}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
