# TurtleBot3 Mine Path Scaling — Lab Demo & Space Requirements

**Project:** TurtleBot3 Burger | Mine Site Route Simulation  
**Date:** October 13–14, 2026  
**Author:** Danielle

---

## 1. The Problem: We Need a Bigger Space

The goal is to run a scaled-down version of a real mine site haul route on a TurtleBot3 Burger robot. The full route (`route_points.csv`) spans **596m × 902m** and contains **7,294 waypoints**.

The current lab space is **1.83m × 4.27m (6ft × 14ft)**. Due to how the path must be scaled to keep the robot within its motor speed limits, this lab can only accommodate **~5% of the full route** — and that 5% is not a representative mine path, just a short curve useful for basic motion testing.

**A minimum space of 37m × 56m is required** to run a meaningful portion of the mine route.

---

## 2. Scaling Calculations

### TurtleBot3 Burger Motor Limits

| Parameter | Value |
|-----------|-------|
| Max translational velocity | 0.22 m/s |
| Max rotational velocity | 2.84 rad/s |
| Min acceptable speed | 0.08 m/s |

### Raw Route Data

| Property | Value |
|----------|-------|
| Waypoints | 7,294 |
| X span | 596m (217.19 → 813.19) |
| Y span | 902m (87.44 → 989.55) |
| Mean step distance | 0.9301m |
| Max heading change between steps | 2.0384 rad |

---

### Step 1 — Fix `dt` from Angular Velocity

Angular velocity depends only on the path geometry (heading changes), not on the map scale:

```
v_theta = dtheta / dt
```

`dtheta` is fixed by the path shape, so `dt` is the only lever. Rearranging for the minimum safe `dt`:

```
dt >= max_dtheta / max_v_theta
dt >= 2.0384 / 2.84 = 0.718s  →  rounded up to 0.72s
```

> **Result: `dt = 0.72s` (locked)** — going lower would cause over-rotation at sharp turns.

---

### Step 2 — Solve for `map_scale` from Linear Velocity

Linear velocity is calculated as:

```
v_L = step_distance / map_scale / dt
```

Rearranging for `map_scale` with `dt = 0.72s` and mean step = 0.9301m:

```
map_scale = step_distance / (v_L × dt)
```

- **For max speed (0.22 m/s) → minimum map_scale:**  
  `0.9301 / (0.22 × 0.72) = 5.87` → **minimum = 6**

- **For min acceptable speed (0.08 m/s) → maximum map_scale:**  
  `0.9301 / (0.08 × 0.72) = 16.15` → **maximum = 16**

> **Result: `map_scale` must be between 6 and 16.**

---

### Step 3 — Physical Map Size at Each Scale

`Width = 596 / map_scale`, `Height = 902 / map_scale`, `Speed = 0.9301 / map_scale / 0.72`

| map_scale | Width (m) | Height (m) | Speed (m/s) | Valid? |
|-----------|-----------|------------|-------------|--------|
| 6  | 99.3  | 150.3 | 0.215 | ✅ |
| 10 | 59.6  | 90.2  | 0.129 | ✅ |
| 13 | 45.8  | 69.4  | 0.099 | ✅ |
| 15 | 39.7  | 60.1  | 0.086 | ✅ |
| 16 | 37.3  | 56.4  | 0.081 | ✅ (just above minimum) |
| 20 | 29.8  | 45.1  | 0.065 | ❌ too slow |

**Recommended: `map_scale = 13`, `dt = 0.72s` → 0.10 m/s in a 45.8m × 69.4m space**

For absolute minimum space: **`map_scale = 16` → 37.3m × 56.4m at 0.081 m/s**

---

## 3. Current Lab Constraint: ~5% of the Route

With `map_scale = 16` (the maximum allowed), the 1.83m × 4.27m lab corresponds to these raw route ranges:

```
X: 1.83m × 16 = 29.3m of raw route  (out of 596m = 4.9%)
Y: 4.27m × 16 = 68.3m of raw route  (out of 902m = 7.6%)
```

The binding constraint is X. In practice, running the script auto-detected **37 waypoints** (≈0.5% of the route) before exceeding the space boundary.

> This is not a representative mine path demo — suitable for **basic motion and velocity testing only**.

---

## 4. Lab Demo Run — `5%ofminepath_beforeController`

**Run date:** October 13, 2026  
**Status:** Open-loop baseline (no PID feedback)

### Configuration

| Parameter | Value |
|-----------|-------|
| Route file | `route_points.csv` |
| Waypoints used | 37 out of 7,294 (~0.5% of full route) |
| map_scale | 16 |
| dt | 0.72s |
| Space | 1.83m × 4.27m (6ft × 14ft lab) |
| Controller | Open-loop (no PID feedback) |

### Results

| Metric | Value |
|--------|-------|
| Average linear speed | 0.0800 m/s |
| Max angular velocity | 2.5158 rad/s (limit: 2.84 rad/s ✅) |
| Total run time | 25.9s |

### Observations

- The Simulink XY graph matches the shape of the MATLAB planned path closely, confirming open-loop velocity commands are being followed.
- The orientation fix (`dtheta = [0; diff(theta)]`) was applied — the robot aligns to the correct initial heading before moving.
- Path shape is consistent between planned and executed trajectories.
- This run is a **baseline before any PID or closed-loop position control** is implemented.

---

## 5. Summary and Next Steps

| Setting | map_scale | Space needed | Speed |
|---------|-----------|--------------|-------|
| Recommended | 13 | 45.8m × 69.4m | 0.10 m/s |
| Minimum | 16 | 37.3m × 56.4m | 0.081 m/s |
| Current lab | 16 | 1.83m × 4.27m | 0.081 m/s (5% only) |

**Action required:** Secure an outdoor or large indoor space of at least **37m × 56m** to run a meaningful portion of the mine route.

**Next development step:** Implement PID controller with odometry feedback (`/odom` subscription) to correct drift accumulation over longer runs.
