% 0. Regenerate the CSV trajectory using Python
fprintf('Regenerating trajectory from Python...\n');
pythonExe = 'c:\Users\merwinmendoza\Documents\Codex\2026-06-29\hel\work\moisture_platform\.venv\Scripts\python.exe';
pythonScript = 'C:\Users\merwinmendoza\Downloads\generate_custom_loop.py';
cmd = sprintf('"%s" "%s"', pythonExe, pythonScript);
[status, cmdOut] = system(cmd);
if status ~= 0
    warning('Python script failed:\n%s', cmdOut);
else
    fprintf('%s', cmdOut);
end

% 1. Load the CSV command schedule
csvPath = 'C:\Users\merwinmendoza\Downloads\Summer2026-Simulation-main\Summer2026-Simulation-main\matlab-simulink\physics-robot-bridge-model\outputs\stage12_turtle_cmd_vel_schedule.csv';
fprintf('Loading CSV data from %s...\n', csvPath);
schedule = readtable(csvPath);

% Create timeseries variables in the base workspace
assignin('base', 'autodrive_linear_vel', timeseries(schedule.linear_velocity_mps, schedule.time_s));
assignin('base', 'autodrive_angular_vel', timeseries(schedule.angular_velocity_radps, schedule.time_s));
fprintf('Loaded timeseries variables into base workspace.\n');

% 2. Modify the Simulink model
modelName = 'example_husky';
load_system(modelName);

blockPath = [modelName '/AutoDRIVE Husky'];
pos = get_param(blockPath, 'Position');

% Calculate block positions on the left side of the AutoDRIVE Husky block
x_src = pos(1) - 260;
x_gain = pos(1) - 100;
y9 = pos(2) + 215;
y10 = pos(2) + 255;

% Remove the old Constant blocks and their lines if they exist
inLines = get_param(blockPath, 'LineHandles');

% Handle Port 9 (Linear Velocity)
if isempty(find_system(modelName, 'SearchDepth', 1, 'Name', 'Linear Velocity From Workspace'))
    if inLines.Inport(9) ~= -1
        delete_line(inLines.Inport(9));
    end
    if ~isempty(find_system(modelName, 'SearchDepth', 1, 'Name', 'Linear Velocity'))
        delete_block([modelName '/Linear Velocity']);
    end
    
    % Add From Workspace and Gain blocks for Linear Velocity
    add_block('simulink/Sources/From Workspace', [modelName '/Linear Velocity From Workspace'], 'Position', [x_src, y9, x_src+130, y9+25]);
    set_param([modelName '/Linear Velocity From Workspace'], 'VariableName', 'autodrive_linear_vel');
    
    add_block('simulink/Math Operations/Gain', [modelName '/Linear Gain'], 'Position', [x_gain, y9, x_gain+40, y9+25]);
    set_param([modelName '/Linear Gain'], 'Gain', '1.0'); % Default gain is 1.0 (no scaling)
    
    % Connect blocks
    add_line(modelName, 'Linear Velocity From Workspace/1', 'Linear Gain/1', 'autorouting', 'on');
    add_line(modelName, 'Linear Gain/1', 'AutoDRIVE Husky/9', 'autorouting', 'on');
    fprintf('Configured Linear Velocity workspace block and Gain.\n');
end

% Handle Port 10 (Angular Velocity)
if isempty(find_system(modelName, 'SearchDepth', 1, 'Name', 'Angular Velocity From Workspace'))
    if inLines.Inport(10) ~= -1
        delete_line(inLines.Inport(10));
    end
    if ~isempty(find_system(modelName, 'SearchDepth', 1, 'Name', 'Angular Velocity'))
        delete_block([modelName '/Angular Velocity']);
    end
    
    % Add From Workspace and Gain blocks for Angular Velocity
    add_block('simulink/Sources/From Workspace', [modelName '/Angular Velocity From Workspace'], 'Position', [x_src, y10, x_src+130, y10+25]);
    set_param([modelName '/Angular Velocity From Workspace'], 'VariableName', 'autodrive_angular_vel');
    
    add_block('simulink/Math Operations/Gain', [modelName '/Angular Gain'], 'Position', [x_gain, y10, x_gain+40, y10+25]);
    set_param([modelName '/Angular Gain'], 'Gain', '1.0'); % Default gain is 1.0 (no scaling)
    
    % Connect blocks
    add_line(modelName, 'Angular Velocity From Workspace/1', 'Angular Gain/1', 'autorouting', 'on');
    add_line(modelName, 'Angular Gain/1', 'AutoDRIVE Husky/10', 'autorouting', 'on');
    fprintf('Configured Angular Velocity workspace block and Gain.\n');
end

% Set model StopTime to 150 seconds
set_param(modelName, 'StopTime', '150');
fprintf('Set model StopTime to 150 seconds.\n');

% Save the model changes
save_system(modelName);
fprintf('Successfully updated %s.slx and saved changes.\n', modelName);
