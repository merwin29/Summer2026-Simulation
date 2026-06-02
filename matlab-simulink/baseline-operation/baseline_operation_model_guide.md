# Baseline Operation Simulink Model Guide

## Purpose

This guide explains the baseline-only haulage simulation model:

`HaulageBaselineOperationSimulation.slx`

This model is meant for the first simulation-design walkthrough before introducing the optimized / machine-learning speed advisor.

The model answers one basic question:

> If a haul truck follows a normal rule-based speed behavior on a configurable haul route, how do speed, distance, fuel use, SFC, and productivity evolve over the haul cycle?

The model does not include the optimized controller yet. That is intentional.

## What This Model Includes

The baseline model includes:

- route scenario selection;
- vehicle scenario selection;
- road surface / rolling resistance scaling;
- route segment lookup;
- payload state;
- baseline speed controller;
- safety governor;
- longitudinal motion;
- fuel and SFC calculation;
- baseline dashboard plots;
- MATLAB logging.


## How To Run

From MATLAB, open the model file in this folder:

```matlab
cd('path_to_this_repo\matlab-simulink\baseline-operation')
open_system('HaulageBaselineOperationSimulation.slx')
```

Then press **Run** in Simulink.

If MATLAB already has an old copy of the model open:

```matlab
bdclose('HaulageBaselineOperationSimulation')
open_system('HaulageBaselineOperationSimulation.slx')
```

This repository contains the generated baseline model for walkthrough and experimentation. The model can be opened and run directly. The larger research framework that generated the model is kept separately.

## Generated Files

| File | Purpose |
| --- | --- |
| `HaulageBaselineOperationSimulation.slx` | Baseline-only Simulink model |
| `baseline_operation_model_guide.md` | Detailed walkthrough for the model |
| `baseline_operation_model_layout.png` | Top-level model layout image |
| `baseline_operation_route_3d_preview.png` | Static 3D route preview |
| `baseline_operation_summary.csv` | One-row summary of baseline time, fuel, SFC, and productivity |
| `baseline_operation_signal_log.csv` | Time-history log of speed, distance, fuel, SFC, and target speed |

## Top-Level Model Flow

The top-level flow is:

```text
Scenario Config
    -> Baseline Operation Pipeline
        -> Baseline Results Dashboard and Logs

3D Visualization Hook is available for route preview.
```

The important idea is:

> Scenario Config defines the experiment. Baseline Operation Pipeline simulates the truck. Results Dashboard and Logs explain the outputs.

## Top-Level Blocks

### Scenario Config

This block defines the simulation inputs.

It contains:

- route geometry library;
- vehicle truck specs;
- road resistance and safety settings;
- simulation run options;
- experiment controls.

It outputs three buses:

- `Route Bus`
- `Vehicle Bus`
- `Safety Bus`

A bus is a bundle of related signals. Instead of drawing many separate wires, Simulink bundles route properties, vehicle properties, and safety settings into grouped signals.

### Baseline Operation Pipeline

This is the main truck simulation block.

It receives:

- route bus;
- vehicle bus;
- safety bus.

It outputs one 7-value scenario vector:

| Index | Signal | Meaning |
| ---: | --- | --- |
| 1 | `speed_kph` | Current truck speed |
| 2 | `cumulativeDistance_m` | Distance traveled along route |
| 3 | `cumulativeFuel_l` | Fuel consumed so far |
| 4 | `fuelRate_lph` | Instantaneous fuel rate |
| 5 | `instSfc_l_per_tkm` | Instantaneous specific fuel consumption |
| 6 | `productiveTonKm` | Payload-distance work completed |
| 7 | `targetSpeed_kph` | Baseline controller target speed |

### Baseline Results Dashboard And Logs

This block logs the baseline scenario output and provides dashboard plots.

It contains:

- `Baseline Log`
- `Baseline Metric Dashboard`

Open `Baseline Metric Dashboard` to view:

- speed dashboard;
- route progress dashboard;
- cumulative fuel dashboard;
- fuel rate dashboard;
- SFC dashboard;
- productivity dashboard.

### 3D Visualization Hook

This block points to a route preview image.

It is not the fuel model. It is a visualization support block.

## Scenario Config Details

### Experiment Controls

This is the main place to change cases.

| Block | Meaning | Current default |
| --- | --- | ---: |
| `Route Scenario ID` | Selects route type | 1 |
| `Vehicle Scenario ID` | Selects haul truck class | 1 |
| `Surface Multiplier` | Scales road resistance effect | 1 |

Route options:

| ID | Route |
| ---: | --- |
| 1 | Open pit demo |
| 2 | Underground demo |
| 3 | Lab track demo |

Vehicle options:

| ID | Vehicle |
| ---: | --- |
| 1 | Large diesel haul truck |
| 2 | Medium haul truck |
| 3 | Ultra-class haul truck |

Surface multiplier examples:

| Value | Interpretation |
| ---: | --- |
| 0.85 | smoother / lower-resistance surface |
| 1.00 | nominal road surface |
| 1.15 | rougher / higher-resistance surface |

### Route Geometry Library

This block stores route data for the available route scenarios.

For the open-pit route, the current values are:

| Seg. | Operating role | Length (m) | Grade (%) | Limit (km/h) | Payload |
| ---: | --- | ---: | ---: | ---: | ---: |
| 1 | Loader exit | 180 | 1.0 | 18 | 279 t |
| 2 | Ramp up 1 | 520 | 6.5 | 28 | 279 t |
| 3 | Ramp up 2 | 640 | 8.0 | 25 | 279 t |
| 4 | Bench connector | 420 | 0.2 | 35 | 279 t |
| 5 | Dump approach | 220 | 2.0 | 16 | 279 t |
| 6 | Return flat | 500 | -0.2 | 35 | 0 t |
| 7 | Ramp down | 820 | -7.0 | 28 | 0 t |
| 8 | Loader approach | 260 | -1.5 | 16 | 0 t |

The route also uses rolling resistance:

```text
effective grade = geometric grade + rolling resistance
```

Geometric grade describes the physical road slope.

Effective grade is used for fuel calculation because rough roads make the truck work harder even if the road is not steep.

### Vehicle Truck Specs

This block selects the truck specification.

The model uses vehicle parameters such as:

- empty mass;
- rated payload;
- idle fuel rate;
- max fuel rate;
- frontal area;
- drag coefficient;
- drivetrain efficiency.

These parameters are passed into the fuel and motion blocks.

### Road Resistance And Safety

This block contains operational safety settings.

Important settings include:

| Setting | Meaning |
| --- | --- |
| minimum command speed | avoids unrealistic zero-speed commands while route is active |
| loading / dumping speed cap | slows truck in loader and dump zones |
| downhill retarding threshold | identifies steep downhill segments |
| downhill retarding cap | limits downhill speed for safety |
| max operating speed | upper speed cap |
| surface resistance multiplier | scales effective road resistance |

Safety logic is important because a speed controller should not be allowed to command unsafe behavior.

### Simulation Run Options

This block stores run timing settings.

| Setting | Meaning |
| --- | --- |
| fixed step `dt` | simulation time step |
| stop time | simulation window |
| baseline tracking tau | how smoothly the truck follows target speed |
| output vector width | number of values in scenario output vector |

The current `dt` is 1 second.

## Baseline Operation Pipeline Details

The pipeline flow is:

```text
Route + Vehicle + Safety buses
    -> Route and Payload Lookup
    -> Baseline Controller Blocks
    -> Safety Governor Blocks
    -> Longitudinal Motion Equations
    -> Energy SFC Equations
    -> Native Output Packager
```

### Distance Memory

This block stores the truck's current cumulative distance.

The route lookup uses this distance to decide which road segment the truck is on.

### Route And Payload Lookup

This block asks:

> Given the current truck distance, which route segment is active?

It outputs route properties for the active segment:

- geometric grade;
- effective grade;
- speed limit;
- zone code;
- payload;
- grade code;
- route done flag.

### Baseline Controller Blocks

This block represents normal rule-based truck speed behavior.

It uses:

- grade;
- payload;
- speed limit;
- operating zone.

The current rule is intentionally simple:

- uphill: lower target speed as grade and payload increase;
- flat: moderate target speed;
- downhill: allow different speed behavior, then safety caps apply;
- loader/dump zones: slow down.

This is not optimization. It is the baseline behavior we compare against later.

### Safety Governor Blocks

This block checks the target speed before the truck follows it.

It applies:

- speed limit;
- loading/dumping cap;
- downhill retarding cap;
- minimum command speed;
- maximum operating speed.

The important concept:

> The controller proposes a speed. The safety governor decides the allowed speed.

### Longitudinal Motion Equations

This block updates the truck motion over time.

It uses:

- safe target speed;
- current speed;
- payload-dependent acceleration limits;
- tracking time constant;
- route completion state.

It outputs:

- actual speed;
- cumulative distance;
- step distance;
- step time.

The truck does not instantly jump to the commanded speed. It gradually approaches it.

### Vehicle Parameter Vector

This block unpacks vehicle bus values into a vector used by the fuel model.

The vector includes:

- empty mass;
- idle fuel rate;
- max fuel rate;
- frontal area;
- drag coefficient;
- drivetrain efficiency.

### Energy SFC Equations

This block estimates fuel use and SFC.

The simplified physics calculation uses:

- vehicle mass;
- payload;
- effective grade;
- aerodynamic drag;
- drivetrain efficiency;
- diesel energy content;
- idle fuel rate;
- maximum fuel rate.

The model estimates fuel rate in L/h and integrates it into cumulative fuel in liters.

SFC is calculated as:

```text
SFC = fuel rate / (payload x speed)
```

with units:

```text
L/t-km
```

SFC is only meaningful when the truck is carrying payload.

### Native Output Packager

This block packages the model outputs into a 7-value vector:

```text
[speed, distance, fuel, fuel rate, SFC, productive t-km, target speed]
```

That vector goes to the results dashboard and logs.

## Dashboard Guide

Open:

```text
Baseline Results Dashboard and Logs
    -> Baseline Metric Dashboard
```

Then open any dashboard scope.

### Speed Dashboard

Shows:

- actual baseline speed;
- baseline target speed.

This helps explain controller tracking.

If target speed changes immediately but actual speed changes gradually, that is the tracking/acceleration behavior.

### Route Progress Dashboard

Shows cumulative distance versus time.

The curve becomes flat when the truck finishes the route.

### Cumulative Fuel Dashboard

Shows total fuel consumed so far.

The curve should always increase or stay flat.

### Fuel Rate Dashboard

Shows instantaneous fuel intensity in L/h.

Fuel rate is higher on loaded uphill segments and lower on empty/downhill segments.

### SFC Dashboard

Shows specific fuel consumption in L/t-km.

This connects fuel use to productive work.

### Productivity Dashboard

Shows productive ton-kilometers.

It increases when the truck is loaded and moving.

It does not increase on the empty return.

## Current Baseline Result

For the open-pit route and large diesel haul truck:

| Metric | Value |
| --- | ---: |
| planned route distance | 3560 m |
| simulated distance | 3560 m |
| baseline travel time | 786 s |
| baseline fuel | 18.35 L |
| productive work | 552.42 t-km |
| baseline SFC | 0.03321 L/t-km |
| average speed | 16.31 km/h |

These values are simulation outputs, not field-validated production claims.

## What To Change First

For a first student exercise, change only one thing at a time.

Good first tests:

1. Change `Route Scenario ID` from 1 to 2.
2. Change `Surface Multiplier` from 1.00 to 1.15.
3. Change `Vehicle Scenario ID` from 1 to 2.
4. Change one route segment grade.
5. Change one speed limit.

After each change, ask:

- Did travel time change?
- Did fuel use change?
- Did SFC change?
- Did route completion still happen?
- Did the dashboard behavior make physical sense?

## How This Baseline Model Leads To Optimization

This baseline model establishes the physical and operational simulation foundation.

Later, the optimized model adds one extra idea:

```text
Instead of only rule-based target speed,
use an ML-informed speed advisor.
```

The full model then compares:

```text
baseline speed behavior vs optimized speed behavior
```

But before that comparison is useful, the student should understand:

- how a route is represented;
- how payload changes by segment;
- how speed limits and safety caps work;
- how truck motion is updated;
- how fuel and SFC are computed;
- how outputs are logged and interpreted.

## Suggested Walkthrough For The First Meeting

1. Open the top-level model.
2. Explain the three main blocks:
   - Scenario Config;
   - Baseline Operation Pipeline;
   - Baseline Results Dashboard and Logs.
3. Open Scenario Config.
4. Show Experiment Controls.
5. Show Route Geometry Library.
6. Open Baseline Operation Pipeline.
7. Follow the flow from route lookup to fuel/SFC.
8. Run the model.
9. Open the dashboard scopes.
10. Discuss which parts are assumptions and which parts come from data.

## Useful Simulink Terms

| Term | Meaning |
| --- | --- |
| Inport | Signal entering a subsystem |
| Outport | Signal leaving a subsystem |
| Constant | Editable fixed parameter |
| Bus | Bundle of related signals |
| Bus Creator | Combines signals into a bus |
| Bus Selector | Extracts signals from a bus |
| Demux | Splits a vector into individual signals |
| Mux | Combines signals into a vector |
| Unit Delay | Stores previous time-step value |
| Scope | Plot window |
| To Workspace | Sends simulation output to MATLAB |
| Goto / From | Carries signals without long visible wires |
| MATLAB Function | Custom equations inside a Simulink block |

## Important Assumptions

The current model is simplified.

It assumes:

- a single truck;
- predefined route segments;
- predefined payload schedule;
- simplified longitudinal dynamics;
- simplified fuel physics;
- no queueing;
- no traffic;
- no detailed tire, brake, retarder, or transmission model;
- no OEM performance curves yet.

The model is still useful because it makes the computational logic explicit and testable.

## Take Away

The baseline model is the foundation.

It shows how a haul truck moves through a route, how payload and grade affect operation, and how fuel and SFC are calculated.

Once this baseline behavior is understood, the optimized model can be introduced as an advisory layer that changes target speed while preserving the same safety and physics structure.
