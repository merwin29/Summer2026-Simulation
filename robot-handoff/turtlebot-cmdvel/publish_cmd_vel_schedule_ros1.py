#!/usr/bin/env python3
"""Publish a generated TurtleBot /cmd_vel schedule with ROS 1.

Safety behavior:
- The script is a dry run unless --arm is provided.
- Published commands are capped by --max-linear and --max-angular.
- A zero Twist is sent before and after playback.
- Ctrl+C sends a zero Twist before shutdown.
"""

from __future__ import annotations

import argparse
import csv
import math
import time
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class CommandRow:
    time_s: float
    phase: str
    segment_id: int
    linear_x: float
    angular_z: float


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Publish a TurtleBot cmd_vel schedule from CSV using ROS 1."
    )
    parser.add_argument(
        "csv",
        nargs="?",
        default="stage12_turtle_cmd_vel_schedule.csv",
        help="Path to the cmd_vel schedule CSV.",
    )
    parser.add_argument("--topic", default="/cmd_vel", help="ROS velocity command topic.")
    parser.add_argument(
        "--arm",
        action="store_true",
        help="Actually publish motion commands. Without this, only dry-run output is printed.",
    )
    parser.add_argument("--duration", type=float, default=None)
    parser.add_argument("--time-scale", type=float, default=1.0)
    parser.add_argument("--linear-scale", type=float, default=1.0)
    parser.add_argument("--angular-scale", type=float, default=1.0)
    parser.add_argument("--max-linear", type=float, default=0.18)
    parser.add_argument("--max-angular", type=float, default=0.65)
    parser.add_argument("--preview-every", type=int, default=25)
    return parser.parse_args()


def read_schedule(csv_path: Path) -> list[CommandRow]:
    if not csv_path.is_file():
        raise FileNotFoundError(f"CSV file not found: {csv_path}")

    rows: list[CommandRow] = []
    with csv_path.open("r", newline="", encoding="utf-8-sig") as file:
        reader = csv.DictReader(file)
        for row_number, row in enumerate(reader, start=2):
            try:
                rows.append(
                    CommandRow(
                        time_s=float(row["time_s"]),
                        phase=row["command_phase"],
                        segment_id=int(float(row["segmentId"])),
                        linear_x=float(row["linear_velocity_mps"]),
                        angular_z=float(row["angular_velocity_radps"]),
                    )
                )
            except (KeyError, ValueError) as exc:
                raise ValueError(f"Invalid command row {row_number}: {row}") from exc
    if not rows:
        raise ValueError("CSV schedule has no command rows.")
    return rows


def clamp(value: float, limit: float) -> float:
    if not math.isfinite(value):
        raise ValueError(f"Non-finite command value: {value}")
    return max(-abs(limit), min(abs(limit), value))


def scaled_command(row: CommandRow, args: argparse.Namespace) -> tuple[float, float]:
    return (
        clamp(row.linear_x * args.linear_scale, args.max_linear),
        clamp(row.angular_z * args.angular_scale, args.max_angular),
    )


def dry_run(rows: list[CommandRow], args: argparse.Namespace) -> int:
    print("DRY RUN ONLY: pass --arm to publish to the robot.")
    print(f"CSV: {Path(args.csv).resolve()}")
    print(f"Rows: {len(rows)}")
    print(f"Command topic: {args.topic}")
    print(f"Duration: {rows[-1].time_s - rows[0].time_s:.2f} s")

    for idx, row in enumerate(rows):
        if args.duration is not None and row.time_s > args.duration:
            break
        if idx % max(1, args.preview_every) != 0 and idx != len(rows) - 1:
            continue
        linear, angular = scaled_command(row, args)
        print(
            f"t={row.time_s:6.2f}s seg={row.segment_id:2d} "
            f"phase={row.phase:>5s} linear.x={linear: .3f} angular.z={angular: .3f}"
        )
    return 0


def publish_ros1(rows: list[CommandRow], args: argparse.Namespace) -> int:
    try:
        import rospy
        from geometry_msgs.msg import Twist
    except ImportError as exc:
        raise RuntimeError(
            "ROS 1 Python packages were not found. Source your ROS environment first, "
            "for example: source /opt/ros/noetic/setup.bash"
        ) from exc

    rospy.init_node("haulage_cmd_vel_schedule_player", anonymous=True)
    publisher = rospy.Publisher(args.topic, Twist, queue_size=10)

    def make_twist(linear: float = 0.0, angular: float = 0.0) -> Twist:
        msg = Twist()
        msg.linear.x = float(linear)
        msg.angular.z = float(angular)
        return msg

    def stop_robot() -> None:
        zero = make_twist()
        for _ in range(10):
            publisher.publish(zero)
            time.sleep(0.02)

    print("ARMED: publishing cmd_vel schedule.")
    print(f"Topic: {args.topic}")
    print("Press Ctrl+C to stop and publish zero velocity.")

    try:
        stop_robot()
        start_wall = time.monotonic()
        first_time = rows[0].time_s

        for row in rows:
            if rospy.is_shutdown():
                break
            if args.duration is not None and row.time_s > args.duration:
                break

            relative_time = (row.time_s - first_time) * args.time_scale
            wait_s = start_wall + relative_time - time.monotonic()
            if wait_s > 0:
                time.sleep(wait_s)

            linear, angular = scaled_command(row, args)
            publisher.publish(make_twist(linear, angular))

        stop_robot()
    except KeyboardInterrupt:
        print("\nInterrupted. Sending zero velocity.")
        stop_robot()

    print("Playback complete. Zero velocity sent.")
    return 0


def main() -> int:
    args = parse_args()
    if args.time_scale <= 0:
        raise ValueError("--time-scale must be positive.")
    rows = read_schedule(Path(args.csv))
    if not args.arm:
        return dry_run(rows, args)
    return publish_ros1(rows, args)


if __name__ == "__main__":
    raise SystemExit(main())
