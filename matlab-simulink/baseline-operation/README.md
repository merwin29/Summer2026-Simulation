# Baseline Operation Simulink Model

This folder contains the baseline-only Simulink model for the haulage simulation walkthrough.

Use this model for the first simulation design discussion before adding the optimized / ML speed advisor. It keeps the system focused on route setup, truck parameters, safety limits, motion, fuel use, SFC, and logging.

## Open The Model

In MATLAB:

```matlab
cd('path_to_repo\matlab-simulink\baseline-operation')
open_system('HaulageBaselineOperationSimulation.slx')
```

Then press **Run** in Simulink.

## What To Inspect First

Open these top-level blocks in order:

1. `Scenario Config`
2. `Baseline Operation Pipeline`
3. `Baseline Results Dashboard and Logs`
4. `3D Visualization Hook`

## Files

| File | Purpose |
| --- | --- |
| `HaulageBaselineOperationSimulation.slx` | Baseline-only Simulink model |
| `baseline_operation_model_guide.md` | Full walkthrough of every major block |
| `baseline_operation_summary.csv` | Final baseline fuel, time, SFC, and productivity summary |
| `baseline_operation_signal_log.csv` | Time-series simulation outputs |
| `baseline_operation_model_layout.png` | Model layout screenshot |
| `baseline_operation_route_3d_preview.png` | Route geometry preview |

## Important Scope

This version intentionally does not include the optimized controller or ML speed policy. The purpose is to first understand the baseline truck simulation clearly.
