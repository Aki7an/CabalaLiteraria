#!/usr/bin/env python3
"""Exporta la tabla de hitos de CifraLetra desde PlayFab.

Crea las estadísticas del título (si faltan) y escribe un CSV con una fila
por jugador:

  playfab_id, nombre, primer_acceso_utc, tutorial_completado_utc,
  primer_puzle_utc, ultimo_puzle_utc, puzles_completados, ultima_actividad_utc

Las fechas están en UTC. La clave se lee de PLAYFAB_SECRET_KEY o de
tools/playfab_secret.txt y no se imprime.

Uso:
  python tools/export_playfab_milestones.py
  python tools/export_playfab_milestones.py --setup
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

TITLE_ID = "1BC2FD"
OUT_PATH = Path(__file__).resolve().parent / "out" / "playfab_milestones.csv"

DATA_KEYS = [
    "ms_first_access",
    "ms_tutorial_completed",
    "ms_first_puzzle",
    "ms_last_puzzle",
    "ms_puzzles_completed",
    "ms_last_activity",
]

STAT_NAMES = [
    "MsFirstAccess",
    "MsTutorialCompleted",
    "MsFirstPuzzle",
    "MsLastPuzzle",
    "MsPuzzlesCompleted",
    "MsLastActivity",
]

COLUMNS = [
    "playfab_id",
    "nombre",
    "primer_acceso_utc",
    "tutorial_completado_utc",
    "primer_puzle_utc",
    "ultimo_puzle_utc",
    "puzles_completados",
    "ultima_actividad_utc",
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
    payload = json.dumps(body).encode()
    last_error = "error desconocido"
    for attempt in range(4):
        request = urllib.request.Request(
            url,
            data=payload,
            headers={
                "Content-Type": "application/json",
                "X-SecretKey": secret,
                "X-ReportErrorAsSuccess": "true",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                parsed = json.loads(response.read().decode())
        except urllib.error.HTTPError as exc:
            if exc.code == 429 and attempt < 3:
                time.sleep(2 * (attempt + 1))
                continue
            detail = exc.read().decode(errors="replace")
            raise RuntimeError(f"{path} HTTP {exc.code}: {detail[:300]}") from exc
        code = int(parsed.get("code", 0))
        if code == 200:
            return parsed.get("data") or {}
        last_error = f"{parsed.get('error')} {parsed.get('errorMessage')}".strip()
        if code == 429 or "TooManyRequests" in last_error:
            time.sleep(2 * (attempt + 1))
            continue
        raise RuntimeError(f"{path} failed: {last_error}")
    raise RuntimeError(f"{path} failed: {last_error}")


def ensure_statistics(secret: str) -> None:
    for name in STAT_NAMES:
        try:
            playfab(
                "/Admin/CreatePlayerStatisticDefinition",
                secret,
                {
                    "StatisticName": name,
                    "VersionChangeInterval": "Never",
                    "AggregationMethod": "Last",
                },
            )
            print(f"Estadística creada: {name}")
        except RuntimeError as exc:
            message = str(exc).lower()
            if "conflict" in message or "already" in message or "exist" in message:
                print(f"Estadística ya existe: {name}")
                continue
            raise


def all_players_segment_id(secret: str) -> str:
    data = playfab("/Admin/GetAllSegments", secret, {})
    for segment in data.get("Segments") or []:
        if str(segment.get("Name", "")).strip().lower() == "all players":
            return str(segment.get("Id", ""))
    raise RuntimeError("No se encontró el segmento All Players en PlayFab.")


def iter_players(secret: str, segment_id: str):
    token = ""
    while True:
        body = {"SegmentId": segment_id, "MaxBatchSize": 1000}
        if token:
            body["ContinuationToken"] = token
        data = playfab("/Admin/GetPlayersInSegment", secret, body)
        for profile in data.get("PlayerProfiles") or []:
            yield profile
        token = str(data.get("ContinuationToken") or "")
        if not token:
            break


def user_values(secret: str, playfab_id: str) -> dict:
    data = playfab(
        "/Admin/GetUserData",
        secret,
        {"PlayFabId": playfab_id, "Keys": DATA_KEYS},
    )
    records = data.get("Data") or {}
    values = {}
    for key, entry in records.items():
        if isinstance(entry, dict):
            values[key] = str(entry.get("Value") or "")
        else:
            values[key] = str(entry or "")
    return values


def account_dates(secret: str, playfab_id: str) -> dict:
    data = playfab("/Admin/GetUserAccountInfo", secret, {"PlayFabId": playfab_id})
    info = data.get("UserInfo") or data.get("AccountInfo") or {}
    title = info.get("TitleInfo") or {}
    return {
        "first": str(title.get("FirstLogin") or title.get("Created") or info.get("Created") or ""),
        "activity": str(title.get("LastLogin") or ""),
        "name": str(title.get("DisplayName") or ""),
    }


def display_date(value: str) -> str:
    text = (value or "").strip()
    if len(text) < 19:
        return ""
    return text[:10] + " " + text[11:19]


def row_for(profile: dict, values: dict, account: dict) -> dict:
    count = values.get("ms_puzzles_completed", "")
    return {
        "playfab_id": str(profile.get("PlayerId") or profile.get("PlayFabId") or ""),
        "nombre": str(profile.get("DisplayName") or account.get("name") or ""),
        "primer_acceso_utc": display_date(
            values.get("ms_first_access") or account.get("first") or str(profile.get("Created") or "")
        ),
        "tutorial_completado_utc": display_date(values.get("ms_tutorial_completed", "")),
        "primer_puzle_utc": display_date(values.get("ms_first_puzzle", "")),
        "ultimo_puzle_utc": display_date(values.get("ms_last_puzzle", "")),
        "puzles_completados": count,
        "ultima_actividad_utc": display_date(
            values.get("ms_last_activity")
            or account.get("activity")
            or str(profile.get("LastLogin") or "")
        ),
    }


def export_table(secret: str) -> int:
    segment_id = all_players_segment_id(secret)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    written = 0
    with_tutorial = 0
    with_puzzle = 0
    with OUT_PATH.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=COLUMNS)
        writer.writeheader()
        for profile in iter_players(secret, segment_id):
            playfab_id = str(profile.get("PlayerId") or "")
            if not playfab_id:
                continue
            try:
                values = user_values(secret, playfab_id)
                account = account_dates(secret, playfab_id)
            except RuntimeError as exc:
                print(f"Aviso: {playfab_id} omitido ({exc})", file=sys.stderr)
                continue
            row = row_for(profile, values, account)
            writer.writerow(row)
            written += 1
            if row["tutorial_completado_utc"]:
                with_tutorial += 1
            if row["puzles_completados"] not in ("", "0"):
                with_puzzle += 1
            if written % 25 == 0:
                print(f"Exportados {written} jugadores...")
            time.sleep(0.12)
    print(f"Jugadores: {written}")
    print(f"Con tutorial completado: {with_tutorial}")
    print(f"Con al menos un puzle: {with_puzzle}")
    print(f"CSV: {OUT_PATH}")
    return written


def main() -> int:
    parser = argparse.ArgumentParser(description="Exporta los hitos de PlayFab a CSV.")
    parser.add_argument(
        "--setup",
        action="store_true",
        help="Solo crea las estadísticas del título, sin exportar jugadores.",
    )
    args = parser.parse_args()
    secret = load_secret()
    if not secret:
        print(
            "Falta la clave de PlayFab. Ponla en PLAYFAB_SECRET_KEY o en tools/playfab_secret.txt.",
            file=sys.stderr,
        )
        return 1
    ensure_statistics(secret)
    if args.setup:
        return 0
    export_table(secret)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
