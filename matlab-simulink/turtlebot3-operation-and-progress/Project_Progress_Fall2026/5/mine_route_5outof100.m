cd("/home/linuxpc/Downloads/Summer2026-Simulation-main/matlab-simulink/physics-robot-bridge-model/outputs/MineSite");

a = readtable('route_points.csv');
xpos = a{1:end, 'x'};
ypos = a{1:end, 'y'};

space_x = 6  * 0.3048;   % 1.83m
space_y = 14 * 0.3048;   % 4.27m

map_scale = 16;
dt        = 0.72;

% Find how many waypoints fit
n_waypoints = length(xpos);
for n = 2:length(xpos)
    x_range = (max(xpos(1:n)) - min(xpos(1:n))) / map_scale;
    y_range = (max(ypos(1:n)) - min(ypos(1:n))) / map_scale;
    if x_range > space_x || y_range > space_y
        n_waypoints = n - 1;
        break;
    end
end

fprintf('Using first %d waypoints out of %d total\n', n_waypoints, length(xpos));

xpos = xpos(1:n_waypoints);
ypos = ypos(1:n_waypoints);

positions = [xpos./map_scale, ypos./map_scale];

dx = diff(positions(:,1));
dy = diff(positions(:,2));
t  = dt * ones(size(dx));

v_x = dx ./ t;
v_y = dy ./ t;
v_L = sqrt((v_x.^2) + (v_y.^2));
v_L = min(v_L, 0.22);

% Fixed: restore initial heading so robot faces the right direction
theta  = atan2(dy, dx);
dtheta = [theta(1); diff(theta)];    % <-- changed from [0; diff(theta)]
dtheta = atan2(sin(dtheta), cos(dtheta));
v_theta = dtheta ./ t;
v_theta = max(min(v_theta, 2.84), -2.84);

v_L     = [v_L;     0];
v_theta = [v_theta; 0];
time    = (0:dt:(length(v_L)-1)*dt)';

cd("/home/linuxpc/Downloads/Summer2026-Simulation-main/matlab-simulink/physics-robot-bridge-model/outputs");
T = table(time, v_L, v_theta, 'VariableNames', {'Time_s', 'Linear_vel_ms', 'Angular_vel_rads'});
writetable(T, 'velocity_commands.csv');

vel_ts     = timeseries(T.Linear_vel_ms,    T.Time_s);
ang_vel_ts = timeseries(T.Angular_vel_rads, T.Time_s);

fprintf('Average linear speed: %.4f m/s\n',  mean(v_L(1:end-1)));
fprintf('Max angular velocity: %.4f rad/s\n', max(abs(v_theta)));
fprintf('Total run time:       %.1f s\n',     time(end));
disp('CSV written successfully');
