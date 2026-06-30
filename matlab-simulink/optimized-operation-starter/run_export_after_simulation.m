%RUN_EXPORT_AFTER_SIMULATION Export baseline or optimized Simulink results.
%
% Use this script after running the Simulink model.
%
% Required workspace variable:
%
%   out
%
% This script adds the current folder to the MATLAB path, finds the
% scenario output inside the Simulink output object, and writes CSV files.
%
% Change this value to "baseline" when exporting a baseline run.
scenarioName = "optimized";

starterFolder = fileparts(mfilename("fullpath"));
addpath(starterFolder);
rehash;

fprintf("Export helper folder:\n%s\n\n", starterFolder);
fprintf("Function location:\n");
which export_optimized_simulink_output
fprintf("\n");

if exist("out", "var") ~= 1
    if evalin("base", "exist('out','var') == 1")
        out = evalin("base", "out");
    else
        error("Variable 'out' was not found. Run the Simulink model first, then run this script.");
    end
end

fprintf("Variables stored inside out:\n");
try
    disp(out.who);
catch
    disp("Could not list out.who. The exporter will still try to read the output.");
end

[scenarioSamples, scenarioSummary] = export_optimized_simulink_output(out, scenarioName);

assignin("base", scenarioName + "Samples", scenarioSamples);
assignin("base", scenarioName + "Summary", scenarioSummary);

fprintf("\nExport complete.\n");
fprintf("Created files:\n");
fprintf("  %s_timeseries.csv\n", scenarioName);
fprintf("  %s_summary.csv\n", scenarioName);

