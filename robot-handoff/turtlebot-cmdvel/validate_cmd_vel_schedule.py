#!/usr/bin/env python3
"""Validate a TurtleBot /cmd_vel CSV schedule before robot testing.

This script does not require ROS. Run it on any machine with Python 3 before
publishing commands to a physical robot.
"""

from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path


REQUIRED_COLUMNS = {
    "time_s",
    "command_phase",
    "segmentId",
    "linear_velocity_mps",
    "angular_velocity_radps",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate a generated TurtleBot /cmd_vel schedule CSV."
    )
    parser.add_argument(
        "csv",
        nargs="?",
        default="stage12_turtle_cmd_vel_schedule.csv",
        help="Path to the cmd_vel schedule CSV.",
    )
    parser.add_argument(
        "--max-linear",
        type=float,
        default=0.20,
        help="Maximum allowed absolute linear speed in m/s.",
    )
    parser.add_argument(
        "--max-angular",
        type=float,
        default=0.75,
        help="Maximum allowed absolute angular speed in rad/s.",
    )
    parser.add_argument(
        "--expected-dt",
        type=float,
        default=0.10,
        help="Expected time step in seconds.",
    )
    parser.add_argument(
        "--dt-tolerance",
        type=float,
        default=1e-6,
        help="Allowed timing tolerance in seconds.",
    )
    return parser.parse_args()


def read_rows(csv_path: Path) -> list[dict[str, str]]:
    if not csv_path.is_file():
        raise FileNotFoundError(f"CSV file not found: {csv_path}")

    with csv_path.open("r", newline="", encoding="utf-8-sig") as file:
        reader = csv.DictReader(file)
        missing = REQUIRED_COLUMNS.difference(reader.fieldnames or [])
        if missing:
            raise ValueError(f"CSV is missing required columns: {sorted(missing)}")
        return list(reader)


def to_float(row: dict[str, str], column: str, row_number: int) -> float:
    try:
        value = float(row[column])
    except (KeyError, ValueError) as exc:
        raise ValueError(f"Invalid {column!r} at row {row_number}: {row}") from exc
    if not math.isfinite(value):
        raise ValueError(f"Non-finite {column!r} at row {row_number}: {value}")
    return value


def main() -> int:
    args = parse_args()
    csv_path = Path(args.csv)
    rows = read_rows(csv_path)

    if not rows:
        raise ValueError("CSV has no command rows.")

    times: list[float] = []
    linear: list[float] = []
    angular: list[float] = []
    phases: dict[str, int] = {}
    segments: set[int] = set()

    warnings: list[str] = []

    for row_number, row in enumerate(rows, start=2):
        time_s = to_float(row, "time_s", row_number)
        linear_velocity = to_float(row, "linear_velocity_mps", row_number)
        angular_velocity = to_float(row, "angular_velocity_radps", row_number)

        try:
            segment_id = int(float(row["segmentId"]))
        except ValueError as exc:
            raise ValueError(f"Invalid segmentId at row {row_number}: {row}") from exc

        phase = row["command_phase"].strip()
        phases[phase] = phases.get(phase, 0) + 1
        segments.add(segment_id)
        times.append(time_s)
        linear.append(linear_velocity)
        angular.append(angular_velocity)

    for idx in range(1, len(times)):
        dt = times[idx] - times[idx - 1]
        if dt <= 0:
            warnings.append(
                f"time is not strictly increasing at row {idx + 2}: dt={dt:.6g}"
            )
        elif abs(dt - args.expected_dt) > args.dt_tolerance:
            warnings.append(
                f"unexpected dt at row {idx + 2}: dt={dt:.6g} s"
            )

    max_linear = max(abs(value) for value in linear)
    max_angular = max(abs(value) for value in angular)

    if max_linear > args.max_linear:
        warnings.append(
            f"max |linear.x| {max_linear:.3f} m/s exceeds cap {args.max_linear:.3f}"
        )
    if max_angular > args.max_angular:
        warnings.append(
            f"max |angular.z| {max_angular:.3f} rad/s exceeds cap {args.max_angular:.3f}"
        )

    if abs(linear[-1]) > 1e-9 or abs(angular[-1]) > 1e-9:
        warnings.append("last row is not a zero stop command")

    print("TurtleBot cmd_vel schedule summary")
    print("----------------------------------")
    print(f"file:             {csv_path}")
    print(f"rows:             {len(rows)}")
    print(f"duration:         {times[-1] - times[0]:.2f} s")
    print(f"time range:       {times[0]:.2f} to {times[-1]:.2f} s")
    print(f"max |linear.x|:   {max_linear:.3f} m/s")
    print(f"max |angular.z|:  {max_angular:.3f} rad/s")
    print(f"segments:         {sorted(segments)}")
    print(f"phases:           {phases}")

    if warnings:
        print("\nWarnings")
        for warning in warnings:
            print(f"- {warning}")
        return 2

    print("\nValidation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
