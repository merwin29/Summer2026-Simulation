function report = runStage12PhysicsKinematicsBridge(routeId, vehicleId)
%RUNSTAGE12PHYSICSKINEMATICSBRIDGE Build and run physics/robot bridge model.
%
% Stage 12 introduces two built-in MATLAB/Simulink modeling families:
%   1. Simscape Driveline Longitudinal Vehicle for full-scale haul-truck
%      longitudinal physics.
%   2. Robotics System Toolbox Unicycle Kinematic Model for Turtle-style
%      robot path playback and /cmd_vel handoff.
%
% Examples:
%   report = runStage12PhysicsKinematicsBridge()
%   report = runStage12PhysicsKinematicsBridge("open_pit_demo", "large_diesel_haul_truck")

if nargin < 1 || strlength(string(routeId)) == 0
    routeId = "open_pit_demo";
end
if nargin < 2 || strlength(string(vehicleId)) == 0
    vehicleId = "large_diesel_haul_truck";
end

project = setupHaulageProject();
route = selectRouteScenario(routeId);
vehicle = selectVehicleScenario(vehicleId);
options = defineSimulationOptions();
policy = loadSpeedPolicy(project.policyCsv);
payloadSchedule = haulage.buildPayloadScheduleFromRoute(route, vehicle);

optimizedScenario = haulage.simulateRoute(route, vehicle, policy, payloadSchedule, "optimized", options);
longitudinal = buildLongitudinalDriveCycle(optimizedScenario.log, vehicle);

labRoute = selectRouteScenario("lab_track_demo");
turtle = buildTurtleRobotHandoff(labRoute, project.outputDir);

stage12_longitudinal_target_speed_mps = longitudinal.targetSpeedTs;
stage12_longitudinal_grade_pct = longitudinal.gradeTs;
stage12_turtle_linear_velocity_mps = turtle.linearVelocityTs;
stage12_turtle_angular_velocity_radps = turtle.angularVelocityTs;

stage12InputPath = fullfile(project.outputDir, "stage12_physics_kinematics_inputs.mat");
save(stage12InputPath, ...
    "stage12_longitudinal_target_speed_mps", ...
    "stage12_longitudinal_grade_pct", ...
    "stage12_turtle_linear_velocity_mps", ...
    "stage12_turtle_angular_velocity_radps");
loadStage12PhysicsKinematicsBridgeInputs(project.rootDir);

params = struct();
params.modelPath = fullfile(project.rootDir, "simulink", "HaulagePhysicsKinematicsBridge.slx");
params.stopTime_s = 390;
params.longitudinalDemoScope = "Loaded outbound physics slice before dump-approach retarding transition";
params.loadedMass_kg = vehicle.base.emptyMass_kg + 279000;
params.tireRollingRadius_m = 1.8;
params.rollingCoefficient = 0.03;
params.dragCoefficient = vehicle.base.dragCoefficient;
params.frontalArea_m2 = vehicle.base.frontalArea_m2;
params.maxDriveTorque_Nm = 1100000;
params.maxBrakeForce_N = 300000;
params.torqueGain = 120000;
params.brakeGain = 120000;

[modelName, modelPath] = buildStage12PhysicsKinematicsBridgeModel(params);

fprintf("Running Stage 12 physics/kinematics bridge model: %s\n", modelName);
simOut = sim(modelName);

longitudinalLog = collectLongitudinalLog(simOut);
turtleLog = collectTurtleLog(simOut);
summary = summarizeStage12(longitudinalLog, turtleLog, params);

longitudinalDriveCyclePath = fullfile(project.outputDir, "stage12_longitudinal_drive_cycle.csv");
longitudinalLogPath = fullfile(project.outputDir, "stage12_longitudinal_simscape_signal_log.csv");
turtleLogPath = fullfile(project.outputDir, "stage12_turtle_kinematic_signal_log.csv");
summaryPath = fullfile(project.outputDir, "stage12_physics_kinematics_summary.csv");
dashboardPath = fullfile(project.outputDir, "stage12_physics_kinematics_dashboard.png");
reportPath = fullfile(project.outputDir, "stage12_physics_kinematics_report.mat");

writetable(longitudinal.driveCycleTable, longitudinalDriveCyclePath);
writetable(longitudinalLog, longitudinalLogPath);
writetable(turtleLog, turtleLogPath);
writetable(summary, summaryPath);
plotStage12Dashboard(longitudinalLog, turtleLog, turtle.waypointTable, turtle.commandTable, dashboardPath);

report = struct();
report.project = project;
report.route = route;
report.vehicle = vehicle;
report.payloadSchedule = payloadSchedule;
report.optimizedScenario = optimizedScenario;
report.longitudinal = longitudinal;
report.turtle = turtle;
report.params = params;
report.modelName = modelName;
report.modelPath = modelPath;
report.simOut = simOut;
report.longitudinalLog = longitudinalLog;
report.turtleLog = turtleLog;
report.summary = summary;
report.files = struct( ...
    "modelPath", modelPath, ...
    "longitudinalDriveCyclePath", longitudinalDriveCyclePath, ...
    "stage12InputPath", stage12InputPath, ...
    "longitudinalLogPath", longitudinalLogPath, ...
    "turtleWaypointPath", turtle.waypointPath, ...
    "turtleCmdVelPath", turtle.commandPath, ...
    "turtleHandoffPath", turtle.handoffPath, ...
    "turtleLogPath", turtleLogPath, ...
    "summaryPath", summaryPath, ...
    "dashboardPath", dashboardPath, ...
    "reportPath", reportPath);

save(reportPath, "report");

fprintf("\nStage 12 run complete.\n");
fprintf("  model:                 %s\n", modelPath);
fprintf("  model input MAT:       %s\n", stage12InputPath);
fprintf("  dashboard:             %s\n", dashboardPath);
fprintf("  longitudinal log:      %s\n", longitudinalLogPath);
fprintf("  turtle waypoints:      %s\n", turtle.waypointPath);
fprintf("  turtle cmd_vel:        %s\n", turtle.commandPath);
fprintf("  turtle handoff JSON:   %s\n", turtle.handoffPath);
fprintf("  summary:               %s\n", summaryPath);
disp(summary);
end

function longitudinal = buildLongitudinalDriveCycle(optimizedLog, vehicle)
log = optimizedLog;
time_s = [0; log.time_s];
targetSpeed_mps = [log.targetSpeed_kph(1); log.targetSpeed_kph] / 3.6;
grade_pct = [log.geometricGrade_pct(1); log.geometricGrade_pct];
payload_t = [log.payload_t(1); log.payload_t];
segmentId = [log.segmentId(1); log.segmentId];

stopTime_s = ceil(max(time_s) + 20);
time_s = [time_s; stopTime_s];
targetSpeed_mps = [targetSpeed_mps; 0];
grade_pct = [grade_pct; 0];
payload_t = [payload_t; payload_t(end)];
segmentId = [segmentId; segmentId(end)];

driveCycleTable = table(time_s, segmentId, payload_t, grade_pct, ...
    targetSpeed_mps, targetSpeed_mps * 3.6, ...
    repmat(vehicle.base.emptyMass_kg, numel(time_s), 1), ...
    'VariableNames', ["time_s", "segmentId", "payload_t", "grade_pct", ...
    "targetSpeed_mps", "targetSpeed_kph", "emptyMass_kg"]);

longitudinal = struct();
longitudinal.driveCycleTable = driveCycleTable;
longitudinal.targetSpeedTs = timeseries(targetSpeed_mps, time_s);
longitudinal.gradeTs = timeseries(grade_pct, time_s);
longitudinal.stopTime_s = stopTime_s;
end

function turtle = buildTurtleRobotHandoff(labRoute, outputDir)
if ~isfolder(outputDir)
    mkdir(outputDir);
end

rawXY = [labRoute.startX_m, labRoute.startY_m; labRoute.endX_m(end), labRoute.endY_m(end)];
rawZ = [labRoute.startZ_m; labRoute.endZ_m(end)];
firstHeading = atan2(rawXY(2, 2) - rawXY(1, 2), rawXY(2, 1) - rawXY(1, 1));
rotation = [cos(-firstHeading), -sin(-firstHeading); sin(-firstHeading), cos(-firstHeading)];
localXY = (rawXY - rawXY(1, :)) * rotation.';
localXY(abs(localXY) < 1e-10) = 0;

waypointId = (1:size(localXY, 1))';
sourceSegmentId = [labRoute.segmentId; labRoute.segmentId(end)];
grade_pct = [labRoute.geometricGrade_pct; labRoute.geometricGrade_pct(end)];
speedLimit_mps = [labRoute.speedLimit_kph; labRoute.speedLimit_kph(end)] / 3.6;
waypointTable = table(waypointId, sourceSegmentId, localXY(:, 1), localXY(:, 2), rawZ, ...
    grade_pct, speedLimit_mps, ...
    'VariableNames', ["waypointId", "sourceSegmentId", "x_m", "y_m", "z_m", ...
    "grade_pct", "speedLimit_mps"]);

dt = 0.1;
maxLinear_mps = 0.18;
maxAngular_radps = 0.65;
time = 0.0;
heading = 0.0;
rows = table();

for idx = 1:(height(waypointTable) - 1)
    p0 = [waypointTable.x_m(idx), waypointTable.y_m(idx)];
    p1 = [waypointTable.x_m(idx + 1), waypointTable.y_m(idx + 1)];
    delta = p1 - p0;
    segmentDistance = hypot(delta(1), delta(2));
    if segmentDistance <= 1e-9
        continue;
    end

    desiredHeading = atan2(delta(2), delta(1));
    turnAngle = wrapAngle(desiredHeading - heading);
    if abs(turnAngle) > 1e-4
        turnOmega = sign(turnAngle) * maxAngular_radps;
        turnDuration = abs(turnAngle) / maxAngular_radps;
        [rows, time] = appendCommandRows(rows, time, dt, turnDuration, 0, turnOmega, ...
            idx, "turn", desiredHeading, waypointTable.grade_pct(idx));
        heading = desiredHeading;
    end

    segmentSpeed = min(maxLinear_mps, max(0.05, waypointTable.speedLimit_mps(idx)));
    driveDuration = segmentDistance / segmentSpeed;
    [rows, time] = appendCommandRows(rows, time, dt, driveDuration, segmentSpeed, 0, ...
        idx, "drive", desiredHeading, waypointTable.grade_pct(idx));
end

[rows, time] = appendCommandRows(rows, time, dt, 2.0, 0, 0, ...
    height(waypointTable), "stop", heading, waypointTable.grade_pct(end));

commandTable = rows;
commandTable.Properties.Description = "Open-loop Turtle robot /cmd_vel schedule generated from lab_track_demo route.";

waypointPath = fullfile(outputDir, "stage12_turtle_route_waypoints.csv");
commandPath = fullfile(outputDir, "stage12_turtle_cmd_vel_schedule.csv");
handoffPath = fullfile(outputDir, "stage12_turtle_robot_handoff.json");
writetable(waypointTable, waypointPath);
writetable(commandTable, commandPath);

handoff = struct();
handoff.topic = "/cmd_vel";
handoff.messageType = "geometry_msgs/Twist";
handoff.frameId = "map";
handoff.commandRate_hz = 10;
handoff.linearVelocityColumn = "linear_velocity_mps";
handoff.angularVelocityColumn = "angular_velocity_radps";
handoff.linearVelocityMapsTo = "Twist.linear.x";
handoff.angularVelocityMapsTo = "Twist.angular.z";
handoff.routeWaypointFile = waypointPath;
handoff.cmdVelScheduleFile = commandPath;
handoff.notes = [
    "Use this as a low-speed open-loop lab handoff first.";
    "Keep the robot on blocks or in an open test area during first playback.";
    "A closed-loop path follower should replace open-loop playback for hardware experiments.";
    "Grade is included as metadata for experiment logic; the Turtle robot command itself is planar /cmd_vel."];
writeJson(handoffPath, handoff);

turtle = struct();
turtle.waypointTable = waypointTable;
turtle.commandTable = commandTable;
turtle.waypointPath = waypointPath;
turtle.commandPath = commandPath;
turtle.handoffPath = handoffPath;
turtle.linearVelocityTs = timeseries(commandTable.linear_velocity_mps, commandTable.time_s);
turtle.angularVelocityTs = timeseries(commandTable.angular_velocity_radps, commandTable.time_s);
turtle.stopTime_s = ceil(time + 2);
end

function [rows, time] = appendCommandRows(rows, time, dt, duration, linearVelocity, angularVelocity, segmentId, phase, targetHeading, grade)
n = max(1, ceil(duration / dt));
newTime = time + (0:(n - 1))' * dt;
newRows = table(newTime, ...
    repmat(string(phase), n, 1), ...
    repmat(segmentId, n, 1), ...
    repmat(linearVelocity, n, 1), ...
    repmat(angularVelocity, n, 1), ...
    repmat(targetHeading, n, 1), ...
    repmat(grade, n, 1), ...
    repmat("/cmd_vel", n, 1), ...
    'VariableNames', ["time_s", "command_phase", "segmentId", ...
    "linear_velocity_mps", "angular_velocity_radps", "target_heading_rad", ...
    "grade_pct", "ros_topic"]);
if isempty(rows)
    rows = newRows;
else
    rows = [rows; newRows]; %#ok<AGROW>
end
time = time + n * dt;
end

function angle = wrapAngle(angle)
angle = atan2(sin(angle), cos(angle));
end

function writeJson(filePath, data)
text = jsonencode(data, PrettyPrint=true);
fid = fopen(filePath, "w");
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "%s\n", text);
end

function longitudinalLog = collectLongitudinalLog(simOut)
speedTs = simOut.get("stage12_longitudinal_speed_mps");
targetTs = simOut.get("stage12_longitudinal_target_log_mps");
gradeTs = simOut.get("stage12_longitudinal_grade_log_pct");
torqueTs = simOut.get("stage12_longitudinal_torque_log_Nm");
brakeTs = simOut.get("stage12_longitudinal_brake_log_N");

time_s = speedTs.Time(:);
actualSpeed_mps = speedTs.Data(:);
targetSpeed_mps = interp1(targetTs.Time(:), targetTs.Data(:), time_s, "linear", "extrap");
grade_pct = interp1(gradeTs.Time(:), gradeTs.Data(:), time_s, "linear", "extrap");
axleTorque_Nm = interp1(torqueTs.Time(:), torqueTs.Data(:), time_s, "previous", "extrap");
brakeForce_N = interp1(brakeTs.Time(:), brakeTs.Data(:), time_s, "previous", "extrap");

longitudinalLog = table(time_s, targetSpeed_mps, actualSpeed_mps, ...
    targetSpeed_mps * 3.6, actualSpeed_mps * 3.6, grade_pct, axleTorque_Nm, brakeForce_N, ...
    'VariableNames', ["time_s", "targetSpeed_mps", "actualSpeed_mps", ...
    "targetSpeed_kph", "actualSpeed_kph", "grade_pct", "axleTorque_Nm", "brakeForce_N"]);
end

function turtleLog = collectTurtleLog(simOut)
stateTs = simOut.get("stage12_turtle_state");
linearTs = simOut.get("stage12_turtle_linear_velocity_log_mps");
angularTs = simOut.get("stage12_turtle_angular_velocity_log_radps");

time_s = stateTs.Time(:);
state = squeeze(stateTs.Data);
if size(state, 1) ~= numel(time_s)
    state = state.';
end
linear_velocity_mps = interp1(linearTs.Time(:), linearTs.Data(:), time_s, "previous", "extrap");
angular_velocity_radps = interp1(angularTs.Time(:), angularTs.Data(:), time_s, "previous", "extrap");

turtleLog = table(time_s, state(:, 1), state(:, 2), state(:, 3), ...
    linear_velocity_mps, angular_velocity_radps, ...
    'VariableNames', ["time_s", "x_m", "y_m", "theta_rad", ...
    "linear_velocity_mps", "angular_velocity_radps"]);
end

function summary = summarizeStage12(longitudinalLog, turtleLog, params)
summary = table( ...
    params.loadedMass_kg, ...
    max(longitudinalLog.actualSpeed_kph), ...
    longitudinalLog.actualSpeed_kph(end), ...
    max(abs(longitudinalLog.axleTorque_Nm)), ...
    max(longitudinalLog.brakeForce_N), ...
    turtleLog.x_m(end), ...
    turtleLog.y_m(end), ...
    turtleLog.theta_rad(end), ...
    max(turtleLog.linear_velocity_mps), ...
    max(abs(turtleLog.angular_velocity_radps)), ...
    'VariableNames', ["loadedMass_kg", "longitudinalMaxSpeed_kph", ...
    "longitudinalFinalSpeed_kph", "maxAbsAxleTorque_Nm", "maxBrakeForce_N", ...
    "turtleFinalX_m", "turtleFinalY_m", "turtleFinalTheta_rad", ...
    "turtleMaxLinearVelocity_mps", "turtleMaxAbsAngularVelocity_radps"]);
end

function plotStage12Dashboard(longitudinalLog, turtleLog, waypointTable, commandTable, dashboardPath)
fig = figure("Name", "Stage 12 Physics/Kinematics Dashboard", "Color", "w", "Visible", "off");
tiledlayout(fig, 2, 2, "Padding", "compact", "TileSpacing", "compact");

nexttile;
plot(longitudinalLog.time_s, longitudinalLog.targetSpeed_kph, "LineWidth", 1.4);
hold on;
plot(longitudinalLog.time_s, longitudinalLog.actualSpeed_kph, "LineWidth", 1.4);
grid on;
xlabel("Time (s)");
ylabel("Speed (km/h)");
title("Longitudinal Vehicle: Target vs Actual Speed");
legend("ML target", "Simscape vehicle", "Location", "best");

nexttile;
yyaxis left;
plot(longitudinalLog.time_s, longitudinalLog.grade_pct, "LineWidth", 1.2);
ylabel("Grade (%)");
yyaxis right;
plot(longitudinalLog.time_s, abs(longitudinalLog.axleTorque_Nm) / 1000, "LineWidth", 1.2);
hold on;
plot(longitudinalLog.time_s, longitudinalLog.brakeForce_N / 1000, "LineWidth", 1.2);
ylabel("Torque / brake (kNm or kN)");
grid on;
xlabel("Time (s)");
title("Route Grade And Controller Effort");
legend("Grade", "Axle torque magnitude", "Brake force", "Location", "best");

nexttile;
plot(waypointTable.x_m, waypointTable.y_m, "ko--", "LineWidth", 1.1, "MarkerFaceColor", "w");
hold on;
plot(turtleLog.x_m, turtleLog.y_m, "b", "LineWidth", 1.5);
axis equal;
grid on;
xlabel("X (m)");
ylabel("Y (m)");
title("Turtle Robot Kinematic Path");
legend("Route waypoints", "Simulated robot path", "Location", "best");

nexttile;
plot(commandTable.time_s, commandTable.linear_velocity_mps, "LineWidth", 1.2);
hold on;
plot(commandTable.time_s, commandTable.angular_velocity_radps, "LineWidth", 1.2);
grid on;
xlabel("Time (s)");
ylabel("Command");
title("Turtle Robot /cmd_vel Schedule");
legend("linear.x (m/s)", "angular.z (rad/s)", "Location", "best");

exportgraphics(fig, dashboardPath, "Resolution", 180);
close(fig);
end
