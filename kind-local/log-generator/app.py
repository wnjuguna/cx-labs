#!/usr/bin/env python3
"""Stream UTF-8 log files line-by-line to stdout at a fixed global rate; loop at EOF."""

from __future__ import annotations

import glob
import os
import sys
import time


def _env_float(name: str, default: float) -> float:
    raw = os.environ.get(name, "").strip()
    if not raw:
        return default
    return float(raw)


def _discover_paths(log_dir: str) -> list[str]:
    files_env = os.environ.get("LOG_GENERATOR_FILES", "").strip()
    if files_env:
        names = [x.strip() for x in files_env.split(",") if x.strip()]
        paths = []
        for name in names:
            p = name if os.path.isabs(name) else os.path.join(log_dir, name)
            paths.append(p)
        return sorted(paths)

    pattern = os.environ.get("LOG_GENERATOR_GLOB", "*.log")
    return sorted(glob.glob(os.path.join(log_dir, pattern)))


def main() -> None:
    log_dir = os.environ.get("LOG_GENERATOR_LOG_DIR", "/logs")
    lines_per_sec = _env_float("LOG_GENERATOR_LINES_PER_SEC", 5.0)
    if lines_per_sec <= 0:
        print("LOG_GENERATOR_LINES_PER_SEC must be positive", file=sys.stderr)
        sys.exit(1)

    utf8_errors = os.environ.get("LOG_GENERATOR_UTF8_ERRORS", "strict").lower()
    if utf8_errors not in ("strict", "replace"):
        print(
            "LOG_GENERATOR_UTF8_ERRORS must be strict or replace",
            file=sys.stderr,
        )
        sys.exit(1)

    prefix = os.environ.get("LOG_GENERATOR_PREFIX", "")
    delay = 1.0 / lines_per_sec

    while True:
        paths = [p for p in _discover_paths(log_dir) if os.path.isfile(p)]
        if not paths:
            print(
                f"log-generator: no log files under {log_dir!r} "
                f"(glob={os.environ.get('LOG_GENERATOR_GLOB', '*.log')!r}); retrying in 30s",
                file=sys.stderr,
                flush=True,
            )
            time.sleep(30)
            continue

        handles: list[tuple[str, object]] = []
        try:
            for p in paths:
                f = open(p, encoding="utf-8", errors=utf8_errors, newline="")
                handles.append((p, f))

            print(
                f"log-generator: streaming {len(handles)} file(s) at {lines_per_sec} line(s)/sec",
                file=sys.stderr,
                flush=True,
            )

            while True:
                for _path, fh in handles:
                    line = fh.readline()
                    if not line:
                        fh.seek(0)
                        line = fh.readline()
                    if not line:
                        time.sleep(delay)
                        continue
                    text = line.rstrip("\r\n")
                    if prefix:
                        print(f"{prefix}{text}", flush=True)
                    else:
                        print(text, flush=True)
                    time.sleep(delay)
        finally:
            for _, fh in handles:
                try:
                    fh.close()
                except OSError:
                    pass


if __name__ == "__main__":
    main()
