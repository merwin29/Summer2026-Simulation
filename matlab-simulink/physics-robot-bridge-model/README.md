# Physics And Robot Bridge Model

This folder contains the fixed Stage 12 Simulink model package.

The key fix is that the model now has a loader for the `From Workspace` inputs used by:

- `ML Target Speed`
- `Route Grade Percent`
- `cmd_vel linear.x`
- `cmd_vel angular.z`

Without those variables, Simulink reports errors such as:

```text
Variable 'stage12_longitudinal_target_speed_mps' does not exist.
Variable 'stage12_turtle_angular_velocity_radps' does not exist.
```

## Main Files

| File | Purpose |
| --- | --- |
| `simulink/HaulagePhysicsKinematicsBridge.slx` | Simscape + Robotics System Toolbox bridge model |
| `loadStage12PhysicsKinematicsBridgeInputs.m` | Loads required Stage 12 timeseries variables |
| `outputs/stage12_physics_kinematics_inputs.mat` | Saved model input variables |
| `outputs/stage12_longitudinal_drive_cycle.csv` | Full-scale target speed and grade schedule |
| `outputs/stage12_turtle_cmd_vel_schedule.csv` | Turtle robot `/cmd_vel` command schedule |
| `outputs/stage12_turtle_route_waypoints.csv` | Robot route waypoints |
| `outputs/stage12_turtle_robot_handoff.json` | ROS handoff metadata |
| `docs/stage12_physics_kinematics_bridge.md` | Full explanation of the model and assumptions |
| `docs/stage12_turtle_robot_handoff.md` | Robot command handoff guide |

## How To Open The Model

From this folder in MATLAB:

```matlab
loadStage12PhysicsKinematicsBridgeInputs()
open_system('simulink/HaulagePhysicsKinematicsBridge.slx')
```

The `.slx` model also has load/init callbacks that call the loader automatically. If the model is already open and still shows missing-variable errors, run:

```matlab
loadStage12PhysicsKinematicsBridgeInputs()
set_param('HaulagePhysicsKinematicsBridge','SimulationCommand','update')
```

## What This Model Demonstrates

This is a bridge between:

- the ML speed recommendation layer;
- a full-scale haul truck longitudinal plant using Simscape Driveline;
- a Turtle-style robot kinematic plant using Robotics System Toolbox;
- a ROS-style `/cmd_vel` handoff for lab robot testing.

## Important Limitation

This is not a final validated haul truck digital twin. The current full-scale side is a first stable loaded-outbound physics slice. The robot side is an open-loop command handoff that should be tested safely before moving to closed-loop path following.
