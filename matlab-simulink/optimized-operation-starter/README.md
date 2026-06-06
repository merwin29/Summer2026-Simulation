# Optimized Operation Starter Package

This folder contains the machine-learning speed policy outputs needed to build the optimized haulage scenario in Simulink.

The goal is not to retrain the ML model this weekend. The goal is to take the ML speed recommendations and connect them into the baseline Simulink architecture as an **Optimized Speed Advisor**.

## What Is Included

| File | Purpose |
| --- | --- |
| `optimized_operation_weekend_assignment.md` | Step-by-step student task brief |
| `ml_speed_policy_table.csv` | Original ML policy output by grade class and payload band |
| `ml_speed_policy_lookup_matrix.csv` | Simulink-friendly lookup table format |
| `ml_model_metrics.json` | Basic model accuracy and training/test summary |
| `ml_policy_evaluation_summary.json` | Offline ML policy evaluation summary |
| `reference_expected_comparison.csv` | Reference final results for checking the Simulink implementation |

## Starting Point

Start from the baseline model:

`../baseline-operation/HaulageBaselineOperationSimulation.slx`

The optimized model should keep the same route, vehicle, safety, motion, fuel, SFC, dashboard, and logging structure. The main change is replacing the rule-based baseline speed target with an ML policy speed target.

## Core Design

```text
Route + Payload
    -> Optimized Speed Advisor
    -> Safety Governor
    -> Longitudinal Motion
    -> Energy / SFC Model
    -> Results Dashboard and Logs
```

The ML policy is an advisor. The safety governor still has final authority.

## Expected Reference Result

Using the current open-pit route and full-scale haul truck assumptions, the optimized version should be close to:

| Metric | Baseline | Optimized |
| --- | ---: | ---: |
| travel time | 786 s | 693 s |
| fuel use | 18.35 L | 15.97 L |
| SFC | 0.0332 L/t-km | 0.0289 L/t-km |
| fuel saved | | 12.97% |

These are simulation-reference values, not field-validated production claims.
