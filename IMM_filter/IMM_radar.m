clear; clc; close all;

load('x_radar_oneman.mat'); load('y_radar_oneman.mat');
t = linspace(0, 2*pi, length(x_radar));
dt = t(2) - t(1);

% 튀는 값 제거
mean_x = mean(x_radar);
std_x = std(x_radar);
mean_y = mean(y_radar);
std_y = std(y_radar);

threshold = 1; % 3 표준편차를 기준으로 이상치 제거
valid_indices = abs(x_radar - mean_x) < threshold * std_x & abs(y_radar - mean_y) < threshold * std_y;

x_radar_filtered = x_radar(valid_indices);
y_radar_filtered = y_radar(valid_indices);

% Plotting the position
figure;
subplot(2, 1, 1);
scatter(x_radar_filtered, y_radar_filtered, 5, 'red', 'filled', 'DisplayName', 'Radar detected');
xlabel('x');
ylabel('y');
title('Position');
legend;
hold on;

% Adjust layout
sgtitle('IMM filter Tracking ');
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

% Track using the constant-velocity filter
numSteps = numel(x_radar_filtered);
dist = zeros(1, numSteps);
estPos = zeros(3, numSteps);
for i = 2:numSteps
    predict(cvekf, dt);
    dist(i) = distance(cvekf, measPos(:,i)); % Distance from true position
    estPos(:,i) = positionSelector * correct(cvekf, measPos(:,i));
end
hold on;
subplot(2, 1, 1);
plot(estPos(1,:), estPos(2,:), '-g', 'DisplayName', 'CV Low PN');
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
plot(estPos(1,:), estPos(2,:), '-c', 'DisplayName', 'CV High PN');
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
plot(estPos(1,:), estPos(2,:), '-m', 'DisplayName', 'IMM');
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
