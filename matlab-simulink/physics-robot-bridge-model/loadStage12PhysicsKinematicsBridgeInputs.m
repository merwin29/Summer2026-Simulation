function inputs = loadStage12PhysicsKinematicsBridgeInputs(projectRoot)
%LOADSTAGE12PHYSICSKINEMATICSBRIDGEINPUTS Load Stage 12 model inputs.
%
% The Stage 12 Simulink model uses From Workspace blocks. Those blocks need
% four timeseries variables in the MATLAB base workspace. This helper loads
% them from the saved Stage 12 input MAT file when available, or rebuilds
% them from the CSV outputs.
%
% Examples:
%   loadStage12PhysicsKinematicsBridgeInputs()
%   inputs = loadStage12PhysicsKinematicsBridgeInputs("C:\path\haulage_sim_framework")

if nargin < 1 || strlength(string(projectRoot)) == 0
    projectRoot = fileparts(mfilename("fullpath"));
end

projectRoot = string(projectRoot);
outputDir = fullfile(projectRoot, "outputs");
inputMatPath = fullfile(outputDir, "stage12_physics_kinematics_inputs.mat");

if isfile(inputMatPath)
    inputs = load(inputMatPath);
else
    inputs = rebuildInputsFromCsv(outputDir);
end

requiredVariables = [
    "stage12_longitudinal_target_speed_mps"
    "stage12_longitudinal_grade_pct"
    "stage12_turtle_linear_velocity_mps"
    "stage12_turtle_angular_velocity_radps"];

for idx = 1:numel(requiredVariables)
    variableName = requiredVariables(idx);
    if ~isfield(inputs, variableName)
        error("Stage12:MissingInput", ...
            "Required Stage 12 input '%s' was not found.", variableName);
    end
    assignin("base", variableName, inputs.(variableName));
end

fprintf("Loaded Stage 12 Simulink input variables from: %s\n", outputDir);
end

function inputs = rebuildInputsFromCsv(outputDir)
driveCyclePath = fullfile(outputDir, "stage12_longitudinal_drive_cycle.csv");
cmdVelPath = fullfile(outputDir, "stage12_turtle_cmd_vel_schedule.csv");

if ~isfile(driveCyclePath)
    error("Stage12:MissingDriveCycle", ...
        "Could not find %s. Run runStage12PhysicsKinematicsBridge first.", driveCyclePath);
end
if ~isfile(cmdVelPath)
    error("Stage12:MissingCmdVel", ...
        "Could not find %s. Run runStage12PhysicsKinematicsBridge first.", cmdVelPath);
end

driveCycle = readtable(driveCyclePath);
cmdVel = readtable(cmdVelPath);

inputs = struct();
inputs.stage12_longitudinal_target_speed_mps = timeseries( ...
    driveCycle.targetSpeed_mps, driveCycle.time_s);
inputs.stage12_longitudinal_grade_pct = timeseries( ...
    driveCycle.grade_pct, driveCycle.time_s);
inputs.stage12_turtle_linear_velocity_mps = timeseries( ...
    cmdVel.linear_velocity_mps, cmdVel.time_s);
inputs.stage12_turtle_angular_velocity_radps = timeseries( ...
    cmdVel.angular_velocity_radps, cmdVel.time_s);
end
