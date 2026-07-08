# TurtleBot Waypoint Following Next Step

This is the next step after open-loop velocity playback.

Open-loop playback uses:

```text
time -> linear/angular velocity -> /cmd_vel
```

Waypoint following uses:

```text
waypoints + current odometry -> corrected linear/angular velocity -> /cmd_vel
```

The key difference is feedback. The robot uses `/odom` to decide how to correct its motion.

## 1. Why This Step Matters

The velocity CSV can make the robot move, but it cannot correct drift. If the robot slips, starts at a slightly different angle, or turns differently from the model, open-loop playback keeps sending the original commands.

Waypoint following makes the robot ask:

```text
Where am I now?
Where is the next waypoint?
What turn command moves me toward it?
```

That is the first move toward a real robot controller.

## 2. Controller Loop

The loop is:

```text
load waypoint file
subscribe to /odom
compute current x, y, theta
select active waypoint
compute heading error
publish limited /cmd_vel
advance waypoint when close enough
stop at final waypoint
```

## 3. Files Added For This Step

| File | Purpose |
| --- | --- |
| `load_turtlebot_waypoints.m` | Loads `stage12_turtle_route_waypoints.csv` into MATLAB |
| `compute_turtlebot_waypoint_command.m` | Pure MATLAB waypoint control law |
| `run_turtlebot_waypoint_follower_ros1.m` | ROS1/MATLAB script that publishes closed-loop `/cmd_vel` |
| `turtlebot_waypoint_follower_log.csv` | Output log created after a waypoint test |

## 4. Basic Control Law

The active waypoint is:

```text
target = [x_waypoint, y_waypoint]
```

The robot pose from odometry is:

```text
pose = [x_robot, y_robot, theta_robot]
```

The controller computes:

```text
dx = x_waypoint - x_robot
dy = y_waypoint - y_robot
desired_heading = atan2(dy, dx)
heading_error = desired_heading - theta_robot
```

Then it commands:

```text
angular.z = K_heading * heading_error
linear.x = limited forward speed
```

If the heading error is large, the robot turns in place before driving forward. This is slower but safer for first tests.

## 5. MATLAB Dry Test Without Robot

This checks the controller logic without ROS:

```matlab
cd('/home/linuxpc/Downloads/Summer2026-Simulation-main/robot-handoff/turtlebot-cmdvel')
waypointHandoff = load_turtlebot_waypoints();

params = struct();
params.maxLinear_mps = 0.05;
params.maxAngular_radps = 0.40;
params.kHeading = 1.20;
params.kDistance = 0.45;
params.switchRadius_m = 0.15;
params.turnInPlaceAngle_rad = pi/4;

x = 0;
y = 0;
theta = 0;
activeWaypoint = 2;

[v, omega, activeWaypoint, done, debug] = compute_turtlebot_waypoint_command( ...
    x, y, theta, waypointHandoff.xy_m, activeWaypoint, params)
```

Expected result:

- `v` should be positive and small;
- `omega` should be near zero if the robot is facing the next waypoint;
- `done` should be false.

## 6. ROS1 Hardware Test

Use this only after the robot is safely connected and `/odom` is active.

1. Start TurtleBot bringup.
2. Start MATLAB and connect to ROS:

```matlab
setenv('ROS_MASTER_URI', 'http://192.168.0.200:11311')
setenv('ROS_IP', '192.168.0.165')
setenv('ROS_HOSTNAME', '192.168.0.165')
rosinit('http://192.168.0.200:11311', 'NodeHost', '192.168.0.165')
```

Use the correct IP addresses for the lab setup.

3. Confirm topics:

```matlab
rostopic list
```

The list should include:

```text
/cmd_vel
/odom
```

4. Move to the shared handoff folder:

```matlab
cd('/home/linuxpc/Downloads/Summer2026-Simulation-main/robot-handoff/turtlebot-cmdvel')
```

5. Run the follower:

```matlab
run_turtlebot_waypoint_follower_ros1
```

The script writes:

```text
turtlebot_waypoint_follower_log.csv
turtlebot_waypoints_in_odom_frame.csv
```

At startup, the script reads the first `/odom` message and aligns the route waypoints to the robot's current odom pose. This means the route starts where the robot is placed. The robot should be physically pointed in the direction of the first route segment before running the script.

## 7. Safety Settings For First Test

The first waypoint follower uses conservative defaults:

```text
maxLinear_mps = 0.05
maxAngular_radps = 0.40
switchRadius_m = 0.15
maxRunTime_s = 420
```

This means the robot moves slowly and switches to the next waypoint when it gets within 15 cm of the current target.

The full route is about 15.4 m long, so a slow full-route test can take several minutes. For a short partial test, reduce `maxRunTime_s` inside `run_turtlebot_waypoint_follower_ros1.m`.

The robot also sends a zero stop command when the script ends or is interrupted.

## 8. What To Compare

After the test, compare:

| Data | Source |
| --- | --- |
| intended route | `stage12_turtle_route_waypoints.csv` |
| measured route | `turtlebot_waypoint_follower_log.csv` |
| transformed route | `turtlebot_waypoints_in_odom_frame.csv` |
| command history | `cmd_linear_mps`, `cmd_angular_radps` |
| tracking behavior | distance and heading error columns |

The first success criterion is not perfect path tracking. The first success criterion is:

```text
The robot moves from waypoint to waypoint and stops safely.
```

## 9. Simulink Version Of The Same Logic

The same controller can be rebuilt in Simulink using these blocks:

```text
ROS Subscribe /odom
    -> Bus Selector for position and orientation
    -> yaw calculation
    -> MATLAB Function waypoint controller
    -> Bus Assignment into geometry_msgs/Twist
    -> ROS Publish /cmd_vel
```

The MATLAB Function block should implement the same logic as:

```text
compute_turtlebot_waypoint_command.m
```

The first Simulink version should output these diagnostic signals:

- active waypoint index;
- distance to waypoint;
- heading error;
- commanded linear speed;
- commanded angular speed;
- route done flag.

## 10. Next Improvement After This

Once the simple waypoint follower works, the next improvement is Pure Pursuit:

```text
find lookahead point on route
compute curvature to that point
convert curvature into angular velocity
publish smoother /cmd_vel
```

Pure Pursuit will be smoother than point-to-point heading control, but the point-to-point controller is easier to debug first.
