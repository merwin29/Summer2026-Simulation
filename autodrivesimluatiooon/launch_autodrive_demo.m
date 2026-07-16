% Add the AutoDRIVE Simulink API to MATLAB path
apiPath = 'C:\Users\merwinmendoza\Downloads\AutoDRIVE-Ecosystem-AutoDRIVE-MathWorks-2.0.3.0\autodrive_simulink_api';
addpath(genpath(apiPath));

% Open the Husky example Simulink model
open_system('example_husky.slx');

disp('AutoDRIVE path configured and example_husky.slx opened!');
disp('Please verify that AutoDRIVE Simulator is running, then press Run in Simulink.');
