function [sampleTable, summaryTable] = export_optimized_simulink_output(simOut, outputPrefix)
%EXPORT_OPTIMIZED_SIMULINK_OUTPUT Convert Simulink optimized scenario output to CSV.
%
% Usage after running the Simulink model:
%
%   [samples, summary] = export_optimized_simulink_output(out, "optimized");
%
% If the simulation output is named "out" in the base workspace, this also works:
%
%   [samples, summary] = export_optimized_simulink_output();
%
% The expected scenario vector is:
%
%   [speed_kph, distance_m, fuel_l, fuelRate_lph, ...
%    instSfc_l_per_tkm, productiveTonKm, targetSpeed_kph]
%
% The function writes:
%
%   optimized_timeseries.csv
%   optimized_summary.csv

if nargin < 1 || isempty(simOut)
    if evalin("base", "exist('out','var') == 1")
        simOut = evalin("base", "out");
    else
        error("No simulation output was provided, and variable 'out' was not found in the base workspace.");
    end
end

if nargin < 2 || strlength(string(outputPrefix)) == 0
    outputPrefix = "optimized";
end

outputPrefix = string(outputPrefix);
[time_s, data, sourceName] = findScenarioVector(simOut);

data = normalizeDataMatrix(data);

if size(data, 2) < 7
    error("The extracted signal has %d columns. Expected at least 7 columns for the scenario vector.", size(data, 2));
end

data = data(:, 1:7);
time_s = normalizeTimeVector(time_s, size(data, 1));

sampleTable = table( ...
    time_s(:), ...
    data(:, 1), ...
    data(:, 2), ...
    data(:, 3), ...
    data(:, 4), ...
    data(:, 5), ...
    data(:, 6), ...
    data(:, 7), ...
    'VariableNames', { ...
        'time_s', ...
        'speed_kph', ...
        'distance_m', ...
        'fuel_l', ...
        'fuelRate_lph', ...
        'instSfc_l_per_tkm', ...
        'productiveTonKm', ...
        'targetSpeed_kph'});

validDistance = isfinite(sampleTable.distance_m);
if any(validDistance)
    finalDistance_m = max(sampleTable.distance_m(validDistance));
    finalIdx = find(sampleTable.distance_m >= finalDistance_m - 1e-6, 1, "first");
else
    finalIdx = height(sampleTable);
    finalDistance_m = sampleTable.distance_m(finalIdx);
end

if isempty(finalIdx)
    finalIdx = height(sampleTable);
end

travelTime_s = sampleTable.time_s(finalIdx);
fuel_l = sampleTable.fuel_l(finalIdx);
productiveTonKm = max(sampleTable.productiveTonKm, [], "omitnan");

if productiveTonKm > 0
    cycleSfc_l_per_tkm = fuel_l / productiveTonKm;
else
    cycleSfc_l_per_tkm = NaN;
end

if travelTime_s > 0
    averageSpeed_kph = (finalDistance_m / travelTime_s) * 3.6;
else
    averageSpeed_kph = NaN;
end

summaryTable = table( ...
    sourceName, ...
    height(sampleTable), ...
    travelTime_s, ...
    finalDistance_m, ...
    fuel_l, ...
    productiveTonKm, ...
    cycleSfc_l_per_tkm, ...
    averageSpeed_kph, ...
    'VariableNames', { ...
        'sourceName', ...
        'sampleCount', ...
        'travelTime_s', ...
        'finalDistance_m', ...
        'fuel_l', ...
        'productiveTonKm', ...
        'cycleSfc_l_per_tkm', ...
        'averageSpeed_kph'});

timeseriesFile = outputPrefix + "_timeseries.csv";
summaryFile = outputPrefix + "_summary.csv";

writetable(sampleTable, timeseriesFile);
writetable(summaryTable, summaryFile);

fprintf("Extracted scenario output from: %s\n", sourceName);
fprintf("Wrote %s\n", timeseriesFile);
fprintf("Wrote %s\n", summaryFile);
disp(summaryTable);

end

function [time_s, data, sourceName] = findScenarioVector(simOut)
time_s = [];
data = [];
sourceName = "";

if isa(simOut, "Simulink.SimulationOutput")
    candidateNames = getSimulationOutputNames(simOut);

    preferredNames = [ ...
        "optimized_log", ...
        "optimizedScenarioOutput", ...
        "optimized_output", ...
        "simout", ...
        "yout", ...
        "logsout"];

    for name = preferredNames
        if any(candidateNames == name)
            value = simOut.get(char(name));
            [time_s, data] = extractFromValue(value);
            if ~isempty(data)
                sourceName = name;
                return;
            end
        end
    end

    for name = candidateNames(:)'
        value = simOut.get(char(name));
        [time_s, data] = extractFromValue(value);
        if ~isempty(data) && hasScenarioVectorShape(data)
            sourceName = name;
            return;
        end
    end

    error("No scenario vector was found inside the Simulink.SimulationOutput object. Check whether the output port or To Workspace block is being logged.");
else
    [time_s, data] = extractFromValue(simOut);
    if isempty(data)
        error("The provided value could not be converted into a scenario output table.");
    end
    sourceName = "direct_input";
end
end

function names = getSimulationOutputNames(simOut)
try
    names = string(simOut.who);
catch
    try
        names = string(who(simOut));
    catch
        names = strings(0, 1);
    end
end
end

function [time_s, data] = extractFromValue(value)
time_s = [];
data = [];

if isempty(value)
    return;
end

if isnumeric(value)
    data = value;
    return;
end

if isa(value, "timeseries")
    time_s = value.Time;
    data = value.Data;
    return;
end

if isa(value, "Simulink.SimulationData.Signal")
    [time_s, data] = extractFromValue(value.Values);
    return;
end

if isa(value, "Simulink.SimulationData.Dataset")
    for k = 1:value.numElements
        element = value.get(k);
        [candidateTime, candidateData] = extractFromValue(element);
        if ~isempty(candidateData) && hasScenarioVectorShape(candidateData)
            time_s = candidateTime;
            data = candidateData;
            return;
        end
    end
    return;
end

if isstruct(value)
    if isfield(value, "time") && isfield(value, "signals")
        time_s = value.time;
        signals = value.signals;
        if isstruct(signals) && isfield(signals, "values")
            data = signals.values;
            return;
        end
    end

    if isfield(value, "Values")
        [time_s, data] = extractFromValue(value.Values);
        return;
    end
end
end

function tf = hasScenarioVectorShape(data)
try
    data = normalizeDataMatrix(data);
    tf = size(data, 2) >= 7;
catch
    tf = false;
end
end

function data = normalizeDataMatrix(data)
data = squeeze(data);

if isvector(data)
    data = data(:).';
end

if ndims(data) > 2
    n = size(data, ndims(data));
    data = reshape(data, [], n).';
end

if size(data, 1) == 7 && size(data, 2) ~= 7
    data = data.';
end

if size(data, 2) > 7
    firstCol = data(:, 1);
    if all(isfinite(firstCol)) && all(diff(firstCol) >= 0)
        data = data(:, 2:end);
    end
end
end

function time_s = normalizeTimeVector(time_s, rowCount)
if isempty(time_s)
    time_s = (0:rowCount-1).';
    return;
end

time_s = squeeze(time_s);
time_s = time_s(:);

if numel(time_s) ~= rowCount
    time_s = (0:rowCount-1).';
end
end

