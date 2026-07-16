% Load the system
load_system('example_husky');

fprintf('Checking GPU settings in model configuration...\n');

% Set GPU Acceleration to off
try
    set_param('example_husky', 'GPUAcceleration', 'off');
    fprintf('Disabled GPUAcceleration.\n');
catch ME
    fprintf('Error setting GPUAcceleration: %s\n', ME.message);
end

% Set Generate GPU Code to None
try
    set_param('example_husky', 'GenerateGPUCode', 'None');
    fprintf('Disabled GenerateGPUCode.\n');
catch ME
    fprintf('Error setting GenerateGPUCode: %s\n', ME.message);
end

% Save and close
save_system('example_husky');
fprintf('Saved changes to example_husky.slx.\n');
