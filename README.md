# Summer2026-Simulation

MODULE 1: Mining Program 
We will devide the path of the mine in straght lines doe simplicity, and then apply this segments into the optimizarion program to then determine the speicfic veolcities we should use
  
  MOD1.1: This will focus on the segments, like each dinvidual segment
  
  Each segment must have:
   
    Distance/Lenght
    Width
    Slope
    Safety Constraints
    Orientation (where the segment is pointing toeards to)

  MOD 1.2: This will actually code and program how each segment must coenct, the actual building of the mine wusing the "segment pieces"

  RECOMENDNATION:
  Lest sstart by doing a simple 4 segment quadrilateral mine without slopes, then based on thsi start miving to more complex mines with more segments and even more crazy slopes

  
MODULE 2: Robot program:
This will actually make the robot/gaul representation

  MOD2.1: This will focus on the actual robot program, it should have:
    
    Payload
    Energy Consumption
    Turn Rates
    Turn Speed
    Accelearation (limits of the robot or haul truck)

MODULE 3:
This will basically be a recopilation of ALL the different variabels we use in all the other modules

MODULE 4:
This is the MAIN module that basically connects all the previous moduels and makes them work in unison to make the overall program execute

Module 5:
This will be the module that will show a very simple 2D represetation of the simulaiton, perfect for the first deomstrations, and a good way to demonstrate advances, we will later improve it to a 3D model

CHATGPT recomends:

    MAIN SIMULATION
    │
    ├── Rover Module
    │   ├── Dynamics
    │   ├── Motor System
    │   ├── Battery Model
    │   ├── Energy Consumption
    │   └── Sensor Models
    │
    ├── Mine Module
    │   ├── Terrain
    │   ├── Slopes
    │   ├── Obstacles
    │   ├── Friction Zones
    │   └── Environmental Conditions
    │
    ├── Optimization Module
    │   ├── Velocity Inputs
    │   ├── Route Optimization
    │   └── Energy Strategy
    │
    ├── Data Logging Module
    │   ├── Power Usage
    │   ├── Travel Time
    │   ├── Battery Drain
    │   └── Efficiency Metrics
    │
    └── Visualization Module


INPUTS and OUTPUTS EARLY

This is critical.

Example:

Rover Module
Inputs

    velocity command
    terrain slope
    payload weight

Outputs

    power consumption
    position
    battery drain
    wheel torque


Mine Module
Inputs
    
    rover position
Outputs

    terrain type
    slope
    friction coefficient

## MATLAB / Simulink Baseline Model

A baseline-only haulage model has been added for the first Simulink walkthrough:

`matlab-simulink/baseline-operation/HaulageBaselineOperationSimulation.slx`

This model focuses on normal haul truck operation before adding the optimized speed advisor. It includes route scenario selection, vehicle configuration, road surface assumptions, baseline speed control, safety limits, motion, fuel/SFC calculation, dashboards, and logs.

Start here:

`matlab-simulink/baseline-operation/README.md`

## MATLAB / Simulink Optimized Starter

The next-stage starter package for adding the ML speed policy is here:

`matlab-simulink/optimized-operation-starter/README.md`

This folder does not provide a finished optimized Simulink model. It provides the ML speed policy outputs, reference results, and a weekend assignment for building the optimized speed-advisor branch from the baseline model.

## MATLAB / Simulink Physics And Robot Bridge

The Stage 12 physics and robot bridge model is here:

`matlab-simulink/physics-robot-bridge-model/README.md`

This package includes the fixed `HaulagePhysicsKinematicsBridge.slx` model, the input loader for the Simulink `From Workspace` blocks, the saved Stage 12 input MAT file, and the Turtle robot `/cmd_vel` handoff files.

Use this if Simulink reports missing variables such as `stage12_longitudinal_target_speed_mps` or `stage12_turtle_angular_velocity_radps`.

## TurtleBot `/cmd_vel` Hardware Test Package

The first robot-side test package is here:

`robot-handoff/turtlebot-cmdvel/README.md`

This package converts the Stage 12 Turtle robot output into a practical robot test workflow. It includes the generated `/cmd_vel` CSV, route waypoints, a no-ROS validation script, ROS 2 and ROS 1 publishers, and a staged safety protocol for wheels-lifted testing, short floor runs, and telemetry logging.
