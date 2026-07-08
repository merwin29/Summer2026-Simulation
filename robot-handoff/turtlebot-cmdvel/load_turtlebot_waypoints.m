function waypointHandoff = load_turtlebot_waypoints(csvFile)
%LOAD_TURTLEBOT_WAYPOINTS Load robot-scale route waypoints for path following.
%
% Usage:
%
%   waypointHandoff = load_turtlebot_waypoints();
%   waypointHandoff = load_turtlebot_waypoints("stage12_turtle_route_waypoints.csv");
%
% The helper creates these base-workspace variables for Simulink/MATLAB use:
%
%   waypointTable
%   waypointXY
%   waypointSpeedLimit_mps
%   waypointHandoff

if nargin < 1 || strlength(string(csvFile)) == 0
    csvFile = "stage12_turtle_route_waypoints.csv";
end

csvFile = string(csvFile);

if ~isfile(csvFile)
    error("Waypoint CSV file was not found: %s", csvFile);
end

T = readtable(csvFile);
requiredColumns = ["waypointId", "x_m", "y_m", "speedLimit_mps"];

for k = 1:numel(requiredColumns)
    if ~ismember(requiredColumns(k), string(T.Properties.VariableNames))
        error("Missing required column '%s' in %s.", requiredColumns(k), csvFile);
    end
end

waypointXY = [T.x_m, T.y_m];
waypointSpeedLimit_mps = T.speedLimit_mps;

if any(~isfinite(waypointXY), "all") || any(~isfinite(waypointSpeedLimit_mps))
    error("Waypoint file contains NaN or Inf values.");
end

segmentLength_m = sqrt(sum(diff(waypointXY, 1, 1).^2, 2));
totalPathLength_m = sum(segmentLength_m);

waypointHandoff = struct();
waypointHandoff.csvFile = csvFile;
waypointHandoff.table = T;
waypointHandoff.xy_m = waypointXY;
waypointHandoff.speedLimit_mps = waypointSpeedLimit_mps;
waypointHandoff.segmentLength_m = segmentLength_m;
waypointHandoff.totalPathLength_m = totalPathLength_m;
waypointHandoff.count = height(T);

assignin("base", "waypointTable", T);
assignin("base", "waypointXY", waypointXY);
assignin("base", "waypointSpeedLimit_mps", waypointSpeedLimit_mps);
assignin("base", "waypointHandoff", waypointHandoff);

fprintf("Loaded TurtleBot route waypoints: %s\n", csvFile);
fprintf("Waypoint count: %d\n", waypointHandoff.count);
fprintf("Approximate path length: %.2f m\n", totalPathLength_m);
fprintf("\nCreated workspace variables: waypointTable, waypointXY, waypointSpeedLimit_mps, waypointHandoff\n");

end

