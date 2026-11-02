#!/usr/bin/env python3
"""Resume coste y tokens de las sesiones locales de OpenCode.

Lee en modo solo lectura la base SQLite que OpenCode mantiene en
``~/.local/share/opencode/opencode.db`` y agrupa las sesiones por modelo,
variante o día. No modifica la base ni envía datos a ningún sitio.

Ejemplos:

    ./coste_sesiones_opencode.py --days 30
    ./coste_sesiones_opencode.py --days 30 --model deepseek
    ./coste_sesiones_opencode.py --days 30 --group variant
    ./coste_sesiones_opencode.py --days 7 --json

El esquema de la base no es una API pública: si OpenCode cambia las tablas,
el script deja de funcionar. Contrástalo con ``opencode stats``.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

DEFAULT_DB = Path.home() / ".local" / "share" / "opencode" / "opencode.db"


def parse_model(raw: str | None) -> dict:
    """El campo model guarda un JSON: proveedor, modelo y variante opcional."""
    if not raw:
        return {}
    try:
        value = json.loads(raw)
    except (TypeError, ValueError):
        return {}
    return value if isinstance(value, dict) else {}


def load_sessions(db: Path, days: int, model_filter: str | None) -> list[dict]:
    if not db.is_file():
        sys.exit(f"No existe la base de sesiones: {db}")

    since = None
    if days > 0:
        since = int((datetime.now() - timedelta(days=days)).timestamp() * 1000)

    query = """
        SELECT model, cost,
               tokens_input, tokens_output, tokens_reasoning,
               tokens_cache_read, tokens_cache_write,
               time_created
        FROM session_v2
    """
    params: tuple = ()
    if since is not None:
        query += " WHERE time_created >= ?"
        params = (since,)

    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    try:
        rows = list(conn.execute(query, params))
    except sqlite3.DatabaseError as exc:
        sys.exit(f"No se pudo leer la base ({exc}). ¿Cambió el esquema?")
    finally:
        conn.close()

    sessions = []
    for (raw, cost, inp, out, rea, cache_r, cache_w, created) in rows:
        meta = parse_model(raw)
        model_id = meta.get("id", "(desconocido)")
        if model_filter and model_filter.lower() not in model_id.lower():
            continue
        sessions.append(
            {
                "provider": meta.get("providerID", "?"),
                "model": model_id,
                "variant": meta.get("variant", "(sin variante)"),
                "cost": cost or 0.0,
                "input": inp or 0,
                "output": out or 0,
                "reasoning": rea or 0,
                "cache_read": cache_r or 0,
                "cache_write": cache_w or 0,
                "created": created,
            }
        )
    return sessions


def group_key(session: dict, group: str) -> str:
    if group == "day":
        return datetime.fromtimestamp(session["created"] / 1000).strftime("%Y-%m-%d")
    if group == "variant":
        return f"{session['model']} #{session['variant']}"
    return f"{session['provider']}/{session['model']}"


def summarize(sessions: list[dict], group: str) -> list[dict]:
    buckets: dict[str, dict] = defaultdict(
        lambda: {
            "sessions": 0,
            "cost": 0.0,
            "input": 0,
            "output": 0,
            "reasoning": 0,
            "cache_read": 0,
            "cache_write": 0,
        }
    )
    for session in sessions:
        bucket = buckets[group_key(session, group)]
        bucket["sessions"] += 1
        for field in ("cost", "input", "output", "reasoning", "cache_read", "cache_write"):
            bucket[field] += session[field]
    return [
        {"key": key, **value}
        for key, value in sorted(buckets.items(), key=lambda item: -item[1]["cost"])
    ]


def human(n: float) -> str:
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.0f}k"
    return str(int(n))


def print_table(rows: list[dict]) -> None:
    header = (
        f"{'Grupo':44} {'ses':>3} {'coste':>8} {'$/ses':>8} "
        f"{'entrada':>9} {'salida':>8} {'razón.':>8} {'caché':>10}"
    )
    print(header)
    print("-" * len(header))
    for row in rows:
        per_session = row["cost"] / row["sessions"] if row["sessions"] else 0.0
        print(
            f"{row['key'][:44]:44} {row['sessions']:>3} "
            f"{row['cost']:>8.3f} {per_session:>8.3f} "
            f"{human(row['input']):>9} {human(row['output']):>8} "
            f"{human(row['reasoning']):>8} {human(row['cache_read']):>10}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Coste y tokens de las sesiones locales de OpenCode."
    )
    parser.add_argument("--db", type=Path, default=DEFAULT_DB, help="ruta de opencode.db")
    parser.add_argument(
        "--days",
        type=int,
        default=30,
        help="ventana en días; 0 para todas las sesiones (por defecto 30)",
    )
    parser.add_argument("--model", help="filtra por texto en el id del modelo")
    parser.add_argument(
        "--group",
        choices=("model", "variant", "day"),
        default="model",
        help="criterio de agrupación (por defecto model)",
    )
    parser.add_argument("--json", action="store_true", help="salida JSON")
    args = parser.parse_args()

    sessions = load_sessions(args.db, args.days, args.model)
    if not sessions:
        sys.exit("No hay sesiones en la ventana indicada.")

    rows = summarize(sessions, args.group)

    if args.json:
        print(json.dumps({"sessions": len(sessions), "groups": rows}, indent=2, default=str))
        return

    print_table(rows)
    total_cost = sum(row["cost"] for row in rows)
    total_input = sum(row["input"] for row in rows)
    cache_read = sum(row["cache_read"] for row in rows)
    reasoning = sum(row["reasoning"] for row in rows)
    output = sum(row["output"] for row in rows)
    share = 100 * cache_read / (total_input + cache_read) if total_input + cache_read else 0
    print(
        f"\n{len(sessions)} sesiones · ${total_cost:.3f} · "
        f"${total_cost / len(sessions):.3f} por sesión"
    )
    print(
        f"caché sobre entrada total: {share:.1f}% · "
        f"razonamiento sobre salida: {100 * reasoning / (output + reasoning) if output + reasoning else 0:.1f}%"
    )


if __name__ == "__main__":
    main()
