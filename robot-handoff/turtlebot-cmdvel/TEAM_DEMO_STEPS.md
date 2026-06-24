# TurtleBot Team Demonstration Steps

This guide explains how to demonstrate the Stage 12 robot output on a TurtleBot-style robot.

The purpose of this first test is simple:

```text
MATLAB / Simulink route output
    -> velocity schedule CSV
    -> ROS /cmd_vel messages
    -> TurtleBot motion
    -> logged robot response
```

This is an open-loop playback test. The robot receives speed commands, but it does not yet correct its path using odometry feedback.

## 1. What The Team Should Understand First

Before running anything, explain these three files.

| File | Meaning |
| --- | --- |
| `stage12_turtle_route_waypoints.csv` | Robot-scale route points that represent the haulage path |
| `stage12_turtle_cmd_vel_schedule.csv` | Time-based speed and turn commands for the robot |
| `stage12_turtle_robot_handoff.json` | Metadata that explains how the CSV maps into ROS |

The command schedule has these important columns:

| CSV column | Meaning |
| --- | --- |
| `time_s` | Command time in seconds |
| `command_phase` | Whether the robot is driving, turning, or stopping |
| `segmentId` | Route segment being represented |
| `linear_velocity_mps` | Forward speed command |
| `angular_velocity_radps` | Turning speed command |
| `grade_pct` | Route grade represented by that command row |
| `ros_topic` | Target ROS topic, currently `/cmd_vel` |

ROS uses this mapping:

```text
linear_velocity_mps   -> geometry_msgs/Twist.linear.x
angular_velocity_radps -> geometry_msgs/Twist.angular.z
```

## 2. Demonstration Roles

For a live robot demo, use three roles.

| Role | Responsibility |
| --- | --- |
| Presenter | Explains the purpose of the test and what each file means |
| Robot operator | Runs commands on the robot computer |
| Safety observer | Watches the robot and stops the test if motion is unsafe |

The safety observer should be able to stop the robot immediately using the robot's emergency stop, power switch, or keyboard interrupt.

## 3. Before The Meeting

On the robot computer, clone or copy this folder:

```bash
git clone https://github.com/merwin29/Summer2026-Simulation.git
cd Summer2026-Simulation/robot-handoff/turtlebot-cmdvel
```

If the folder is copied manually, make sure these files are present:

```text
stage12_turtle_cmd_vel_schedule.csv
stage12_turtle_route_waypoints.csv
stage12_turtle_robot_handoff.json
validate_cmd_vel_schedule.py
publish_cmd_vel_schedule_ros2.py
publish_cmd_vel_schedule_ros1.py
TEAM_DEMO_STEPS.md
```

## 4. Execution Environment

The demonstration uses two different environments.

| Environment | Main purpose |
| --- | --- |
| Windows workstation | MATLAB/Simulink review, CSV inspection, validation, and dry-run preview |
| Ubuntu/ROS robot computer | TurtleBot bringup, `/cmd_vel` publishing, robot motion, and telemetry logging |

ROS is not a separate operating system. It is robotics middleware that is most commonly run on Ubuntu Linux. The Windows workstation can be used to explain the workflow and inspect the generated outputs, but the actual TurtleBot motion test should run inside the robot's ROS environment.

Windows can be used for the non-hardware checks:

```powershell
python validate_cmd_vel_schedule.py stage12_turtle_cmd_vel_schedule.csv
python publish_cmd_vel_schedule_ros2.py stage12_turtle_cmd_vel_schedule.csv --duration 3 --preview-every 5
```

These commands validate and preview the schedule, but they do not move the robot unless the ROS publisher is armed and connected to the robot's ROS network.

For robot motion, use the Ubuntu/ROS computer connected to the TurtleBot:

```bash
cd Summer2026-Simulation/robot-handoff/turtlebot-cmdvel
python3 validate_cmd_vel_schedule.py stage12_turtle_cmd_vel_schedule.csv
python3 publish_cmd_vel_schedule_ros2.py stage12_turtle_cmd_vel_schedule.csv --duration 3 --preview-every 5
```

If the operator is working from a Windows laptop, the normal workflow is to connect to the robot computer through SSH:

```powershell
ssh ubuntu@ROBOT_IP_ADDRESS
```

Then run the robot-side commands inside the Ubuntu/ROS terminal.

Recommended division for the demonstration:

```text
Windows workstation:
    explain Simulink output, route waypoints, CSV schedule, and validation

Ubuntu/ROS robot computer:
    start TurtleBot bringup, publish /cmd_vel, record /odom, and run hardware tests
```

## 5. Step 1: Show The Route Output

Open the waypoint file:

```bash
head stage12_turtle_route_waypoints.csv
```

Explain:

- each row is a point on the robot-scale route;
- this is the lab version of the haul road geometry;
- later, these waypoints can become the input to a closed-loop path follower.

## 6. Step 2: Show The Velocity Output

Open the command schedule:

```bash
head stage12_turtle_cmd_vel_schedule.csv
```

Explain:

- the file is a time-indexed list of robot speed commands;
- forward speed goes to `/cmd_vel.linear.x`;
- turning speed goes to `/cmd_vel.angular.z`;
- this first version is intentionally capped at low robot speeds.

## 7. Step 3: Validate The Schedule Without ROS

Run:

```bash
python3 validate_cmd_vel_schedule.py stage12_turtle_cmd_vel_schedule.csv
```

Expected result:

```text
rows:             955
duration:         about 95.40 s
max |linear.x|:   about 0.180 m/s
max |angular.z|:  about 0.650 rad/s
Validation passed.
```

If this fails, do not run the robot. Fix the CSV or regenerate the output.

## 8. Step 4: Dry Run The Publisher

For ROS 2:

```bash
python3 publish_cmd_vel_schedule_ros2.py stage12_turtle_cmd_vel_schedule.csv \
  --duration 3 \
  --preview-every 5
```

For ROS 1:

```bash
python3 publish_cmd_vel_schedule_ros1.py stage12_turtle_cmd_vel_schedule.csv \
  --duration 3 \
  --preview-every 5
```

Explain:

- without `--arm`, the script only previews commands;
- it does not publish to the robot;
- this is the safe way to verify the schedule before hardware motion.

## 9. Step 5: Start The Robot Bringup

Use the normal TurtleBot startup process for the lab.

For ROS 2, the setup usually looks like:

```bash
source /opt/ros/<ros2_distro>/setup.bash
```

Then confirm topics:

```bash
ros2 topic list
```

For ROS 1, the setup usually looks like:

```bash
source /opt/ros/<ros1_distro>/setup.bash
```

Then confirm topics:

```bash
rostopic list
```

Before publishing generated commands, verify that the robot can already receive normal teleoperation commands.

## 10. Step 6: Confirm `/cmd_vel` And `/odom`

For ROS 2:

```bash
ros2 topic info /cmd_vel
ros2 topic echo /odom
```

For ROS 1:

```bash
rostopic info /cmd_vel
rostopic echo /odom
```

What to check:

- `/cmd_vel` exists;
- `/odom` exists;
- odometry changes when the robot moves;
- no other controller is fighting for `/cmd_vel`.

## 11. Step 7: Wheels-Lifted Test

Lift the robot wheels off the ground or place the robot on a safe stand.

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

- the wheels spin forward for positive `linear.x`;
- the robot turns in the expected direction for positive `angular.z`;
- pressing `Ctrl+C` stops the robot;
- the robot does not keep moving after the script exits.

If the direction is wrong, stop and check robot frame conventions before floor testing.

## 12. Step 8: Short Floor Test

Use a clear open area.

For ROS 2:

```bash
python3 publish_cmd_vel_schedule_ros2.py stage12_turtle_cmd_vel_schedule.csv \
  --arm \
  --duration 10 \
  --time-scale 2.0 \
  --max-linear 0.08 \
  --max-angular 0.30
```

For ROS 1:

```bash
python3 publish_cmd_vel_schedule_ros1.py stage12_turtle_cmd_vel_schedule.csv \
  --arm \
  --duration 10 \
  --time-scale 2.0 \
  --max-linear 0.08 \
  --max-angular 0.30
```

Watch for:

- unexpected spinning;
- drifting into obstacles;
- delayed stopping;
- wheel slip;
- command direction mismatch.

If anything feels unsafe, stop with `Ctrl+C` or the robot emergency stop.

## 13. Step 9: Record Robot Telemetry

Start logging before the floor test.

For ROS 2:

```bash
ros2 bag record /cmd_vel /odom
```

For ROS 1:

```bash
rosbag record /cmd_vel /odom
```

Minimum signals to save:

| Signal | Why it matters |
| --- | --- |
| `/cmd_vel` | what the simulation commanded |
| `/odom` | what the robot actually did |
| battery voltage, if available | rough energy or power proxy |
| notes | floor surface, payload, test duration, issues |

The important comparison is:

```text
commanded speed and turn rate
    vs
actual robot motion from odometry
```

## 14. Step 10: Longer Open-Loop Test

Only do this after the short floor test behaves safely.

For ROS 2:

```bash
python3 publish_cmd_vel_schedule_ros2.py stage12_turtle_cmd_vel_schedule.csv \
  --arm \
  --time-scale 1.0 \
  --max-linear 0.18 \
  --max-angular 0.65
```

For ROS 1:

```bash
python3 publish_cmd_vel_schedule_ros1.py stage12_turtle_cmd_vel_schedule.csv \
  --arm \
  --time-scale 1.0 \
  --max-linear 0.18 \
  --max-angular 0.65
```

This is the full open-loop schedule. The robot may drift because this version does not use odometry feedback for correction.

## 15. How To Explain The Demo To The Team

Use this short explanation:

```text
The haul truck simulation produces a route and speed profile. For the robot test, we scale that idea into a TurtleBot command schedule. Each row gives a forward speed and turn rate. The ROS publisher converts those rows into /cmd_vel messages. The robot executes the commands, and we log /cmd_vel and /odom so we can compare what we asked for against what the robot actually did.
```

## 16. What This Test Proves

This test proves:

- the MATLAB/Simulink output can be converted into robot commands;
- the robot team can run a repeatable route-speed experiment;
- command timing, speed caps, and stop behavior are testable;
- the project has a path from haulage simulation to physical robot demonstration.

This test does not yet prove:

- accurate path following;
- robust navigation;
- obstacle avoidance;
- energy optimization on the physical robot;
- closed-loop correction using odometry.

## 17. Next Engineering Step

The next version should replace open-loop playback with closed-loop waypoint following:

```text
route waypoints + /odom
    -> path follower
    -> safety limiter
    -> /cmd_vel
    -> TurtleBot
```

Good first choices:

- Pure Pursuit path follower;
- simple waypoint controller;
- Nav2 waypoint following if using ROS 2;
- battery and current logging for energy experiments.
