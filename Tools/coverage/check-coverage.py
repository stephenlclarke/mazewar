#!/usr/bin/env python3
"""Check a SonarQube generic coverage report against a minimum percentage."""

import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def coverage_percentage(path: Path) -> float:
    lines = ET.parse(path).getroot().findall(".//lineToCover")
    if not lines:
        return 0.0
    return 100 * sum(line.attrib.get("covered") == "true" for line in lines) / len(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Check generated coverage.")
    parser.add_argument("--minimum", type=float, default=85.0)
    parser.add_argument("--coverage", type=Path, required=True)
    args = parser.parse_args()
    actual = coverage_percentage(args.coverage)
    print(f"Swift coverage: {actual:.2f}%")
    if actual + 1e-9 < args.minimum:
        print(f"Swift coverage is below required {args.minimum:.2f}%", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
