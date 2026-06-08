# Optimized Haulage Simulation — Progress Report

## What Was Completed

- Created `HaulageOptimizedOperationSimulation.slx` from the baseline model (baseline remains untouched).
- Added an **Optimized Operation Pipeline** as a copy of the baseline pipeline.
- Replaced **Baseline Controller Blocks** with the **Optimized Speed Advisor** subsystem.
- Implemented an ML-based **2-D Lookup Table** using values from `ml_speed_policy_lookup_matrix.csv`.
- Kept **Safety Governor**, **Motion**, and **Fuel/SFC** blocks unchanged.
- Verified that the model runs successfully and produces output data.

---

## Current Results vs. Reference

| Metric | Baseline | Optimized (Current) | Reference |
|----------|----------:|----------:|----------:|
| Travel Time | 786 s | 1400 s | 693 s |
| Fuel Use | 18.35 L | 12.52 L | 15.97 L |
| Distance | 3560 m | 3560 m | 3560 m |

---

## Known Issues to Fix

- Simulation runs until the configured stop time limit (**1400 s**) instead of terminating at route completion (**~693 s**).
- Truck appears to remain capped at **12 km/h** (dump zone speed limit) during return-trip segments.
- Root cause has not yet been identified.
  - Most likely related to:
    - Zone code handling, or
    - Route completion signal logic within the **Optimized Pipeline**.

---

## Next Steps

1. Diagnose why route completion is not triggering correctly.
2. Verify zone code signals on return segments (**S6–S8**).
3. Re-validate simulation results against the reference model after fixes are implemented.

---

## Status Summary

(GOOD) Optimized controller integration completed.

(GOOD) ML lookup table successfully implemented.

(GOOD) Simulation executes and generates outputs.

(IMPROVE) Route completion logic requires debugging before performance can be validated against the reference results.
