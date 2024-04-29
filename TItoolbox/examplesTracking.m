% Load data if unavailable. 
if ~exist('IndoorTIRadarData','dir')
    dataURL = "https://ssd.mathworks.com/supportfiles/timmwaveradar/data/IndoorTIRadarData.zip";
    datasetFolder = pwd;
    unzip(dataURL, datasetFolder);
end

% Load radar data
load(fullfile(pwd,'IndoorTIRadarData','IndoorTIRadarData.mat'),'detectionLog','timeLog');

% Load video data
vidReader = VideoReader(fullfile(pwd,'IndoorTIRadarData','IndoorTIRadarReferenceVideo.mp4'));

display = HelperTIRadarTrackingDisplay('XLimits',[0 15],...
    'YLimits',[-8 8],...
    'MaxRange',25,...
    'CameraReferenceLines',zeros(2,0),...
    'RadarReferenceLines',zeros(2,0));

refImage = read(vidReader, 140);
display(detectionLog{140}, {}, objectTrack.empty(0,1), refImage);

for k = 1:numel(detectionLog)
    detections = detectionLog{k};
    for j = 1:numel(detections)
        detections{j}.MeasurementNoise(1,1) = 9; % 3^2 deg^2
        detections{j}.MeasurementNoise(2,2) = 0.36; % 0.6^2 m^2
    end
    detectionLog{k} = detections;
end

minRangeRate = 0.5;

epsilon = 3;
minNumPts = 1;

tracker = trackerJPDA(TrackLogic="Integrated");
tracker.FilterInitializationFcn = @initPeopleTrackingFilter;

% Volume of measurement space
azSpan = 60;
rSpan = 25;
dopplerSpan = 5;
V = azSpan*rSpan*dopplerSpan;

% Number of false alarms per step
nFalse = 8;

% Number of new targets per step
nNew = 0.01;

% Probability of detecting the object
Pd = 0.9;

tracker.ClutterDensity = nFalse/V;
tracker.NewTargetDensity = nNew/V;
tracker.DetectionProbability = Pd;

% Confirm a track with more than 95 percent
% probability of existence
tracker.ConfirmationThreshold = 0.95; 

% Delete a track with less than 0.0001
% probability of existence
tracker.DeletionThreshold = 1e-4;

tracks = objectTrack.empty(0,1);

for k = 1:numel(detectionLog)
    % Timestamp
    time = timeLog(k);

    % Radar at current time stamp
    detections = detectionLog{k};
    
    % Remove static returns
    isDynamic = false(1,numel(detections));
    for d = 1:numel(detections)
        isDynamic(d) = abs(detections{d}.Measurement(3)) > minRangeRate;
    end
    detectionsDynamic = detections(isDynamic);

    % Camera image
    refImage = read(vidReader, k);

    % Cluster detections
    if isempty(detectionsDynamic)
        clusters = zeros(0,1,'uint32');
    else
        clusters = partitionDetections(detectionsDynamic,epsilon,minNumPts,'Algorithm','DBSCAN');
    end
    
    % Centroid estimation
    clusteredDets = mergeDetections(detectionsDynamic, clusters);

    % % Track centroid returns
    if isLocked(tracker) || ~isempty(clusteredDets)
        tracks = tracker(clusteredDets, time);
    end

    % Update display
    display(detections, clusteredDets, tracks, refImage);

    if abs((time - 15)) <= 0.05
        im = getframe(gcf);
    end
end

f = figure;
imshow(im.cdata,'Parent',axes(f));

function filter = initPeopleTrackingFilter(detection)
% Create 3-D filter first
filter3D = initcvekf(detection);

% Create 2-D filter from the 3-D
state = filter3D.State(1:4);
stateCov = filter3D.StateCovariance(1:4,1:4);

% Reduce uncertainty in cross range-rate to 5 m/s
velCov = stateCov([2 4],[2 4]);
[v, d] = eig(velCov);
D = diag(d);
D(2) = 1;
stateCov([2 4],[2 4]) = v*diag(D)*v';

% Process noise in a slowly changing environment
Q = 0.25*eye(2);

filter = trackingEKF(State = state,...
    StateCovariance = stateCov,...
    StateTransitionFcn = @constvel,...
    StateTransitionJacobianFcn = @constveljac,...
    HasAdditiveProcessNoise = false,...
    MeasurementFcn = @cvmeas,...
    MeasurementJacobianFcn = @cvmeasjac,...
    ProcessNoise = Q,...
    MeasurementNoise = detection.MeasurementNoise);

end