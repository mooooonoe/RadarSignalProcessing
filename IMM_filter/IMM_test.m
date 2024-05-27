% MATLAB code equivalent to the provided Python code

% Define time
t = linspace(0, 2*pi, 100);
dt = t(2) - t(1);

% Position
x = 2*cos(t);
y = sin(2*t);

% Velocity
dxdt = -2*sin(t);
dydt = 2*cos(2*t);

% Acceleration
d2xdt2 = -2*cos(t);
d2ydt2 = -4*sin(2*t);

% Jerk
d3xdt3 = 2*sin(t);
d3ydt3 = -8*cos(2*t);

% Angular speed (scalar)
omega = (dxdt .* d2ydt2 - dydt .* d2xdt2) ./ (dxdt.^2 + dydt.^2);

% Speed (scalar)
speed = sqrt(dxdt.^2 + dydt.^2);

% Measurement error
gps_sig = 0.1;
omega_sig = 0.3;
speed_sig = 0.1;

% Noisy measurements
x_gps = x + gps_sig * randn(size(x));
y_gps = y + gps_sig * randn(size(y));
omega_sens = omega + omega_sig * randn(size(omega));
speed_sens = speed + speed_sig * randn(size(speed));

% Plotting the position
figure;
subplot(2,2,1);
plot(x, y, 'DisplayName', 'True position'); hold on;
scatter(x_gps, y_gps, 5, 'red', 'filled', 'DisplayName', 'GPS measurements');
xlabel('x');
ylabel('y');
title('Position');
legend;

% Plotting the angular speed
subplot(2,2,2);
plot(t, omega, 'DisplayName', 'True angular speed'); hold on;
scatter(t, omega_sens, 5, 'red', 'filled', 'DisplayName', 'Measured angular speed');
xlabel('Time');
ylabel('Angular Speed');
title('Angular Speed');
legend;

% Plotting the speed
subplot(2,2,3);
plot(t, speed, 'DisplayName', 'True speed'); hold on;
scatter(t, speed_sens, 5, 'red', 'filled', 'DisplayName', 'Measured speed');
xlabel('Time');
ylabel('Speed');
title('Speed');
legend;

% Adjust layout
sgtitle('Position, Angular Speed, and Speed');
set(gcf, 'Position', [100, 100, 800, 600]);
