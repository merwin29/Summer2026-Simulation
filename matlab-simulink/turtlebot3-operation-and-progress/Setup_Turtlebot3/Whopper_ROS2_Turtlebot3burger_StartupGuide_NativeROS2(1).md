# TurtleBot3 Burger — Startup Guide (Native ROS2, Ubuntu 22.04)

## System Overview

| Component | Details |
|-----------|---------|
| Robot | TurtleBot3 Burger |
| Robot IP | `192.168.0.134` |
| Laptop OS | Ubuntu 22.04 (native ROS2 Humble — no Docker needed) |
| Laptop IP | `192.168.0.43` |
| ROS Domain ID | `0` |
| LiDAR | LDS-03 |
| DDS Middleware | CycloneDDS (required — default FastDDS fails over WiFi due to multicast blocking) |

---

## One-Time Setup (do once per machine)

### On the Laptop

Install CycloneDDS:

```bash
sudo apt install ros-humble-rmw-cyclonedds-cpp
```

Add to `~/.bashrc` so it persists across terminals:

```bash
echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc
source ~/.bashrc
```

### On the Robot (via SSH)

```bash
ssh ubuntu@192.168.0.134
# Password: turtlebot
sudo apt install ros-humble-rmw-cyclonedds-cpp
```

Add to robot's `~/.bashrc`:

```bash
echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc
source ~/.bashrc
```

---

## Quick Start (after one-time setup is done)

### Terminal 1 — SSH into Robot and Run Bringup

```bash
ssh ubuntu@192.168.0.134
# Password: turtlebot
```

Then inside SSH:

```bash
source /opt/ros/humble/setup.bash
source ~/turtlebot3_ws/install/setup.bash
export TURTLEBOT3_MODEL=burger
export LDS_MODEL=LDS-03
export ROS_DOMAIN_ID=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ros2 launch turtlebot3_bringup robot.launch.py
```

Leave this running.

### Terminal 2 — Laptop (verify connection)

```bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export CYCLONEDDS_URI='<CycloneDDS><Domain><Discovery><Peers><Peer address="192.168.0.134"/></Peers></Discovery></Domain></CycloneDDS>'
export ROS_DOMAIN_ID=0
ros2 topic list
```

You should see `/odom`, `/cmd_vel`, `/scan`, and others. Done.

---

## Every Session — Step by Step (detailed)

### Step 1 — Power on the Robot

1. Place the robot on a flat surface with clearance around it.
2. Flip the power switch on the TurtleBot3 base.
3. Wait ~30 seconds for the Raspberry Pi to boot.
4. The OpenCR board LEDs should light up once fully booted.

---

### Step 2 — SSH into the Robot

From a terminal on your laptop:

```bash
ssh ubuntu@192.168.0.134
# Password: turtlebot
```

> Both your laptop and robot must be on the same WiFi network.

---

### Step 3 — Launch Robot Bringup (on the Robot)

Inside the SSH session, run all of these:

```bash
source /opt/ros/humble/setup.bash
source ~/turtlebot3_ws/install/setup.bash
export TURTLEBOT3_MODEL=burger
export LDS_MODEL=LDS-03
export ROS_DOMAIN_ID=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ros2 launch turtlebot3_bringup robot.launch.py
```

**Expected output — look for these lines:**
```
[turtlebot3_ros-3] [turtlebot3_node]: Init DynamixelSDKWrapper
[turtlebot3_ros-3] [DynamixelSDKWrapper]: Succeeded to open the port(/dev/ttyACM0)!
[turtlebot3_ros-3] [turtlebot3_node]: Calibration End
[turtlebot3_ros-3] [turtlebot3_node]: Add Motors
[turtlebot3_ros-3] [turtlebot3_node]: Add Wheels
[turtlebot3_ros-3] [turtlebot3_node]: Add Sensors
[turtlebot3_ros-3] [turtlebot3_node]: Run!
[diff_drive_controller]: Init Odometry
[diff_drive_controller]: Run!
```

Leave this terminal open and running. Do **not** close it.

---

### Step 4 — Set Up the Laptop Terminal

Open a **new terminal** on your laptop and run:

```bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export CYCLONEDDS_URI='<CycloneDDS><Domain><Discovery><Peers><Peer address="192.168.0.134"/></Peers></Discovery></Domain></CycloneDDS>'
export ROS_DOMAIN_ID=0
```

> If you added `RMW_IMPLEMENTATION` to `~/.bashrc` in the one-time setup, you only need to export `CYCLONEDDS_URI` and `ROS_DOMAIN_ID`.

---

### Step 5 — Verify Connection

```bash
ros2 topic list
```

**You should see:**
```
/battery_state
/cmd_vel
/imu
/joint_states
/magnetic_field
/odom
/parameter_events
/robot_description
/rosout
/scan
/sensor_state
/tf
/tf_static
```

If `/cmd_vel` and `/odom` appear, the laptop and robot are communicating correctly.

---

### Step 6 — Teleoperate the Robot (Optional Test)

```bash
export TURTLEBOT3_MODEL=burger
ros2 run turtlebot3_teleop teleop_keyboard
```

| Key | Action |
|-----|--------|
| `W` | Forward |
| `X` | Backward |
| `A` | Rotate left |
| `D` | Rotate right |
| `S` | Stop |
| `Space` | Emergency stop |

---

### Step 7 — Open MATLAB (Optional)

```bash
/usr/local/MATLAB/R2026b/bin/matlab
```

In MATLAB, verify ROS2 connection:

```matlab
ros2("topic","list")
```

You should see the same robot topics listed above.

---

### Step 8 — MATLAB: Create Node and Publisher

Run once at the start of each MATLAB session:

```matlab
% Create ROS2 node and publisher
node = ros2node("/matlab_control");
pub  = ros2publisher(node, "/cmd_vel", "geometry_msgs/Twist");
msg  = ros2message("geometry_msgs/Twist");
```

---

### Step 9 — MATLAB: Movement Test

Make sure the robot has clear space before running.

```matlab
% Move forward for 2 seconds
msg.linear.x  = 0.1;   % m/s (max 0.22)
msg.angular.z = 0.0;
send(pub, msg);
pause(2);

% Stop
msg.linear.x  = 0.0;
msg.angular.z = 0.0;
send(pub, msg);
```

```matlab
% Turn in place for 2 seconds
msg.linear.x  = 0.0;
msg.angular.z = 0.5;   % rad/s, positive = left (max 2.84)
send(pub, msg);
pause(2);

% Stop
msg.angular.z = 0.0;
send(pub, msg);
```

---

### Step 10 — MATLAB: Continuous Odometry

This prints the robot's position and heading continuously as it moves.

```matlab
sub = ros2subscriber(node, "/odom", "nav_msgs/Odometry", @(msg) fprintf("x=%.3f  y=%.3f  yaw=%.3f rad\n", msg.pose.pose.position.x, msg.pose.pose.position.y, 2*atan2(msg.pose.pose.orientation.z, msg.pose.pose.orientation.w)));
```

The callback fires automatically every time a new odometry message arrives (~30 Hz). To stop it: `clear sub`

**To see x and y update, send a motor command** — do not push the robot by hand:

```matlab
% Move forward — watch x increase in the odometry output
msg.linear.x  = 0.2;
msg.angular.z = 0.0;
send(pub, msg);
```

```matlab
% Stop
msg.linear.x = 0.0;
send(pub, msg);
```

> **Important:** Odometry is calculated from **wheel encoders**. Only motorized movement (commands sent via `/cmd_vel`) is tracked. Physically pushing or lifting the robot will not update x, y, or yaw.

---

## Shutdown Procedure

1. Stop teleop or any running nodes with `Ctrl+C`.
2. In the SSH session, stop bringup with `Ctrl+C`.
3. Shut down the Raspberry Pi cleanly:
   ```bash
   sudo shutdown now
   ```
4. Wait for the Pi's LEDs to go out, then flip the robot power switch off.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Cannot SSH into robot | Check both devices are on the same WiFi network; ping `192.168.0.134` |
| `ros2 topic list` only shows `/parameter_events` and `/rosout` | Make sure `RMW_IMPLEMENTATION=rmw_cyclonedds_cpp` and `CYCLONEDDS_URI` are both set on the laptop; confirm bringup is running on the robot with same RMW |
| `turtlebot3_ros` exits with code `-11` on robot | Run `sudo apt install ros-humble-turtlebot3-node ros-humble-turtlebot3-bringup` on the robot (after `sudo apt update`) |
| `KeyError: 'LDS_MODEL'` on bringup | Add `export LDS_MODEL=LDS-03` before launching bringup |
| `PackageNotFoundError: coin_d4_driver` | Bringup is running on the laptop, not the robot — it must run inside the SSH session |
| `ros2: command not found` | Run `source /opt/ros/humble/setup.bash` |
| Workspace packages not found | Run `source ~/turtlebot3_ws/install/setup.bash` |
| OpenCR not connecting | Re-flash OpenCR firmware (see OpenCR Setup guide) |
| Robot not responding to teleop | Run `ros2 topic echo /cmd_vel` to confirm messages are publishing |

---

## Why CycloneDDS Instead of FastDDS?

ROS2 Humble uses FastDDS by default, which relies on **UDP multicast** for node discovery. Most WiFi routers block multicast traffic between wireless clients, so the laptop and robot cannot find each other even on the same network.

CycloneDDS supports **unicast peer-to-peer discovery** via the `CYCLONEDDS_URI` environment variable, which bypasses the multicast limitation by directly contacting the robot's IP address. Both devices must use the same DDS middleware.
