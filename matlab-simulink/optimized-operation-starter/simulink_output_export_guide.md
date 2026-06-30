# Exporting Optimized Simulink Results To CSV

This guide explains how to extract results after running the optimized Simulink model.

The simulation output shown in MATLAB is usually a `Simulink.SimulationOutput` object named `out`. That object is a container. The numerical results are stored inside one of its logged signals, output ports, or `To Workspace` variables.

## Expected Scenario Output Vector

The optimized model should write the same 7-value output vector used by the baseline model:

```text
[speed_kph, distance_m, fuel_l, fuelRate_lph, instSfc_l_per_tkm, productiveTonKm, targetSpeed_kph]
```

These become the CSV columns:

| Column | Meaning |
| --- | --- |
| `time_s` | simulation time |
| `speed_kph` | truck speed |
| `distance_m` | cumulative route distance |
| `fuel_l` | cumulative fuel used |
| `fuelRate_lph` | instantaneous fuel rate |
| `instSfc_l_per_tkm` | instantaneous SFC |
| `productiveTonKm` | cumulative productive work |
| `targetSpeed_kph` | controller target speed |

## Step 1: Run The Model

Run the optimized model normally in Simulink.

After the run, MATLAB should show a workspace variable named:

```matlab
out
```

## Step 2: Check What Is Inside `out`

In the MATLAB Command Window:

```matlab
out.who
```

This lists the logged variables stored inside the simulation output object.

Common useful names are:

```text
yout
logsout
simout
optimized_log
optimizedScenarioOutput
```

If `out.who` only shows metadata and no signal/output names, the model is running but the signal is not being saved. See the troubleshooting section below.

## Step 3: Export The Optimized Results

From the folder:

```text
matlab-simulink/optimized-operation-starter
```

run:

```matlab
[optimizedSamples, optimizedSummary] = export_optimized_simulink_output(out, "optimized");
```

If MATLAB reports:

```text
Unrecognized function or variable 'export_optimized_simulink_output'
```

then MATLAB is not currently looking in the folder that contains the exporter. Use either of these fixes.

Option 1, run the helper script:

```matlab
run_export_after_simulation
```

Option 2, add the folder manually:

```matlab
cd('/home/linuxpc/Downloads/Summer2026-Simulation-main/matlab-simulink/optimized-operation-starter')
addpath(pwd)
rehash
which export_optimized_simulink_output
[optimizedSamples, optimizedSummary] = export_optimized_simulink_output(out, "optimized");
```

If `which export_optimized_simulink_output` prints `not found`, the local copy of the repository is missing the new export file. Download or pull the latest version of the repository.

This writes:

```text
optimized_timeseries.csv
optimized_summary.csv
```

The timeseries file contains all simulation samples. The summary file contains final comparison metrics such as travel time, final distance, fuel use, cycle SFC, and average speed.

## Step 4: Compare Against The Reference

Open:

```text
reference_expected_comparison.csv
```

The optimized summary should be close to the reference optimized values:

| Metric | Expected optimized value |
| --- | ---: |
| travel time | about `693 s` |
| fuel use | about `15.97 L` |
| SFC | about `0.0289 L/t-km` |
| final distance | `3560 m` |
| productive work | about `552.42 t-km` |

Small differences are acceptable. Large differences usually mean one of the following:

- the wrong payload band is selected;
- the wrong grade code is selected;
- the ML target speed is not passing through the safety governor;
- the output vector order changed;
- the model is stopping too early or too late.

## Important: Do Not Average Cumulative Signals

The logged scenario vector contains a mix of instantaneous signals and cumulative signals. These should not all be averaged.

| Signal | Correct summary value |
| --- | --- |
| `speed_kph` | average only over the active travel portion, or compute `finalDistance_m / travelTime_s` |
| `distance_m` | final value, not average |
| `fuel_l` | final value, not average |
| `fuelRate_lph` | average may be useful, but it is not the final fuel use |
| `instSfc_l_per_tkm` | do not use simple average for cycle SFC |
| `productiveTonKm` | final value, not average |
| `targetSpeed_kph` | average is only descriptive; compare time profile if possible |

The main comparison metrics should be calculated as:

```text
travelTime_s = time when final route distance is reached
finalDistance_m = final cumulative distance
fuel_l = final cumulative fuel
productiveTonKm = final cumulative t-km
cycleSfc_l_per_tkm = fuel_l / productiveTonKm
averageSpeed_kph = finalDistance_m / travelTime_s * 3.6
```

For example, averaging `cumulativeDistance_m` will produce a value near the middle of the route, not the final route distance. Averaging `cumulativeFuel_l` will produce a midpoint fuel value, not total fuel used.

## Troubleshooting: `out` Only Shows Metadata

If MATLAB shows `out` but no useful signal data, the model is not saving the scenario output.

Use one of these fixes.

### Option A: Save The Root Output Port

1. Open the optimized Simulink model.
2. Go to **Model Settings**.
3. Open **Data Import/Export**.
4. Enable **Output**.
5. Keep **Single simulation output** enabled.
6. Run the model again.
7. Check:

```matlab
out.who
```

There should now be an output variable such as `yout`.

### Option B: Add A `To Workspace` Block

1. Open the optimized model.
2. Find the final `Scenario Output` signal.
3. Add a `To Workspace` block connected to that signal.
4. Set **Variable name** to:

```text
optimized_log
```

5. Set **Save format** to either:

```text
Timeseries
```

or:

```text
Structure With Time
```

6. Run the model again.
7. Export:

```matlab
[optimizedSamples, optimizedSummary] = export_optimized_simulink_output(out, "optimized");
```

## Recommended Deliverable For The Weekend Assignment

Submit these files:

```text
optimized_timeseries.csv
optimized_summary.csv
```

Also include screenshots of:

- the top-level optimized Simulink model;
- the `Optimized Speed Advisor` block;
- the final output table in MATLAB.
