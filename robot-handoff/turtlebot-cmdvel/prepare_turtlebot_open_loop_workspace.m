%PREPARE_TURTLEBOT_OPEN_LOOP_WORKSPACE Prepare Simulink inputs for TurtleBot playback.
%
% Run this script before opening or running a Simulink model that uses
% From Workspace blocks named vel_ts and ang_vel_ts.
%
% The source CSV already stores linear_velocity_mps in m/s. The linearScale
% below is a lab safety slowdown factor, not a unit conversion.

csvFile = "stage12_turtle_cmd_vel_schedule.csv";

% Use 1.0 to execute the generated command exactly.
% Use 1/3.6 for a slow first lab test around 0.05 m/s max forward speed.
linearScale = 1/3.6;

% Keep angular commands unchanged by default. Lower this for first tests if
% turns feel too aggressive.
angularScale = 1.0;

cmdVelHandoff = load_turtlebot_cmdvel_timeseries(csvFile, linearScale, angularScale);

fprintf("\nRecommended Simulink settings for live robot playback:\n");
fprintf("  SolverType: Fixed-step\n");
fprintf("  FixedStep: %.3f\n", cmdVelHandoff.samplePeriod_s);
fprintf("  EnablePacing: on\n");
fprintf("  PacingRate: 1\n");
fprintf("  StopTime: %.2f\n", cmdVelHandoff.stopTime_s);

