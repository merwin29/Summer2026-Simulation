# TurtleBot3 Burger — Startup Guide

## Overview

| Component | Details |
|-----------|---------|
| Robot | TurtleBot3 Burger |
| Robot IP | `192.168.0.134` |
| Laptop OS | Ubuntu 20.04 (host) |
| ROS2 Environment | Docker container (Ubuntu 22.04 + ROS2 Humble) |
| Docker Image | `humble-tb3:latest` |
| ROS Domain ID | `0` |

---

## Note on Future Setup Change

> **Planned upgrade:** The current workflow uses a Docker container on an Ubuntu 20.04 laptop because ROS2 Humble requires Ubuntu 22.04, which cannot be installed natively on this machine. At a future point, we plan to switch to a dedicated computer running Ubuntu 22.04 natively. When that happens, the Docker steps (Steps 4–5) will be replaced by simply sourcing ROS2 directly on that machine — no container needed. All other steps (robot bringup, SSH, teleop) remain identical.

---

## Step 1 — Power on the Robot

1. Place the robot on a flat surface with clearance around it.
2. Flip the power switch on the TurtleBot3 base.
3. Wait ~30 seconds for the Raspberry Pi to boot.
4. The OpenCR board LEDs should light up once fully booted.

---

## Step 2 — SSH into the Robot

From a terminal on your laptop:

```bash
ssh ubuntu@192.168.0.134
# Password: turtlebot
```

> **Note:** Your laptop and the robot must be on the same WiFi network.

---

## Step 3 — Launch Robot Bringup (on the Robot)

Inside the SSH session:

```bash
source /opt/ros/humble/setup.bash
export TURTLEBOT3_MODEL=burger
ros2 launch turtlebot3_bringup robot.launch.py
```

**Expected output — look for these lines:**
```
[turtlebot3_node] OpenCR is connected
[turtlebot3_node] HW Version ...
[turtlebot3_node] Firmware Version ...
```

Leave this terminal running. Do **not** close it — bringup must stay active.

---

## Step 4 — Start the Docker Container (on Your Laptop)

> **When switching to a Ubuntu 22.04 computer:** Skip this step entirely. Instead, open a terminal and run `source /opt/ros/humble/setup.bash` directly, then jump to Step 5.

Open a **new terminal** on your laptop.

**If the container already exists:**
```bash
docker start -ai humble_ros
```

**If starting fresh (first time or after container was removed):**
```bash
docker run -it --network=host -e ROS_DOMAIN_ID=0 --name humble_ros humble-tb3:latest bash
```

---

## Step 5 — Verify Connection (inside Docker container)

```bash
source /opt/ros/humble/setup.bash
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

## Step 6 — Teleoperate the Robot (Optional Test)

Inside the Docker container:

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
| Cannot SSH into robot | Check that both devices are on the same WiFi network |
| `ros2 topic list` is empty | Confirm bringup is running on the robot; check `ROS_DOMAIN_ID=0` on both sides |
| OpenCR not connecting in bringup | Re-flash OpenCR firmware (see OpenCR Setup guide) |
| `docker start` says container not found | Run the `docker run` command from Step 4 instead |
| Robot not responding to teleop | Run `ros2 topic echo /cmd_vel` to confirm messages are publishing |
