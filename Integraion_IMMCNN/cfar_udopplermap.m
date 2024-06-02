clear; clc; close all;
load("X:\Personals\Subin_Moon\Radar\0_u_DopplerMapData\walk\walk_adc_raw_data.mat");
load("X:\Personals\Subin_Moon\Radar\0_u_DopplerMapData\walk\walk_radarCube.mat");

%% parameters
chirpsIdx=50;chanIdx=1;frameIdx = 130;

% MTI parameter
MTIfiltering = 1;

% Range Azimuth FFT parameter
minRangeBinKeep = 0; rightRangeBinDiscard = 1; log_plot = 1; STATIC_ONLY = 0; angleFFTSize = 256;
ratio = 0.5; DopplerCorrection = 0; d = 1;

%% Radar cfg
numrangeBins=256;NChirp=128;NChan=4;NSample=256;Nframe = 256;c = 3e8;pri=76.51e-6;prf=1/pri;
start_frequency = 77e9;wavelength = c / start_frequency;slope = 32.7337;samples_per_chirp = 256;
chirps_per_frame = 128;sampling_rate = 5e9;bandwidth = 1.6760e9;range_resolution = c/(2*bandwidth);
velocity_resolution =wavelength/(2*pri*NChirp);sampling_time = NSample/sampling_rate;
max_vel = wavelength/(4*pri);max_range = sampling_rate*c/(2*slope);
frame_periodicity = 4e-2;

%% func
detected_points(:,:) = zeros(NSample, NChirp+1);
HistoryMap = zeros(Nframe, 2);

[frameComplex] = RESHAPE(NChirp, NChan, NSample, frameIdx, adcRawData);
[currChDataQ, currChDataI, t] = FT_TIME(NSample, sampling_time, chirpsIdx, chanIdx, frameComplex);
[rangeProfileData, radarCubeData_demo, channelData, rangeBin] = FT_RANGE(NChirp, NChan, NSample, ...
    chirpsIdx, chanIdx, numrangeBins, range_resolution, frameComplex);
[radarCubeData_mti, rangeProfileData_mti, channelData_mti] = MTI_filter(NChirp, NChan, NSample, ...
    chirpsIdx, chanIdx, radarCubeData_demo);
[max_row, max_col, maxValue, velocityAxis, doppler, doppler_mti, db_doppler] = FFT_DOPPLER(NChirp, NChan, NSample, ...
    chanIdx, max_vel, velocity_resolution, MTIfiltering, radarCubeData_demo, radarCubeData_mti);


%% CFAR
[detected_points_each] = CFAR(frameIdx, numrangeBins, rangeProfileData_mti, db_doppler);
% DBSCAN
[clusterGrid, R, C, Range] = DBSCAN(velocityAxis, rangeBin, detected_points_each);

%% find cetrio
[time_axis,micro_doppler] = microdoppler(NChirp, NChan, Nframe, C, radarCube);
sdb = squeeze(10*log10((abs(micro_doppler(:,chanIdx,:)))));

%% plot
figure('Position', [300,100, 1500, 500]);
tiledlayout(1,3);
nexttile;
imagesc(velocityAxis,rangeBin,db_doppler);
xlabel('Velocity (m/s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
title('Range-Doppler Map (MTI)');
colorbar;
axis xy

nexttile;
imagesc(velocityAxis,rangeBin,clusterGrid);
hold on;
xlabel('Velocity (m/s)');
ylabel('Range (m)');
title('Data Clustering');
axis xy
colorbar;

%% Save sdb as an image with custom size
figure('Position', [200, 100, 500, 400]);
axes('Position', [0 0 1 1], 'Units', 'normalized');
imagesc(time_axis, velocityAxis, sdb);
axis off;
colormap('gray');
set(gca, 'LooseInset', get(gca, 'TightInset'));
saveas(gca, 'sdb.jpeg');
close(gcf);

%% neural network
im = imread("sdb.jpeg"); 
im_gray = rgb2gray(im);  
im_resized = imresize(im_gray, [227 227]);

load('trainedNetwork.mat'); 

X = single(im_resized);
X = reshape(X, [227, 227, 1]); 

scores = predict(trainedNetwork_2, X);

[score, idx] = max(scores);
if exist('classNames', 'var') == 0
    classNames = {'Drone', 'Cycle', 'Human'}; 
end

label = classNames{idx};
nexttile;
imshow(im_resized);
score_percent = score * 100;
title(string(label) + " (Score: " + string(score_percent) + "%)", 'FontSize', 15);

