# TurtleBot `/cmd_vel` Test Package

This folder turns the Stage 12 robot handoff into something the team can test on a TurtleBot-style robot.

The first hardware goal is modest:

> Publish the generated velocity schedule to `/cmd_vel`, confirm safe robot motion, and log telemetry for comparison.

This is **open-loop playback**. It does not yet use odometry feedback to correct the path.

## Files

| File | Purpose |
| --- | --- |
| `stage12_turtle_cmd_vel_schedule.csv` | Time-indexed command schedule generated from the haulage route |
| `stage12_turtle_route_waypoints.csv` | Robot-scale route waypoints |
| `stage12_turtle_robot_handoff.json` | Metadata describing topic, message type, and column mapping |
| `validate_cmd_vel_schedule.py` | Checks timing, speed caps, and stop command |
| `publish_cmd_vel_schedule_ros2.py` | ROS 2 publisher for `/cmd_vel` |
| `publish_cmd_vel_schedule_ros1.py` | ROS 1 publisher for `/cmd_vel` |

## CSV To ROS Mapping

| CSV column | ROS message field |
| --- | --- |
| `linear_velocity_mps` | `geometry_msgs/Twist.linear.x` |
| `angular_velocity_radps` | `geometry_msgs/Twist.angular.z` |

The generated schedule is approximately 10 Hz and currently lasts about 95 seconds.

## Before Connecting To A Robot

Run validation:

```bash
python3 validate_cmd_vel_schedule.py stage12_turtle_cmd_vel_schedule.csv
```

Expected values:

- max `linear.x`: about `0.18 m/s`
- max `angular.z`: about `0.65 rad/s`
- final row: zero stop command

Run a dry preview:

```bash
python3 publish_cmd_vel_schedule_ros2.py stage12_turtle_cmd_vel_schedule.csv
```

or for ROS 1:

```bash
python3 publish_cmd_vel_schedule_ros1.py stage12_turtle_cmd_vel_schedule.csv
```

Without `--arm`, the publisher does **not** send commands to the robot.

## First Hardware Test: Wheels Lifted

Use the first hardware test only to confirm command direction.

For ROS 2:

```bash
python3 publish_cmd_vel_schedule_ros2.py stage12_turtle_cmd_vel_schedule.csv \
  --arm \
  --duration 5 \
  --time-scale 2.0 \
  --max-linear 0.08 \
  --max-angular 0.30
```

For ROS 1:

```bash
python3 publish_cmd_vel_schedule_ros1.py stage12_turtle_cmd_vel_schedule.csv \
  --arm \
  --duration 5 \
  --time-scale 2.0 \
  --max-linear 0.08 \
  --max-angular 0.30
```

Check:

- wheels rotate in the expected forward direction;
- positive angular command turns in the expected direction;
- Ctrl+C sends zero velocity;
- robot does not continue moving after the script exits.

## Second Hardware Test: Short Floor Run

Use an open area and keep an emergency stop ready.

```bash
python3 publish_cmd_vel_schedule_ros2.py stage12_turtle_cmd_vel_schedule.csv \
  --arm \
  --duration 10 \
  --time-scale 2.0 \
  --max-linear 0.08 \
  --max-angular 0.30
```

Repeat with longer duration only after the short test behaves safely.

## Full Open-Loop Playback

After short tests pass:

```bash
python3 publish_cmd_vel_schedule_ros2.py stage12_turtle_cmd_vel_schedule.csv \
  --arm \
  --time-scale 1.0 \
  --max-linear 0.18 \
  --max-angular 0.65
```

The full run is still open-loop. The robot may drift from the intended waypoint route because the schedule does not yet correct using odometry.

## What To Log

Minimum robot telemetry:

| Signal | Why |
| --- | --- |
| `/cmd_vel` | commanded linear and angular velocity |
| `/odom` | actual robot motion |
| battery voltage, if available | rough energy proxy |
| timestamps | synchronization |
| notes | floor surface, payload, issues, emergency stops |

ROS 2 example:

```bash
ros2 bag record /cmd_vel /odom
```

ROS 1 example:

```bash
rosbag record /cmd_vel /odom
```

## Meeting Demonstration Plan

1. Show `stage12_turtle_route_waypoints.csv`.
2. Show `stage12_turtle_cmd_vel_schedule.csv`.
3. Run `validate_cmd_vel_schedule.py`.
4. Run the publisher without `--arm` as a dry run.
5. If a robot is available, run the 5-second wheels-lifted test.
6. Decide whether the next task is open-loop floor testing or closed-loop path following.

## Next Engineering Step

The next better controller should be:

```text
waypoints + odometry feedback
    -> path follower
    -> /cmd_vel
    -> TurtleBot
```

The likely first closed-loop option is Pure Pursuit or a simple waypoint-following controller.
