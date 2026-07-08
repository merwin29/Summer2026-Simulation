%RUN_TURTLEBOT_WAYPOINT_FOLLOWER_ROS1 Run a conservative ROS1 waypoint follower.
%
% This is the first closed-loop step after open-loop CSV playback.
%
% Required before running:
%   1. TurtleBot bringup is active.
%   2. MATLAB is connected to ROS using rosinit.
%   3. /odom and /cmd_vel are visible in rostopic list.
%
% The controller reads /odom, steers toward the next waypoint, and publishes
% capped geometry_msgs/Twist commands to /cmd_vel.

waypointHandoff = load_turtlebot_waypoints("stage12_turtle_route_waypoints.csv");

params = struct();
params.maxLinear_mps = 0.05;
params.maxAngular_radps = 0.40;
params.kHeading = 1.20;
params.kDistance = 0.45;
params.switchRadius_m = 0.15;
params.turnInPlaceAngle_rad = pi / 4;

sampleRate_hz = 10;
maxRunTime_s = 420;
startWaypointIndex = 2;

fprintf("Starting ROS1 waypoint follower.\n");
fprintf("Max linear: %.3f m/s\n", params.maxLinear_mps);
fprintf("Max angular: %.3f rad/s\n", params.maxAngular_radps);
fprintf("Switch radius: %.3f m\n", params.switchRadius_m);
fprintf("Max run time: %.1f s\n", maxRunTime_s);

cmdPub = rospublisher("/cmd_vel", "geometry_msgs/Twist");
cmdMsg = rosmessage(cmdPub);
odomSub = rossubscriber("/odom", "nav_msgs/Odometry");

fprintf("Waiting for first /odom message to align route waypoints...\n");
initialOdomMsg = receive(odomSub, 5.0);
[initialX_m, initialY_m, initialYaw_rad] = odomPose2d(initialOdomMsg);
waypointXY_odom_m = transformWaypointsToOdomFrame( ...
    waypointHandoff.xy_m, initialX_m, initialY_m, initialYaw_rad);

fprintf("Initial odom pose: x=%.3f m, y=%.3f m, yaw=%.3f rad\n", ...
    initialX_m, initialY_m, initialYaw_rad);
fprintf("Waypoint route has been aligned to the initial odom pose.\n");

cleanupObj = onCleanup(@() sendStopCommand(cmdPub, cmdMsg));
rate = rosrate(sampleRate_hz);

waypointIndex = startWaypointIndex;
routeDone = false;
testStart = tic;

maxRows = ceil(maxRunTime_s * sampleRate_hz) + 10;
logData = nan(maxRows, 11);
logRow = 0;

while toc(testStart) < maxRunTime_s && ~routeDone
    try
        odomMsg = receive(odomSub, 1.0);
    catch
        warning("No /odom message received within 1 second. Sending stop command.");
        sendStopCommand(cmdPub, cmdMsg);
        waitfor(rate);
        continue;
    end

    [x_m, y_m, yaw_rad] = odomPose2d(odomMsg);

    [linearCmd_mps, angularCmd_radps, waypointIndex, routeDone, debug] = ...
        compute_turtlebot_waypoint_command( ...
            x_m, y_m, yaw_rad, waypointXY_odom_m, waypointIndex, params);

    cmdMsg.Linear.X = linearCmd_mps;
    cmdMsg.Linear.Y = 0.0;
    cmdMsg.Linear.Z = 0.0;
    cmdMsg.Angular.X = 0.0;
    cmdMsg.Angular.Y = 0.0;
    cmdMsg.Angular.Z = angularCmd_radps;
    send(cmdPub, cmdMsg);

    logRow = logRow + 1;
    if logRow <= maxRows
        logData(logRow, :) = [ ...
            toc(testStart), ...
            x_m, ...
            y_m, ...
            yaw_rad, ...
            debug.activeWaypointIndex, ...
            debug.targetX_m, ...
            debug.targetY_m, ...
            debug.distanceToWaypoint_m, ...
            debug.headingError_rad, ...
            linearCmd_mps, ...
            angularCmd_radps];
    end

    waitfor(rate);
end

sendStopCommand(cmdPub, cmdMsg);

logData = logData(1:logRow, :);
logTable = array2table(logData, "VariableNames", { ...
    "time_s", ...
    "odom_x_m", ...
    "odom_y_m", ...
    "odom_yaw_rad", ...
    "activeWaypointIndex", ...
    "target_x_m", ...
    "target_y_m", ...
    "distanceToWaypoint_m", ...
    "headingError_rad", ...
    "cmd_linear_mps", ...
    "cmd_angular_radps"});

writetable(logTable, "turtlebot_waypoint_follower_log.csv");
writetable(array2table(waypointXY_odom_m, "VariableNames", {"x_m", "y_m"}), ...
    "turtlebot_waypoints_in_odom_frame.csv");

fprintf("Waypoint follower finished.\n");
fprintf("Route done: %d\n", routeDone);
fprintf("Rows logged: %d\n", height(logTable));
fprintf("Wrote turtlebot_waypoint_follower_log.csv\n");
fprintf("Wrote turtlebot_waypoints_in_odom_frame.csv\n");

function waypointXY_odom_m = transformWaypointsToOdomFrame(waypointXY_route_m, initialX_m, initialY_m, initialYaw_rad)
routeOrigin = waypointXY_route_m(1, :);
relativeRoute = waypointXY_route_m - routeOrigin;

rotation = [ ...
    cos(initialYaw_rad), -sin(initialYaw_rad); ...
    sin(initialYaw_rad),  cos(initialYaw_rad)];

waypointXY_odom_m = (rotation * relativeRoute.').';
waypointXY_odom_m(:, 1) = waypointXY_odom_m(:, 1) + initialX_m;
waypointXY_odom_m(:, 2) = waypointXY_odom_m(:, 2) + initialY_m;
end

function [x_m, y_m, yaw_rad] = odomPose2d(odomMsg)
x_m = odomMsg.Pose.Pose.Position.X;
y_m = odomMsg.Pose.Pose.Position.Y;
q = odomMsg.Pose.Pose.Orientation;

qx = q.X;
qy = q.Y;
qz = q.Z;
qw = q.W;

yaw_rad = atan2(2.0 * (qw * qz + qx * qy), 1.0 - 2.0 * (qy^2 + qz^2));
end

function sendStopCommand(cmdPub, cmdMsg)
cmdMsg.Linear.X = 0.0;
cmdMsg.Linear.Y = 0.0;
cmdMsg.Linear.Z = 0.0;
cmdMsg.Angular.X = 0.0;
cmdMsg.Angular.Y = 0.0;
cmdMsg.Angular.Z = 0.0;
send(cmdPub, cmdMsg);
end
