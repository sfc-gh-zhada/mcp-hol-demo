#!/usr/bin/env python3
"""Generate Snowflake seed SQL from the public Banking77 CSV files."""

import csv
import sys
from collections import defaultdict
from pathlib import Path


def sql_string(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def read_rows(path: Path) -> list[tuple[str, str]]:
    with path.open(newline="", encoding="utf-8") as source:
        reader = csv.reader(source)
        header = next(reader, None)
        if header != ["text", "category"]:
            raise SystemExit(f"unexpected CSV header in {path}: {header}")
        return [(row[0], row[1]) for row in reader if len(row) == 2]


def write_table(output, table: str, rows: list[tuple[str, str]]) -> None:
    output.write(f"CREATE OR REPLACE TABLE MCP_HOL.SUPPORT.{table} (TEXT VARCHAR, LABEL VARCHAR);\n\n")
    for offset in range(0, len(rows), 500):
        batch = rows[offset : offset + 500]
        output.write(f"INSERT INTO MCP_HOL.SUPPORT.{table} (TEXT, LABEL) VALUES\n")
        output.write(",\n".join(f"({sql_string(text)}, {sql_string(label)})" for text, label in batch))
        output.write(";\n\n")


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: build_banking77_sql.py TRAIN_CSV TEST_CSV OUTPUT_SQL")

    train_rows = read_rows(Path(sys.argv[1]))
    test_rows = read_rows(Path(sys.argv[2]))

    probe_counts: dict[str, int] = defaultdict(int)
    training: list[tuple[str, str]] = []
    probe: list[tuple[str, str]] = []
    for row in train_rows:
        label = row[1]
        if probe_counts[label] < 2:
            probe.append(row)
            probe_counts[label] += 1
        else:
            training.append(row)

    if len(probe_counts) != 77 or len(probe) != 154:
        raise SystemExit("expected 77 labels and a 154-row probe split")

    with Path(sys.argv[3]).open("w", encoding="utf-8") as output:
        output.write("-- Generated from PolyAI Banking77 (CC BY 4.0).\n")
        output.write("-- Source: https://github.com/PolyAI-LDN/task-specific-datasets/tree/master/banking_data\n")
        output.write("-- B77_PROBE contains the first two training examples per label; B77_TEST is the publisher's test split.\n\n")
        write_table(output, "B77_TRAIN", training)
        write_table(output, "B77_PROBE", probe)
        write_table(output, "B77_TEST", test_rows)
        output.write("SELECT 'B77_TRAIN' AS DATASET, COUNT(*) AS ROWS, COUNT(DISTINCT LABEL) AS LABELS FROM MCP_HOL.SUPPORT.B77_TRAIN\n")
        output.write("UNION ALL SELECT 'B77_PROBE', COUNT(*), COUNT(DISTINCT LABEL) FROM MCP_HOL.SUPPORT.B77_PROBE\n")
        output.write("UNION ALL SELECT 'B77_TEST', COUNT(*), COUNT(DISTINCT LABEL) FROM MCP_HOL.SUPPORT.B77_TEST\n")
        output.write("ORDER BY DATASET;\n")


if __name__ == "__main__":
    main()