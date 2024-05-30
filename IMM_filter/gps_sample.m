clear; clc; close all;

load('x_radar.mat'); load('y_radar.mat');
t = linspace(0, 2*pi, length(x_radar));
dt = t(2) - t(1);

% 튀는 값 제거
mean_x = mean(x_radar);
std_x = std(x_radar);
mean_y = mean(y_radar);
std_y = std(y_radar);

threshold = 2; % 3 표준편차를 기준으로 이상치 제거
valid_indices = abs(x_radar - mean_x) < threshold * std_x & abs(y_radar - mean_y) < threshold * std_y;

x_radar_filtered = x_radar(valid_indices);
y_radar_filtered = y_radar(valid_indices);

% Plotting the position
figure;
subplot(2, 1, 1);
scatter(x_radar_filtered, y_radar_filtered, 5, 'red', 'filled', 'DisplayName', 'GPS measurements');
xlabel('x');
ylabel('y');
title('Position');
legend;
hold on;

% Adjust layout
sgtitle('Position and Normalized Distance');
set(gcf, 'Position', [100, 100, 800, 600]);

% Define measurements to be the position with noise
measPos = [x_radar_filtered; y_radar_filtered; zeros(size(x_radar_filtered))];

% Define the initial state and covariance
positionSelector = [1 0 0 0 0 0; 0 0 1 0 0 0; 0 0 0 0 1 0]; % Position from state
initialState = [x_radar_filtered(1); 0; y_radar_filtered(1); 0; 0; 0]; % First measurement as initial state
initialCovariance = diag([1, 1e4, 1, 1e4, 1, 1e4]); % Velocity is not measured

% Create a constant-velocity trackingEKF
cvekf = trackingEKF(@constvel, @cvmeas, initialState, ...
    'StateTransitionJacobianFcn', @constveljac, ...
    'MeasurementJacobianFcn', @cvmeasjac, ...
    'StateCovariance', initialCovariance, ...
    'HasAdditiveProcessNoise', false, ...
    'ProcessNoise', eye(3));

% Track using the constant-velocity filter with low process noise
numSteps = numel(x_radar_filtered);
dist_low_pn = zeros(1, numSteps);
estPos_low_pn = zeros(3, numSteps);
for i = 2:numSteps
    predict(cvekf, dt);
    dist_low_pn(i) = distance(cvekf, measPos(:,i)); % Distance from true position
    estPos_low_pn(:,i) = positionSelector * correct(cvekf, measPos(:,i));
end
hold on;
subplot(2, 1, 1);
plot(estPos_low_pn(1,:), estPos_low_pn(2,:), '-g', 'DisplayName', 'CV Low PN');
axis equal;
legend;

% Plot normalized distance for low process noise
hold on;
subplot(2, 1, 2);
plot((1:numSteps)*dt, dist_low_pn, 'g', 'DisplayName', 'CV Low PN');
title('Normalized Distance from Estimated Position to True Position');
xlabel('Time (s)');
ylabel('Normalized Distance');
legend;

% Increase the process noise for the constant-velocity filter
cvekf2 = trackingEKF(@constvel, @cvmeas, initialState, ...
    'StateTransitionJacobianFcn', @constveljac, ...
    'MeasurementJacobianFcn', @cvmeasjac, ...
    'StateCovariance', initialCovariance, ...
    'HasAdditiveProcessNoise', false, ...
    'ProcessNoise', diag([50, 50, 1])); % Large uncertainty in the horizontal acceleration

dist_high_pn = zeros(1, numSteps);
estPos_high_pn = zeros(3, numSteps);
for i = 2:numSteps
    predict(cvekf2, dt);
    dist_high_pn(i) = distance(cvekf2, measPos(:,i)); % Distance from true position
    estPos_high_pn(:,i) = positionSelector * correct(cvekf2, measPos(:,i));
end
hold on;
subplot(2, 1, 1);
plot(estPos_high_pn(1,:), estPos_high_pn(2,:), '-c', 'DisplayName', 'CV High PN');
axis equal;
legend;

% Plot normalized distance for high process noise
hold on;
subplot(2, 1, 2);
plot((1:numSteps)*dt, dist_high_pn, 'c', 'DisplayName', 'CV High PN');
title('Normalized Distance from Estimated Position to True Position');
xlabel('Time (s)');
ylabel('Normalized Distance');
legend;
