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

### Step 6 — Teleoperate the Robot by computer (Optional Test or if main demo does not work)

In the terminal of the PC (not MatLab)
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

### Step 7 — Open MATLAB

```bash
/usr/local/MATLAB/R2026b/bin/matlab
```

In MATLAB, verify ROS2 connection:

```matlab
ros2("topic","list")
```

You should see the same robot topics listed above.

### Step 8 — Open Simulink

When you open up Simulink there should be a project called
```turtlebot3_ros2_test1.slx ```

If not, there should be a copy of the simulink model that is in the same location as these instructions.

Once that is set up press run at the top which should be under the simulation tab.

The simulation has no stop or pause once run, so if you want to stop do the following

From a new terminal on your laptop:

```bash
ssh ubuntu@192.168.0.134
# Password: turtlebot
```
Then place the following command to stop the robot, if you want to play the robot again press the run button on Simulink

```ros2 topic pub -r 20 /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"```
