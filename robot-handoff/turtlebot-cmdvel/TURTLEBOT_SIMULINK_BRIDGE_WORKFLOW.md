# TurtleBot Simulink Bridge Workflow

This document defines the cleaned project workflow for moving from the haulage simulation output to TurtleBot motion.

The current robot-side objective is:

```text
velocity CSV
    -> Simulink timeseries inputs
    -> ROS /cmd_vel publisher
    -> TurtleBot motion
    -> /odom measurement
    -> path and command comparison
```

This workflow does not modify any individual contributor folders. It uses the project-level `robot-handoff/turtlebot-cmdvel` package as the shared handoff point.

## 1. Current Status

The robot-side bridge has been demonstrated in a simple Simulink model:

- the TurtleBot can receive velocity commands from Simulink;
- the command source can be a CSV file;
- the robot can move through `/cmd_vel`;
- odometry can be read from `/odom`;
- the measured robot path can be plotted.

The current control mode is open-loop playback. The robot receives a schedule of velocity commands, but it does not yet correct its motion using waypoint error.

## 2. Files Used By The Shared Workflow

| File | Purpose |
| --- | --- |
| `stage12_turtle_cmd_vel_schedule.csv` | Time schedule of forward and angular velocity commands |
| `stage12_turtle_route_waypoints.csv` | Robot-scale route waypoints |
| `validate_cmd_vel_schedule.py` | Safety and format validation before robot testing |
| `load_turtlebot_cmdvel_timeseries.m` | Converts the CSV into `vel_ts` and `ang_vel_ts` for Simulink |
| `prepare_turtlebot_open_loop_workspace.m` | One-command setup script for Simulink playback |
| `publish_cmd_vel_schedule_ros1.py` | Optional ROS1 Python publisher |
| `publish_cmd_vel_schedule_ros2.py` | Optional ROS2 Python publisher |

## 3. Meaning Of The CSV Columns

The main command file is:

```text
stage12_turtle_cmd_vel_schedule.csv
```

The important columns are:

| Column | Unit | Meaning |
| --- | --- | --- |
| `time_s` | s | command timestamp |
| `linear_velocity_mps` | m/s | forward velocity command |
| `angular_velocity_radps` | rad/s | yaw-rate command |
| `segmentId` | index | route segment represented by the command |
| `command_phase` | text | drive, turn, or stop |

ROS uses:

```text
linear_velocity_mps    -> geometry_msgs/Twist.linear.x
angular_velocity_radps -> geometry_msgs/Twist.angular.z
```

## 4. Scaling Rule

The `linear_velocity_mps` column is already in meters per second.

Therefore:

```matlab
linear_velocity_mps / 3.6
```

should not be described as a unit conversion. It is a lab safety slowdown.

Use this convention:

```matlab
linearScale = 1.0;    % execute generated speed
linearScale = 1/3.6;  % slow first lab test
```

The shared loader makes this explicit:

```matlab
cmdVelHandoff = load_turtlebot_cmdvel_timeseries( ...
    "stage12_turtle_cmd_vel_schedule.csv", ...
    1/3.6, ...
    1.0);
```

This creates:

```text
vel_ts      -> scaled linear velocity command, m/s
ang_vel_ts  -> scaled angular velocity command, rad/s
```

## 5. Open-Loop Simulink Test Procedure

Use this for the current working demonstration.

1. Start ROS and TurtleBot bringup using the lab ROS1 setup.
2. Open MATLAB from the Ubuntu/ROS computer.
3. Initialize ROS in MATLAB.
4. Go to this folder:

```matlab
cd('/home/linuxpc/Downloads/Summer2026-Simulation-main/robot-handoff/turtlebot-cmdvel')
```

5. Prepare the workspace:

```matlab
prepare_turtlebot_open_loop_workspace
```

6. Confirm these variables exist:

```matlab
whos vel_ts ang_vel_ts cmdVelHandoff
```

7. Open the TurtleBot Simulink model used for robot playback.
8. Configure the model:

```matlab
set_param(gcs, 'EnablePacing', 'on')
set_param(gcs, 'PacingRate', '1')
set_param(gcs, 'SolverType', 'Fixed-step')
set_param(gcs, 'FixedStep', '0.1')
```

9. Keep the first test slow:

```matlab
cmdVelHandoff.maxCommandLinear_mps
cmdVelHandoff.maxCommandAngular_radps
```

10. Run the model with the robot in an open area.

## 6. What To Log

For every test, save:

| Signal | Why |
| --- | --- |
| `/cmd_vel` | command sent to the robot |
| `/odom` | measured robot response |
| test notes | floor surface, payload, speed scale, issues |

Minimum comparison table:

| Metric | Meaning |
| --- | --- |
| commanded linear velocity | from CSV or `/cmd_vel` |
| measured linear velocity | from `/odom` |
| commanded angular velocity | from CSV or `/cmd_vel` |
| measured angular velocity | from `/odom` |
| final x-y position | from `/odom` |
| intended endpoint | from waypoint file |

## 7. Current Limitation

The current playback approach does not use path error.

That means:

```text
CSV command says what to do
robot executes as best it can
odom records what actually happened
```

If the robot drifts, slips, or turns differently than expected, the command schedule does not automatically correct it.

## 8. Next Step: Waypoint + Odometry Feedback

The next controller should use the waypoints and odometry together:

```text
route waypoints
    + current /odom pose
    -> path tracking error
    -> corrected linear/angular velocity
    -> /cmd_vel
    -> TurtleBot
```

Recommended first implementation:

1. Load `stage12_turtle_route_waypoints.csv`.
2. Subscribe to `/odom`.
3. Find the next waypoint ahead of the robot.
4. Compute heading error:

```text
heading_error = desired_heading - current_heading
```

5. Command:

```text
linear.x  = limited forward speed
angular.z = Kp * heading_error
```

6. Advance to the next waypoint when the robot is close enough.
7. Keep all commands capped by safety limits.

This is a simple waypoint follower. Pure Pursuit can replace it later once the route and odometry pipeline are stable.

## 9. Meeting Explanation

Use this explanation:

```text
The robot bridge now has a working open-loop path. The simulation produces a CSV of linear and angular velocity commands. Simulink loads those commands as timeseries inputs and publishes them to /cmd_vel. The TurtleBot moves, while /odom records what actually happened. The waypoint file describes the intended route, but the current robot execution is still open-loop. Our next step is to use odometry feedback and waypoints to correct the robot path in real time.
```

