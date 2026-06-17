# Stage 12: Longitudinal Physics And Turtle Robot Kinematics Bridge

## Purpose

Stage 12 adds two built-in MATLAB/Simulink modeling families to the haulage framework:

1. **Simscape Driveline Longitudinal Vehicle** for full-scale haul-truck longitudinal physics.
2. **Robotics System Toolbox Unicycle Kinematic Model** for Turtle-style robot route playback and `/cmd_vel` handoff.

The goal is not to replace the existing ML speed-advisory framework. The goal is to give the project a cleaner physical plant layer and a clear bridge to lab robots.

The new model is:

```text
simulink/HaulagePhysicsKinematicsBridge.slx
```

The runner is:

```matlab
report = runStage12PhysicsKinematicsBridge();
```

## Why We Are Doing This

Our previous models already compare baseline speed behavior against ML-recommended speed behavior. Those models are transparent and easy to inspect, but the truck motion is simplified:

```text
target speed -> acceleration limit -> updated speed -> updated distance
```

That is useful for research logic, but it hides the physical plant. A real truck does not instantly become the recommended speed. A real truck responds through:

- drivetrain torque;
- braking / retarding force;
- vehicle mass;
- road grade;
- rolling resistance;
- aerodynamic drag;
- tire radius;
- controller behavior.

Stage 12 makes that relationship explicit.

The new full-scale side becomes:

```text
ML target speed
    -> speed error controller
    -> axle torque / brake force
    -> Simscape Longitudinal Vehicle
    -> actual vehicle speed
```

The robot side becomes:

```text
route waypoints
    -> /cmd_vel schedule
    -> Unicycle Kinematic Model
    -> robot pose [x, y, theta]
```

## Installed Toolboxes Used

This stage uses toolboxes currently installed on the machine:

| Toolbox | Role |
| --- | --- |
| Simulink | block diagram simulation |
| Simscape | physical modeling infrastructure |
| Simscape Driveline | Longitudinal Vehicle block |
| Robotics System Toolbox | Unicycle Kinematic Model and robot motion concepts |

## Model-Level Architecture

The Stage 12 model has two main subsystems.

```text
HaulagePhysicsKinematicsBridge
    |
    |-- Full-Scale Haul Truck Longitudinal Plant
    |
    |-- Turtle Robot Kinematic Plant
```

These two subsystems are intentionally independent. The first teaches full-scale truck physics. The second produces a robot-scale path and command handoff.

## Full-Scale Haul Truck Longitudinal Plant

### What It Does

This subsystem uses the Simscape Driveline `Longitudinal Vehicle` block.

It takes:

- ML target speed, in m/s;
- route grade, in percent;
- wind speed, currently zero;
- actual vehicle speed feedback.

It outputs:

- actual vehicle speed;
- axle torque command;
- brake force command, currently held at zero in this first stable slice;
- route grade log.

The first implementation runs a stable loaded-outbound physics slice of the route and stops before the dump-approach retarding transition. This is intentional. The purpose of this stage is to introduce the built-in longitudinal plant cleanly before adding a more careful braking/retarding controller for the full haul cycle.

### Why Longitudinal Vehicle

A haul truck speed/fuel study is mostly a longitudinal problem. We care about how fast the truck moves along the haul road, how grade changes the required effort, and how much braking or torque is needed.

For this stage, we are not yet modeling:

- steering;
- lateral tire slip;
- yaw dynamics;
- detailed suspension;
- truck body roll;
- multiple axles.

Those belong to later stages such as Vehicle Body, Three-Axle Vehicle Body, Tire blocks, or Vehicle Dynamics Blockset.

### Physics Being Represented

The Longitudinal Vehicle block represents the idea:

```text
tractive effort - braking - resistance = mass * acceleration
```

The resistance terms include:

| Effect | Meaning |
| --- | --- |
| road grade | uphill grade resists motion; downhill grade assists motion |
| rolling resistance | tire/road resistance that grows with vehicle weight |
| aerodynamic drag | air resistance based on drag coefficient and frontal area |
| braking force | commanded force opposing motion |

The key grade force is approximately:

```text
F_grade = m * g * grade
```

where grade is used as a slope ratio. For example, 8% grade means approximately `0.08`.

Rolling resistance is approximately:

```text
F_roll = C_roll * m * g
```

Aerodynamic drag is approximately:

```text
F_drag = 0.5 * rho * Cd * A * v^2
```

### Current Truck Parameters

The first implementation uses the current large haul truck placeholders:

| Parameter | Value |
| --- | ---: |
| empty mass | 150,000 kg |
| loaded payload used in plant | 279,000 kg |
| total loaded mass | 429,000 kg |
| tire rolling radius | 1.8 m |
| rolling coefficient | 0.03 |
| drag coefficient | 0.70 |
| frontal area | 10 m^2 |

Important limitation:

> The first Simscape plant uses fixed loaded mass. The previous route still includes loaded and empty legs, but the Simscape plant is intentionally fixed-mass for the first implementation.

Second important limitation:

> The first Simscape run is a stable outbound slice, not the complete haul cycle. The complete cycle still exists in the Stage 10 model. Stage 12 is the bridge toward a more physical plant.

This is a learning step. Later we can add:

- loaded and empty plant variants;
- variant subsystems;
- a variable-mass approximation;
- separate outbound and return simulations.

### Speed Controller

The Longitudinal Vehicle block does not accept target speed directly. It accepts physical torque and brake effects.

So Stage 12 adds a simple speed-error controller:

```text
speed error = target speed - actual speed
```

If the target speed is higher than actual speed:

```text
apply drive torque
```

If the actual speed is higher than target speed:

```text
future version: apply brake or retarding force
current version: coast with zero active brake force
```

The model currently uses a proportional controller with saturation:

```text
drive torque = limited gain * positive speed error
brake force  = currently zero for the first stable implementation
```

This is intentionally simple. The controller is not the research contribution. It is the bridge between an ML speed recommendation and a physical vehicle plant.

The brake/retarding port is already wired into the subsystem, but active braking is disabled for the first implementation because the first aggressive braking controller made the Simscape plant numerically stiff at the dump-approach transition. A better retarding controller should be added after this first plant is understood.

### Sign Conventions

Two sign corrections are included inside the model:

| Correction | Why It Exists |
| --- | --- |
| forward speed sign correction | the axle orientation reports forward motion with the opposite sign |
| Simscape grade sign correction | the route table uses positive grade as uphill, while this block orientation requires the opposite sign |

The logged grade remains in the route-table convention:

```text
positive = uphill
negative = downhill
```

## Turtle Robot Kinematic Plant

### What It Does

This subsystem uses the Robotics System Toolbox `Unicycle Kinematic Model`.

It takes:

- linear velocity command, m/s;
- angular velocity command, rad/s.

It outputs:

- robot x position;
- robot y position;
- robot heading angle theta;
- state derivatives.

This maps naturally to Turtle robot control because Turtle robots commonly receive ROS velocity commands through:

```text
/cmd_vel
```

The ROS message type is:

```text
geometry_msgs/Twist
```

The two fields we care about first are:

```text
Twist.linear.x
Twist.angular.z
```

### Kinematic Physics

The unicycle model is a planar robot model:

```text
dx/dt     = v * cos(theta)
dy/dt     = v * sin(theta)
dtheta/dt = omega
```

where:

| Variable | Meaning |
| --- | --- |
| `v` | forward linear velocity |
| `omega` | heading angular velocity |
| `theta` | robot heading |

This model does not simulate wheel torque, slip, battery energy, or terrain contact. It is a motion-geometry model. That is exactly what we need first for robot route playback.

The Simulink block is configured so that the command file behaves like a ROS `/cmd_vel` schedule:

- maximum solver step is limited to `0.05 s`;
- command sources are sampled at `0.1 s`;
- command interpolation is disabled;
- output after the final command is set to zero;
- wheel radius is set to `1.0` inside the teaching model so the input column `linear_velocity_mps` passes through as meters per second.

## Turtle Robot Output For The Robot Team

The robot team needs files that are directly usable for robot work, not haul-truck-only plots.

Stage 12 produces three handoff files:

| File | Purpose |
| --- | --- |
| `outputs/stage12_turtle_route_waypoints.csv` | robot-scale route points in meters |
| `outputs/stage12_turtle_cmd_vel_schedule.csv` | time-indexed `/cmd_vel` command schedule |
| `outputs/stage12_turtle_robot_handoff.json` | explains topic, message type, columns, and safety notes |

### The Most Important File

The key file is:

```text
outputs/stage12_turtle_cmd_vel_schedule.csv
```

It contains:

| Column | Meaning |
| --- | --- |
| `time_s` | command timestamp |
| `command_phase` | `turn`, `drive`, or `stop` |
| `segmentId` | route segment being represented |
| `linear_velocity_mps` | maps to `Twist.linear.x` |
| `angular_velocity_radps` | maps to `Twist.angular.z` |
| `target_heading_rad` | heading used for the open-loop segment |
| `grade_pct` | route metadata |
| `ros_topic` | `/cmd_vel` |

### How The Team Uses It

For a first robot test, the team can read each row of the CSV and publish:

```text
linear.x  = linear_velocity_mps
angular.z = angular_velocity_radps
```

to:

```text
/cmd_vel
```

at:

```text
10 Hz
```

The JSON file confirms this mapping:

```text
linear_velocity_mps  -> Twist.linear.x
angular_velocity_radps -> Twist.angular.z
```

### Safety Note For Robot Testing

The current command schedule is open-loop. That means it does not use robot localization feedback yet.

First tests should be:

1. robot wheels lifted or robot on blocks;
2. very low speed;
3. open floor area;
4. emergency stop available;
5. short playback window;
6. then closed-loop path following later.

Eventually, this should become:

```text
waypoints + robot pose feedback
    -> Pure Pursuit or path follower
    -> /cmd_vel
    -> Turtle robot
```

## Generated Files

Running:

```matlab
report = runStage12PhysicsKinematicsBridge();
```

creates:

| File | Purpose |
| --- | --- |
| `simulink/HaulagePhysicsKinematicsBridge.slx` | Stage 12 Simulink model |
| `outputs/stage12_longitudinal_drive_cycle.csv` | ML target speed and grade schedule for Simscape plant |
| `outputs/stage12_longitudinal_simscape_signal_log.csv` | target speed, actual speed, grade, torque, brake |
| `outputs/stage12_turtle_route_waypoints.csv` | robot route waypoints |
| `outputs/stage12_turtle_cmd_vel_schedule.csv` | robot `/cmd_vel` handoff schedule |
| `outputs/stage12_turtle_robot_handoff.json` | robot handoff metadata |
| `outputs/stage12_turtle_kinematic_signal_log.csv` | simulated robot pose and command log |
| `outputs/stage12_physics_kinematics_inputs.mat` | time-series variables used by the Simulink `From Workspace` blocks |
| `outputs/stage12_physics_kinematics_summary.csv` | compact summary metrics |
| `outputs/stage12_physics_kinematics_dashboard.png` | dashboard image |
| `outputs/stage12_physics_kinematics_report.mat` | MATLAB report struct |

For robot hardware work, use:

```text
docs/stage12_turtle_robot_handoff.md
```

The Simulink model includes a load callback that calls:

```matlab
loadStage12PhysicsKinematicsBridgeInputs()
```

This prevents missing-variable errors in the `From Workspace` blocks when the model is opened directly. If the model reports missing variables, run the loader once from the project root:

```matlab
loadStage12PhysicsKinematicsBridgeInputs()
```

## How This Connects To The ML Model

The ML model still plays the same role:

```text
payload + grade class
    -> recommended speed
```

But Stage 12 changes what happens after the recommendation.

Before:

```text
recommended speed -> direct speed tracking equation
```

Now:

```text
recommended speed
    -> controller
    -> torque/brake
    -> physical vehicle block
    -> actual speed
```

This is more defensible because the ML model is an advisor, not magic.

## What This Stage Does Not Claim

Stage 12 is not yet a validated OEM-grade haul-truck dynamic model.

Current limitations:

- fixed loaded mass in the Simscape longitudinal plant;
- longitudinal plant currently runs a stable outbound slice before dump-zone retarding;
- simplified proportional speed controller;
- active braking/retarding is wired but disabled in the first stable run;
- time-indexed grade input rather than distance-indexed road profile;
- no detailed engine map yet;
- no transmission model yet;
- no tire slip model yet;
- Turtle robot commands are open-loop;
- no robot localization feedback yet;
- grade is robot metadata, not a physical robot terrain interaction yet.

These limitations are useful because they define the next steps.

## Next Implementation Steps

Recommended order:

1. Replace time-indexed grade with a `Road Profile` block or distance-indexed grade lookup.
2. Add separate loaded and empty vehicle plant variants.
3. Add a diesel engine / drivetrain layer using Simscape Driveline examples.
4. Add tire/friction blocks for road condition effects.
5. Replace open-loop Turtle commands with closed-loop Pure Pursuit.
6. Publish the generated `cmd_vel` schedule from ROS 2.
7. Log Turtle robot odometry and compare actual robot path against the simulated route.

## Clean Interpretation

The project now has three layers:

```text
ML advisory layer:
    recommends efficient speed

Full-scale physics layer:
    tests whether a haul truck can physically follow the recommendation

Robot handoff layer:
    converts route/speed concepts into small-robot commands
```

That is the bridge from paper logic to Simulink engineering model to lab robot demonstration.
