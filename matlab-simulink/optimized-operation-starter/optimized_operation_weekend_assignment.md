# Weekend Assignment: Build The Optimized Haulage Scenario

## Purpose

The baseline Simulink model already shows how a haul truck moves through a route using normal rule-based speed behavior.

Your task is to build the next version:

> A haul truck simulation where the target speed comes from a machine-learning speed policy instead of the baseline rule-based controller.

This is not a machine-learning training task. The ML model has already produced a speed policy. Your job is to connect that policy into Simulink correctly and safely.

## Big Picture

The optimized simulation should follow this logic:

```text
Route segment properties
    -> payload state
    -> ML optimized speed advisor
    -> safety governor
    -> truck motion
    -> fuel and SFC model
    -> logs and plots
```

The most important idea:

> The ML policy recommends a target speed. The safety governor decides whether that recommendation is allowed.

## Files You Need

| File | How To Use It |
| --- | --- |
| `../baseline-operation/HaulageBaselineOperationSimulation.slx` | Starting model to copy or extend |
| `ml_speed_policy_table.csv` | Original ML speed policy output |
| `ml_speed_policy_lookup_matrix.csv` | Easier format for a Simulink lookup table |
| `ml_model_metrics.json` | Model performance context |
| `ml_policy_evaluation_summary.json` | Offline estimate of policy benefit |
| `reference_expected_comparison.csv` | Final result check after implementation |

## ML Policy Meaning

The policy is based on two main inputs:

1. `grade_class`
2. `payload_t`

The policy output is:

```text
recommended optimized speed in km/h
```

The current grade code convention is:

| Grade Code | Grade Class | Interpretation |
| ---: | --- | --- |
| 1 | Uphill | positive grade / ramp up |
| 2 | Flat | flat or mild grade |
| 3 | Downhill | negative grade / ramp down |

The payload bands are:

| Payload Band | Approximate Meaning |
| --- | --- |
| `0-140` | empty or lightly loaded |
| `140-180` | low-medium load |
| `180-220` | medium load |
| `220-260` | high load |
| `260-300` | near full load |
| `>300` | above 300 t |

For our current open-pit route, the truck is:

- loaded at `279 t` on segments S1-S5;
- empty at `0 t` on segments S6-S8.

## Simulink-Friendly Lookup Matrix

Use `ml_speed_policy_lookup_matrix.csv`.

It has this structure:

| grade_code | grade_class | 0-140 | 140-180 | 180-220 | 220-260 | 260-300 | >300 |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | Uphill | 21.26 | 17.50 | 15.00 | 13.50 | 15.50 | 18.50 |
| 2 | Flat | 28.36 | 27.71 | 27.24 | 27.34 | 27.50 | 27.74 |
| 3 | Downhill | 26.35 | 23.86 | 22.91 | 22.00 | 22.50 | 24.27 |

This can be implemented using:

- a `2-D Lookup Table` block, or
- payload-band selector blocks plus a grade-class selector, or
- a MATLAB Function block only if the block-based version becomes too messy.

Prefer block-based logic first.

## What To Build

Create a new Simulink model based on the baseline model.

Recommended name:

```text
HaulageOptimizedOperationSimulation.slx
```

Do not delete or overwrite the baseline model.

## Required New Block

Add one new subsystem:

```text
Optimized Speed Advisor
```

Inputs:

| Input | Unit | Source |
| --- | --- | --- |
| `payload_t` | tonnes | Payload State block |
| `gradeCode` | code 1/2/3 | Route properties |
| `speedLimit_kph` | km/h | Route properties |
| `zoneCode` | code | Route properties |

Output:

| Output | Unit | Meaning |
| --- | --- | --- |
| `targetSpeed_kph` | km/h | ML-recommended target speed before final motion tracking |

## Required Safety Logic

The optimized speed must still pass through the same safety rules as the baseline model.

Keep these constraints:

| Safety Rule | Why It Matters |
| --- | --- |
| route speed limit | prevents overspeeding per segment |
| loader/dump zone cap | keeps approach zones slow |
| downhill retarding cap | prevents unrealistic downhill command speeds |
| minimum command speed | avoids zero-speed lookup artifacts |
| acceleration/deceleration limits | prevents instant speed jumps |

Do not allow the ML policy to bypass safety.

## Suggested Block Workflow

1. Open the baseline model.
2. Save a copy as `HaulageOptimizedOperationSimulation.slx`.
3. Open `Baseline Operation Pipeline`.
4. Find where the baseline controller outputs `targetSpeed_kph`.
5. Replace or parallel that block with `Optimized Speed Advisor`.
6. Feed the advisor with `payload_t` and `gradeCode`.
7. Use the policy lookup matrix to compute ML target speed.
8. Route the ML target speed through the existing safety governor.
9. Keep the same motion and fuel/SFC model.
10. Log the same 7-value output vector:

```text
[speed_kph, distance_m, fuel_l, fuelRate_lph, instSfc_l_per_tkm, productiveTonKm, targetSpeed_kph]
```

## What Not To Change

Do not change these parts yet:

- route segment distances;
- route grades;
- payload schedule;
- vehicle mass;
- fuel/SFC model;
- output vector format;
- safety limits;
- baseline model file.

This first optimized version should isolate one question:

> What changes when the speed target comes from the ML policy?

## Validation Target

After your optimized model runs, compare your final output against `reference_expected_comparison.csv`.

Expected approximate values:

| Metric | Baseline | Optimized |
| --- | ---: | ---: |
| route distance | 3560 m | 3560 m |
| productive work | 552.42 t-km | 552.42 t-km |
| travel time | 786 s | 693 s |
| fuel use | 18.35 L | 15.97 L |
| SFC | 0.0332 L/t-km | 0.0289 L/t-km |
| fuel saved | | 2.38 L |
| fuel saved percent | | 12.97% |

Small differences are okay if block settings differ slightly. Large differences usually mean:

- the wrong grade code is being selected;
- the wrong payload band is being selected;
- safety caps are missing;
- the output vector order changed;
- the route stops too early or too late.

## Deliverables

Please prepare:

1. A screenshot of the top-level optimized model.
2. A screenshot inside the `Optimized Speed Advisor` block.
3. A short note explaining how payload and grade select the ML speed.
4. A CSV or table comparing baseline and optimized:
   - travel time;
   - fuel use;
   - SFC;
   - average speed;
   - final distance.
5. A list of questions or issues you ran into.

## Exporting The Optimized Output

After running the optimized model, MATLAB should create a variable named `out`.

Run this from the `optimized-operation-starter` folder:

```matlab
[optimizedSamples, optimizedSummary] = export_optimized_simulink_output(out, "optimized");
```

If MATLAB reports that `export_optimized_simulink_output` is not recognized, open and run:

```matlab
run_export_after_simulation
```

That script adds the current folder to the MATLAB path and then runs the exporter.

This creates:

```text
optimized_timeseries.csv
optimized_summary.csv
```

If `out` only shows metadata and no signal data, use:

```text
simulink_output_export_guide.md
```

The guide explains how to enable output logging or add a `To Workspace` block to the final `Scenario Output` signal.

## Stretch Goals

If the core version works:

1. Add a dashboard plot showing baseline target speed vs optimized target speed.
2. Show which route segment is active over time.
3. Add a display for current payload and grade code.
4. Try changing the surface multiplier and observe the effect.
5. Try a different route scenario if available.

## Key Explanation To Remember

The optimized scenario is not an autonomous driver. It is a speed advisor:

```text
ML policy recommends speed
    -> safety block filters speed
        -> truck follows the allowed command gradually
```

That structure makes the model easier to defend, easier to inspect, and safer to extend later.
