clear; clc; close all;
% MATLAB code to integrate provided data for tracking maneuvering targets

% Define the scenario
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
subplot(2, 1, 1);
plot(x, y, 'DisplayName', 'True position'); hold on;
scatter(x_gps, y_gps, 5, 'red', 'filled', 'DisplayName', 'GPS measurements');
xlabel('x');
ylabel('y');
title('Position');
legend;
hold on;

% % Plotting the angular speed
% subplot(2,2,2);
% plot(t, omega, 'DisplayName', 'True angular speed'); hold on;
% scatter(t, omega_sens, 5, 'red', 'filled', 'DisplayName', 'Measured angular speed');
% xlabel('Time');
% ylabel('Angular Speed');
% title('Angular Speed');
% legend;
% 
% % Plotting the speed
% subplot(2,2,3);
% plot(t, speed, 'DisplayName', 'True speed'); hold on;
% scatter(t, speed_sens, 5, 'red', 'filled', 'DisplayName', 'Measured speed');
% xlabel('Time');
% ylabel('Speed');
% title('Speed');
% legend;

% Adjust layout
sgtitle('Position, Angular Speed, and Speed');
set(gcf, 'Position', [100, 100, 800, 600]);

% Integrate generated data into tracking filters

% Define measurements to be the position with noise
measPos = [x_gps; y_gps; zeros(size(x_gps))];

% Define the initial state and covariance
positionSelector = [1 0 0 0 0 0; 0 0 1 0 0 0; 0 0 0 0 1 0]; % Position from state
initialState = positionSelector' * measPos(:,1);
initialCovariance = diag([1, 1e4, 1, 1e4, 1, 1e4]); % Velocity is not measured

% Create a constant-velocity trackingEKF
cvekf = trackingEKF(@constvel, @cvmeas, initialState, ...
    'StateTransitionJacobianFcn', @constveljac, ...
    'MeasurementJacobianFcn', @cvmeasjac, ...
    'StateCovariance', initialCovariance, ...
    'HasAdditiveProcessNoise', false, ...
    'ProcessNoise', eye(3));

% Track using the constant-velocity filter
numSteps = numel(t);
dist = zeros(1, numSteps);
estPos = zeros(3, numSteps);
for i = 2:numSteps
    predict(cvekf, dt);
    dist(i) = distance(cvekf, measPos(:,i)); % Distance from true position
    estPos(:,i) = positionSelector * correct(cvekf, measPos(:,i));
end
hold on;
subplot(2, 1, 1);
plot(estPos(1,:), estPos(2,:), '.g', 'DisplayName', 'CV Low PN');
title('True and Estimated Positions with CV Filter');
axis equal;
legend;

% Plot normalized distance
hold on;
subplot(2, 1, 2);
plot((1:numSteps)*dt, dist, 'g', 'DisplayName', 'CV Low PN');
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

dist = zeros(1, numSteps);
estPos = zeros(3, numSteps);
for i = 2:numSteps
    predict(cvekf2, dt);
    dist(i) = distance(cvekf2, measPos(:,i)); % Distance from true position
    estPos(:,i) = positionSelector * correct(cvekf2, measPos(:,i));
end
hold on;
subplot(2, 1, 1);
plot(estPos(1,:), estPos(2,:), '.c', 'DisplayName', 'CV High PN');
title('True and Estimated Positions with Increased Process Noise');
axis equal;
legend;

% Plot normalized distance
hold on;
subplot(2, 1, 2);
plot((1:numSteps)*dt, dist, 'c', 'DisplayName', 'CV High PN');
title('Normalized Distance from Estimated Position to True Position');
xlabel('Time (s)');
ylabel('Normalized Distance');
legend;

% Use an interacting multiple-model (IMM) filter
imm = trackingIMM('TransitionProbabilities', 0.99); % Default IMM with three models
initialize(imm, initialState, initialCovariance);

% Track using the IMM filter
dist = zeros(1, numSteps);
estPos = zeros(3, numSteps);
modelProbs = zeros(3, numSteps);
modelProbs(:,1) = imm.ModelProbabilities;
for i = 2:numSteps
    predict(imm, dt);
    dist(i) = distance(imm, measPos(:,i)); % Distance from true position
    estPos(:,i) = positionSelector * correct(imm, measPos(:,i));
    modelProbs(:,i) = imm.ModelProbabilities;
end
hold on;
subplot(2, 1, 1);
plot(estPos(1,:), estPos(2,:), '.m', 'DisplayName', 'IMM');
title('True and Estimated Positions with IMM Filter');
axis equal;
legend;

% Plot normalized distance
hold on;
subplot(2, 1, 2);
plot((1:numSteps)*dt, dist, 'm', 'DisplayName', 'IMM');
title('Normalized Distance from Estimated Position to True Position');
xlabel('Time (s)');
ylabel('Normalized Distance');
legend;

% Plot model probabilities
figure;
plot((1:numSteps)*dt, modelProbs);
title('Model Probabilities vs. Time');
xlabel('Time (s)');
ylabel('Model Probabilities');
legend('IMM-CV', 'IMM-CA', 'IMM-CT');
