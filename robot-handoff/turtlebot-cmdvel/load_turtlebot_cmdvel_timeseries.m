function handoff = load_turtlebot_cmdvel_timeseries(csvFile, linearScale, angularScale)
%LOAD_TURTLEBOT_CMDVEL_TIMESERIES Load cmd_vel CSV output for Simulink.
%
% This helper converts stage12_turtle_cmd_vel_schedule.csv into the
% workspace variables commonly used by Simulink From Workspace blocks:
%
%   vel_ts      -> linear velocity command, m/s
%   ang_vel_ts  -> angular velocity command, rad/s
%
% Usage:
%
%   handoff = load_turtlebot_cmdvel_timeseries();
%   handoff = load_turtlebot_cmdvel_timeseries("stage12_turtle_cmd_vel_schedule.csv", 1/3.6, 1.0);
%
% Important:
%   linear_velocity_mps is already in m/s. The linearScale argument is a
%   lab safety multiplier, not a unit conversion.

if nargin < 1 || strlength(string(csvFile)) == 0
    csvFile = "stage12_turtle_cmd_vel_schedule.csv";
end

if nargin < 2 || isempty(linearScale)
    linearScale = 1.0;
end

if nargin < 3 || isempty(angularScale)
    angularScale = 1.0;
end

csvFile = string(csvFile);

if ~isfile(csvFile)
    error("CSV file was not found: %s", csvFile);
end

T = readtable(csvFile);
requiredColumns = ["time_s", "linear_velocity_mps", "angular_velocity_radps"];

for k = 1:numel(requiredColumns)
    if ~ismember(requiredColumns(k), string(T.Properties.VariableNames))
        error("Missing required column '%s' in %s.", requiredColumns(k), csvFile);
    end
end

time_s = T.time_s;
linear_raw_mps = T.linear_velocity_mps;
angular_raw_radps = T.angular_velocity_radps;

if any(~isfinite(time_s)) || any(~isfinite(linear_raw_mps)) || any(~isfinite(angular_raw_radps))
    error("The command CSV contains NaN or Inf values.");
end

if any(diff(time_s) <= 0)
    error("The time_s column must be strictly increasing.");
end

linear_cmd_mps = linear_raw_mps .* linearScale;
angular_cmd_radps = angular_raw_radps .* angularScale;

vel_ts = timeseries(linear_cmd_mps, time_s);
vel_ts.Name = "cmd_vel_linear_x_mps";
vel_ts.TimeInfo.Units = "seconds";
vel_ts.DataInfo.Units = "m/s";

ang_vel_ts = timeseries(angular_cmd_radps, time_s);
ang_vel_ts.Name = "cmd_vel_angular_z_radps";
ang_vel_ts.TimeInfo.Units = "seconds";
ang_vel_ts.DataInfo.Units = "rad/s";

handoff = struct();
handoff.csvFile = csvFile;
handoff.sampleCount = height(T);
handoff.startTime_s = time_s(1);
handoff.stopTime_s = time_s(end);
handoff.samplePeriod_s = median(diff(time_s));
handoff.linearScale = linearScale;
handoff.angularScale = angularScale;
handoff.maxRawLinear_mps = max(abs(linear_raw_mps));
handoff.maxRawAngular_radps = max(abs(angular_raw_radps));
handoff.maxCommandLinear_mps = max(abs(linear_cmd_mps));
handoff.maxCommandAngular_radps = max(abs(angular_cmd_radps));
handoff.commandTable = T;
handoff.vel_ts = vel_ts;
handoff.ang_vel_ts = ang_vel_ts;

assignin("base", "cmdVelTable", T);
assignin("base", "vel_ts", vel_ts);
assignin("base", "ang_vel_ts", ang_vel_ts);
assignin("base", "cmdVelHandoff", handoff);

fprintf("Loaded TurtleBot cmd_vel schedule: %s\n", csvFile);
fprintf("Samples: %d\n", handoff.sampleCount);
fprintf("Time range: %.2f to %.2f s\n", handoff.startTime_s, handoff.stopTime_s);
fprintf("Median sample period: %.3f s\n", handoff.samplePeriod_s);
fprintf("Linear scale: %.4f\n", linearScale);
fprintf("Angular scale: %.4f\n", angularScale);
fprintf("Max raw linear command: %.3f m/s\n", handoff.maxRawLinear_mps);
fprintf("Max scaled linear command: %.3f m/s\n", handoff.maxCommandLinear_mps);
fprintf("Max raw angular command: %.3f rad/s\n", handoff.maxRawAngular_radps);
fprintf("Max scaled angular command: %.3f rad/s\n", handoff.maxCommandAngular_radps);
fprintf("\nCreated workspace variables: vel_ts, ang_vel_ts, cmdVelTable, cmdVelHandoff\n");

end

