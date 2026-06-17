# Turtle Robot Handoff: Stage 12 Output

## What You Are Receiving

This handoff converts the haulage route idea into a small-robot command package.

The main output is:

```text
outputs/stage12_turtle_cmd_vel_schedule.csv
```

This is a time-indexed velocity command schedule for a Turtle-style differential-drive robot.

It is paired with:

```text
outputs/stage12_turtle_route_waypoints.csv
outputs/stage12_turtle_robot_handoff.json
```

## What The Files Mean

| File | Meaning |
| --- | --- |
| `stage12_turtle_route_waypoints.csv` | Route points in meters for the lab-scale haulage path |
| `stage12_turtle_cmd_vel_schedule.csv` | Commands to publish to the robot over time |
| `stage12_turtle_robot_handoff.json` | Machine-readable description of topic, message type, and column mapping |

## ROS Topic

Publish commands to:

```text
/cmd_vel
```

Message type:

```text
geometry_msgs/Twist
```

## Column Mapping

Use the CSV columns like this:

| CSV Column | ROS Field |
| --- | --- |
| `linear_velocity_mps` | `Twist.linear.x` |
| `angular_velocity_radps` | `Twist.angular.z` |

The command rate is:

```text
10 Hz
```

So each row is spaced by approximately:

```text
0.1 s
```

## How To Use It

For each row in `stage12_turtle_cmd_vel_schedule.csv`:

1. Read `linear_velocity_mps`.
2. Read `angular_velocity_radps`.
3. Create a `geometry_msgs/Twist` message.
4. Set:

```text
msg.linear.x  = linear_velocity_mps
msg.angular.z = angular_velocity_radps
```

5. Publish to `/cmd_vel`.
6. Wait until the next timestamp.

## Safety Procedure

First test:

1. Put the robot on blocks or lift wheels off the ground.
2. Confirm wheel direction.
3. Confirm angular direction.
4. Run only the first few seconds.
5. Move to an open floor area.
6. Keep an emergency stop available.
7. Then run the full schedule slowly.

The current file is an **open-loop playback**. It does not yet use odometry feedback to correct the route.

## What To Log During Robot Tests

Please log:

| Signal | Why |
| --- | --- |
| `/cmd_vel` | commanded motion |
| `/odom` | actual robot motion |
| battery voltage, if available | rough energy proxy |
| timestamp | synchronization |
| test notes | floor surface, payload, issues |

Useful comparison later:

```text
commanded path vs odometry path
commanded speed vs measured speed
travel time
tracking error
```

## What This Demonstrates

The Turtle robot is not pretending to be a full haul truck. It is demonstrating the control logic:

```text
route segment
    -> speed command
    -> robot motion
    -> telemetry log
```

Later, the command schedule should be replaced with a closed-loop path follower:

```text
waypoints + odometry
    -> Pure Pursuit / controller
    -> /cmd_vel
    -> robot
```

## Current Limits

- open-loop command playback;
- no odometry correction yet;
- no physical grade effect on the robot yet;
- grade is included as route metadata;
- energy is not estimated unless battery/motor telemetry is logged.

This is the first hardware handoff, meant to get safe robot motion and telemetry collection started.
