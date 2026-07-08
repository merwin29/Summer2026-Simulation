function [linearCmd_mps, angularCmd_radps, waypointIndex, routeDone, debug] = compute_turtlebot_waypoint_command(x_m, y_m, yaw_rad, waypointXY_m, waypointIndex, params)
%COMPUTE_TURTLEBOT_WAYPOINT_COMMAND Simple waypoint-following controller.
%
% The controller steers toward the active waypoint using current odometry.
% It is intentionally conservative for first lab tests.
%
% Inputs:
%   x_m, y_m, yaw_rad  current robot pose from /odom
%   waypointXY_m       N-by-2 array [x_m, y_m]
%   waypointIndex      active waypoint index
%   params             optional struct with controller limits
%
% Outputs:
%   linearCmd_mps      command for /cmd_vel.linear.x
%   angularCmd_radps   command for /cmd_vel.angular.z
%   waypointIndex      updated active waypoint index
%   routeDone          true when final waypoint is reached
%   debug              diagnostic struct for logging

if nargin < 6 || isempty(params)
    params = struct();
end

maxLinear_mps = getParam(params, "maxLinear_mps", 0.05);
maxAngular_radps = getParam(params, "maxAngular_radps", 0.40);
kHeading = getParam(params, "kHeading", 1.20);
kDistance = getParam(params, "kDistance", 0.45);
switchRadius_m = getParam(params, "switchRadius_m", 0.15);
turnInPlaceAngle_rad = getParam(params, "turnInPlaceAngle_rad", pi / 4);

nWaypoints = size(waypointXY_m, 1);
waypointIndex = max(1, min(round(waypointIndex), nWaypoints));

routeDone = false;
linearCmd_mps = 0.0;
angularCmd_radps = 0.0;

debug = struct();
debug.activeWaypointIndex = waypointIndex;
debug.targetX_m = NaN;
debug.targetY_m = NaN;
debug.distanceToWaypoint_m = NaN;
debug.desiredHeading_rad = NaN;
debug.headingError_rad = NaN;
debug.maxLinearUsed_mps = maxLinear_mps;

if nWaypoints == 0 || ~isfinite(x_m) || ~isfinite(y_m) || ~isfinite(yaw_rad)
    routeDone = true;
    return;
end

while waypointIndex <= nWaypoints
    target = waypointXY_m(waypointIndex, :);
    distanceToWaypoint_m = hypot(target(1) - x_m, target(2) - y_m);

    if distanceToWaypoint_m > switchRadius_m
        break;
    end

    waypointIndex = waypointIndex + 1;
end

if waypointIndex > nWaypoints
    routeDone = true;
    debug.activeWaypointIndex = nWaypoints;
    return;
end

target = waypointXY_m(waypointIndex, :);
dx = target(1) - x_m;
dy = target(2) - y_m;
distanceToWaypoint_m = hypot(dx, dy);
desiredHeading_rad = atan2(dy, dx);
headingError_rad = wrapToPiLocal(desiredHeading_rad - yaw_rad);

angularCmd_radps = clamp(kHeading * headingError_rad, -maxAngular_radps, maxAngular_radps);

if abs(headingError_rad) > turnInPlaceAngle_rad
    linearCmd_mps = 0.0;
else
    headingScale = max(0.0, cos(headingError_rad));
    linearCmd_mps = min(maxLinear_mps, kDistance * distanceToWaypoint_m) * headingScale;
end

debug.activeWaypointIndex = waypointIndex;
debug.targetX_m = target(1);
debug.targetY_m = target(2);
debug.distanceToWaypoint_m = distanceToWaypoint_m;
debug.desiredHeading_rad = desiredHeading_rad;
debug.headingError_rad = headingError_rad;
debug.maxLinearUsed_mps = maxLinear_mps;

end

function value = getParam(params, fieldName, defaultValue)
if isfield(params, fieldName)
    value = params.(fieldName);
else
    value = defaultValue;
end
end

function y = clamp(x, lower, upper)
y = min(max(x, lower), upper);
end

function angle = wrapToPiLocal(angle)
angle = mod(angle + pi, 2 * pi) - pi;
end

